// hoi4_http_client.cpp — outbound HTTP(S) via cpp-httplib + mbedTLS.
//
// One HTTP stack for both directions now: server = hoi4_http_server.cpp
// (loopback, no TLS), client = this file (TLS via mbedTLS, Windows root
// store verification through httplib's load_system_certs path). Replaces
// the former WinHTTP transport + hoi4_relay.cpp loopback CONNECT relay:
// WinHTTP existed for Schannel TLS with zero deps, the relay existed only
// because WinHTTP picks addresses v6-first and hangs on broken-IPv6 boxes.
// httplib's set_hostname_addr_map pins a probe-selected IP while SNI /
// Host / cert validation stay on the real hostname, so family selection
// lives in ~60 lines here instead of a proxy + thread.
//
// What is still WinHTTP: proxy DISCOVERY only (WinHttpGetIEProxyConfigFor-
// CurrentUser / WinHttpGetProxyForUrl — the OS's own settings sources;
// winhttp.dll is part of Windows, not a vendored library). Transport never
// touches it.
//
// API: hoi4.http_request(method, url, headers, body [, timeout_ms])
//   method/url: strings (http/https only)
//   headers: single string, one "Name: value" per line (any newline form).
//     nil = none.
//   body: string or nil (nil -> no request body; method decides semantics)
//   timeout_ms: optional HARD DEADLINE for the whole request (default
//     180000). The exchange runs on a worker thread; the caller waits at
//     most the remaining budget and bails with (nil, "timeout") on expiry
//     (the worker is left running, bounded by its own per-phase timeouts —
//     a detached abandoned completion simply drops its result).
// Returns (status:int, body:string) on HTTP-level completion, or
// (nil, err:string) on transport failure.
// THREAD MODEL: safe on any thread, BLOCKS THE CALLER. From the main VM a
// call freezes the frame — always go through async_exec from gameplay code.
#ifndef CPPHTTPLIB_MBEDTLS_SUPPORT
#define CPPHTTPLIB_MBEDTLS_SUPPORT
#endif
#include "hoi4_common.h"
#include "third-party/httplib/httplib.h"

#include <winhttp.h>
#include <atomic>
#include <chrono>
#include <map>
#include <memory>
#include <string>
#include <thread>

// ---------------------------------------------------------------- config
#define HC_BODY_CAP   (4u * 1024u * 1024u)   // 4MB receive cap
#define HC_UA         "hoi4_bridge/1.0 (httplib-mbedtls)"
#define HC_DEFAULT_TIMEOUT_MS  180000
#define HC_CONNECT_CAP_MS      30000         // connect phase ceiling
#define HC_PROBE_MS            1200          // per-address probe budget
#define HC_PROBE_TOTAL_MS      2500          // whole-probe ceiling (eats budget)

// ---------------------------------------------------------------- url parse
struct ParsedUrl {
    std::string scheme, host;      // host: no brackets even for v6 literals
    std::string port;              // decimal string (defaulted)
    std::string path_with_query;   // always starts with '/'
    int         port_num = 0;
};

static bool hc_is_ip_literal(const std::string &h) {
    if (!h.empty() && h[0] == '[') return true;
    for (char c : h) {
        if (c == ':') return true;                       // v6 literal
        if (!(c >= '0' && c <= '9') && c != '.') return false;
    }
    return true;                                          // digits+dots = v4
}

static bool parse_url(const std::string &url, ParsedUrl &out, std::string &err) {
    size_t p = url.find("://");
    if (p == std::string::npos) { err = "url not http/https"; return false; }
    out.scheme = url.substr(0, p);
    for (char &c : out.scheme) c = (char)tolower((unsigned char)c);
    if (out.scheme != "http" && out.scheme != "https") {
        err = "url not http/https"; return false;
    }
    std::string rest = url.substr(p + 3);
    // path/query starts at the first '/' or '?'
    size_t slash = rest.find_first_of("/?");
    std::string authority = (slash == std::string::npos) ? rest : rest.substr(0, slash);
    std::string pq = (slash == std::string::npos) ? "" : rest.substr(slash);
    if (pq.empty()) pq = "/";
    else if (pq[0] == '?') pq = "/" + pq;
    // strip userinfo
    size_t at = authority.rfind('@');
    if (at != std::string::npos) authority = authority.substr(at + 1);
    // v6 literal: [addr] or [addr]:port
    if (!authority.empty() && authority[0] == '[') {
        size_t close = authority.find(']');
        if (close == std::string::npos) { err = "bad ipv6 literal"; return false; }
        out.host = authority.substr(1, close - 1);
        if (close + 1 < authority.size()) {
            if (authority[close + 1] != ':') { err = "bad authority"; return false; }
            out.port = authority.substr(close + 2);
        }
    } else {
        size_t colon = authority.rfind(':');
        if (colon != std::string::npos) {
            out.host = authority.substr(0, colon);
            out.port = authority.substr(colon + 1);
        } else {
            out.host = authority;
        }
    }
    if (out.host.empty() || out.host.size() > 255) { err = "bad host"; return false; }
    if (out.port.empty()) {
        out.port_num = (out.scheme == "https") ? 443 : 80;
    } else {
        char *end = nullptr;
        long v = strtol(out.port.c_str(), &end, 10);
        if (!end || *end != 0 || v <= 0 || v > 65535) { err = "bad port"; return false; }
        out.port_num = (int)v;
    }
    out.path_with_query = pq;
    return true;
}

// ---------------------------------------------------------------- probe
// non-blocking connect with timeout; 1 = connected (relay.c lineage)
// *werr: first failing winsock error code seen (for one-line diagnostics)
static int probe_try_connect(SOCKET so, const struct sockaddr *sa, int salen,
                             int ms_timeout, int *werr) {
    u_long nb = 1;
    ioctlsocket(so, FIONBIO, &nb);
    int rc = connect(so, sa, salen);
    if (rc == 0) return 1;
    int e = WSAGetLastError();
    if (e != WSAEWOULDBLOCK) { if (*werr == 0) *werr = e; return 0; }
    fd_set wf, ef;
    FD_ZERO(&wf); FD_ZERO(&ef); FD_SET(so, &wf); FD_SET(so, &ef);
    TIMEVAL tv = { ms_timeout / 1000, (ms_timeout % 1000) * 1000 };
    if (select(0, NULL, &wf, &ef, &tv) <= 0) {
        if (*werr == 0) *werr = WSAETIMEDOUT;
        return 0;
    }
    int err = 0, len = sizeof(err);
    getsockopt(so, SOL_SOCKET, SO_ERROR, (char *)&err, &len);
    if (err != 0 && *werr == 0) *werr = err;
    return err == 0;
}

// Probe resolved addresses v4-first and return the first reachable IP
// (for set_hostname_addr_map pinning). Broken-IPv6 boxes: a dead v6 never
// stalls the request. Returns "" when probing is pointless (IP literal) or
// nothing answered — callers then fall through to the direct path.
static std::string probe_direct_addr(const std::string &host,
                                     const std::string &port,
                                     long long *budget_ms) {
    if (hc_is_ip_literal(host)) return "";
    char portA[16];
    _snprintf_s(portA, sizeof(portA), _TRUNCATE, "%s", port.c_str());
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    struct addrinfo *res = NULL;
    if (getaddrinfo(host.c_str(), portA, &hints, &res) != 0 || !res) return "";

    std::string picked;
    int nv4 = 0, nv6 = 0, werr = 0, sockfail = 0;
    DWORD64 t0 = GetTickCount64();
    for (int pass = 0; pass < 2 && picked.empty(); pass++) {
        for (struct addrinfo *ai = res; ai && picked.empty(); ai = ai->ai_next) {
            if ((pass == 0) != (ai->ai_family == AF_INET)) continue;
            if (ai->ai_family == AF_INET) nv4++; else nv6++;
            long long left = *budget_ms - (long long)(GetTickCount64() - t0);
            if (left < 300) break;                     // probing ate the budget
            int ms = (int)(left < HC_PROBE_MS ? left : HC_PROBE_MS);
            SOCKET so = socket(ai->ai_family, SOCK_STREAM, IPPROTO_TCP);
            if (so == INVALID_SOCKET) { if (!sockfail) sockfail = WSAGetLastError(); continue; }
            if (probe_try_connect(so, ai->ai_addr, (int)ai->ai_addrlen, ms,
                                  &werr)) {
                char ip[64] = {0};
                InetNtopA(ai->ai_family,
                          ai->ai_family == AF_INET
                              ? (void *)&((struct sockaddr_in *)ai->ai_addr)->sin_addr
                              : (void *)&((struct sockaddr_in6 *)ai->ai_addr)->sin6_addr,
                          ip, sizeof(ip));
                picked = ip;
            }
            closesocket(so);
        }
    }
    freeaddrinfo(res);
    *budget_ms -= (long long)(GetTickCount64() - t0);
    if (*budget_ms < 0) *budget_ms = 0;
    L("[httpc] probe %s nv4=%d nv6=%d sockfail=%d werr=%d -> %s", host.c_str(),
      nv4, nv6, sockfail, werr, picked.empty() ? "none" : picked.c_str());
    return picked;
}

// ---------------------------------------------------------------- proxy
// utf-8 -> wide (heap). caller HeapFrees. (httpclient.cpp lineage)
static wchar_t *hc_widen(const char *s, size_t n) {
    if (!s) return NULL;
    if (n == 0) n = strlen(s);
    int wlen = MultiByteToWideChar(CP_UTF8, 0, s, (int)n, NULL, 0);
    if (wlen <= 0) return NULL;
    wchar_t *w = (wchar_t *)HeapAlloc(GetProcessHeap(), 0,
                                      (size_t)(wlen + 1) * sizeof(wchar_t));
    if (!w) return NULL;
    MultiByteToWideChar(CP_UTF8, 0, s, (int)n, w, wlen);
    w[wlen] = 0;
    return w;
}

// pick host:port from a PAC-style proxy string ("h:p" or "http=h:p;https=h:p")
static bool proxy_from_pac_string(const wchar_t *w, std::string &host, int &port) {
    if (!w || !*w) return false;
    int wlen = (int)wcslen(w);
    int alen = WideCharToMultiByte(CP_UTF8, 0, w, wlen, NULL, 0, NULL, NULL);
    if (alen <= 0) return false;
    std::string s((size_t)alen, 0);
    WideCharToMultiByte(CP_UTF8, 0, w, wlen, &s[0], alen, NULL, NULL);
    // prefer the https= entry, then http=, then the bare token
    std::string token;
    size_t best = std::string::npos, bestlen = 0;
    size_t pos = 0;
    int prio_best = -1;
    while (pos <= s.size()) {
        size_t semi = s.find(';', pos);
        std::string e = (semi == std::string::npos) ? s.substr(pos)
                                                    : s.substr(pos, semi - pos);
        int prio = 0;
        if (e.rfind("https=", 0) == 0) { e = e.substr(6); prio = 2; }
        else if (e.rfind("http=", 0) == 0) { e = e.substr(5); prio = 1; }
        if (!e.empty() && prio >= prio_best) { best = 1; token = e; prio_best = prio; }
        if (semi == std::string::npos) break;
        pos = semi + 1;
    }
    if (best == std::string::npos || token.empty()) return false;
    size_t colon = token.rfind(':');
    if (colon == std::string::npos) { host = token; port = 80; return true; }
    host = token.substr(0, colon);
    port = atoi(token.c_str() + colon + 1);
    if (port <= 0 || port > 65535) port = 80;
    return !host.empty();
}

// The IE proxy config API does not expose the ProxyEnable toggle and leaks
// a stale lpszProxy after the user turns the proxy off — gate the static
// branch on the registry value ourselves.
static bool ie_proxy_enabled(void) {
    DWORD v = 0, size = sizeof(v);
    if (RegGetValueW(HKEY_CURRENT_USER,
                     L"Software\\Microsoft\\Windows\\CurrentVersion"
                     L"\\Internet Settings",
                     L"ProxyEnable", RRF_RT_REG_DWORD, NULL, &v,
                     &size) != ERROR_SUCCESS)
        return false;
    return v != 0;
}

// System proxy discovery via the OS's own settings sources (IE config +
// WPAD). Transport never touches WinHTTP — only these two discovery calls.
static bool discover_proxy(const std::string &url, std::string &host, int &port) {
    wchar_t *wurl = hc_widen(url.c_str(), url.size());
    if (!wurl) return false;
    bool found = false;
    HINTERNET hs = WinHttpOpen(L"hoi4_bridge/1.0 (proxy discovery)",
                               WINHTTP_ACCESS_TYPE_NO_PROXY,
                               WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    do {
        WINHTTP_CURRENT_USER_IE_PROXY_CONFIG ie;
        memset(&ie, 0, sizeof(ie));
        if (WinHttpGetIEProxyConfigForCurrentUser(&ie)) {
            if (ie.fAutoDetect) {
                WINHTTP_AUTOPROXY_OPTIONS ao;
                memset(&ao, 0, sizeof(ao));
                ao.dwFlags = WINHTTP_AUTOPROXY_AUTO_DETECT;
                ao.dwAutoDetectFlags = WINHTTP_AUTO_DETECT_TYPE_DHCP |
                                       WINHTTP_AUTO_DETECT_TYPE_DNS_A;
                ao.fAutoLogonIfChallenged = TRUE;
                WINHTTP_PROXY_INFO pi;
                memset(&pi, 0, sizeof(pi));
                if (WinHttpGetProxyForUrl(hs, wurl, &ao, &pi) &&
                    pi.dwAccessType == WINHTTP_ACCESS_TYPE_NAMED_PROXY) {
                    found = proxy_from_pac_string(pi.lpszProxy, host, port);
                }
            } else if (ie.lpszProxy && ie_proxy_enabled()) {
                // static per-user proxy. bypass list not honored (rare on the
                // toolchain's targets; document and accept)
                found = proxy_from_pac_string(ie.lpszProxy, host, port);
            }
        }
    } while (0);
    if (hs) WinHttpCloseHandle(hs);
    HeapFree(GetProcessHeap(), 0, wurl);
    return found;
}

// ---------------------------------------------------------------- task
struct HttpTask {
    HANDLE done = NULL;                    // manual-reset, signaled by worker
    std::shared_ptr<httplib::Client> cli;  // worker-owned
    httplib::Request req;
    bool ok = false;
    std::string err;
    int status = 0;
    std::string body;
};

static const char *httplib_err_str(httplib::Error e) {
    switch (e) {
    case httplib::Error::Connection:            return "connection failed";
    case httplib::Error::BindIPAddress:         return "bind failed";
    case httplib::Error::Read:                  return "read failed";
    case httplib::Error::Write:                 return "write failed";
    case httplib::Error::ExceedRedirectCount:   return "redirect loop";
    case httplib::Error::Canceled:              return "canceled";
    case httplib::Error::SSLConnection:         return "TLS handshake failed";
    case httplib::Error::SSLLoadingCerts:       return "cert load failed";
    case httplib::Error::SSLServerVerification: return "cert verification failed";
    case httplib::Error::ProxyConnection:       return "proxy connect failed";
    case httplib::Error::ConnectionTimeout:     return "connect timeout";
    case httplib::Error::Timeout:               return "socket timeout";
    case httplib::Error::ExceedMaxPayloadSize:  return "payload too large";
    default:                                    return "unknown transport error";
    }
}

static int hc_fail(lua_State *Ls, const char *msg) {
    lua_pushnil(Ls);
    lua_pushstring(Ls, msg);
    return 2;
}

int hoi4_http_request(lua_State *Ls) {
    size_t ml = 0, ul = 0, hl = 0, bl = 0;
    const char *method  = luaL_checklstring(Ls, 1, &ml);
    const char *url     = luaL_checklstring(Ls, 2, &ul);
    const char *headers = lua_isnoneornil(Ls, 3) ? NULL : luaL_checklstring(Ls, 3, &hl);
    const char *body    = lua_isnoneornil(Ls, 4) ? NULL : luaL_checklstring(Ls, 4, &bl);
    long timeout_ms = lua_isnoneornil(Ls, 5) ? HC_DEFAULT_TIMEOUT_MS
                                             : (long)luaL_checkinteger(Ls, 5);
    if (timeout_ms < 1000) timeout_ms = 1000;
    if (!method || !*method || ml > 15 || !url || ul < 9 || ul > 2040)
        return hc_fail(Ls, "bad method/url");

    ParsedUrl u;
    std::string err;
    if (!parse_url(url, u, err)) return hc_fail(Ls, err.c_str());

    long long budget = (long long)timeout_ms;
    std::string proxy_host;
    int proxy_port = 0;
    bool has_proxy = discover_proxy(url, proxy_host, proxy_port);
    std::string direct_addr;
    if (!has_proxy) {
        // family selection: probe v4-first and pin the winner (replaces
        // hoi4_relay.cpp). Probing eats the deadline budget.
        direct_addr = probe_direct_addr(u.host, u.port, &budget);
    }
    L("[httpc] %s %s proxy=%d pin=%s", method, url, (int)has_proxy,
      direct_addr.empty() ? "-" : direct_addr.c_str());
    long long remaining = budget;      // probe already decremented it in place
    if (remaining < 1000) remaining = 1000;

    auto task = std::make_shared<HttpTask>();
    task->done = CreateEventA(NULL, TRUE, FALSE, NULL);
    if (!task->done) return hc_fail(Ls, "event create failed");
    task->req.method = method;
    task->req.path = u.path_with_query;
    if (body) task->req.body.assign(body, bl);
    task->req.headers.emplace("User-Agent", HC_UA);
    if (headers && hl) {
        // "Name: value" lines, any newline form
        std::string h(headers, hl);
        size_t pos = 0;
        while (pos < h.size()) {
            size_t e = h.find('\n', pos);
            if (e == std::string::npos) e = h.size();
            size_t b = pos, ee = e;
            if (ee > b && h[ee - 1] == '\r') ee--;
            size_t colon = h.find(':', b);
            if (colon < ee && colon > b) {
                size_t vs = colon + 1;
                while (vs < ee && (h[vs] == ' ' || h[vs] == '\t')) vs++;
                task->req.headers.emplace(h.substr(b, colon - b),
                                          h.substr(vs, ee - vs));
            }
            pos = e + 1;
        }
    }

    // connect-phase budget in whole seconds (1..HC_CONNECT_CAP_MS/1000)
    long long conn_s = remaining / 1000;
    if (conn_s > HC_CONNECT_CAP_MS / 1000) conn_s = HC_CONNECT_CAP_MS / 1000;
    if (conn_s < 1) conn_s = 1;
    std::chrono::milliseconds rw_ms(remaining);

    // 1-arg ctor with the full scheme://host:port — httplib 0.56's 2-arg
    // (host, port) form does NOT strip the scheme and fails to connect.
    // v6 literals need brackets back for URL form (parse_url stripped them).
    std::string host = u.host;
    if (host.find(':') != std::string::npos) host = "[" + host + "]";
    task->cli = std::make_shared<httplib::Client>(u.scheme + "://" + host +
                                                  ":" + u.port);
    task->cli->set_connection_timeout(std::chrono::seconds(conn_s));
    task->cli->set_read_timeout(rw_ms);
    task->cli->set_write_timeout(rw_ms);
    task->cli->set_payload_max_length(HC_BODY_CAP);
    if (has_proxy) {
        task->cli->set_proxy(proxy_host, proxy_port);
    } else if (!direct_addr.empty()) {
        task->cli->set_hostname_addr_map({{u.host, direct_addr}});
    }

    std::string urlS(url);                 // log label for the worker
    std::thread([task, urlS] {
        httplib::Response res;
        httplib::Error e;
        task->ok = (task->cli->send(task->req, res, e));
        if (task->ok) {
            task->status = res.status;
            task->body = std::move(res.body);
        } else {
            task->err = httplib_err_str(e);
        }
        L("[httpc] done %s ok=%d status=%d err=%s", urlS.c_str(), (int)task->ok,
          task->status, task->err.c_str());
        SetEvent(task->done);   // no waiter on timeout path: result is dropped
    }).detach();

    DWORD w = WaitForSingleObject(task->done, (DWORD)remaining);
    if (w != WAIT_OBJECT_0) return hc_fail(Ls, "timeout");
    if (!task->ok) return hc_fail(Ls, task->err.c_str());
    // Audit records host+port+sizes ONLY - never headers, never the query
    // string. The shipped example mod sends "Authorization: Bearer <key>"
    // (example_autopilot.lua:560), so logging either would turn the audit trail
    // into a secret store.
    audit_net(Ls, method, u.host.c_str(), u.port_num, u.scheme.c_str(),
              (long long)(bl ? bl : 0), (int)task->status,
              (long long)task->body.size());
    lua_pushinteger(Ls, (lua_Integer)task->status);
    lua_pushlstring(Ls, task->body.data(), task->body.size());
    return 2;
}

// register hoi4.http_request into an arbitrary state (main VM already covers
// it via hoi4_lib; async worker states need an explicit call after openlibs).
void hoi4_register_http(lua_State *Ls) {
    lua_getglobal(Ls, "hoi4");
    if (!lua_istable(Ls, -1)) {
        lua_pop(Ls, 1);
        lua_newtable(Ls);
        lua_setglobal(Ls, "hoi4");
        lua_getglobal(Ls, "hoi4");
    }
    lua_pushcfunction(Ls, hoi4_http_request);
    lua_setfield(Ls, -2, "http_request");
    lua_pop(Ls, 1);
}

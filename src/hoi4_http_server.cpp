// hoi4_http_server.cpp — local HTTP service
//
// Loopback-only HTTP/1.1 control plane for the toolchain. Execution model
// reuses the proven IPC discipline: engine-touching work runs ONLY on the
// main thread at frame top (http_poll_main, called from tick_dispatch_lua
// with g_luaLock held); httplib worker threads only queue + wait.
//
// Endpoints (v1):
//   GET  /health       {version, session_active, paused, game_hour, speed}
//   POST /console      body: raw cmd line or {"cmd": "..."}          (main-thread console_invoke_core)
//   POST /lua          body: raw chunk or {"chunk": "..."}           (main-thread lua_exec_chunk)
//   POST /game/pause   body: state int or {"state": n}               (main-thread, toggle semantics)
//   GET  /events       SSE stream: session_start/session_end + heartbeat
// Sampling profiler (thin wrappers; params as query args):
//   POST /profile/start?ms=1&stacks=1    POST /profile/stop
//   POST /profile/top?n=40               POST /profile/folded[?path=...]
//   GET  /profile/status
//
// Switch: -http[=port] on the game command line (explicit opt-in, same
// discipline as -ipc). Default port 17389. Loopback bind only.

#include "hoi4_common.h"
#include "third-party/httplib/httplib.h"

#include <atomic>
#include <string>
#include <vector>
#include <mutex>
#include <deque>
#include <stdlib.h>       // free() for the unbounded echo paths
#include <unordered_map>
#include <cstdlib>

#define HTTP_DEFAULT_PORT 17389
#define HTTP_PAYLOAD_MAX   (64 * 1024)
#define HTTP_REQ_TIMEOUT_MS 120000

// ---------------------------------------------------------------- req queue
// kinds executed on the main thread
enum ReqKind {
    RK_CONSOLE = 1, RK_LUA = 2, RK_PAUSE = 3,
    RK_PROF_START = 4, RK_PROF_STOP = 5, RK_PROF_TOP = 6,
    RK_PROF_FOLDED = 7, RK_PROF_STATUS = 8, RK_PROF_THREADS = 9,
};

struct HttpReq {
    uint64_t    id = 0;
    ReqKind     kind = RK_CONSOLE;
    std::string payload;              // cmd / chunk / state string / folded path
    long        a = 0, b = 0;         // profile params: ms + flags(bit0 stacks,bit1 all), or n
    // completion
    HANDLE      done = nullptr;       // manual-reset event, signaled by main
    int         status = 0;           // executor's ok flag
    std::string result;
    // ownership: exactly ONE side closes done/deletes r. The worker deletes on
    // the normal path; on timeout it marks `abandoned` and the MAIN thread
    // deletes after exec_one finishes (worker used to delete at timeout while
    // main still held the queued pointer -> UAF).
    volatile LONG abandoned = 0;
};

static std::mutex              g_qMtx;
static std::deque<HttpReq *>   g_queue;
static std::atomic<uint64_t>   g_reqSeq{0};

// ---------------------------------------------------------------- SSE bus
// Fan-out ring: every event gets a monotonic seq; each /events client tracks
// its own cursor and reads everything newer (the old shared pop-queue only
// delivered each event to ONE arbitrary client).
struct EvItem { uint64_t seq; std::string frame; };
static std::mutex              g_evMtx;
static std::deque<EvItem>      g_events;      // bounded ring, 256 entries
static uint64_t                g_evSeq = 0;
static HANDLE                  g_evSignal = nullptr;   // auto-reset wakeup hint

static void sse_json_escape(std::string &out, const char *s) {
    for (const char *p = s; *p; p++) {
        switch (*p) {
        case '"':  out += "\\\""; break;
        case '\\': out += "\\\\"; break;
        case '\n': out += "\\n"; break;
        case '\r': break;
        case '\t': out += "\\t"; break;
        default:   out += *p; break;
        }
    }
}

extern "C" void http_push_event(const char *name, const char *payload) {
    if (!name) return;
    std::string frame = "data: {\"event\":\"";
    sse_json_escape(frame, name);
    if (payload && *payload) {
        frame += "\",\"info\":\"";
        sse_json_escape(frame, payload);
    }
    frame += "\"}\n\n";
    {
        std::lock_guard<std::mutex> lk(g_evMtx);
        if (g_events.size() >= 256) g_events.pop_front();
        g_events.push_back({++g_evSeq, std::move(frame)});
    }
    if (g_evSignal) SetEvent(g_evSignal);
}

// ---------------------------------------------------------------- main side
static void exec_one(HttpReq *r) {
    char out[8192];              // shared scratch for the profiler paths below
    out[0] = 0;
    switch (r->kind) {
    case RK_CONSOLE: {
        // unbounded echo: the old fixed 8KB stack buffer cut long output
        // (list_flags / help / any dump command) with no signal to the caller
        size_t len = 0; int ok = 0;
        char *s = console_invoke_alloc(r->payload.c_str(), &len, &ok);
        r->status = ok;
        r->result = s ? std::string(s, len) : std::string();
        free(s);
        break;
    }
    case RK_LUA: {
        size_t len = 0; int ok = 0;
        char *s = lua_exec_chunk_alloc(r->payload.c_str(), &len, &ok);
        r->status = ok;
        r->result = s ? std::string(s, len) : std::string();
        free(s);
        break;
    }
    case RK_PAUSE: {
        // strict whole-string int parse (atoi silently maps "abc"/"" to 0)
        const char *s = r->payload.c_str();
        char *end = nullptr;
        long v = strtol(s, &end, 10);
        while (end && (*end == ' ' || *end == '\t' ||
                       *end == '\r' || *end == '\n')) end++;
        if (end == s || (end && *end != 0)) {
            r->status = 0;
            r->result = "bad state (want integer)";
        } else {
            r->status = game_pause_invoke((int)v);
            r->result = r->status ? "ok" : "failed (no game/manager)";
        }
        break;
    }
    case RK_PROF_START: {
        // sampler target = this main thread (frame-top execution guarantees it)
        const char *err = samp_api_start((unsigned)(r->a > 0 ? r->a : 1),
                                         (int)(r->b & 1), GetCurrentThreadId(),
                                         (int)((r->b >> 1) & 1),
                                         out, sizeof(out));
        r->status = err ? 0 : 1;
        r->result = err ? err : out;
        break;
    }
    case RK_PROF_STOP:
        r->status = samp_api_stop(out, sizeof(out));
        r->result = r->status ? out : "profile not running";
        break;
    case RK_PROF_TOP: {
        // top can legitimately outgrow the shared 8 KB buffer: big cap here
        static char big[65536];                  // exec_one is main-thread-only
        int n = (int)(r->a > 0 ? r->a : 30);
        r->status = samp_api_top(n, big, sizeof(big));
        r->result = r->status ? big : "profile never started";
        break;
    }
    case RK_PROF_FOLDED:
        r->status = samp_api_folded(r->payload.empty() ? nullptr
                                                       : r->payload.c_str(),
                                    out, sizeof(out));
        r->result = r->status ? out
                              : "no stack data (start with stacks=1) or write failed";
        break;
    case RK_PROF_STATUS:
        samp_api_status(out, sizeof(out));
        r->status = 1;
        r->result = out;
        break;
    case RK_PROF_THREADS: {
        static char big[65536];                  // exec_one is main-thread-only
        r->status = samp_api_threads(big, sizeof(big));
        r->result = big;
        break;
    }
    }
}

// frame-top executor (g_luaLock held, main thread)
extern "C" int http_poll_main(int max_requests) {
    int ran = 0;
    while (ran < max_requests) {
        HttpReq *r = nullptr;
        {
            std::lock_guard<std::mutex> lk(g_qMtx);
            if (!g_queue.empty()) {
                r = g_queue.front();
                g_queue.pop_front();
            }
        }
        if (!r) break;
        exec_one(r);
        if (InterlockedCompareExchange(&r->abandoned, 0, 0)) {
            // worker already timed out and gave up ownership: clean up here
            CloseHandle(r->done);
            delete r;
        } else {
            SetEvent(r->done);   // worker still waiting: it deletes
        }
        ran++;
    }
    return ran;
}

// ---------------------------------------------------------------- handlers
// extract a top-level "key":"string" from a tiny JSON body (bounded scan —
// no full parser; bodies are ours). Returns true on hit.
static bool json_str(const std::string &body, const char *key, std::string &out) {
    std::string needle = "\"";
    needle += key;
    needle += "\"";
    size_t p = body.find(needle);
    if (p == std::string::npos) return false;
    p = body.find(':', p + needle.size());
    if (p == std::string::npos) return false;
    p = body.find('"', p + 1);
    if (p == std::string::npos) return false;
    size_t e = body.find('"', p + 1);
    if (e == std::string::npos) return false;
    out = body.substr(p + 1, e - p - 1);
    return true;
}

// payload extraction: raw text, or {"cmd":..} / {"chunk":..} / {"state":..}
static std::string pick_payload(const httplib::Request &req, const char *key) {
    std::string v;
    if (!req.body.empty() && req.body[0] == '{' && json_str(req.body, key, v))
        return v;
    return req.body;
}

static void run_main_thread_req(const httplib::Request &req,
                                httplib::Response &res, ReqKind kind,
                                const char *key, long pa = 0, long pb = 0,
                                const char *payload_override = nullptr) {
    if (req.body.size() > HTTP_PAYLOAD_MAX) {
        res.status = 413;
        res.set_content("{\"ok\":false,\"error\":\"payload too large\"}",
                        "application/json");
        return;
    }
    HttpReq *r = new HttpReq();
    r->id = ++g_reqSeq;
    r->kind = kind;
    r->payload = payload_override ? payload_override : pick_payload(req, key);
    r->a = pa;
    r->b = pb;
    r->done = CreateEventA(nullptr, TRUE, FALSE, nullptr);
    {
        std::lock_guard<std::mutex> lk(g_qMtx);
        g_queue.push_back(r);
    }
    DWORD w = WaitForSingleObject(r->done, HTTP_REQ_TIMEOUT_MS);
    if (w == WAIT_OBJECT_0) {
        // main thread has finished exec_one and signaled; result is complete.
        std::string body = "{\"ok\":";
        body += r->status ? "true" : "false";
        body += ",\"result\":\"";
        // JSON-escape the result text (quotes/backslash/newlines)
        for (char c : r->result) {
            switch (c) {
            case '"':  body += "\\\""; break;
            case '\\': body += "\\\\"; break;
            case '\n': body += "\\n"; break;
            case '\r': break;
            case '\t': body += "\\t"; break;
            default:   body += c; break;
            }
        }
        body += "\"}";
        res.set_content(body, "application/json");
        CloseHandle(r->done);
        delete r;
    } else {
        // Timeout: hand ownership to the main thread (it owns cleanup once it
        // sees `abandoned`). We must NOT touch r or r->done after this point —
        // the queue still holds the pointer and exec_one may run any frame.
        InterlockedExchange(&r->abandoned, 1);
        res.status = 504;
        res.set_content("{\"ok\":false,\"error\":\"main-thread timeout\"}",
                        "application/json");
    }
}

// ---------------------------------------------------------------- server
static std::atomic<bool> g_started{false};
static httplib::Server  *g_svr = nullptr;

// CGameDate 总小时 -> "Y.M.D.H" (语义逐项对齐 sv2_lib.lua SL.date, 即存档
// 提取器形态): 哨兵 0 / 0x29C3388 ("‑1.1.1.1" 合法日期) / 43808760 (ctor)
// -> 空串; 无闰年 365 日历; 小时 = h%24+1。校验: test1 -> "1937.7.5.22"。
static void hoi4_date_str(unsigned h, char *out, size_t cap) {
    out[0] = 0;
    if (h == 0 || h == 0x29C3388u || h == 43808760u) return;
    long long day0 = ((long long)h - 43800000LL) / 24;
    long long yr = day0 / 365, dd = day0 % 365;
    static const int ML[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
    int mo = 0;
    for (int i = 0; i < 12; i++) {
        if (dd < ML[i]) { mo = i + 1; break; }
        dd -= ML[i];
    }
    if (mo == 0) { mo = 12; dd = 0; }
    _snprintf_s(out, cap, _TRUNCATE, "%lld.%d.%lld.%d",
                yr, mo, dd + 1, h % 24 + 1);
}

static DWORD WINAPI http_server_thread(LPVOID arg) {
    int port = (int)(uintptr_t)arg;
    httplib::Server svr;
    g_svr = &svr;

    svr.Get("/health", [](const httplib::Request &, httplib::Response &res) {
        // session_active = frame heartbeat alive (menu keeps a frontend gs,
        // so gs!=0 alone is wrong there); hour/speed only meaningful in game.
        int in_game = session_in_game();
        int paused = game_paused_read();
        uint64_t gs = h4_rd64((uint64_t)(uintptr_t)g_base + RVA_GAMESTATE_PTR, 0);
        unsigned hour = (in_game && gs) ? h4_rd32(gs + GS_GAME_HOUR, 0) : 0u;
        char date[32];
        hoi4_date_str(hour, date, sizeof(date));
        char body[320];
        _snprintf_s(body, sizeof(body), _TRUNCATE,
                    "{\"ok\":true,\"version\":\"%s\","
                    "\"session_active\":%s,\"paused\":%s,"
                    "\"date\":%s%s%s,\"game_hour\":%u,\"speed\":%d}",
                    offsets_version(),
                    in_game ? "true" : "false",
                    paused < 0 ? "null" : (paused ? "true" : "false"),
                    date[0] ? "\"" : "",
                    date[0] ? date : "null",
                    date[0] ? "\"" : "",
                    hour,
                    (in_game && gs) ? (int)h4_rd32(gs + GS_SPEED, 0) : -1);
        res.set_content(body, "application/json");
    });

    svr.Post("/console", [](const httplib::Request &req, httplib::Response &res) {
        run_main_thread_req(req, res, RK_CONSOLE, "cmd");
    });
    svr.Post("/lua", [](const httplib::Request &req, httplib::Response &res) {
        run_main_thread_req(req, res, RK_LUA, "chunk");
    });
    svr.Post("/game/pause", [](const httplib::Request &req, httplib::Response &res) {
        run_main_thread_req(req, res, RK_PAUSE, "state");
    });

    // ---- sampling profiler (/profile/*) — thin wrappers over the same
    // frame-top queue; params arrive as query args, results in "result".
    //   POST /profile/start?ms=1&stacks=1&scope=all    (stacks=栈模式; scope=all=全线程)
    //   POST /profile/stop                     stop, keep data
    //   POST /profile/top?n=40                 leaf histogram top lines
    //   POST /profile/folded?path=...          write folded stacks file
    //   GET  /profile/status                   counters
    //   GET  /profile/threads                  per-tid hits/cpu (scope=all)
    svr.Post("/profile/start", [](const httplib::Request &req, httplib::Response &res) {
        long ms = 1, flags = 0;
        if (req.has_param("ms"))     ms = strtol(req.get_param_value("ms").c_str(), nullptr, 10);
        if (req.has_param("stacks")) flags |= strtol(req.get_param_value("stacks").c_str(), nullptr, 10) ? 1 : 0;
        if (req.has_param("scope") && req.get_param_value("scope") == "all") flags |= 2;
        run_main_thread_req(req, res, RK_PROF_START, "", ms, flags);
    });
    svr.Post("/profile/stop", [](const httplib::Request &req, httplib::Response &res) {
        run_main_thread_req(req, res, RK_PROF_STOP, "");
    });
    svr.Post("/profile/top", [](const httplib::Request &req, httplib::Response &res) {
        long n = 30;
        if (req.has_param("n")) n = strtol(req.get_param_value("n").c_str(), nullptr, 10);
        run_main_thread_req(req, res, RK_PROF_TOP, "", n);
    });
    svr.Post("/profile/folded", [](const httplib::Request &req, httplib::Response &res) {
        std::string q;
        const char *ovr = nullptr;
        if (req.has_param("path")) { q = req.get_param_value("path"); ovr = q.c_str(); }
        run_main_thread_req(req, res, RK_PROF_FOLDED, "path", 0, 0, ovr);
    });
    svr.Get("/profile/status", [](const httplib::Request &req, httplib::Response &res) {
        run_main_thread_req(req, res, RK_PROF_STATUS, "");
    });
    svr.Get("/profile/threads", [](const httplib::Request &req, httplib::Response &res) {
        run_main_thread_req(req, res, RK_PROF_THREADS, "");
    });

    svr.Get("/events", [](const httplib::Request &, httplib::Response &res) {
        res.set_chunked_content_provider(
            "text/event-stream",
            [](size_t /*offset*/, httplib::DataSink &sink) {
                // per-client cursor over the shared ring: start at "now"
                // (history before connect is not replayed), then deliver every
                // event with seq > cursor. Heartbeats actually get WRITTEN —
                // the old code built the frame and then dropped it.
                uint64_t cursor;
                {
                    std::lock_guard<std::mutex> lk(g_evMtx);
                    cursor = g_evSeq;
                }
                for (;;) {
                    std::vector<std::string> pending;
                    {
                        std::lock_guard<std::mutex> lk(g_evMtx);
                        for (const auto &e : g_events) {
                            if (e.seq > cursor) {
                                pending.push_back(e.frame);
                                cursor = e.seq;
                            }
                        }
                    }
                    bool alive = true;
                    for (const auto &f : pending) {
                        if (!sink.write(f.data(), f.size())) { alive = false; break; }
                    }
                    if (!alive) return false;               // client gone
                    if (!pending.empty()) continue;         // drain first
                    if (WaitForSingleObject(g_evSignal, 15000) != WAIT_OBJECT_0) {
                        static const char hb[] = ": heartbeat\n\n";
                        if (!sink.write(hb, sizeof(hb) - 1))
                            return false;                   // client gone
                    }
                }
            },
            [](bool) {});
    });

    // enforce the 64 KiB cap at the httplib layer too (the handler-side check
    // only runs after the WHOLE body has been read and allocated; httplib's
    // default ceiling is 100 MiB).
    svr.set_payload_max_length(HTTP_PAYLOAD_MAX);

    L("[http] server ready on 127.0.0.1:%d", port);
    bool ok = svr.listen("127.0.0.1", port);
    L("[http] listen() returned %d, server exiting", ok ? 1 : 0);
    g_svr = nullptr;
    g_started = false;
    return 0;
}

static void http_start_on_port(int port) {
    if (port < 1024) port = 1024;
    if (port > 65535) port = 65535;
    if (g_started.exchange(true)) return;
    g_evSignal = CreateEventA(nullptr, FALSE, FALSE, nullptr);
    HANDLE h = CreateThread(NULL, 0, http_server_thread,
                            (LPVOID)(uintptr_t)port, 0, NULL);
    if (h) CloseHandle(h);
    else { g_started = false; L("[http] server thread create FAILED"); }
}

// Exported for the attach-injection fallback (a1_attach_inject.py): the
// remote thread calls this with a single int (rcx) to bring the HTTP
// service up in an already-running game where no -http cmdline flag exists.
extern "C" __declspec(dllexport) void __cdecl http_enable(int port) {
    if (port <= 0) port = HTTP_DEFAULT_PORT;
    if (!g_initialized) {
        // P5: arrived before lua_init_thread finished (racy attach path).
        // Refuse rather than serve requests against a half-built VM.
        L("[http] http_enable(%d) refused: runtime not initialized", port);
        return;
    }
    L("[http] http_enable(%d)", port);
    http_start_on_port(port);
}

extern "C" void http_maybe_autostart(void) {
    const char *cl = GetCommandLineA();
    if (!cl) return;
    const char *p = strstr(cl, "-http");
    if (!p) return;
    p += 5;
    int port = HTTP_DEFAULT_PORT;
    if (*p == '=') {
        port = atoi(p + 1);
        if (port <= 0) port = HTTP_DEFAULT_PORT;
    }
    L("[http] cmdline flag found, enabling on 127.0.0.1:%d", port);
    http_start_on_port(port);
}

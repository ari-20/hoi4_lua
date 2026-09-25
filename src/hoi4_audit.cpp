// hoi4_audit.cpp - external-boundary audit log for mod Lua.
//
// WHY THIS EXISTS
// The preventive controls (hoi4_harden.cpp strips the stdlib, hoi4_lua_policy.cpp
// scopes file access) cover the filesystem and the network. They cannot cover
// the framework's highest-risk capability - arbitrary game-memory writes and
// engine calls - because sandboxing those would delete the framework. So the
// remaining control for that surface is visibility: the log is the detection
// layer, not a nicety.
//
// The companion question - "did a write corrupt world state?" - is already
// answered by the lua_verify export/diff toolchain (the sv2 segments and
// linediff). This module deliberately does not duplicate it. It answers a
// different question: what crossed the process boundary, and who put it there.
//
// BOUNDEDNESS - the design rule that shapes everything below
// Sizing the log by "the shipped mods call this rarely" was rejected: mods are
// external input, and the cost of being wrong is a log that floods exactly when
// something is going wrong. So volume is bounded STRUCTURALLY instead:
//
//   * external-boundary events (net, file access, code load) are logged per
//     DISTINCT TARGET - first sight full line, repeats increment a counter and
//     are reported as "xN". Volume scales with how many different hosts/paths
//     exist (human-scale), never with call count.
//   * every denial is logged in full, always. A denial flood is itself evidence
//     and must never be deduplicated away.
//   * internal primitives (mem read/write, engine calls, console) are
//     AGGREGATED only, summarised once per mod at session end.
//
// CREDENTIALS - never log request headers or the query string. The shipped
// example mod sends "Authorization: Bearer <api key>"
// (example_autopilot.lua:560), so headers/URLs would turn this log into a
// secret store. Record host + port + byte counts only.
//
// The audit directory is deliberately NOT registered as a path-policy root, so
// mod Lua cannot open this log (hoi4_lua_policy.cpp rejects any path outside a
// registered root). The preventive control protects the detection control for
// free - do not "helpfully" add it to the root table.

#include "hoi4_common.h"

#include <wchar.h>

#define AUDIT_MAX_DISTINCT  512      // distinct targets tracked before folding
#define AUDIT_MAX_MODS       32
#define AUDIT_LINE_MAX      512
#define AUDIT_ROTATE_BYTES  (8u * 1024u * 1024u)
#define AUDIT_ROTATE_KEEP    10

// --------------------------------------------------------------- level + state

typedef enum { AUDIT_OFF = 0, AUDIT_NORMAL = 1, AUDIT_VERBOSE = 2 } AuditLevel;

static AuditLevel g_level = AUDIT_NORMAL;   // default ON: a security log that
                                            // defaults off is never recording
                                            // when it is needed
static char       g_levelName[16];          // for the test harness / diagnostics

// ------------------------------------------------------------------ distinct

// One entry per distinct target. `count` is how many times it was seen; the
// first sighting is what gets a full log line.
typedef struct {
    char table[16];
    char target[384];
    unsigned count;
    int    used;
} AuditDistinct;

static AuditDistinct g_distinct[AUDIT_MAX_DISTINCT];
static int  g_distinctCount;
static int  g_distinctFolded;               // overflow: stop allocating, keep counting
static SRWLOCK g_auditLock = SRWLOCK_INIT;

// ------------------------------------------------------------- aggregates

// Internal primitives: counts per mod per class, emitted once at session end.
typedef struct {
    char mod[64];
    unsigned long long mem_read, mem_write, engine_call, console, code_load;
    // console command names are a small fixed set and it is the privileged
    // channel (console("save x") writes a file; console("lua <chunk>") is code
    // execution), so a per-name histogram is the minimum useful granularity.
    char     cmd[16][48];
    unsigned cmdCount[16];
    int      cmdN;
} AuditAgg;

static AuditAgg g_agg[AUDIT_MAX_MODS];
static int      g_aggCount;

static AuditAgg *agg_for(const char *mod) {
    for (int i = 0; i < g_aggCount; i++)
        if (strcmp(g_agg[i].mod, mod) == 0) return &g_agg[i];
    if (g_aggCount >= AUDIT_MAX_MODS) return &g_agg[AUDIT_MAX_MODS - 1];
    AuditAgg *a = &g_agg[g_aggCount++];
    memset(a, 0, sizeof(*a));
    snprintf(a->mod, sizeof(a->mod), "%s", mod);
    return a;
}

static void agg_console_cmd(AuditAgg *a, const char *name) {
    if (!name || !*name) return;
    for (int i = 0; i < a->cmdN; i++)
        if (strcmp(a->cmd[i], name) == 0) { a->cmdCount[i]++; return; }
    if (a->cmdN >= 16) return;
    snprintf(a->cmd[a->cmdN], sizeof(a->cmd[0]), "%s", name);
    a->cmdCount[a->cmdN] = 1;
    a->cmdN++;
}

// ------------------------------------------------------------- output sink

static HANDLE g_file = INVALID_HANDLE_VALUE;
static char   g_path[MAX_PATH];
static unsigned long long g_bytes;
static char   g_buf[AUDIT_LINE_MAX * 32];
static size_t g_bufLen;

// TSV safety: a tab or newline inside a field would break the column contract.
// Only those two are escaped - JSON-style escaping is unnecessary and the
// escaping itself is a common corruption source.
static void tsv_safe(const char *in, char *out, size_t cap) {
    size_t o = 0;
    for (const char *p = in; p && *p && o + 2 < cap; p++) {
        if (*p == '\t')      { out[o++] = '\\'; out[o++] = 't'; }
        else if (*p == '\n') { out[o++] = '\\'; out[o++] = 'n'; }
        else if (*p == '\r') { out[o++] = '\\'; out[o++] = 'r'; }
        else                   out[o++] = *p;
    }
    out[o] = 0;
}

static void audit_rotate(void) {
    if (g_file == INVALID_HANDLE_VALUE || g_path[0] == 0) return;
    if (g_bytes < AUDIT_ROTATE_BYTES) return;
    CloseHandle(g_file);
    g_file = INVALID_HANDLE_VALUE;
    char from[MAX_PATH], to[MAX_PATH];
    for (int i = AUDIT_ROTATE_KEEP - 1; i >= 1; i--) {
        snprintf(from, sizeof(from), "%s.%d", g_path, i);
        snprintf(to, sizeof(to), "%s.%d", g_path, i + 1);
        MoveFileExA(from, to, MOVEFILE_REPLACE_EXISTING);
    }
    snprintf(to, sizeof(to), "%s.1", g_path);
    MoveFileExA(g_path, to, MOVEFILE_REPLACE_EXISTING);
    g_file = CreateFileA(g_path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                         OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (g_file != INVALID_HANDLE_VALUE) {
        SetFilePointer(g_file, 0, NULL, FILE_END);
        g_bytes = 0;
    }
}

// Buffered append. `flush` is for the events whose tail matters most after a
// crash; the rest ride the buffer. Deliberately NOT FlushFileBuffers per line -
// that is what makes L() expensive.
static void audit_write(const char *line, int flush) {
    if (g_level == AUDIT_OFF || g_file == INVALID_HANDLE_VALUE) return;
    size_t n = strlen(line);
    if (n + 1 > sizeof(g_buf) - g_bufLen) {
        DWORD w;
        if (g_bufLen) WriteFile(g_file, g_buf, (DWORD)g_bufLen, &w, NULL);
        g_bytes += g_bufLen;
        g_bufLen = 0;
        audit_rotate();
    }
    if (n + 1 > sizeof(g_buf)) {                 // oversized line: write direct
        DWORD w;
        WriteFile(g_file, line, (DWORD)n, &w, NULL);
        WriteFile(g_file, "\n", 1, &w, NULL);
        g_bytes += n + 1;
        return;
    }
    memcpy(g_buf + g_bufLen, line, n);
    g_bufLen += n;
    g_buf[g_bufLen++] = '\n';
    if (flush) {
        DWORD w;
        WriteFile(g_file, g_buf, (DWORD)g_bufLen, &w, NULL);
        g_bytes += g_bufLen;
        g_bufLen = 0;
    }
}

static void ts_now(char *out, size_t cap) {
    SYSTEMTIME st; GetLocalTime(&st);
    snprintf(out, cap, "%04d-%02d-%02dT%02d:%02d:%02d.%03d",
             st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond,
             st.wMilliseconds);
}

// ------------------------------------------------------------ attribution

// Walks the C call stack for the first frame whose source is a file ("@path").
// Uses the C API (lua_getstack/lua_getinfo), NOT the Lua-visible `debug` table -
// which matters because hoi4_harden.cpp reduces `debug` to getinfo/traceback.
// The two features therefore do not conflict; attribution keeps working.
//
// CAVEAT: the source string is attacker-controlled in principle - a mod can
// call load(chunk, "@any/path.lua"). Treat this column as indicative, not
// authoritative; the fs_exec event records the REAL path plus a content hash and
// is the column to cross-check against.
void audit_attribute(lua_State *Ls, char *out, size_t cap, int *line) {
    lua_Debug ar;
    for (int lvl = 1; lvl < 12; lvl++) {
        if (!lua_getstack(Ls, lvl, &ar)) break;
        if (!lua_getinfo(Ls, "Sl", &ar)) break;
        if (ar.source && ar.source[0] == '@') {
            const char *p = ar.source + 1;
            // Report the path relative to the mod root when it lives under one,
            // so the column stays short and stable across machines.
            const char *slash = strstr(p, "/mods/");
            snprintf(out, cap, "%s", slash ? slash + 6 : p);
            if (line) *line = ar.currentline;
            return;
        }
    }
    snprintf(out, cap, "(native/C)");
    if (line) *line = 0;
}

// Extracts the mod directory name from a source path. The path is reported
// relative to "mods/" by audit_attribute, so the mod name is simply the first
// component. Placeholder sources such as "(native/C)" have no mod and must not
// be truncated at their slash - that produced a literal "(native" in the log.
static const char *mod_of_source(const char *source) {
    if (!source || source[0] == '(') return "-";
    const char *slash = strchr(source, '/');
    if (!slash) return "-";
    static char buf[64];
    size_t n = (size_t)(slash - source);
    if (n >= sizeof(buf)) n = sizeof(buf) - 1;
    memcpy(buf, source, n);
    buf[n] = 0;
    return buf;
}

// ------------------------------------------------------- distinct-target memo

// Returns 1 when this (table,target) pair is NEW (caller emits a full line),
// 0 when it is a repeat (the counter was bumped and nothing is emitted).
static int distinct_first(const char *table, const char *target,
                          unsigned *outCount) {
    AcquireSRWLockExclusive(&g_auditLock);
    for (int i = 0; i < g_distinctCount; i++) {
        if (strcmp(g_distinct[i].table, table) == 0 &&
            strcmp(g_distinct[i].target, target) == 0) {
            g_distinct[i].count++;
            if (outCount) *outCount = g_distinct[i].count;
            ReleaseSRWLockExclusive(&g_auditLock);
            return 0;
        }
    }
    if (g_distinctCount < AUDIT_MAX_DISTINCT) {
        AuditDistinct *d = &g_distinct[g_distinctCount++];
        snprintf(d->table, sizeof(d->table), "%s", table);
        snprintf(d->target, sizeof(d->target), "%s", target);
        d->count = 1;
        d->used = 1;
        if (outCount) *outCount = 1;
    } else {
        g_distinctFolded++;                     // bounded: stop allocating
        if (outCount) *outCount = 0;
    }
    ReleaseSRWLockExclusive(&g_auditLock);
    return 1;
}

// ------------------------------------------------------------------ emit

static void emit(const char *event, const char *mod, const char *source,
                 int line, const char *target, const char *detail, int flush) {
    char tm[32], ev[24], md[64], src[192], tg[400], dt[256];
    ts_now(tm, sizeof(tm));
    tsv_safe(event, ev, sizeof(ev));
    tsv_safe(mod, md, sizeof(md));
    tsv_safe(source, src, sizeof(src));
    tsv_safe(target, tg, sizeof(tg));
    tsv_safe(detail, dt, sizeof(dt));
    char linebuf[AUDIT_LINE_MAX];
    snprintf(linebuf, sizeof(linebuf), "%s\t%s\t%s\t%s:%d\t%s\t%s",
             tm, ev, md, src, line, tg, dt);
    audit_write(linebuf, flush);
}

// ---------------------------------------------------- external boundary API

// File-system event. Called from hoi4_lua_policy.cpp's pol_check (the single
// funnel every io.open/lines/input/output/remove/rename passes through) and
// directly from the hoi4.* file helpers that scope themselves and therefore
// never reach pol_check.
void audit_fs(lua_State *Ls, const char *op, const char *path, int denied,
              const char *reason) {
    if (g_level == AUDIT_OFF) return;
    char src[192]; int line = 0;
    audit_attribute(Ls, src, sizeof(src), &line);
    const char *mod = mod_of_source(src);

    if (denied) {
        // Denials are never deduplicated: a flood is the evidence.
        emit("fs_deny", mod, src, line, path, reason ? reason : "", 1);
        return;
    }
    unsigned n = 0;
    char key[400];
    snprintf(key, sizeof(key), "%s|%s", op, path);
    if (!distinct_first("fs", key, &n)) return;   // repeat: counted, not logged
    emit("fs", mod, src, line, path, op, 0);
}

// Network event. Records host + port + sizes ONLY.
// NEVER headers (the example mod sends an Authorization bearer token) and never
// the query string (it can carry keys too).
void audit_net(lua_State *Ls, const char *method, const char *host, int port,
               const char *scheme, long long bytes_out, int status,
               long long bytes_in) {
    if (g_level == AUDIT_OFF) return;
    char src[192]; int line = 0;
    audit_attribute(Ls, src, sizeof(src), &line);
    char target[400], detail[256];
    snprintf(target, sizeof(target), "%s:%d", host ? host : "?", port);
    snprintf(detail, sizeof(detail), "scheme=%s method=%s out=%lld status=%d in=%lld",
             scheme ? scheme : "?", method ? method : "?", bytes_out, status, bytes_in);
    unsigned n = 0;
    char key[400];
    snprintf(key, sizeof(key), "%s:%d", host ? host : "?", port);
    if (!distinct_first("net", key, &n)) return;
    emit("net", mod_of_source(src), src, line, target, detail, 1);
}

// Memory-domain denial (hoi4_memgate policy, 2026-09-23): a write_* target
// outside the write domain or a call_u64 target outside the engine's
// executable sections. Never deduplicated — same reasoning as fs_deny.
void audit_mem_deny(lua_State *Ls, const char *kind, uint64_t addr,
                    const char *why) {
    if (g_level == AUDIT_OFF) return;
    char src[192]; int line = 0;
    audit_attribute(Ls, src, sizeof(src), &line);
    char target[40];
    snprintf(target, sizeof(target), "%llx", (unsigned long long)addr);
    emit("mem_deny", mod_of_source(src), src, line, target,
         why ? why : "", 1);
}

// vtable-slot hook install / uninstall / refusal (hoi4_hook.cpp). This is a
// code-redirection facility, so every install is recorded — but unlike
// mem_deny, a SUCCESSFUL install is logged too (a redirect that happened is
// exactly as interesting as one that was refused). Deduplicated per
// (op,id,target) so a hot reload does not spam a line per frame.
void audit_hook(lua_State *Ls, const char *op, const char *id, uint64_t vt,
                int slot, const char *detail) {
    if (g_level == AUDIT_OFF) return;
    char src[192]; int line = 0;
    audit_attribute(Ls, src, sizeof(src), &line);
    char key[600], target[64];
    snprintf(key, sizeof(key), "%s|%s|%llx|%d", op, id ? id : "-",
             (unsigned long long)vt, slot);
    unsigned n = 0;
    if (!distinct_first("hook", key, &n)) return;
    snprintf(target, sizeof(target), "%llx+%d", (unsigned long long)vt, slot);
    emit("hook", mod_of_source(src), src, line, target, detail ? detail : "", 1);
}

// Code load (dofile / loadfile). Deduplicated by content hash so a hot reload// loop or sv2_export's 57-file reload does not emit 57 lines per call - while a
// CONTENT change always produces a new line, which incidentally gives a code
// provenance timeline for free.
void audit_code_load(lua_State *Ls, const char *path, const char *sha256_hex) {
    if (g_level == AUDIT_OFF) return;
    char src[192]; int line = 0;
    audit_attribute(Ls, src, sizeof(src), &line);
    char key[600];
    snprintf(key, sizeof(key), "%s|%s", path, sha256_hex ? sha256_hex : "-");
    unsigned n = 0;
    if (!distinct_first("code", key, &n)) return;
    char detail[128];
    snprintf(detail, sizeof(detail), "sha256=%.16s", sha256_hex ? sha256_hex : "-");
    emit("fs_exec", mod_of_source(src), src, line, path, detail, 1);
}

// Internal-primitive counters. Cheap by construction: no stack walk unless the
// caller is sampling (see audit_sample_attributed).
void audit_bump(lua_State *Ls, const char *cls) {
    if (g_level == AUDIT_OFF) return;
    (void)Ls;
    AcquireSRWLockExclusive(&g_auditLock);
    AuditAgg *a = agg_for("(pending)");         // attributed later at summary
    if (strcmp(cls, "mem_read") == 0)        a->mem_read++;
    else if (strcmp(cls, "mem_write") == 0)  a->mem_write++;
    else if (strcmp(cls, "engine_call") == 0)a->engine_call++;
    else if (strcmp(cls, "console") == 0)    a->console++;
    ReleaseSRWLockExclusive(&g_auditLock);
}

// read_* is the one class that runs into the millions during an export, so it is
// counted every call but only ATTRIBUTED by sampling. The counter answers "how
// much"; the sample answers "who", at 1/N cost.
// read and write share check_addr(), so the write path must not be counted here.
#define AUDIT_READ_SAMPLE 10000
static volatile LONG g_readTick;
void audit_read_tick(lua_State *Ls) {
    if (g_level == AUDIT_OFF) return;
    if (InterlockedIncrement(&g_readTick) % AUDIT_READ_SAMPLE) return;
    char src[192]; int line = 0;
    audit_attribute(Ls, src, sizeof(src), &line);
    AcquireSRWLockExclusive(&g_auditLock);
    AuditAgg *a = agg_for(mod_of_source(src));
    a->mem_read++;                              // the sample's attribution
    ReleaseSRWLockExclusive(&g_auditLock);
}

// --------------------------------------------------------------- lifecycle

static void audit_summary(void) {
    for (int i = 0; i < g_aggCount; i++) {
        AuditAgg *a = &g_agg[i];
        char detail[256];
        snprintf(detail, sizeof(detail),
                 "mem_read=%llu mem_write=%llu engine_call=%llu console=%llu",
                 a->mem_read, a->mem_write, a->engine_call, a->console);
        emit("summary", a->mod, "-", 0, "-", detail, 1);
        for (int c = 0; c < a->cmdN; c++) {
            char cd[128];
            snprintf(cd, sizeof(cd), "cmd=%s x%u", a->cmd[c], a->cmdCount[c]);
            emit("console_cmd", a->mod, "-", 0, a->cmd[c], cd, 0);
        }
    }
    if (g_distinctFolded) {
        char d[96];
        snprintf(d, sizeof(d), "folded=%d", g_distinctFolded);
        emit("summary", "-", "-", 0, "-", d, 1);
    }
    char d[128];
    snprintf(d, sizeof(d), "distinct_targets=%d", g_distinctCount);
    emit("session_end", "-", "-", 0, "-", d, 1);
}

void audit_session_start(const char *game_build, const char *bridge_ver) {
    if (g_level == AUDIT_OFF) return;
    char d[256];
    snprintf(d, sizeof(d), "game=%s bridge=%s",
             game_build ? game_build : "?", bridge_ver ? bridge_ver : "?");
    emit("session_start", "-", "-", 0, "-", d, 1);
}

void audit_session_end(void) {
    if (g_level == AUDIT_OFF) return;
    audit_summary();
    if (g_file != INVALID_HANDLE_VALUE) {
        DWORD w;
        if (g_bufLen) WriteFile(g_file, g_buf, (DWORD)g_bufLen, &w, NULL);
        g_bufLen = 0;
        FlushFileBuffers(g_file);
    }
}

// Opens <dir>/hoi4_audit.log in APPEND mode. The existing bridge log uses
// CREATE_ALWAYS, which truncates on every launch and is exactly why it cannot
// serve as an audit trail.
void audit_open(const char *dir_utf8) {
    if (g_level == AUDIT_OFF || !dir_utf8 || !*dir_utf8) return;
    if (g_file != INVALID_HANDLE_VALUE) return;      // idempotent
    // Normalise the separator: callers legitimately hand in forward slashes
    // (that is what the Lua side and the path helpers produce), but
    // CreateDirectoryA does not accept a mixed "D:/x\audit" form and fails
    // silently, which would disable auditing without a trace.
    char root[MAX_PATH];
    snprintf(root, sizeof(root), "%s", dir_utf8);
    for (char *p = root; *p; p++) if (*p == '/') *p = '\\';
    size_t rl = strlen(root);
    while (rl > 0 && root[rl - 1] == '\\') root[--rl] = 0;

    char sub[MAX_PATH], path[MAX_PATH];
    snprintf(sub, sizeof(sub), "%s\\audit", root);
    // Recursive create: CreateDirectoryA only makes the LAST component, so a
    // missing parent (fresh install, or a caller that has not resolved the logs
    // dir yet) would fail with ERROR_PATH_NOT_FOUND and silently disable
    // auditing. Walk the path and create each level.
    char walk[MAX_PATH];
    snprintf(walk, sizeof(walk), "%s", sub);
    for (char *p = walk + 3; *p; p++) {
        if (*p != '\\') continue;
        *p = 0;
        CreateDirectoryA(walk, NULL);
        *p = '\\';
    }
    if (!CreateDirectoryA(sub, NULL) && GetLastError() != ERROR_ALREADY_EXISTS) {
        L("[audit] cannot create %s (err %d) - auditing disabled", sub,
          GetLastError());
        return;
    }
    snprintf(path, sizeof(path), "%s\\hoi4_audit.log", sub);
    HANDLE h = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                           OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        L("[audit] cannot open %s (err %d) - auditing disabled", path,
          GetLastError());
        return;
    }
    // Publish the handle LAST: every emit path tests g_file, so assigning a
    // valid handle before the path/buffer state is ready would let a
    // concurrent writer emit against a half-initialised sink.
    SetFilePointer(h, 0, NULL, FILE_END);
    snprintf(g_path, sizeof(g_path), "%s", path);
    g_bytes = 0;
    g_bufLen = 0;
    g_file = h;
    L("[audit] appending to %s (level=%s)", g_path, g_levelName);
}

// HOI4_AUDIT=off|normal|verbose, or -audit=<level> on the command line
// (single-dash args pass through to hoi4.exe, same mechanism as -http).
void audit_init_config(void) {
    const char *lvl = getenv("HOI4_AUDIT");
    if (!lvl || !*lvl) {
        const char *cl = GetCommandLineA();
        const char *p = cl ? strstr(cl, "-audit=") : NULL;
        if (p) lvl = p + 7;
    }
    if (lvl && *lvl) {
        if (_strnicmp(lvl, "off", 3) == 0)          g_level = AUDIT_OFF;
        else if (_strnicmp(lvl, "verbose", 7) == 0) g_level = AUDIT_VERBOSE;
        else                                        g_level = AUDIT_NORMAL;
    }
    snprintf(g_levelName, sizeof(g_levelName), "%s",
             g_level == AUDIT_OFF ? "off" :
             g_level == AUDIT_VERBOSE ? "verbose" : "normal");
}

// Test/diagnostic accessors.
int  audit_level_get(void)  { return (int)g_level; }
void audit_level_set(int l) { g_level = (AuditLevel)l; }
int  audit_distinct_count(void) { return g_distinctCount; }

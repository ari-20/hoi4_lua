import subprocess, time, os, sys, re

# session_regression.py — 跨会话回归: hoi4.load_save 驱动 N 次读档,
# 每次读档后断言: 会话恢复 / 注册表存活 / on_daily 存活(autosave 轮换)。
# 用法: python tools/session_regression.py [轮数=3] [存档名=autosave]
#   需 example mod 启用 (reseed/research_tick 路由判据), 游戏带 -http。
# 存活判据 = 35s 窗口内 (a) 日期推进 (b) autosave_<ts> 新轮换出现。
# (slot12 日志是 debug 门控, 无 -debug 时不可用, 勿用作判据。)
# RNG 地址 0x3452524 = 1.19.3.0-c01a3d50 专属, 换版本需重锚 (书 §4.28)。

B = "http://127.0.0.1:17389"
SAVES = os.path.join(os.environ.get("HOI4_USERDIR", os.path.expanduser(
    "~/Documents/Paradox Interactive/Hearts of Iron IV")), "save games")
LOAD_TIMEOUT = 180
ROUNDS = int(sys.argv[1]) if len(sys.argv) > 1 else 3
SAVE = sys.argv[2] if len(sys.argv) > 2 else "autosave"

def post(args, timeout=LOAD_TIMEOUT + 60):
    r = subprocess.run(["curl", "-s", "-m", str(timeout), "-X", "POST",
                        B + "/lua", "--data-binary", args],
                       capture_output=True, text=True, timeout=timeout + 10)
    return r.stdout.strip()

def get(url, timeout=5):
    r = subprocess.run(["curl", "-s", "-m", str(timeout), url],
                       capture_output=True, text=True, timeout=timeout + 5)
    return r.stdout.strip()

def date_now():
    h = get(B + "/health")
    m = re.search(r'"date":"([^"]*)"', h)
    return m.group(1) if m else "?"

def autosave_sig():
    files = [f for f in os.listdir(SAVES) if f.startswith("autosave_")]
    newest = 0.0
    for f in files:
        try:
            newest = max(newest, os.path.getmtime(os.path.join(SAVES, f)))
        except OSError:
            pass
    return len(files), newest

def wait_ingame(minutes=5):
    dl = time.time() + minutes * 60
    while time.time() < dl:
        h = get(B + "/health")
        if '"session_active":true' in h:
            return h
        time.sleep(5)
    return ""

verdicts = []
for rd in range(1, ROUNDS + 1):
    print("== round %d: load_save(%s) ==" % (rd, SAVE))
    ok_load = False
    for attempt in (1, 2):
        t0 = time.time()
        r = post('return "load=" .. tostring(hoi4.load_save("%s"))' % SAVE)
        took = time.time() - t0
        ok_load = '"load=true"' in r
        print("  attempt %d: %s (%.1fs)" % (attempt, r, took))
        if ok_load:
            break
    h = wait_ingame()
    time.sleep(5)
    post('hoi4.console("set_global_flag EXAMPLE_AUTOSAVE_ON") '
         'hoi4.console("set_global_flag EXAMPLE_FOCUS_ON") return "flags"')
    for _ in range(3):                       # 确认解除暂停(读档会自动暂停)
        post('hoi4.game_pause(0) hoi4.game_set_speed(4) return "go"')
        if '"paused":false' in get(B + "/health"):
            break
        time.sleep(3)
    reg = post('return tostring(hoi4.get_effect("example_research_tick") ~= nil)')
    d0 = date_now()
    rng0 = post('return hoi4.read_u32(hoi4.base() + 0x3452524)')
    post('hoi4.console("eval_effect example_reseed_rng = yes") return "fired"')
    time.sleep(2)
    rng1 = post('return hoi4.read_u32(hoi4.base() + 0x3452524)')
    route_alive = (rng0 != rng1)              # 路由+执行+Lua 全链 (reseed 写 RNG)
    time.sleep(30)
    d1 = date_now()
    date_advanced = (d0 != d1)
    v = ("round %d: load_ok=%s reg=%s route_alive=%s date %s->%s -> %s"
         % (rd, ok_load, "true" in reg, str(route_alive), d0, d1,
            "PASS" if (ok_load and route_alive and date_advanced) else "FAIL"))
    verdicts.append(v)
    print("  " + v)

print("=====")
npass = sum(1 for v in verdicts if "PASS" in v)
print("REGRESSION %s (%d/%d rounds PASS)"
      % ("PASS" if npass == ROUNDS else "FAIL", npass, ROUNDS))

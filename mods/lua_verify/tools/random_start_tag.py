#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从大型 mod 的 history/states 里随机挑一个 state, 取其 owner 作为 -start_tag。

原理: history/states/<id> - <name>.txt 里的 `history = { owner = TAG }` 就是
1936 开局该州的归属国, 所以 "随机挑一个 state" 等价于 "按州数加权随机挑国家"。
--uniform-tag 则改为对国家去重后再均匀随机。

默认只取**最高优先级**的那一份 history/states —— 大型 mod (KR 之类总转换)
自带完整世界地图 (1125 州覆盖全图), 把原版的 1081 个旧州混进来只会引入
mod 已废弃的 tag (SOV/RAJ/CHI 等)。要用多源合并加 --merge。用法:

  python random_start_tag.py                  # 随机 (加权) 打印一个 tag
  python random_start_tag.py --seed 42        # 可复现
  python random_start_tag.py --uniform-tag    # 国家均匀随机
  python random_start_tag.py --list           # 列出全部候选 tag + 州数

输出契约: stdout 只打印 TAG 一行 (便于 `TAG=$(...)`); 人类可读信息走 stderr。

--launch 直接拉起游戏:
  python random_start_tag.py --launch                # 随机 tag + 启动
  python random_start_tag.py --launch --human-ai     # 并让 AI 托管玩家国
  python random_start_tag.py --launch --exe-launcher <path>

--human-ai 说明: 传 `-human_ai` 启动参数 (等价游戏内控制台 `human_ai`)。
引擎里它是全局旗 byte_143317269 = 1: 所有 "若该国是玩家则跳过 AI 处理"
的分支 (sub_1406F3BE0 & !269 等 20+ 处) 会照常走 AI 路径, 于是 **玩家国
也被 AI 经营** —— 用于把"只有 AI 才会写"的数据形态喂进导出/对拍。
⚠ 该旗是**启动期一次性**设置的; 游戏内控制台 `human_ai` 是**每次调用翻转**
(toggle), 不是幂等 set — 连按两次等于关掉。脚本发的是启动参数形式, 幂等。
"""
import argparse
import glob
import os
import random
import re
import subprocess
import sys

DOCS = os.path.join(os.path.expanduser("~"), "Documents")
HOI4_USER = os.path.join(DOCS, "Paradox Interactive", "Hearts of Iron IV")
def _steam_path():
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam") as k:
            return winreg.QueryValueEx(k, "SteamPath")[0]
    except OSError:
        return None

STEAM = _steam_path()
WORKSHOP = (os.path.join(STEAM, "steamapps", "workshop", "content", "394360")
            if STEAM else os.environ.get("HOI4_WORKSHOP", ""))
GAME_DIRS = [d for d in [
    os.environ.get("HOI4_GAME_DIR"),
    os.path.join(STEAM, "steamapps", "common", "Hearts of Iron IV") if STEAM else None,
] if d]

OWNER_RE = re.compile(r"^\s*owner\s*=\s*([A-Z]{3})\s*(?:#.*)?$", re.M)


def enabled_mod_dirs():
    """从 dlc_load.json 的 enabled_mods 解析 workshop 目录 (按启用顺序)。"""
    import json
    p = os.path.join(HOI4_USER, "dlc_load.json")
    if not os.path.isfile(p):
        return []
    try:
        with open(p, encoding="utf-8-sig") as f:
            data = json.load(f)
    except Exception:
        return []
    out = []
    for m in data.get("enabled_mods", []):
        base = os.path.basename(m)                       # ugc_1521695605.mod
        stem = os.path.splitext(base)[0]
        if stem.startswith("ugc_"):
            d = os.path.join(WORKSHOP, stem[4:])
            if os.path.isdir(d):
                out.append(d)
    return out


def default_roots():
    """优先级从高到低: workshop mod (按启用顺序倒序, 后启用者胜) → 游戏本体。"""
    roots = [d for d in reversed(enabled_mod_dirs())]
    roots += [d for d in GAME_DIRS if os.path.isdir(d)]
    return roots


def collect(root):
    """-> {tag: [(state_id, path), ...]}"""
    out = {}
    for f in glob.glob(os.path.join(root, "history", "states", "*.txt")):
        try:
            txt = open(f, encoding="utf-8-sig", errors="replace").read()
        except OSError:
            continue
        m = OWNER_RE.search(txt)
        if not m:
            continue
        sid = os.path.basename(f).split(" - ")[0].strip()
        out.setdefault(m.group(1), []).append((sid, f))
    return out


def load_roots(roots, merge=False):
    """roots 按优先级从高到低给出。

    默认 (merge=False): 只取第一个含 history/states 的源 —— 总转换 mod 自带
    完整地图, 往下混会带进被废弃的 tag。
    merge=True: 逐 tag 合并, 高优先级源覆盖低优先级同名 tag。
    """
    if not merge:
        for root in roots:
            d = collect(root)
            if not d:
                continue
            print(f"[src] {root}: {len(d)} tags, "
                  f"{sum(len(v) for v in d.values())} states (sole source)",
                  file=sys.stderr)
            return d
        return {}

    owners = {}
    for root in reversed(roots):          # 低优先级先写, 高优先级覆盖
        d = collect(root)
        if d:
            print(f"[src] {root}: {len(d)} tags, "
                  f"{sum(len(v) for v in d.values())} states", file=sys.stderr)
        owners.update(d)
    return owners


def known_tags(roots):
    """有 history/countries 或 common/countries 定义的 tag 集合。"""
    tags = set()
    for root in roots:
        for f in glob.glob(os.path.join(root, "history", "countries", "*.txt")):
            tags.add(os.path.basename(f).split(" - ")[0].strip())
        for f in glob.glob(os.path.join(root, "common", "countries", "*.txt")):
            tags.add(os.path.splitext(os.path.basename(f))[0].strip())
    return tags


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", action="append", default=None,
                    help="history/states 所在 mod/游戏根目录 (可多次)")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--uniform-tag", action="store_true",
                    help="先对国家去重再均匀随机 (默认按州数加权)")
    ap.add_argument("--no-filter", action="store_true",
                    help="不要求 tag 在国家定义表中出现")
    ap.add_argument("--merge", action="store_true",
                    help="合并全部源 (高优先级覆盖低优先级) 而非只取最高优先级源")
    ap.add_argument("--launch", action="store_true",
                    help="抽到 tag 后直接拉起游戏")
    ap.add_argument("--human-ai", action="store_true",
                    help="--launch 时追加 -human_ai (让 AI 托管抽中的玩家国)")
    _repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--launcher", default=os.path.join(_repo, "hoi4_launcher.exe"),
                    help="--launch 用的 launcher 路径")
    ap.add_argument("--http-port", type=int, default=17389)
    ap.add_argument("--game-args", default="-auto_run=f.txt",
                    help="--launch 透传给游戏的单横线参数 (start_tag 自动加)")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--top", type=int, default=0)
    a = ap.parse_args()

    roots = a.root or default_roots()
    owners = load_roots(roots, merge=a.merge)
    if not owners:
        print("no history/states found under: " + ", ".join(roots), file=sys.stderr)
        return 2

    if not a.no_filter:
        known = known_tags(roots)
        if known:
            dropped = sorted(t for t in owners if t not in known)
            owners = {t: v for t, v in owners.items() if t in known}
            if dropped:
                print(f"[filter] dropped {len(dropped)} tags with no country "
                      f"definition: {' '.join(dropped)}", file=sys.stderr)

    if not owners:
        print("no owner tag survived filtering", file=sys.stderr)
        return 2

    if a.list:
        for t, v in sorted(owners.items(), key=lambda kv: -len(kv[1])):
            print(f"{t}\t{len(v)}")
        return 0

    rng = random.Random(a.seed)
    if a.uniform_tag:
        pool = sorted(owners)
        tag = rng.choice(pool)
        sid, path = rng.choice(sorted(owners[tag]))
    else:
        # 展平成 (tag, state) 列表后单点抽取 = 按州数加权
        flat = [(t, s) for t, v in owners.items() for s in v]
        tag, (sid, path) = rng.choice(sorted(flat))

    print(f"[pick] tag={tag} state={sid} file={path}", file=sys.stderr)
    print(f"[pick] candidate tags={len(owners)} "
          f"states={sum(len(v) for v in owners.values())} "
          f"seed={a.seed}", file=sys.stderr)
    if a.top:
        top = sorted(owners.items(), key=lambda kv: -len(kv[1]))[:a.top]
        print("[top] " + " ".join(f"{t}:{len(v)}" for t, v in top), file=sys.stderr)
    print(tag)

    if a.launch:
        if not os.path.isfile(a.launcher):
            print(f"launcher not found: {a.launcher}", file=sys.stderr)
            return 2
        extra = ["-human_ai"] if a.human_ai else []
        cmd = [a.launcher, f"-start_tag={tag}",
               *extra, *a.game_args.split(), f"-http={a.http_port}"]
        print("[launch] " + subprocess.list2cmdline(cmd), file=sys.stderr)
        if a.human_ai:
            print("[launch] human_ai ON — 玩家国将由 AI 经营"
                  " (启动后记得推进时钟让 AI 跑起来)", file=sys.stderr)
        return subprocess.call(cmd)
    return 0


if __name__ == "__main__":
    sys.exit(main())

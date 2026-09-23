# -*- coding: utf-8 -*-
# defines_l2.py -- defines 值级对拍: 磁盘 (vanilla+mod 分层) vs 运行时 M.define
# 输入1: 磁盘侧自动解析 (dlc_load.json mod 顺序, 后层覆盖, replace_path 感知)
# 输入2: 运行时侧 dump (tmp_defines_runtime.txt, NAME<TAB>qword 十进制, 游戏内生成)
# 用法: python defines_l2.py [dump侧txt路径]
import io, os, re, json, struct, sys, collections
sys.stdout.reconfigure(encoding='utf-8')
BASE = os.path.expanduser(os.environ.get('HOI4_USERDIR',
    '~/Documents/Paradox Interactive/Hearts of Iron IV/'))
def _find_game_dir():
    cands = [os.environ.get('HOI4_GAME_DIR')]
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r'Software\Valve\Steam') as k:
            steam = winreg.QueryValueEx(k, 'SteamPath')[0]
        cands.append(os.path.join(steam, 'steamapps', 'common', 'Hearts of Iron IV'))
    except OSError:
        pass
    for c in cands:
        if c and os.path.isfile(os.path.join(c, 'hoi4.exe')):
            return c.replace('\\', '/')
    raise SystemExit('HOI4 game dir not found (no hoi4.exe): set HOI4_GAME_DIR')

GAME = _find_game_dir() + '/'
MODDIR = BASE + 'mod/'
TOOLS = MODDIR + 'test/tools/'

# ---------- 1. 磁盘侧解析 ----------
def parse_defines_lua(path):
    """NDefines lua (嵌套表或平铺 NDefines.NNs.NAME=v) → {NAME: [值..]} 全部出现"""
    try:
        txt = io.open(path, encoding='utf-8', errors='replace').read()
    except OSError:
        return {}
    txt = re.sub(r'--.*', '', txt)
    out = {}
    stack = []
    def safe_eval(rhs):
        rhs = rhs.strip().rstrip(',')
        if re.fullmatch(r'[-+*/().\d\s]+', rhs) and any(c.isdigit() for c in rhs):
            try:
                return eval(rhs, {'__builtins__': {}}, {})  # 纯数字表达式
            except Exception:
                return None
        m = re.fullmatch(r'"([^"]*)"', rhs)
        if m: return m.group(1)
        if rhs == 'true': return 1
        if rhs == 'false': return 0
        return None  # 表/复杂表达式 → None
    for ln in txt.splitlines():
        m = re.match(r'^\s*([A-Za-z_][A-Za-z0-9_.]*)\s*=\s*(.*)$', ln)
        if not m: continue
        name, rhs = m.group(1), m.group(2)
        if rhs.startswith('{'):
            if '.' in name:
                continue  # 平铺到表, 非 leaf
            stack.append(name)
            continue
        if ln.strip() == '}':
            if stack: stack.pop()
            continue
        if '.' in name:
            segs = name.split('.')
            name = segs[-1]
        v = safe_eval(rhs)
        if v is not None:
            out.setdefault(name, []).append(v)
    return out

def layered_defines():
    dlc = json.load(io.open(BASE + 'dlc_load.json', encoding='utf-8'))
    layers = []  # (mod_rel_or_None=vanilla, abs_dir)
    replacer = set()
    for m in dlc['enabled_mods']:
        s = io.open(BASE + m, encoding='utf-8', errors='replace').read()
        p = re.search(r'^\s*path="([^"]*)"', s, re.M)
        for rp in re.findall(r'replace_path="([^"]*)"', s):
            replacer.add(rp.replace('\\', '/').rstrip('/'))
        if p:
            layers.append(p.group(1).replace('\\', '/').rstrip('/'))
    # 收集 rel 文件列表: 每层 common/defines/*.lua
    rels = []
    vdir = GAME + 'common/defines'
    van = {} if 'common/defines' in replacer else \
        {'common/defines/' + f: vdir + '/' + f for f in os.listdir(vdir) if f.endswith('.lua')}
    rels.append(sorted(van))
    for ld in layers:
        d = ld + '/common/defines'
        if os.path.isdir(d):
            rels.append(sorted('common/defines/' + f for f in os.listdir(d) if f.endswith('.lua')))
    # rel → 最终文件 (后层覆盖)
    winner = dict(van)
    for ld in layers:
        d = ld + '/common/defines'
        if os.path.isdir(d):
            for f in sorted(os.listdir(d)):
                if f.endswith('.lua'):
                    winner['common/defines/' + f] = d + '/' + f
    vals, src = {}, {}
    for rel in sorted(winner):
        for nm, vlist in parse_defines_lua(winner[rel]).items():
            vals.setdefault(nm, [])
            vals[nm].extend(vlist)   # 跨文件同名的所有出现都保留
            src[nm] = rel
    return vals, src

# ---------- 2. 运行时值解码 ----------
def decode(raw):
    """qword (lua tostring, 已带符号) → 候选 [(解码名, 值, 容差)]"""
    out = []
    i64 = raw if raw < 0 else (raw - (1 << 64) if raw & (1 << 63) else raw)
    low = i64 & 0xFFFFFFFF
    i32 = low - 0x100000000 if low >= 0x80000000 else low
    u8 = low & 0xFF
    out.append(('i64', i64, 0)); out.append(('i32', i32, 0))
    out.append(('u16', low & 0xFFFF, 0)); out.append(('u8', u8, 0))
    if abs(i64) < (1 << 52):
        out.append(('fx1e-5', i64 / 1e5, 5e-6))
        out.append(('fx32k', i64 / 32768.0, 4e-5))
    try:
        out.append(('f32', struct.unpack('<f', struct.pack('<I', low))[0], 1e-6))
        out.append(('f64', struct.unpack('<d', struct.pack('<q', i64))[0], 1e-9))
    except Exception:
        pass
    return out

def match(raw, expect):
    if isinstance(expect, str) or isinstance(expect, list):
        return 'SKIP'
    for how, v, tol in decode(raw):
        if isinstance(expect, int) and not isinstance(expect, bool):
            if isinstance(v, int) and v == expect:
                return how
            if abs(v - expect) < 0.5:
                return how
        else:
            if abs(v - expect) <= max(tol, abs(expect) * tol if tol else 0) + (0 if tol else 1e-9):
                return how
    return None

# ---------- 3. 主流程 ----------
def main():
    dpath = sys.argv[1] if len(sys.argv) > 1 else TOOLS + 'tmp_defines_runtime.txt'
    rt = {}
    for ln in io.open(dpath, encoding='utf-8', errors='replace'):
        if ln.startswith('#'): continue
        p = ln.rstrip('\n').split('\t')
        if len(p) == 2 and p[1].lstrip('-').isdigit():
            rt[p[0]] = int(p[1])
    disk, src = layered_defines()
    ok, bad, nrt, ndisk, nskip = 0, [], 0, [], 0
    amb = 0
    rpt = ['== defines 值级对拍 (t93) ==']
    types = collections.Counter()
    for nm in sorted(rt):
        if nm not in disk:
            nrt += 1; continue
        exps = disk[nm]
        if any(isinstance(x, (str, list)) for x in exps):
            nskip += 1; continue
        hows = [match(rt[nm], e) for e in exps]
        hits = [(how, e) for how, e in zip(hows, exps) if how]
        if hits:
            ok += 1; types[hits[0][0]] += 1
            if len(set(exps)) > 1: amb += 1
        else:
            bad.append((nm, exps, src[nm], ['%s=%r' % (h[0], h[1]) for h in decode(rt[nm])][:7]))
    for nm in sorted(set(disk) - set(rt)):
        vlist = disk[nm]
        if not any(isinstance(x, (str, list)) for x in vlist):
            ndisk.append((nm, vlist, src[nm]))
    rpt.append('对拍: MATCH=%d DIFF=%d | 仅运行时=%d | 仅磁盘=%d | 跳过(串/表)=%d | 多值命中(命名空间歧义)=%d'
               % (ok, len(bad), nrt, len(ndisk), nskip, amb))
    rpt.append('编码分布: ' + ', '.join('%s=%d' % kv for kv in types.most_common()))
    rpt.append('---- DIFF 明细 ----')
    for nm, exps, sr, cands in bad[:60]:
        rpt.append('  %s = %s (%s) runtime候选: %s' % (nm, exps, sr, ' '.join(cands)))
    if len(bad) > 60:
        rpt.append('  ... 另 %d 条' % (len(bad) - 60))
    rpt.append('---- 仅磁盘 (mod 新增或扫描漏网) ----')
    for nm, vlist, sr in ndisk[:20]:
        rpt.append('  %s = %s (%s)' % (nm, vlist, sr))
    print('\n'.join(rpt))
    io.open(TOOLS + 'defines_l2_report.txt', 'w', encoding='utf-8', newline='\n').write('\n'.join(rpt) + '\n')

if __name__ == '__main__':
    main()

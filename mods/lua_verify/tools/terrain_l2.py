# -*- coding: utf-8 -*-
# terrain_l2.py -- terrain 三侧对账 (t93 深化批)
# 三侧: 磁盘 (categories + terrain 块, 同 relpath 后层整文件胜) /
#       运行时 A 族 idb (游戏性名) / 运行时第二数组 (图形名)
# + LUT 同余直证: 磁盘 terrain 条目 color=c → 运行时 LUT[c] == 该条目第二数组下标
# 输入: tmp_terrain_cat2.txt (运行时第二数组 idx<TAB>name, 游戏内 dump)
#       tmp_terrain_lut.txt   (运行时 LUT byte<TAB>idx, 游戏内 dump)
# 用法: python terrain_l2.py
import io, os, re, json, sys, collections
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
TOOLS = os.path.dirname(os.path.abspath(__file__)).replace(chr(92), '/') + '/'

def parse_blocks(path):
    """00_terrain.txt → {块名: [(条目名, {'type':t,'color':c})]} **保落盘序, 重名不折叠**"""
    txt = io.open(path, encoding='utf-8', errors='replace').read()
    txt = re.sub(r'#.*', '', txt)
    out = collections.defaultdict(list)
    toks = re.findall(r'\{|\}|=|[A-Za-z_][A-Za-z0-9_.]*|-?\d+\.?\d*|"[^"]*"', txt)
    i, n = 0, len(toks)
    stack = []          # 块名栈
    curblk = None       # 顶层块名 (categories/terrain)
    while i < n:
        t = toks[i]
        if t == '}':
            if stack: stack.pop()
            if not stack: curblk = None
        elif t == '{':
            pass
        elif i + 2 < n and toks[i + 1] == '=' and toks[i + 2] == '{':
            name = t
            if not stack:
                curblk = name
                stack.append(name)
            else:
                ent = {}
                # 条目体: 扫描到配平 }
                depth, j = 1, i + 3
                body = []
                while j < n and depth > 0:
                    if toks[j] == '{': depth += 1
                    elif toks[j] == '}': depth -= 1
                    body.append(toks[j]); j += 1
                btxt = ' '.join(body)
                tm = re.search(r'\btype\s*=\s*([A-Za-z_][A-Za-z0-9_.]*)', btxt)
                cm = re.search(r'\bcolor\s*=\s*\{\s*(-?\d+)', btxt)
                if tm: ent['type'] = tm.group(1)
                if cm: ent['color'] = int(cm.group(1))
                out[stack[0]].append((name, ent))
                i = j - 1
        elif i + 1 < n and toks[i + 1] == '=' and toks[i + 2] != '{':
            if not curblk and not stack:
                pass
        i += 1
    return dict(out)

def layered():
    dlc = json.load(io.open(BASE + 'dlc_load.json', encoding='utf-8'))
    repl = False
    moddirs = []
    for m in dlc['enabled_mods']:
        s = io.open(BASE + m, encoding='utf-8', errors='replace').read()
        p = re.search(r'^\s*path="([^"]*)"', s, re.M)
        repl |= any(r.replace(chr(92), '/').rstrip('/') == 'common/terrain'
                    for r in re.findall(r'replace_path="([^"]*)"', s))
        if p: moddirs.append(p.group(1).replace(chr(92), '/').rstrip('/'))
    # 同 relpath 后层整文件胜; 不同文件按名升序合并 (后者块内键覆盖)
    winner = {}
    if not repl:
        d = GAME + 'common/terrain'
        if os.path.isdir(d):
            for f in sorted(os.listdir(d)):
                winner[f] = d + '/' + f
    for d in moddirs:
        dd = d + '/common/terrain'
        if os.path.isdir(dd):
            for f in sorted(os.listdir(dd)):
                winner[f] = dd + '/' + f
    cats, terr = {}, []
    for f in sorted(winner):
        for blk, ents in parse_blocks(winner[f]).items():
            if blk == 'categories':
                for nm, e in ents: cats[nm] = e
            elif blk == 'terrain':
                terr.extend(ents)          # 保落盘序, 重名不折叠
    return cats, terr, sorted(winner)

def main():
    cats, terr, files = layered()
    cat2 = {}
    for ln in io.open(TOOLS + 'tmp_terrain_cat2.txt', encoding='utf-8'):
        p = ln.rstrip('\n').split('\t')
        if len(p) == 2: cat2[int(p[0])] = None if p[1] == 'nil' else p[1]
    lut = {}
    try:
        for ln in io.open(TOOLS + 'tmp_terrain_lut.txt', encoding='utf-8'):
            p = ln.rstrip('\n').split('\t')
            if len(p) == 2: lut[int(p[0])] = int(p[1])
    except OSError:
        lut = {}
    rpt = ['== terrain 三侧对账 (t93) ==', 'layers: ' + str(len(files))]
    terr_names = [nm for nm, _ in terr]
    rpt.append('磁盘: categories=%d terrain 条目=%d (唯一名 %d, 重名 %d) | 运行时第二数组=%d'
               % (len(cats), len(terr), len(set(terr_names)),
                  len(terr_names) - len(set(terr_names)), len(cat2)))
    # 0) 落盘序 ≡ 运行时序 (最强: 第二数组 idx 顺序 == 磁盘 terrain 块条目顺序)
    live_seq = [cat2.get(i) for i in sorted(cat2)]
    # 运行时 idx0 = Null Object 名空, 磁盘首条目对应 idx1
    disk_seq = terr_names
    n_cmp = min(len(live_seq) - 1, len(disk_seq))
    seq_bad = [(i + 1, disk_seq[i], live_seq[i + 1])
               for i in range(n_cmp) if disk_seq[i] != live_seq[i + 1]]
    rpt.append('落盘序 ≡ 运行时序: %s (比 %d 项, 异 %d%s)'
               % ('MATCH' if not seq_bad else 'DIFF', n_cmp, len(seq_bad),
                  (' ' + str(seq_bad[:5])) if seq_bad else ''))
    # 1) 第二数组 ⊆ 磁盘 terrain 块
    live2 = {v for k, v in cat2.items() if v}
    miss = sorted(live2 - set(terr_names))
    extra_disk = sorted(set(terr_names) - live2)
    rpt.append('第二数组 ⊆ 磁盘 terrain: %s (live=%d, 未中 %d%s)'
               % ('MATCH' if not miss else 'DIFF', len(live2), len(miss),
                  (' ' + ','.join(miss[:6])) if miss else ''))
    rpt.append('  磁盘多余(未装载) %d: %s' % (len(extra_disk), ','.join(extra_disk[:10])))
    # 2) LUT 同余: color → 下标 (按 color 索引磁盘条目, 重名各占一色)
    by_color = {}
    for nm, e in terr:
        if e.get('color') is not None:
            by_color.setdefault(e['color'], []).append(nm)
    okc, badc, none_c = 0, [], 0
    for b, idx in sorted(lut.items()):
        nm = cat2.get(idx)
        if not nm:
            none_c += 1; continue
        cands = by_color.get(b, [])
        if nm in cands:
            okc += 1
        else:
            badc.append((b, nm, 'color=%s 持有者=%s' % (b, ','.join(cands) or '无')))
    rpt.append('LUT↔color 同余: OK=%d 异常=%d (LUT 指向无类槽 %d)'
               % (okc, len(badc), none_c))
    for x in badc[:10]:
        rpt.append('  byte %d → %s (%s)' % x)
    # 3) 图形 type 回链: 磁盘条目 type 集合 ⊆ categories
    types = {e.get('type') for _, e in terr if e.get('type')}
    bad_t = sorted(t for t in types if t not in cats)
    rpt.append('磁盘 type 回链 ⊆ categories: %s (types=%d 越集 %d%s)'
               % ('MATCH' if not bad_t else 'DIFF', len(types), len(bad_t),
                  (' ' + ','.join(bad_t[:6])) if bad_t else ''))
    txt = '\n'.join(rpt)
    print(txt)
    io.open(TOOLS + 'terrain_l2_report.txt', 'w', encoding='utf-8', newline='\n').write(txt + '\n')

if __name__ == '__main__':
    main()

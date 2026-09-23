#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""linediff.py — trivial differ (t89 迁移): 两个 savefull 形态文件逐行对拍。

输入 = 两份 `dim\\tpath\\tval` 行文件 (save 提取件 / mem savefull 导出件)。
对拍 = (dim, path) 分组多重集 join:
  MATCH      值配对且相等 (精确 / 数值容差 m_num / 去引号相等)
  DIFF       值配对但不等
  MISS_MEM   save 侧未配对 (mem 无此行)
  MISS_SAVE  mem 侧未配对 (mem 多发, save 无此行)

用法:
  python linediff.py <save文件> <mem文件> [--report 路径] [--samples N]
      [--node 节点名] [--blocks 块名清单文件]

  --node X    只对拍节点 X (节点 = 非国家 dim 本身 / 国家 dim 的 'country.<首段词>')
  --samples N 每节点样例行上限, 默认 8, 0 = 全量明细
"""
import re
import sys

# ==========================================================================
# 裁定豁免 (EXEMPT 独立分类)
# ⚠ 裁定豁免需要用户同意才能增加，不能擅自增加
# 现行 6 叶 (T80 三叶 + 2026-09-11 用户追加三墙钟叶):
#   #checksum / #version / #dlcs   写盘时生成 (T80 裁定)
#   #session                       墙钟秒 (暂停也走, 同刻锚不可复现)
#   all_playthrough_data 内 seconds_played  墙钟秒 (嵌在 blob 行内,
#                                   按值掩码处理, 行内其余 163 字段仍对拍)
#   active_peace.time_duration     写时墙钟 (落盘时刻重算 now−和会开始,
#                                   9-11 用户裁定纳入)
# ==========================================================================
EXEMPT_LEAVES = {
    ('#', 'checksum'),
    ('#', 'version'),
    ('#', 'dlcs'),
    ('#', 'session'),
    ('peace_conference', 'active_peace.time_duration'),
}
# 值级掩码豁免: (dim, path) -> 掩码正则 (掩掉的部分不参与比较)
EXEMPT_VALUE_MASK = {
    ('all_playthrough_data', '#1.#1.data.first.playthroughs'):
        re.compile(r'seconds_played=\d+'),
}


def _mask(key, v):
    r = EXEMPT_VALUE_MASK.get(key)
    return r.sub('seconds_played=@', v) if r else v

# dim 分类 (r3 实测定案): 含小写字母 = 顶层块 (states/equipments/...),
# 全大写 = 国家/pseudo-country dim (含 DIP/OCC/RCG 等特种项目 pseudo 国)。
# 块级 [N] 重复块 (combat_data_entry[10]) 归组时剥回基名。
def _is_block(dim):
    return any(c.islower() for c in dim) or dim == '#'


def node_of(dim, pth):
    if _is_block(dim):
        return re.sub(r'\[\d+\]$', '', dim)
    return 'country.' + pth.split('.', 1)[0]


def _f(x):
    return float(str(x).strip('"'))


def m_num(a, b):
    """与 classdiff 同口径: 数值容差 ±(0.011 + |a|*1e-4), 非数值去引号字符串等。"""
    try:
        fa, fb = _f(a), _f(b)
        return abs(fa - fb) <= 0.011 + abs(fa) * 1e-4
    except ValueError:
        return str(a).strip('"') == str(b).strip('"')


def load(path):
    """-> dict[(dim, pth)] -> [val, ...] (保出现序)"""
    groups = {}
    with open(path, encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.rstrip('\r\n')
            if not line or line.startswith('# '):
                continue
            parts = line.split('\t', 2)
            if len(parts) != 3:
                continue
            key = (parts[0], parts[1])
            v = parts[2]
            lst = groups.get(key)
            if lst is None:
                groups[key] = [v]
            else:
                lst.append(v)
    return groups


def pair_group(sv, mv):
    """(save_vals, mem_vals) -> (match, diff[(s,m)], miss_mem[s], miss_save[m])"""
    if len(sv) == 1 and len(mv) == 1:
        if sv[0] == mv[0] or m_num(sv[0], mv[0]):
            return 1, [], [], []
        return 0, [(sv[0], mv[0])], [], []
    # 多重集: 精确串等先行扣减
    from collections import Counter
    sc, mc = Counter(sv), Counter(mv)
    match = 0
    rem_s, rem_m = [], []
    for v, n in sc.items():
        take = min(n, mc.get(v, 0))
        match += take
        rem_s.extend([v] * (n - take))
    for v, n in mc.items():
        rem_m.extend([v] * (n - sc.get(v, 0)))
    # 残余: 容差/去引号配对 (组通常极小; 大组退化为排序后位置配对)
    diff, mm, ms = [], [], []
    if len(rem_s) <= 64 and len(rem_m) <= 64:
        used = [False] * len(rem_m)
        for s in rem_s:
            hit = -1
            for j, m in enumerate(rem_m):
                if not used[j] and m_num(s, m):
                    hit = j
                    break
            if hit >= 0:
                used[hit] = True
                match += 1
            else:
                mm.append(s)
        for j, m in enumerate(rem_m):
            if not used[j]:
                ms.append(m)
        # 双侧均有残余: 位置配对转 DIFF (数量小, 顺序即文档序)
        k = min(len(mm), len(ms))
        for i in range(k):
            diff.append((mm[i], ms[i]))
        mm, ms = mm[k:], ms[k:]
    else:
        rem_s.sort()
        rem_m.sort()
        k = min(len(rem_s), len(rem_m))
        for i in range(k):
            if m_num(rem_s[i], rem_m[i]):
                match += 1
            else:
                diff.append((rem_s[i], rem_m[i]))
        mm, ms = rem_s[k:], rem_m[k:]
    return match, diff, mm, ms


def main(argv):
    args, opts = [], {}
    i = 1
    while i < len(argv):
        a = argv[i]
        if a.startswith('--'):
            if '=' in a:
                k, v = a[2:].split('=', 1)
                opts[k] = v
            elif i + 1 < len(argv) and not argv[i + 1].startswith('--'):
                opts[a[2:]] = argv[i + 1]
                i += 1
            else:
                opts[a[2:]] = True
        else:
            args.append(a)
        i += 1

    if len(args) < 2:
        print(__doc__)
        return 1
    save_path, mem_path = args[0], args[1]
    report_path = opts.get('report', 'tmp_linediff_report.txt')
    samples_cap = int(opts.get('samples', '8'))
    only_node = opts.get('node')

    save_g = load(save_path)
    mem_g = load(mem_path)

    stats = {}   # node -> {MATCH, DIFF, MISS_MEM, MISS_SAVE, EXEMPT}
    samples = {}  # node -> [行...]
    total = {'MATCH': 0, 'DIFF': 0, 'MISS_MEM': 0, 'MISS_SAVE': 0,
             'EXEMPT': 0}

    def bump(node, k, n=1):
        st = stats.setdefault(node, {'MATCH': 0, 'DIFF': 0,
                                     'MISS_MEM': 0, 'MISS_SAVE': 0,
                                     'EXEMPT': 0})
        st[k] += n
        total[k] += n

    def sample(node, line):
        lst = samples.setdefault(node, [])
        if samples_cap == 0 or len(lst) < samples_cap:
            lst.append(line)

    for key in set(save_g) | set(mem_g):
        dim, pth = key
        node = node_of(dim, pth)
        if only_node and node != only_node:
            continue
        if key in EXEMPT_LEAVES:
            n = max(len(save_g.get(key, [])), len(mem_g.get(key, [])))
            bump(node, 'EXEMPT', n)
            for v in save_g.get(key, []):
                sample(node, '  EXEMPT %s\t%s\tsave=%s' % (dim, pth, v))
            continue
        sv = [_mask(key, v) for v in save_g.get(key, [])]
        mv = [_mask(key, v) for v in mem_g.get(key, [])]
        match, diff, mm, ms = pair_group(sv, mv)
        bump(node, 'MATCH', match)
        for s, m in diff:
            bump(node, 'DIFF')
            sample(node, '  DIFF %s\t%s\tsave=%s	mem=%s' % (dim, pth, s, m))
        for s in mm:
            bump(node, 'MISS_MEM')
            sample(node, '  MISS_MEM %s\t%s\tsave=%s' % (dim, pth, s))
        for m in ms:
            bump(node, 'MISS_SAVE')
            sample(node, '  MISS_SAVE %s\t%s\tmem=%s' % (dim, pth, m))

    out = []
    for node in sorted(stats):
        out.append('==== %s: %s' % (node, stats[node]))
        out.extend(samples.get(node, []))
    out.append('TOTAL: %s' % total)
    text = '\n'.join(out) + '\n'
    with open(report_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    sys.stdout.write(text)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

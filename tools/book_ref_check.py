# -*- coding: utf-8 -*-
"""book 引用完整性检查器
硬问题: 标题节号重复 / §引用断链
警告:   零填充引用漂移 (§4.01 式, 经规范化可解析 — 仍应修)
用法: python book_ref_check.py <file.md|dir> [--dir]
与 md_table_check.py 互补: 该工具查表格形状, 本工具查节号体系与引用闭合。"""
import io, os, re, sys, glob
sys.stdout.reconfigure(encoding='utf-8')

# 节号: 多级点分数字, 末段可带字母 (4.1.4a / 0.A / 1.1b / 1.1b.1)。
# 标题侧 (?=\s|$) 保证整体吞号 (1.1b.1 不误判为 1.1b); 引用侧 (?![A-Za-z0-9_])
# 排除占位符 (§4.xx) 与更长数字尾随。
RE_TITLE = re.compile(r'^(#{2,6})\s+((?:\d+[A-Za-z]?\.)+(?:\d+[A-Za-z]?|[A-Za-z]))(?=\s|$)')
RE_REF = re.compile(r'§((?:\d+[A-Za-z]?\.)+(?:\d+[A-Za-z]?|[A-Za-z]))(?![A-Za-z0-9_])')
RE_SPAN = re.compile(r'``.*?``|`[^`]*`')  # 行内码内是引用样式本身, 非真引用


def norm(num):
    """规范化: 组件级去前导零 + 后缀小写 (4.01 -> 4.1, 4.22.5A -> 4.22.5a)"""
    parts = num.split('.')
    out = []
    for p in parts:
        if p.isdigit():
            out.append(str(int(p)))
        else:
            m = re.fullmatch(r'(\d+)([A-Za-z])', p)
            out.append(str(int(m.group(1))) + m.group(2).lower() if m else p.lower())
    return '.'.join(out)


def scan(path):
    """返回 (titles{编号: [(file, line, 标题文本)]}, refs[(file, line, 编号)])"""
    titles, refs = {}, []
    in_code = False
    for i, line in enumerate(io.open(path, encoding='utf-8'), 1):
        if line.strip().startswith('```'):
            in_code = not in_code
            continue
        if not in_code:
            m = RE_TITLE.match(line)
            if m:
                titles.setdefault(m.group(2), []).append((path, i, line.strip()[:70]))
            for r in RE_REF.finditer(RE_SPAN.sub('', line)):
                refs.append((path, i, r.group(1)))
    return titles, refs


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), '..', 'book')
    if os.path.isdir(arg) or '--dir' in sys.argv[2:]:
        files = sorted(glob.glob(os.path.join(arg, '*.md')))
    else:
        files = [arg]
    titles, refs = {}, []
    for f in files:
        t, r = scan(f)
        for k, v in t.items():
            titles.setdefault(k, []).extend(v)
        refs.extend(r)

    issues, warns = [], []

    # 1) 标题节号唯一性 (原形 + 规范化双重检查)
    by_norm = {}
    for num, occ in titles.items():
        if len(occ) > 1:
            issues.append(('重复节号 §' + num,
                           '; '.join('%s:%d' % (os.path.basename(f), n) for f, n, _ in occ)))
        by_norm.setdefault(norm(num), []).append(num)
    for n, nums in by_norm.items():
        if len(nums) > 1:
            issues.append(('规范化撞号 ' + ' / '.join('§' + x for x in nums),
                           '同一规范化编号 %s' % n))

    # 2) § 引用闭合 (精确命中 → 过; 规范化命中 → 零填充警告; 否则断链)
    norm_titles = {norm(k) for k in titles}
    seen = set()
    for f, ln, num in refs:
        key = (os.path.basename(f), num)
        if key in seen:
            continue
        seen.add(key)
        if re.fullmatch(r'\d+\.x', num):
            continue  # 通配占位 (「全书 §4.x 按号寻址」), 非具体引用
        if num in titles:
            continue
        if norm(num) in norm_titles:
            warns.append((os.path.basename(f), ln, '零填充引用 §' + num,
                          '应写 §' + norm(num)))
        else:
            issues.append(('断链 §' + num,
                           '%s:%d' % (os.path.basename(f), ln)))

    for msg, c in issues:
        print('硬问题  %-40s %s' % (msg, c))
    for f, ln, msg, c in warns:
        print('警告    %-40s %s:%d (%s)' % (msg, f, ln, c))
    print('合计 文件:%d 标题:%d 引用(唯一):%d 断链/重复:%d 零填充:%d'
          % (len(files), len(titles), len(seen), len(issues), len(warns)))
    sys.exit(1 if issues else 0)


if __name__ == '__main__':
    main()

# -*- coding: utf-8 -*-
"""markdown 表格格式检查器 v2 (§0.4 机械校验)
硬错误: 列数/分隔行/合并偏移格/+0x/删除线/findings外联/批次名/伪标题/日期戳
警告:   plain 偏移行非升序 / 待定词表外标记 / 偏移算式
用法: python md_table_check.py <file.md|dir> [--dir]"""
import io, re, sys, glob, os
sys.stdout.reconfigure(encoding='utf-8')

T_BATCH = re.compile(r'(?<![\w/\\._-])(?:t8|t9)\d[a-zA-Z0-9_\-]*(?![\w]*\.(?:json|txt|c|py|lua))')
# 白名单: m14_dump 路径上下文 / 下划线开头的 dump 工具件名(带扩展名)
T_OK = re.compile(r'(?:m14_dump|[\w/\\]*_t8\d[\w]*|[\w/\\]*_t9\d[\w]*)\.(?:json|txt|c|py|lua)\b')
RE_FINDINGS = re.compile(r'_findings')
RE_STRIKE = re.compile(r'~~')
RE_HEXOFF = re.compile(r'\+0x')  # BASE+0x… / BASE + 0x… 属绝对地址, 豁免(见下)
RE_MERGE = re.compile(r'^\s*\+\d+\s*/\s*\+?\d+')          # 首列 +N/+M
RE_BRACE = re.compile(r'^\s*\+\d+\s*[{\[]\s*\+\d+')        # 首列 +N{+M}
RE_EXPR = re.compile(r'^\s*\+\d+\s*\+\s*\d')               # 首列 +N+M 算式
RE_PLAIN = re.compile(r'^\s*\+(\d+)(?:\.\.(\d+))?\s*$')    # 首列 +N 或 +N..+M
RE_PSEUDO = re.compile(r'^\*\*[^*]+\*\*:?\s*$')
RE_DATE = re.compile(r'2026-\d\d|(?<![\d.-])9-1[0-9](?![\d-])')
RE_MARK = re.compile(r'待复核|待核(?!准)|待探针|待调合|待出叶|名待验|未定形|中置信|低置信|终裁|裁决|判决|复核成立|翻案|作废|误植|收编|册语化|旧注|旧记|旧说|销账|转正|终批|追批|(?<!偏)移交')
RE_SPAN = re.compile(r'``.*?``|`[^`]*`')  # 行内码: 内含的是被引用的样式本身, 非违规 (双反引码跨优先)


def cols(line):
    t = line.strip()
    if not (t.startswith('|') and t.endswith('|')):
        return None
    inner = t[1:-1]
    parts = re.split(r'(``.*?``|`[^`]*`)', inner)
    n = 1
    for p in parts:
        if p.startswith('`') and p.endswith('`') and len(p) > 1:
            continue
        n += len(re.findall(r'(?<!\\)\|', p))
    return n


def is_sep(line):
    t = line.strip()
    if not (t.startswith('|') and t.endswith('|')):
        return False
    body = t[1:-1].replace('\\|', '')
    return bool(re.fullmatch(r'[\s:\-|]+', body))


def first_cell(line):
    t = line.strip()
    if not t.startswith('|'):
        return ''
    body = t[1:]
    # 去掉行内码保护
    parts = re.split(r'(``.*?``|`[^`]*`)', body)
    seg = parts[0]
    return seg.split('|')[0].strip()


def check_file(path):
    raw = io.open(path, encoding='utf-8').read()
    lines = raw.split('\n')
    issues, warns = [], []
    tables = 0
    # 屏蔽 fenced code block
    in_code = False
    cleaned = []
    for l in lines:
        if l.strip().startswith('```'):
            in_code = not in_code
            cleaned.append(True)
            continue
        cleaned.append(in_code)

    def ctx_of(idx):
        # 所在文件行上下文(前一行表头/节标题) 简化: 只回行号
        return idx + 1

    i = 0
    in_spec = False  # 主文件 §0.4 书写规范节: 合法引用被禁样式作反例, 豁免行级样式检查
    while i < len(lines):
        l = lines[i]
        if cleaned[i]:
            i += 1
            continue
        if re.match(r'^###\s+0\.4\s', l):
            in_spec = True
        elif re.match(r'^#{1,3}\s', l) and in_spec:
            in_spec = False
        if in_spec:
            i += 1
            continue
        # 行级样式检查先剥行内码: 反引号内的是被引用的样式串本身 (如「禁 +0xN」), 非违规
        l_chk = RE_SPAN.sub('', l)
        for rx, tag in ((RE_STRIKE, '删除线'), (RE_FINDINGS, 'findings外联'),
                        (RE_PSEUDO, '伪标题'), (RE_DATE, '日期戳')):
            if rx.search(l_chk if rx is not RE_FINDINGS else l):
                issues.append((ctx_of(i), tag, l.strip()[:60]))
        for m in RE_HEXOFF.finditer(l_chk):
            if 'BASE' not in l_chk[max(0, m.start() - 6):m.start()]:
                issues.append((ctx_of(i), '+0x', l.strip()[:60]))
        mb = T_BATCH.search(l)
        if mb and not T_OK.search(l):
            issues.append((ctx_of(i), '批次名:' + mb.group(0), l.strip()[:60]))
        mm = RE_MARK.search(l)
        if mm:
            warns.append((ctx_of(i), '词表外:' + mm.group(0), l.strip()[:60]))
        if l.strip().startswith('|') and i + 1 < len(lines) and is_sep(lines[i + 1]):
            tables += 1
            hdr_n = cols(l)
            hdr_first = first_cell(l)
            offset_table = ('偏移' in hdr_first) or ('offset' in hdr_first.lower())
            prev_plain = None
            j = i + 2
            while j < len(lines) and lines[j].strip().startswith('|') and not cleaned[j]:
                row = lines[j]
                n = cols(row)
                fc = first_cell(row)
                if n is None:
                    issues.append((ctx_of(j), 'NOT-A-ROW', repr(row[-40:])))
                elif n != hdr_n:
                    issues.append((ctx_of(j), 'COLS %d!=%d' % (n, hdr_n), row.strip()[:60]))
                if not offset_table and re.match(r'^\s*\+', fc):
                    offset_table = True  # 数据行以 + 开头即按偏移表校验首列
                if offset_table or re.match(r'^\s*\+', fc):
                    if RE_MERGE.match(fc) or RE_BRACE.match(fc):
                        issues.append((ctx_of(j), '合并偏移格', fc[:40]))
                    elif RE_EXPR.match(fc):
                        warns.append((ctx_of(j), '偏移算式', fc[:40]))
                    elif '~~' in fc:
                        issues.append((ctx_of(j), '首列删除线', fc[:40]))
                    mp = RE_PLAIN.match(fc)
                    if mp:
                        v = int(mp.group(1))
                        if prev_plain is not None and v < prev_plain:
                            warns.append((ctx_of(j), '非升序 %d<%d' % (v, prev_plain), fc[:40]))
                        prev_plain = v
                    elif re.match(r'^\s*(?:[a-zA-Z_·]+\s+)?\+', fc):
                        prev_plain = None  # 前缀行钉位, 断开升序链
                j += 1
            i = j
        else:
            i += 1
    return tables, issues, warns


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), '..', 'book',
        'hoi4_runtime_classes.md')
    if os.path.isdir(arg):
        files = sorted(glob.glob(os.path.join(arg, 's4_*.md')))
    else:
        files = [arg]
    tot_t = tot_i = tot_w = 0
    for f in files:
        t, iss, w = check_file(f)
        tot_t += t; tot_i += len(iss); tot_w += len(w)
        name = os.path.basename(f)
        if iss or w:
            print('== %s 表格:%d 问题:%d 警告:%d' % (name, t, len(iss), len(w)))
            for ln, msg, c in iss:
                print('  L%-5d %-18s %s' % (ln, msg, c))
            for ln, msg, c in w:
                print('  L%-5d [警告] %-14s %s' % (ln, msg, c))
    print('合计 文件:%d 表格:%d 硬问题:%d 警告:%d' % (len(files), tot_t, tot_i, tot_w))
    sys.exit(1 if tot_i else 0)


if __name__ == '__main__':
    main()

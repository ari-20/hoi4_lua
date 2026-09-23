#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""savefull3.py — T24-3 全量存档解析器 (v6, 2026-08-31)

v5 (a1_savefull2) 只收 countries={ 单块 (80% 行)。本版全块收集:
  - 顶层块全收 (71 块实例 + 35 顶格叶子), 顶层重复块块级 [n] 编号
    (saved_event_target×6 / faction×5 / combat_data_entry×16 / tech_sharing_group×2)
  - HEAD 正则扩展: 引号键 "0"={ (weather), 插入符键 name^0= (variables)
  - 匿名裸括号条目序号化: '{' / '440 {' 行 push '#N' 序号哨兵 (保条目边界)
  - 多 token 值行整行收: rail_way 的 '2 0 0 0 2 0 0'、countries 超长数值行
  - 行格式: <维度> <路径> <值>
      维度 = 顶层块名 (countries 块内 = 国家 TAG; states/provinces 等全局块 = 块名)
      顶层叶子维度 = '#' (根)
  - 括号净增量法不变量保持: 每行处理后 len(stack) == 当前净深度

用法:
  python savefull3.py <存档> extract   # -> tmp_savefull_all.txt
  python savefull3.py <存档> stat      # 块级覆盖率报告
"""
import re
import sys
from collections import OrderedDict

# 键形态: 裸键 / 引号键 ("0") / 插入符键 (name^0) — ^ 后可带数字
# t80: 键名含点号 (DOD_romania.81_fired= 形态旗标) — 原字符集无 '.' 会把
#   整行判成裸行塞 '@' 哨兵 (提取件 ROM flags.@.value, MISS_SAVE 3 根因)
# t90: 裸键字符集补 /@:- (t80 点号事故同族) — BlackICE 旗名/变量名含
#   特殊字符 (ai_diff: / mechanized_mortar_intro/complete / party_banned@ /
#   ww1/* / german-soviet_treaty_slot) 曾被吞进 @ 哨兵/#N 分支 → 对拍假象
HEAD = re.compile(r'^\t*(?:"([^"]+)"|([A-Za-z0-9_./:@\-\x80-\uffff]+(?:\^\d+)?))=(.*)$')
# 顶格顶层块/叶子 (无缩进)
TOP = re.compile(r'^([A-Za-z0-9_]+)=(.*)$')
# 裸块行: '{' 或 'N {' (faction_system 的 '440 {'); 前缀 tab/空格混合 (BEL advisors 的 ' {')
BARE = re.compile(r'^[\t ]*(\d+ )?\{$')
BARE_INLINE = re.compile(r'^[	 ]*\{(.*)\}$')
# 数组尾行: '数字[ 数字...] 括号外的}' — 值+闭括号同行 (t79w 审计:
#   location={ \n 13218 \t} 跨行单值块; 旧版无分支匹配被整行丢弃)
TAILVAL = re.compile(r'^[0-9.\-][0-9.\- \t]*\}$')


def parse_all(path):
    """全量解析。返回 (out_lines, block_stats, n_lines)。

    block_stats: OrderedDict 块名(含[n]) -> {'lines': 处理行数, 'leaves': 叶子数}
    """
    out_lines = []
    stats = {}
    stack = []            # [顶层块名(带[n]), 子键...] 匿名哨兵 '#N'
    block_seen = {}       # 顶层块名 -> 出现次数 (块级 [n])
    anon_counter = {}     # 当前栈父路径 -> 匿名序号 (条目边界)
    block_stats = OrderedDict()
    cur_block = None
    n_lines = 0
    depth0_lines = 0
    half_anon = None      # (父路径, '#N' 哨兵名, [累积内容]) — 半行内匿名对象

    def emit(val, key=None):
        """叶子出栈: 路径 = stack[1:] (+ key), 维度 = stack[0]。

        块内直接叶子 (stack 仅 1 层, 如 variables.random) 路径 = key。
        countries 块特殊: 维度列 = 国家 TAG (stack[1]), 路径 = stack[2:],
        与 v5/diff 口径一致。
        """
        if not stack:
            return
        if stack[0] == 'countries':
            if len(stack) < 2:
                return
            dim = stack[1]
            if len(stack) > 2:
                path = '.'.join(stack[2:])
            elif key is not None:
                path = key
            else:
                return
            if key is not None:
                path = path + '.' + key if len(stack) > 2 else key
        else:
            dim = stack[0]
            if len(stack) > 1:
                path = '.'.join(stack[1:])
                if key is not None:
                    path = path + '.' + key
            elif key is not None:
                path = key
            else:
                return
        d = len(stack) - 1
        stats[d] = stats.get(d, 0) + 1
        out_lines.append('\t'.join((dim, path, val)))
        bs = block_stats.setdefault(stack[0], {'lines': 0, 'leaves': 0})
        bs['leaves'] += 1

    with open(path, encoding='utf-8', errors='replace') as f:
        for line in f:
            s = line.rstrip('\r\n')
            n_lines += 1
            opens = s.count('{')
            closes = s.count('}')
            depth0_lines += 1
            stripped = s.strip()

            if not stack:
                # 顶层: 块首 / 顶格叶子
                mt = TOP.match(s)
                if mt:
                    key, val = mt.group(1), mt.group(2).strip()
                    if val == '{':
                        # 顶层块首: 重复块 [n]
                        cnt = block_seen.get(key, 0)
                        bname = key if cnt == 0 else '%s[%d]' % (key, cnt + 1)
                        block_seen[key] = cnt + 1
                        stack.append(bname)
                        block_stats[bname] = {'lines': 0, 'leaves': 0}
                        cur_block = bname
                    elif val.startswith('{') and val.endswith('}'):
                        # 单行块 (如 id={ id=11814 type=4713 }): 整串为值
                        stats[0] = stats.get(0, 0) + 1
                        out_lines.append('\t'.join(('#', key, val[1:-1].strip())))
                        block_stats.setdefault('#', {'lines': 0, 'leaves': 0})['leaves'] += 1
                    else:
                        # 顶格叶子
                        stats[0] = stats.get(0, 0) + 1
                        out_lines.append('\t'.join(('#', key, val)))
                        block_stats.setdefault('#', {'lines': 0, 'leaves': 0})['leaves'] += 1
                if cur_block:
                    block_stats[cur_block]['lines'] += 1
                continue

            # 块内: 记行数
            block_stats[stack[0]]['lines'] += 1

            m = HEAD.match(s)
            bare = BARE.match(s)
            val_is_block = False
            skip_delta = False
            if m:
                key = m.group(1) if m.group(1) is not None else m.group(2)
                val = m.group(3).strip()
                if val == '{':
                    val_is_block = True
                    stack.append(key)
                    if len(stack) >= 2:
                        parent = '|'.join(stack[:-1])
                        # 重复键编号: 同父同键第二次起 [n]
                        pkey = (parent, key)
                        cnt = block_seen.get(pkey, 0)
                        if cnt > 0:
                            stack[-1] = '%s[%d]' % (key, cnt + 1)
                        block_seen[pkey] = cnt + 1
                elif val.startswith('{') and val.endswith('}'):
                    # 行内平衡块 (key={v} 或 key={ a b c }): 内串为值 (多 token 整行收)
                    inner = val[1:-1].strip()
                    emit(inner if inner else '{}', key)
                elif '{' not in val and '}' not in val:
                    # 纯标量/串叶子
                    # t80: 同行多赋值形态 (target=HOL\t\t\t\tignore=no) —
                    #   原样出叶会产生 6 列行, diff3 load_save (len!=3) 静默
                    #   丢弃 2,169 行 → 首段 = 键值, 其后 k=v 段拆独立叶
                    if '\t' in val and val.startswith('"'):
                        # 引号串: TAB 在引号内 = 单值一部分 (MD 中队名);
                        #   闭引号后的尾串 = t80 多赋值 (target="LBA"\tignore=no)
                        q = val.find('"', 1)
                        if q == -1:
                            emit(val, key)
                        else:
                            emit(val[:q + 1], key)
                            for extra in val[q + 1:].split('\t'):
                                extra = extra.strip()
                                if not extra:
                                    continue
                                if '=' in extra:
                                    ek, ev = extra.split('=', 1)
                                    emit(ev.strip(), key + '.' + ek.strip())
                                else:
                                    emit(extra, key)
                    elif '\t' in val:
                        parts = [p for p in val.split('\t') if p]
                        emit(parts[0], key)
                        for extra in parts[1:]:
                            if '=' in extra:
                                ek, ev = extra.split('=', 1)
                                emit(ev.strip(), key + '.' + ek.strip())
                            else:
                                emit(extra, key)
                    else:
                        emit(val, key)
                else:
                    # 混合 (罕见): 整行归一为值, 括号计数仍按全行
                    emit(' '.join(stripped.split()), key)
            elif (half_anon and opens == 0 and closes > 0
                    and stripped.endswith('}') and stack
                    and stack[-1] == half_anon[1]):
                # 半行内匿名对象的收尾行 (' 0}'): 出叶后撤掉 push, 跳过通用 delta
                #   ⚠ t90b: 同名字哨兵嵌套时提前命中 = 既定契约 (region
                #   values §21.4, 勿加栈深校验); 但真收尾在栈底 (条目级
                #   `{ "TAG"`, 如 apd) 时 emit 无 key → 路径空 → 静默丢叶
                #   (bi8 `#2 "USA"` 消失实证) — 栈底补 key='#N' 救回
                half_anon[2].append(stripped[:-1].strip())
                stack.pop()
                joined = ' '.join(p for p in half_anon[2] if p)
                if len(stack) > 1:
                    emit(joined)
                else:
                    emit(joined, half_anon[1])
                half_anon = None
                skip_delta = True
            elif bare:
                # 匿名裸块条目: '#N' 序号哨兵 (条目边界)
                parent = '|'.join(stack)
                n = anon_counter.get(parent, 0) + 1
                anon_counter[parent] = n
                val_is_block = True
                stack.append('#%d' % n)
            elif (opens == 1 and closes == 0 and stripped.startswith('{')
                    and stripped != '{' and '=' not in stripped
                    and not stripped.endswith('{')):
                # 半行内匿名对象 ('\t{ "GER"' 内容跨行到 '\t0}'):
                #   先 push '#N' 哨兵, 内容累积到收尾行一次性出叶
                #   ⚠ 必须 opens==1: '{ 365 {' 这类双开括号行是常规嵌套块,
                #     仍走通用 '@' 哨兵 (intel 池族路径依赖该形态)
                parent = '|'.join(stack)
                n = anon_counter.get(parent, 0) + 1
                anon_counter[parent] = n
                half_anon = (parent, '#%d' % n, [stripped[1:].strip()])
                val_is_block = True
                stack.append('#%d' % n)
            elif opens == closes == 1 and BARE_INLINE.match(s):
                # 行内匿名对象 '{ type=84 id=447 }': 整串为值, 计数已平衡
                parent = '|'.join(stack)
                n = anon_counter.get(parent, 0) + 1
                anon_counter[parent] = n
                emit(BARE_INLINE.match(s).group(1).strip(), '#%d' % n)
            elif opens == 0 and closes == 0 and stripped and stripped != '}':
                # 无 = 的多 token 值行 (rail_way 数值行 / 裸引号串行):
                # 条目序号哨兵作路径键 (rail_way 深层已有序; 块内直接层用 #N)
                parent = '|'.join(stack)
                n = anon_counter.get(parent, 0) + 1
                anon_counter[parent] = n
                emit(' '.join(stripped.split()), '#%d' % n)
            elif (opens == 0 and closes >= 1 and stripped != '}'
                    and '=' not in stripped and not stripped.startswith('{')
                    and TAILVAL.match(stripped)):
                # t79w 完整性审计修复: 数组尾行 '13218 \t\t}' (值+闭括号同行,
                #   无 =) — 旧版此形态全部 elif 落空被丢弃 (resave 档 2024 行:
                #   army_history.history_queue.location 382 / enable_tactic 133 /
                #   log 439 / lost_railways 族 392 / captured_provinces 10 等,
                #   其中 ~1600 行真数据)。值 = 去 } 后的数字串, 序号哨兵键。
                #   ⚠ regional_convoys '305 }' 是 SSparseArray 容量闭标注
                #   (与开头 '305 {' 成对) — 也一并收下, 由 diff 侧按语义处理。
                parent = '|'.join(stack)
                n = anon_counter.get(parent, 0) + 1
                anon_counter[parent] = n
                emit(' '.join(stripped[:-1].split()), '#%d' % n)

            # 净增量修正 (不变量: len(stack) == 净深度)
            delta = opens - closes
            if skip_delta:
                skip_delta = False
            elif delta > 0:
                # key={ / '#N' { 已 push 1 层; 其余补哨兵
                if val_is_block:
                    for _ in range(delta - 1):
                        stack.append('@')
                else:
                    for _ in range(delta):
                        stack.append('@')
            elif delta < 0:
                for _ in range(-delta):
                    if stack:
                        stack.pop()
                    else:
                        break
                if not stack:
                    cur_block = None
    return out_lines, stats, n_lines, block_stats


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    path, cmd = sys.argv[1], sys.argv[2]
    lines, stats, n_lines, block_stats = parse_all(path)
    print('扫描行数: %d, 全量叶子: %d, 块实例: %d' % (
        n_lines, len(lines), len(block_stats)))
    if cmd == 'extract':
        # 可选第三参 = 输出路径 (提取异档必须改名, 防覆盖原档口径基线 t73e 教训)
        outp = sys.argv[3] if len(sys.argv) > 3 else 'tmp_savefull_all.txt'
        with open(outp, 'w', encoding='utf-8', newline='\n') as f:
            f.write('\n'.join(lines))
        print('%d 行 -> %s' % (len(lines), outp))
    print('\n块级统计 (按叶子数降序):')
    for name, bs in sorted(block_stats.items(), key=lambda x: -x[1]['leaves']):
        print('  %-28s 行数 %8d  叶子 %8d' % (name, bs['lines'], bs['leaves']))
    print('\n深度分布:')
    for d in sorted(stats):
        print('  深度 %d: %d 叶子' % (d, stats[d]))
    return 0


if __name__ == '__main__':
    sys.exit(main())

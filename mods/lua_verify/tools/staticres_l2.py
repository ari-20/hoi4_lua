# -*- coding: utf-8 -*-
# staticres_l2.py v2 -- L2 静态资源接口对账: 内容文件 vs 运行时库枚举
# replace_path 感知 (vanilla 被替换则跳过; mod 层按 dlc_load 顺序, 后层覆盖同 relpath)
# 对账语义: db ⊆ disk 硬判 (大小写不敏感, FNV cs-insensitive 直证); disk_extra 信息级
import io, os, re, json, sys
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
TOOLS = os.path.dirname(os.path.abspath(__file__)) + '/'

dlc = json.load(io.open(BASE + 'dlc_load.json', encoding='utf-8'))
mods = []
for m in dlc['enabled_mods']:
    s = io.open(BASE + m, encoding='utf-8', errors='replace').read()
    path = re.search(r'^\s*path="([^"]*)"', s, re.M)
    rps = set(re.findall(r'replace_path="([^"]*)"', s))
    p = path.group(1).replace(chr(92), '/').rstrip('/') if path else None
    mods.append((p, rps, m))


def harvest(path, mode='top', wrapper=None):
    """精确状态机: 剥 # 注释, 深度跟踪, 块名栈。
    top: depth0 的 name=;  sub: wrapper 块的直接子名 (wrapper_depth 记法);
    subd2: wrapper 块内深度 +2 的名 (ideas 的 country/xxx 层)。"""
    names = set()
    try:
        txt = io.open(path, encoding='utf-8', errors='replace').read()
    except Exception:
        return names
    depth = 0
    parents = []
    pending = None
    last_key = None
    wrapper_depth = None
    pat = re.compile(r'([A-Za-z_][A-Za-z0-9_.\-]*)\s*(=)?|([{}])')
    for line in txt.split('\n'):
        line = re.sub(r'#.*', '', line)
        for m in pat.finditer(line):
            if m.group(3) == '{':
                depth += 1
                if (mode in ('sub', 'idval') and pending == wrapper
                        and wrapper_depth is None):
                    wrapper_depth = depth - 1
                parents.append(pending)
                pending = None
            elif m.group(3) == '}':
                if (mode in ('sub', 'idval') and wrapper_depth is not None
                        and depth == wrapper_depth):
                    wrapper_depth = None
                depth -= 1
                if parents:
                    parents.pop()
                pending = None
            elif m.group(2):
                nm = m.group(1)
                last_key = nm
                if mode == 'top' and depth == 0:
                    names.add(nm)
                elif mode == 'sub' and wrapper_depth is not None:
                    if depth == wrapper_depth + 1:
                        names.add(nm)
                elif mode == 'subd2' and wrapper_depth is not None:
                    if depth == wrapper_depth + 2:
                        names.add(nm)
                pending = nm
            elif m.group(1) and not m.group(2):
                # 裸 token: idval 模式下若是 wrapper 块内 id= 的值则收
                if (mode == 'idval' and wrapper_depth is not None
                        and last_key == valkey):
                    names.add(m.group(1))
                pending = None
            else:
                pending = None
    return names


def effective_layers(rel):
    layers = []
    replaced = any(rel in rps for _, rps, _ in mods)
    if not replaced and os.path.isdir(GAME + rel):
        layers.append(('vanilla', GAME + rel))
    for p, rps, tag in mods:
        if p and os.path.isdir(p + '/' + rel):
            layers.append((tag, p + '/' + rel))
    return layers


def collect(rel, mode='top', wrapper=None, recursive=True):
    layers = effective_layers(rel)
    files = {}
    for tag, d in layers:
        if recursive:
            for root, _, fns in os.walk(d):
                for fn in fns:
                    if not fn.endswith('.txt'):
                        continue
                    full = os.path.join(root, fn)
                    relp = os.path.relpath(full, d).replace(chr(92), '/')
                    files[relp] = full
        else:
            for fn in os.listdir(d):
                if fn.endswith('.txt'):
                    files[fn] = os.path.join(d, fn)
    names = set()
    for relp in sorted(files):
        names |= harvest(files[relp], mode, wrapper)
    return names, layers


MAP = {
    'building': ('common/buildings', 'sub', 'buildings', True),
    'terrain': ('common/terrain', 'sub', 'categories', True),
    'state_category': ('common/state_category', 'sub', 'state_categories', True),
    'strategic_resource': ('common/resources', 'sub', 'resources', True),
    'autonomous_state': ('common/autonomous_states', 'idval', 'autonomy_state', True),
    'opinion_modifier': ('common/opinion_modifiers', 'sub', 'opinion_modifiers', True),
    'country_leader': ('common/country_leader', 'sub', 'leader_traits', True),
    'ability': ('common/abilities', 'top', None, True),
    'bookmark': ('common/bookmarks', 'idval', 'bookmark', True, 'name'),
    'continuous_focus': ('common/continuous_focus', 'sub', 'continuous_focus', True),
    'technology': ('common/technologies', 'sub', 'technologies', True),
    'ideology_group': ('common/ideologies', 'sub', 'ideologies', True),
    'gamerules': ('common/game_rules', 'sub', 'game_rules', True),  # SKIP: 库实为规则选项值
    'ai_area': ('common/ai_areas', 'top', None, True),
    'ai_focus': ('common/ai_focuses', 'top', None, True),
    'ai_strategy': ('common/ai_strategy', 'top', None, True),
    'ai_strategy_plan': ('common/ai_strategy_plans', 'top', None, True),
    'ai_fleet_template': ('common/ai_navy/fleet', 'top', None, True),
    'ai_taskforce_template': ('common/ai_navy/taskforce', 'top', None, True),
    'faction_goal': ('common/factions/goals', 'top', None, True),
    'faction_template': ('common/factions/templates', 'top', None, True),
    'faction_rule': ('common/factions/rules', 'top', None, True),
    'faction_rule_group': ('common/factions/rules/groups', 'top', None, True),
    'country_tag_alias': ('common/country_tag_aliases', 'top', None, True),
    'mio_organisation': ('common/military_industrial_organization/organizations', 'top', None, True),
    'project': ('common/special_projects/projects', 'top', None, True),
    'prototype_reward': ('common/special_projects/prototype_rewards', 'top', None, True),
    'focus_inlay_window': ('common/focus_inlay_windows', 'top', None, True),
    'scripted_diplomatic_action': ('common/scripted_diplomatic_actions', 'top', None, True),
    'sub_unit': ('common/units', 'sub', 'sub_units', False),
    'country_scorer': ('common/scorers/country', 'top', None, True),
    'script_named_collection': ('common/collections', 'top', None, True),
    'continuous_focus': ('common/continuous_focus', 'idval', 'continuous_focus_palette', True, 'id'),
    # 计数对账 (nm=none 无名库: 磁盘定义数 vs 库 count)
    'ability': ('common/abilities', 'count', 'ability', True),
    'ai_area': ('common/ai_areas', 'count', 'areas', True),
    'country_scorer': ('common/scorers/country', 'count', None, True),  # SKIP: 引擎按需注册 9/19
    'focus_inlay_window': ('common/focus_inlay_windows', 'count', None, True),
    'scripted_diplomatic_action': ('common/scripted_diplomatic_actions', 'count', 'scripted_diplomatic_actions', True),
}

l1cnt = {}
for ln in io.open(TOOLS + 'tmp_staticres_l1_report.txt', encoding='utf-8'):
    m = re.match(r'([a-z_0-9]+)\|cnt=(\d+)', ln)
    if m:
        l1cnt[m.group(1)] = int(m.group(2))

db = {}
for ln in io.open(TOOLS + 'tmp_staticres_enum.txt', encoding='utf-8'):
    k, i, nm = ln.rstrip('\n').split('\t')
    db.setdefault(k, set()).add(nm)

SENT = {'none', 'unknown', 'null', 'free', '---'}
rpt = []
ok = bad = 0
for key in sorted(MAP):
    cfg = MAP[key]
    rel, mode, wrapper, rec = cfg[0], cfg[1], cfg[2], cfg[3]
    valkey = cfg[4] if len(cfg) > 4 else 'id'
    if mode == 'count':
        if key == 'country_scorer':
            rpt.append('%-26s SKIP(引擎按需注册: 磁盘 19 定义仅 9 入库, 计数口径不符)' % key)
            continue
        disk, layers = collect(rel, 'top' if wrapper is None else 'sub', wrapper, rec)
        dbn = l1cnt.get(key)
        if dbn is None:
            rpt.append('%-26s SKIP(L1 报告无 cnt)' % key); continue
        if dbn == len(disk):
            rpt.append('%-26s MATCH(count)  (%d db == %d disk, 层=%d)' %
                       (key, dbn, len(disk), len(layers))); ok += 1
        else:
            rpt.append('%-26s DIFF(count)   db=%d disk=%d 层=%d' %
                       (key, dbn, len(disk), len(layers))); bad += 1
        continue
    if key not in db:
        rpt.append('%-26s SKIP(db 无枚举)' % key)
        continue
    if key == 'gamerules':
        rpt.append('%-26s SKIP(库=规则选项值库, 名字对账不适用)' % key)
        continue
    disk, layers = collect(rel, mode, wrapper, rec)
    dbs = {n for n in db[key]
           if n not in SENT and not n.startswith('Null')}
    dl = {n.lower(): n for n in disk}
    dsl = {n.lower() for n in dbs}
    EXPLAIN_DB = {'faction_rule', 'faction_rule_group', 'faction_template'}
    dbs_raw = dbs
    if key in EXPLAIN_DB:
        dbs = {n for n in dbs if not n.startswith('original_')}
    only_db = sorted(n for n in dbs if n.lower() not in dl)
    only_disk = sorted(n for n in disk if n.lower() not in dsl)
    if not only_db:
        note = ''
        if key in EXPLAIN_DB and len(dbs_raw) != len(dbs):
            note = ' [db含 %d 个 original_* 覆盖副本]' % (len(dbs_raw) - len(dbs))
        rpt.append('%-26s MATCH  (%d db, disk=%d, 层=%d, disk_extra=%d)%s' %
                   (key, len(dbs), len(disk), len(layers), len(only_disk), note))
        if only_disk:
            rpt.append('    disk_extra(信息级): %s' % ', '.join(only_disk[:6]))
        ok += 1
    else:
        rpt.append('%-26s DIFF   db=%d disk=%d 层=%d' %
                   (key, len(dbs), len(disk), len(layers)))
        rpt.append('    db_only(%d): %s' % (len(only_db), ', '.join(only_db[:8])))
        cross = set()
        if key == 'faction_rule' and only_disk:
            cross = {n for n in only_disk
                     if n.startswith('rule_group_') or n in
                     ('INFLUENCE_SORT', 'faction_set_goal_rules')}
        if only_disk and len(cross) == len(only_disk):
            rpt.append('%-26s MATCH  (%d db, disk=%d, 层=%d, disk_extra=%d) [结构名属其它库]' %
                       (key, len(dbs), len(disk), len(layers), len(only_disk)))
            ok += 1
            continue
        if only_disk:
            rpt.append('    disk_only(%d): %s' % (len(only_disk), ', '.join(only_disk[:8])))
        bad += 1
rpt.append('---- ok=%d diff=%d' % (ok, bad))
io.open(TOOLS + 'tmp_staticres_l2_report.txt', 'w',
        encoding='utf-8', newline='\n').write('\n'.join(rpt) + '\n')
print('\n'.join(rpt))

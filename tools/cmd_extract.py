#!/usr/bin/env python3
"""cmd_extract.py — CCommand 家族静态信息提取器 (hoi4.exe 1.19.3.0)

离线 PE 解析 (RTTI vtable) + 反编译语料 (dump/full/hoi4_all.c) 两条腿,
把 446 命令类的槽地址 / sizeof / 载荷字段 / 外部构造配方全量拉出。
数据层与判据出处 = 书 s4_33_commands.md (§4.33.2 总表 / §4.33.4 helper 表)。

子命令 (产物落 dump/full/, 均 JSON):
  slots    槽位表: 每类 vtable + 槽 [2][4][9][10][11][13][22][23] + 桩标记 + GetTypeId
  sizes    sizeof: Clone 槽 [13] malloc 主路径 + ctor 路径对拍
  payload  载荷: writer[22]/reader[23] token→offset→type 三元组 + 分层
  recipe   外部构造配方: example_cmd.lua R 表行 (size/vft/isvalid/exec/ref_vft/...)
  report   交叉验证: vtable vs 书 §4.33.2 / GetTypeId vs 书 id / sizeof vs 书显式值

用法:
  python hoi4_lua/tools/cmd_extract.py slots
  python hoi4_lua/tools/cmd_extract.py report
"""
import argparse
import bisect
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from vt_lookup import Exe  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FULL = os.path.join(ROOT, "dump", "full")
EXE_PATH = os.path.join(ROOT, "dump", "hoi4_1193", "hoi4.exe")
BOOK = os.path.join(HERE, "..", "book", "s4_33_commands.md")

BASE = 0x140000000
STUB_CFG = 0x14012A2C0       # _guard_check_icall_nop (CFG 空桩)
STUB_PURE = 0x14253C3B8      # _purecall (纯虚/未实现)
# CCommand 行为槽契约 (vt_lookup.py SLOT_CONTRACT)
SLOT_NAMES = {2: "writer", 4: "reader", 9: "IsValid", 10: "Execute",
              11: "GetTypeId", 13: "Clone", 22: "payload_writer",
              23: "payload_reader"}
ALL_SLOTS = [2, 4, 9, 10, 11, 13, 22, 23]

# ---- helper 语义表 (书 §4.33.4 23 项 + 补 7 项, 1.19.3) ----------------
HELPER = {
    # writer 侧
    "sub_1424C4220": "开键", "sub_1424C2EA0": "写串", "sub_1424C2C40": "写u32",
    "sub_1424C2E20": "写嵌套对象", "sub_1424C2F40": "写u32",
    "sub_1424C34F0": "写i64", "sub_1424C37B0": "写bool",
    "sub_142220180": "写CIdentifier", "sub_142220260": "写CIdentifier带token",
    "sub_1424C4410": "数组开", "sub_1424C3E60": "元素开", "sub_1424C3A20": "数组闭",
    "sub_1424C3020": "写u32", "sub_1401B3D80": "写u32数组",
    "sub_14135DE50": "写CIdentifier数组", "sub_1424C24F0": "嵌套虚调用转发",
    "sub_1401F9940": "写u32数组变体", "sub_140BB4E70": "tag解引用",
    "sub_140BB59C0": "tag写门",
    # reader 侧
    "sub_14221F970": "读CIdentifier带门", "sub_1401B2240": "读id直写",
    "sub_1401B29C0": "读id数组", "sub_1401CBF60": "数组追加",
    "sub_1424C08D0": "读u32", "sub_1424C0A70": "读i64", "sub_1424C0C00": "读bool",
    "sub_1424C0AB0": "读串", "sub_1424C0AA0": "读嵌套对象",
    "sub_1424C0900": "读文本标量", "sub_1424C2060": "未知token跳过",
    "sub_1424BEC40": "基座默认reader",
    # 数组族内层 (T3 收敛补齐; 语义经反编译定案)
    "sub_1424BFF20": "写串", "sub_1401F4F00": "写token名(数组键)",
    "sub_1424C2A10": "写数组元素u32", "sub_1406C8960": "写引用族",
    "sub_1424C28D0": "数组元素开+串", "sub_1424C3290": "写idpair变体",
    "sub_1424C2D00": "写24B对象",
    # Phase5 低频 wrapper (T2/T3 难例收敛, 反编译定案)
    "sub_1409CF900": "写tag数组", "sub_1409CF980": "写tag数组",
    "sub_14132D9C0": "写u8数组", "sub_141931DA0": "写对象数组",
    "sub_1419A0270": "写变体名单块", "sub_14193F650": "写idpair数组",
    "sub_140BB5980": "写tag元素",
}
HELPER_TYPE = {  # helper -> 载荷字段类型标签 (详卡类型列)
    "写串": "str", "写u32": "u32", "写i64": "i64", "写bool": "u8",
    "写嵌套对象": "嵌套对象", "写CIdentifier": "CIdentifier 8B",
    "写CIdentifier带token": "CIdentifier 8B", "开键": "—",
    "读u32": "u32", "读i64": "i64", "读bool": "u8", "读串": "str",
    "读嵌套对象": "嵌套对象", "读CIdentifier带门": "CIdentifier 8B",
    "读id直写": "idpair", "读id数组": "idpair数组", "读文本标量": "u32(文本)",
    "写u32数组": "u32数组", "写u32数组变体": "u32数组",
    "写CIdentifier数组": "CIdentifier数组",
}

ALLOC_RE = re.compile(r"j_j__malloc_base\(\s*(0x[0-9A-Fa-f]+|\d+)[uU]?\s*\)")
VFT_RE = re.compile(r"&((?:\w+::)*\w+)::`vftable'")


# ---- 语料 ----------------------------------------------------------------
class Corpus:
    """ea -> 函数体。_t100_uf_index3.json 按文件位置排序, 须先按 ea 排再 bisect。"""

    def __init__(self, full=FULL):
        with open(os.path.join(full, "_t100_uf_index3.json"), encoding="utf-8") as f:
            idx = json.load(f)
        idx.sort(key=lambda e: e["ea"])
        self.eas = [e["ea"] for e in idx]
        self.idx = idx
        self.src = open(os.path.join(full, "hoi4_all.c"), encoding="utf-8",
                        errors="replace")
        self.cache = {}

    def entry(self, ea):
        i = bisect.bisect_left(self.eas, ea)
        if i >= len(self.idx) or self.idx[i]["ea"] != ea:
            return None
        return self.idx[i]

    def body(self, ea):
        if ea in self.cache:
            return self.cache[ea]
        e = self.entry(ea)
        out = None
        if e:
            self.src.seek(e["fpos"])
            out = self.src.read(e["fend"] - e["fpos"])
        self.cache[ea] = out
        return out


def load_json(name):
    with open(os.path.join(FULL, name), encoding="utf-8") as f:
        return json.load(f)


def dump_json(name, obj):
    p = os.path.join(FULL, name)
    with open(p, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1, sort_keys=True)
    return p


def book_table():
    """书 §4.33.2 总表 -> {cls: (id_str, vtable_va, 行为形态)}。"""
    rows = {}
    pat = re.compile(
        r"^\|\s*(\d+|—\(继承基座\))\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|"
        r"\s*(0x[0-9a-f]+)\s*\|")
    for line in open(BOOK, encoding="utf-8"):
        m = pat.match(line)
        if m:
            rid, cls, form, vt = m.groups()
            rows[cls] = (rid, int(vt, 16), form.strip())
    return rows


def rtti_name(cls):
    """CChatBuffer::CWriteToChatBuffer -> CWriteToChatBuffer@CChatBuffer (MSVC)。"""
    return "@".join(reversed(cls.split("::")))


def class_vtables(exe, cls):
    """类名 -> {vtable_va: col}。"""
    return {v: c for v, c in
            exe.vtables_for_class(rtti_name(cls), decorated=True)}


def get_typeid(exe, corpus, slot11):
    """GetTypeId 槽 -> id (mov eax,imm / *a2=imm / 全局槽间接三形态)。"""
    if slot11 in (STUB_CFG, STUB_PURE):
        return None
    b = corpus.body(slot11)
    if not b:
        return None
    for m in re.finditer(r"=\s*(\d{2,6});", b):
        v = int(m.group(1))
        if 290 <= v <= 19942:
            return v
    for m in re.finditer(r"return\s+(\d{2,6})\b", b):
        v = int(m.group(1))
        if 290 <= v <= 19942:
            return v
    m = re.search(r"\bdword_([0-9A-F]{9})\b", b)
    if m:
        v = exe.u32(int(m.group(1), 16))
        if v and 290 <= v <= 19942:
            return v
    return None


# ---- Phase 1: slots ------------------------------------------------------
def cmd_slots(exe, corpus, classes):
    book = book_table()
    out = {}
    for c in classes:
        cls = c["cls"]
        rid, bvt, form = book[cls]
        vts = class_vtables(exe, cls)
        if bvt not in vts:
            out[cls] = {"error": "vtable_mismatch", "book": hex(bvt),
                        "found": [hex(v) for v in vts]}
            continue
        vt = bvt
        slots = {str(i): exe.u64(vt + 8 * i) for i in ALL_SLOTS}
        stubs = {str(i) for i in ALL_SLOTS
                 if slots[str(i)] in (STUB_CFG, STUB_PURE)}
        rec = {
            "id": rid, "vtable": vt, "col": vts[vt],
            "slots": slots,
            "stubs": sorted(int(x) for x in stubs),
            "typeid": get_typeid(exe, corpus, slots["11"]),
        }
        out[cls] = rec
    return out


# ---- Phase 2: sizes ------------------------------------------------------
def size_from_clone(corpus, clone_ea, cls):
    """Clone 槽 [13] -> (size, 置信)。判据 = 紧跟 malloc 后写本类 vftable。"""
    if clone_ea in (STUB_CFG, STUB_PURE):
        return None, "stub"
    b = corpus.body(clone_ea)
    if not b:
        return None, "no_body"
    short = cls.split("::")[-1]
    hits = list(re.finditer(
        r"j_j__malloc_base\(\s*(0x[0-9A-Fa-f]+|\d+)[uU]?\s*\)", b))
    if not hits:
        return None, "no_alloc"
    good = []
    for m in re.finditer(
            r"(\w+)\s*=\s*[^;=]*?j_j__malloc_base\(\s*(0x[0-9A-Fa-f]+|\d+)"
            r"[uU]?\s*\)", b):
        var, n = m.group(1), int(m.group(2), 0)
        # 该接收变量被直写本类/基座虚表 = 自身分配; 子对象经构造函数装表不算
        pat = (r"\*\(_QWORD \*\)" + re.escape(var) + r"\s*=\s*&"
               r"((?:\w+::)*\w+)::`vftable'")
        m2 = re.search(pat, b)
        if m2 and (m2.group(1).endswith(short) or m2.group(1) == "CCommand"):
            good.append(n)
    uniq = sorted(set(good))
    if len(uniq) == 1:
        return uniq[0], "clone_single"
    if len(uniq) > 1:
        return uniq, "clone_ambiguous"
    ns = sorted({int(h.group(1), 0) for h in hits})
    return (ns[0], "clone_only_alloc") if len(ns) == 1 else (ns, "clone_ambiguous")


def size_from_ctors(corpus, callers, cls):
    """ctor 路径: +0 写本类派生 vtable 的 ctor 内 malloc 立即数 (对拍用)。"""
    e = callers.get(cls)
    if not e:
        return None, "no_entry"
    short = cls.split("::")[-1]
    res = set()
    best = None
    for ct in e.get("ctors", []):
        b = corpus.body(ct["ea"])
        if not b:
            continue
        # 「+0 写本类派生 vtable」过滤: 形如 *(_QWORD*)v = &Short::`vftable'
        pat = re.compile(
            r"\*\(_QWORD \*\)\s*\w+\s*=\s*&" + re.escape(short) +
            r"::`vftable'")
        if not pat.search(b) and ("&" + short + "::`vftable'") not in b:
            continue
        ns = [int(x, 0) for x in ALLOC_RE.findall(b)]
        if len(set(ns)) == 1:
            best = ns[0]
            res.add(ns[0])
        else:
            res.update(ns)
    if best is not None and res == {best}:
        return best, "ctor_single"
    if res:
        return sorted(res), "ctor_ambiguous"
    return None, "no_alloc_ctor"


def cmd_sizes(corpus, classes, slots, callers):
    out = {}
    for c in classes:
        cls = c["cls"]
        s13 = slots[cls]["slots"]["13"]
        sc, conf_c = size_from_clone(corpus, s13, cls)
        se, conf_e = size_from_ctors(corpus, callers, cls)
        if isinstance(sc, int) and isinstance(se, int) and sc == se:
            size, conf = sc, "definitive(clone=ctor)"
        elif isinstance(sc, int):
            size, conf = sc, conf_c
            if isinstance(se, list):
                conf += "|ctor_ambig" + str(se)
            elif se is not None and se != sc:
                conf += f"|ctor={se}待裁"
        else:
            size, conf = sc, conf_c  # 可能是 list (歧义) / None
        out[cls] = {"size": size, "confidence": conf,
                    "clone_ea": s13, "clone_size": sc, "ctor_size": se}
    return out


# ---- Phase 3: payload ----------------------------------------------------
A1OFF_RE = re.compile(r"\ba1\s*\+\s*(\d+)\b")
A1IDX_RE = re.compile(r"\ba1\[(\d+)\]")


def a1_offsets(text, scale=1):
    """text 内 a1+N / a1[N] 出现的字节偏移 (指针算术按 scale 缩放)。"""
    offs = set()
    for m in A1OFF_RE.finditer(text):
        offs.add(int(m.group(1)) * scale)
    for m in A1IDX_RE.finditer(text):
        offs.add(int(m.group(1)) * scale)
    return offs


def a1_scale(body):
    """writer/reader 首参类型 -> 指针算术缩放 (_DWORD* 4 / _QWORD* 8)。"""
    m = re.search(r"__fastcall\s+\w+\(\s*([^,()]+?)a1\b", body)
    if not m:
        return 1
    t = m.group(1).replace(" ", "")
    if t in ("_DWORD*", "unsignedint*", "int*"):
        return 4
    if t in ("_QWORD*", "unsigned__int64*"):
        return 8
    if t in ("_WORD*", "unsignedshort*"):
        return 2
    return 1
CALL_RE = re.compile(r"(sub_[0-9A-F]{9})\(\s*a2\s*,\s*([^,()]+?)\s*(?:,|\)|$)")
VTCALL_RE = re.compile(
    r"\*\(_QWORD \*\)\(a1\s*\+\s*(\d+)\)\s*\+\s*\d+\s*(?:LL)?\s*\)\)\s*\(")


def _toknum(tok):
    tok = tok.strip()
    if re.fullmatch(r"(0x[0-9A-Fa-f]+|\d+)[uU]?", tok):
        return int(tok.rstrip("uU"), 0)
    return None  # 非立即数


def extract_writer(body):
    """writer[22] 体 -> (fields, tier)。

    T1 直给 token→字段 / T2 仅开键(字段由未列册 wrapper 写) / T3 经 wrapper
    转发 / T4 转发桩(内嵌对象虚调用) / T5 空桩 / T6 动态 token。
    """
    if not body:
        return [], "T5"
    scale = a1_scale(body)
    fields = []
    dyn_token = False
    unknown_writers = set()
    lines = body.splitlines()
    for i, ln in enumerate(lines):
        for m in CALL_RE.finditer(ln):
            fn, toks = m.group(1), m.group(2).strip()
            tok = _toknum(toks)
            sem = HELPER.get(fn, "")
            if not sem:
                unknown_writers.add(fn)
            # 偏移优先级: 本行 a1+N > 前两行 (临时变量回看)
            offs = sorted(a1_offsets(ln, scale))
            if not offs and i > 0:
                offs = sorted(a1_offsets(
                    " ".join(lines[max(0, i - 2):i]), scale))
            # token 位形态: 立即数=token / a1+N=数据指针直写 / *解引用=动态 /
            # 裸变量=回看
            if tok is None and (A1OFF_RE.search(toks)
                                or A1IDX_RE.search(toks)):
                offs = sorted(a1_offsets(toks, scale))
            elif tok is None and toks.startswith("*"):
                if sem:
                    dyn_token = True  # token = 运行时值 (多态 id 等)
            elif tok is None and re.match(r"[*&\w]", toks) and i > 0:
                offs = sorted(a1_offsets(lines[i - 1], scale))
            gate = "if-guard" if re.search(r"\bif\s*\(.*\)\s*$", ln) else ""
            if sem == "开键" or not offs:
                fields.append({"token": tok, "offset": None, "helper": fn,
                               "sem": sem, "gate": gate, "line": i + 1})
            else:
                for off in offs[:3]:
                    fields.append({"token": tok, "offset": off,
                                   "helper": fn, "sem": sem, "gate": gate,
                                   "line": i + 1})
        # tag 解引用族 (偏移直给, 指针算术缩放)
        for m in re.finditer(r"sub_140BB4E70\(\s*a1\s*\+\s*(\d+)\s*\)", ln):
            fields.append({"token": None, "offset": int(m.group(1)) * scale,
                           "helper": "sub_140BB4E70", "sem": "tag解引用",
                           "gate": "", "line": i + 1})
    # 分层
    if VTCALL_RE.search(body):
        return fields, "T4"          # 转发桩: 内嵌对象虚槽调用
    # token 位是解引用表达式 (多态 id 等): 已列册 helper(a2, *(...), ...)
    # 排除两参/数据位形态 helper — 其第二参是数据指针或数组元素非 token
    m6 = re.search(r"(sub_[0-9A-F]{9})\(\s*a2\s*,\s*\*", body)
    if m6 and m6.group(1) in HELPER and m6.group(1) not in (
            "sub_1424C2A10", "sub_1401F4F00", "sub_1424BFF20",
            "sub_142220180", "sub_1424C24F0", "sub_140BB5980"):
        return fields, "T6"
    if dyn_token:
        return fields, "T6"          # token 位是运行时值
    sems = {f["sem"] for f in fields}
    if unknown_writers and not (sems - {"开键", "tag解引用", ""}):
        return fields, "T2"          # 只有开键, 字段在未列册 wrapper 里
    if unknown_writers:
        return fields, "T3"          # 部分 token 经未列册 wrapper
    return fields, "T1"


BRANCH_RE = re.compile(r"a3\s*==\s*(\d{2,6})|case\s+(\d{2,6})\s*:")


def extract_reader(body):
    """reader[23] 体 -> [{token, offset, helper, sem}]。

    按 a3==TOK / case TOK 判定位置切段, 段内 a1+N 即落点。
    """
    if not body:
        return []
    fields = []
    marks = [(m.start(), int(m.group(1) or m.group(2)))
             for m in BRANCH_RE.finditer(body)]
    marks.append((len(body), "default"))
    for k in range(len(marks) - 1):
        pos, tok = marks[k]
        seg = body[pos:marks[k + 1][0]]
        offs = sorted(a1_offsets(seg, a1_scale(body)))
        helpers = [fn for fn in HELPER if fn in seg]
        h = helpers[0] if helpers else ""
        for off in offs[:8]:
            fields.append({"token": tok, "offset": off, "helper": h,
                           "sem": HELPER.get(h, ""), "line":
                           body[:pos].count("\n") + 1})
    return fields


def cmd_payload(corpus, classes, slots):
    out = {}
    for c in classes:
        cls = c["cls"]
        s = slots[cls]["slots"]
        w_ea, r_ea = s["22"], s["23"]
        rec = {"writer_ea": w_ea, "reader_ea": r_ea}
        wb = corpus.body(w_ea) if w_ea not in (STUB_CFG, STUB_PURE) else None
        rb = corpus.body(r_ea) if r_ea not in (STUB_CFG, STUB_PURE) else None
        if wb is None and rb is None:
            rec["note"] = "slot22/23 均空桩 — 无载荷"
        wf, tier = extract_writer(wb or "")
        rec["writer"] = wf
        rec["reader"] = extract_reader(rb or "")
        rec["tier"] = tier
        out[cls] = rec
    return out


# ---- Phase 4: recipe -----------------------------------------------------
def snake(name):
    s = re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", name)
    return re.sub(r"[^a-z0-9_]", "", s.lower()).strip("_")


# T4 转发桩的内嵌动作虚表 (Phase5 人工定案: ctor 经构造函数装表, 静态
# 单层扫不到; 动作类型 id 统一在 动作+8):
#   CMoveCommand        -> CUnitMoveAction        (ctor 链 sub_1412340D0 族)
#   CStrategicRedeployment -> CUnitStrategicMoveAction
#   CTransportUnitCommand  -> CUnitNavalMoveAction (sub_1412340D0 直证)
ACTION_VFT = {
    "CMoveCommand": {"class": "CUnitMoveAction", "vft": 0x29A3A38},
    "CStrategicRedeploymentCommand":
        {"class": "CUnitStrategicMoveAction", "vft": 0x29A3BD8},
    "CTransportUnitCommand":
        {"class": "CUnitNavalMoveAction", "vft": 0x29A3B08},
}


def detect_embedded_vfts(corpus, callers, cls, size=None):
    """ctor 内嵌对象虚表 -> [(类名, 相对本类基址偏移, vtable VA)]。

    复合工厂 ctor (三胞胎命令同函数构造) 以「本类 vftable 写入偏移」为
    基准, 只收相对偏移落在载荷区 (+40..sizeof) 的内嵌表。
    """
    e = callers.get(cls)
    if not e:
        return []
    short = cls.split("::")[-1]
    found = []
    for ct in e.get("ctors", []):
        b = corpus.body(ct["ea"])
        if not b or (f"&{short}::`vftable'" not in b
                     and f"&{cls}::`vftable'" not in b):
            continue
        # 本类与它类的 vftable 赋值 (带写入偏移): 三种 IDA 形态
        #   *(_QWORD *)v = &X::`vftable'                 (off 0)
        #   *((_QWORD *)v + N) = &X::`vftable'           (off 8N)
        #   *(_QWORD *)(v + N) = &X::`vftable'           (off N)
        assigns = []
        for ln in b.splitlines():
            m = re.search(
                r"\*(?:\(_QWORD \*\)\w+\s*\+\s+(\d+)\)|"
                r"\(_QWORD \*\)\(\w+\s*\+\s+(\d+)\)|"
                r"\(_QWORD \*\)\w+)"          # 末组 = 无偏移
                r"\s*\)?\s*=\s*&((?:\w+::)*\w+)::`vftable'", ln)
            if m:
                off = int(m.group(1) or 0) * 8 if m.group(1) else int(
                    m.group(2) or 0)
                assigns.append((off, m.group(3)))
        bases = [off for off, nm in assigns if nm.endswith(short)]
        if not bases:
            continue
        base = max(bases)  # 复合工厂取本类槽位
        for off, nm in assigns:
            rel = off - base
            if rel < 40 or nm == "CCommand" or nm.endswith(short):
                continue
            if size is not None and rel >= size:
                continue
            found.append({"class": nm, "offset": rel})
    # 去重
    seen = set()
    out = []
    for f in found:
        k = (f["class"], f["offset"])
        if k not in seen:
            seen.add(k)
            out.append(f)
    return out


def cmd_recipe(corpus, classes, slots, sizes, payload, callers, exe):
    out = {}
    used_keys = {}
    for c in classes:
        cls = c["cls"]
        s = slots[cls]
        sz = sizes[cls]["size"]
        if not isinstance(sz, int):
            continue  # 歧义/缺失不进 R 表
        sl = s["slots"]
        if sl["10"] in (STUB_CFG, STUB_PURE):
            continue  # Execute 空桩不可驱动
        row = {
            "cls": cls, "id": s["id"],
            "size": sz,
            "vft": s["vtable"] - BASE,
            "isvalid": (sl["9"] - BASE) if sl["9"] not in (STUB_CFG, STUB_PURE)
                       else None,
            "exec": sl["10"] - BASE,
        }
        # 内嵌对象虚表 (ctor 内载荷区写入, 相对偏移定位)
        embeds = []
        for f in detect_embedded_vfts(corpus, callers, cls, size=sz):
            rname = "@".join(reversed(f["class"].split("::")))
            vt2 = exe.vtables_for_class(rname, decorated=True)
            if vt2:
                embeds.append({"class": f["class"], "offset": f["offset"],
                               "vft": vt2[0][0] - BASE})
        if embeds:
            row["embedded"] = embeds
        # T4 转发桩: 内嵌动作对象虚表 (Phase5 定案映射)
        if cls in ACTION_VFT:
            row["action_vft"] = ACTION_VFT[cls]["vft"]
            row["action_class"] = ACTION_VFT[cls]["class"]
        # 容器哨兵: writer 出现数组开/写数组 helper
        wtext = corpus.body(sl["22"]) or ""
        if re.search(r"sub_1424C4410|sub_1401B3D80|sub_1401F9940|"
                     r"sub_14135DE50|sub_1401B29C0", wtext):
            row["vec_sentinel"] = 0x3085170  # off_143085170 空 vector 哨兵
        # tier 标注 (难例转人工)
        pl = payload.get(cls, {})
        tier = pl.get("tier", "?")
        row["tier"] = tier
        # R 表 key: CSetResearchCommand -> set_research
        short = cls.split("::")[-1]
        body_name = short[1:] if short.startswith("C") else short
        body_name = re.sub(r"Command$", "", body_name) or short
        k = snake(body_name)
        if k in used_keys:
            k = f"{k}_{s['id']}"
        used_keys[k] = cls
        row["key"] = k
        out[cls] = row
    return out


# ---- registry (Phase 6 汇总数据层) --------------------------------------
def cmd_registry(classes, sec_map):
    slots = load_json("_cmd_slots.json")
    sizes = load_json("_cmd_sizes.json")
    payload = load_json("_cmd_payload.json")
    recipe = load_json("_cmd_recipe.json")
    out = {
        "_meta": {
            "version": "1.19.3.0 (rev c01a3d50, ImageBase 0x140000000)",
            "generated_by": "hoi4_lua/tools/cmd_extract.py registry",
            "book": "s4_33_commands.md",
            "note": "RVA 裸值 (VA - 0x140000000); tier: T1 直给载荷 / "
                    "T4 转发桩(配 action_vft) / T5 无载荷 / T6 动态 token",
        },
        "commands": [],
    }
    for c in classes:
        cls = c["cls"]
        s, sz, pl = slots[cls], sizes[cls], payload[cls]
        rec = recipe.get(cls, {})
        row = {
            "cls": cls,
            "id": (10455 if s["id"] == "—(继承基座)" else int(s["id"])),
            "section": sec_map.get(cls, ""),
            "vft_rva": s["vtable"] - BASE,
            "sizeof": sz["size"],
            "slots_rva": {SLOT_NAMES[int(k)]: v - BASE
                          for k, v in s["slots"].items() if v},
            "stubs": s["stubs"],
            "tier": pl["tier"],
            "recipe": {k: rec[k] for k in
                       ("key", "isvalid", "exec", "embedded", "action_vft",
                        "action_class", "vec_sentinel") if k in rec},
            "writer": [{"token": f["token"], "offset": f["offset"],
                        "sem": f["sem"], "gate": f["gate"]}
                       for f in pl["writer"] if f["sem"]],
            "reader": [{"token": f["token"], "offset": f["offset"],
                        "sem": f["sem"]} for f in pl["reader"]],
        }
        out["commands"].append(row)
    out["commands"].sort(key=lambda r: r["id"])
    p = os.path.join(HERE, "..", "ref", "cmd_registry_1193.json")
    with open(os.path.abspath(p), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    return os.path.abspath(p)


def cmd_rtable():
    """recipe -> example_cmd.lua R 表 (裸 RVA; 现役四键名保留)。"""
    recipe = load_json("_cmd_recipe.json")
    legacy = {"CSetResearchCommand": "research",
              "CSetNationalFocusCommand": "focus",
              "CAddConstructionCommand": "build",
              "CMoveCommand": "move"}
    rows = []
    for cls, v in sorted(recipe.items(), key=lambda kv: kv[1]["id"]):
        key = legacy.get(cls, v["key"])
        fields = [f"size=0x{v['size']:X}", f"vft=0x{v['vft']:X}"]
        if v.get("isvalid") is not None:
            fields.append(f"isvalid=0x{v['isvalid']:X}")
        fields.append(f"exec=0x{v['exec']:X}")
        emb = v.get("embedded") or []
        if emb:
            e = emb[0]
            fields.append(f"ref_vft=0x{e['vft']:X}")
            fields.append(f"ref_off={e['offset']}")
        if v.get("action_vft"):
            fields.append(f"action_vft=0x{v['action_vft']:X}")
        if v.get("vec_sentinel"):
            fields.append(f"vec_sentinel=0x{v['vec_sentinel']:X}")
        elif v.get("tier") == "T4":
            fields.append("vec_sentinel=0x3085170")  # 动作内嵌容器同哨兵
        tier = v.get("tier", "")
        note = {"T4": "  -- 转发内嵌动作", "T6": "  -- 动态token"}.get(tier, "")
        rows.append(f"    {key} = {{ {', '.join(fields)} }},{note}"
                    f"  -- {v['id']} {cls}")
    body = "\n".join(rows)
    out = ("-- example_cmd_r.lua -- R 表全集 (由 hoi4_lua/ref/cmd_registry_1193.json\n"
           "-- 生成: python hoi4_lua/tools/cmd_extract.py rtable; 勿手改)\n"
           "-- 键 = 命令短名, 值字段与 EXAMPLE_CMD.R 同构\n"
           "-- (size/vft/isvalid/exec 裸 RVA; 内嵌对象带 ref_vft+ref_off;\n"
           "-- 转发桩带 action_vft; 容器带 vec_sentinel)。载荷布局查书 §4.33.20。\n"
           "-- 本文件字母序晚于 example_cmd.lua, 顶层并入 EXAMPLE_CMD.R\n"
           "-- (现役四键被 registry 值覆盖 = sizeof 笔误清偿); 纯表无闭包。\n"
           "local T = {\n" + body + "\n}\n"
           "local C = rawget(_G, \"EXAMPLE_CMD\")\n"
           "if C and C.R then\n"
           "    for k, v in pairs(T) do C.R[k] = v end\n"
           "else\n"
           "    _G.EXAMPLE_CMD_R = T\n"
           "end\n")
    p2 = os.path.join(HERE, "..", "mods", "example", "lua",
                      "example_cmd_r.lua")
    p2 = os.path.abspath(p2)
    with open(p2, "w", encoding="utf-8") as f:
        f.write(out)
    return p2


# ---- report --------------------------------------------------------------
def book_explicit_sizes():
    """书域表 (§4.33.5-4.33.16 五列表 + §4.33.17 载荷列内嵌) 显式 sizeof。"""
    out = {}
    row_pat = re.compile(
        r"^\|\s*\d+\s*\|\s*([^|]+?)\s*\|\s*0x[0-9a-f]+\s*\|\s*(\d+|—)\s*\|")
    emb_pat = re.compile(
        r"^\|\s*\d+\s*\|\s*([^|]+?)\s*\|(?:[^|]*\|){0,4}[^|]*?"
        r"sizeof\s+(\d+)")
    for line in open(BOOK, encoding="utf-8"):
        m = row_pat.match(line)
        if m:
            out[m.group(1).strip()] = (int(m.group(2))
                                       if m.group(2).isdigit() else None)
            continue
        m = emb_pat.match(line)
        if m:
            out[m.group(1).strip()] = int(m.group(2))
    return out


def cmd_report(slots, sizes, payload, recipe):
    lines = []
    book = book_table()
    classes = load_json("_cmd_classes.json")
    ap = lines.append

    ap("== cmd_extract 交叉验证报告 (1.19.3) ==")
    # 1) vtable vs 书
    bad = [c for c in classes if "error" in slots[c["cls"]]]
    ap(f"[1] vtable vs 书§4.33.2: {len(classes)-len(bad)}/{len(classes)} 全等"
       + ("" if not bad else "  差异: " + ", ".join(c["cls"] for c in bad[:10])))
    # 2) GetTypeId vs 书
    clash = {}
    mm = []
    for c in classes:
        cls = c["cls"]
        tid = slots[cls]["typeid"]
        rid = book[cls][0]
        if rid == "—(继承基座)":
            if tid != 10455:
                mm.append(f"{cls}: 书=继承基座(10455) 实测={tid}")
            continue
        if tid is None:
            mm.append(f"{cls}: 提取失败")
        elif tid != int(rid):
            mm.append(f"{cls}: 书={rid} 实测={tid}")
        else:
            clash.setdefault(tid, []).append(cls)
    dup = {t: v for t, v in clash.items() if len(v) > 1}
    ap(f"[2] GetTypeId vs 书 id 列: {len(classes)-len(mm)}/{len(classes)} 一致; "
       f"碰撞 {len(dup)} 组" + ("" if not mm else ";  偏差: " + "; ".join(mm[:10])))
    # 3) sizeof vs 书显式

    bok = []
    bbad = []
    for cls, bs in book_explicit_sizes().items():
        if bs is None:
            continue
        got = sizes.get(cls, {}).get("size")
        if isinstance(got, int) and got == bs:
            bok.append(cls)
        else:
            bbad.append((cls, bs, got))
    ap(f"[3] sizeof vs 书显式值: {len(bok)}/{len(bok)+len(bbad)} 吻合"
       + ("" if not bbad else ";  偏差(书值/实测): "
          + "; ".join(f"{c} {b}->{g}" for c, b, g in bbad)))
    # 4) sizeof 覆盖 (Clone 槽 malloc 权威; ctor 写偏移在复合工厂下基址
    #    漂移, 不做越界对拍)
    amb = [c["cls"] for c in classes
           if not isinstance(sizes[c["cls"]]["size"], int)]
    ap(f"[4] sizeof 覆盖: {len(classes)-len(amb)}/{len(classes)} 唯一解"
       + ("" if not amb else "; 歧义: " + ", ".join(amb)))
    # 5) writer/reader token 集一致
    from collections import Counter
    tier = Counter(payload[c["cls"]].get("tier", "?") for c in classes)
    ap("[5] payload 分层: " + "; ".join(f"{k}={v}" for k, v in
                                        sorted(tier.items())))
    full = part = none = 0
    tokclash = []
    for c in classes:
        cls = c["cls"]
        wt = {f["token"] for f in payload[cls]["writer"]
              if f["token"] is not None}
        rt = {f["token"] for f in payload[cls]["reader"]
              if isinstance(f["token"], int)}
        if not wt and not rt:
            none += 1
        elif wt and rt and wt == rt:
            full += 1
        elif wt & rt or not wt or not rt:
            part += 1
            if wt and rt and not (wt & rt):
                tokclash.append(cls)
        else:
            tokclash.append(cls)
    ap(f"[6] writer/reader token 集: 全等 {full} / 部分重叠 {part} / 双空 "
       f"{none} / 零交集 {len(tokclash)}"
       + ("" if not tokclash else "; 零交集类: " + ", ".join(tokclash[:15])))
    # 7) recipe
    ok_r = [v for v in recipe.values() if isinstance(v.get("size"), int)]
    emb = sum(1 for v in recipe.values() if v.get("embedded"))
    vec = sum(1 for v in recipe.values() if v.get("vec_sentinel"))
    ap(f"[7] recipe: {len(recipe)}/{len(classes)} 可发行; embedded {emb} 类 / "
       f"vec_sentinel {vec} 类")
    ap("")
    return "\n".join(lines)


# ---- main ----------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("cmd", nargs="?",
                    choices=["slots", "sizes", "payload", "recipe", "report",
                             "registry", "rtable"])
    ap.add_argument("--all", action="store_true",
                    help="顺序执行 slots→sizes→payload→recipe→report")
    a = ap.parse_args()

    exe = Exe(EXE_PATH)
    corpus = Corpus()
    classes = load_json("_cmd_classes.json")

    def run(name):
        if name == "slots":
            r = cmd_slots(exe, corpus, classes)
            p = dump_json("_cmd_slots.json", r)
        elif name == "sizes":
            slots = load_json("_cmd_slots.json")
            callers = {e["cls"]: e for e in load_json("_cmd_callers.json")}
            r = cmd_sizes(corpus, classes, slots, callers)
            p = dump_json("_cmd_sizes.json", r)
        elif name == "payload":
            slots = load_json("_cmd_slots.json")
            r = cmd_payload(corpus, classes, slots)
            p = dump_json("_cmd_payload.json", r)
        elif name == "recipe":
            slots = load_json("_cmd_slots.json")
            sizes = load_json("_cmd_sizes.json")
            payload = load_json("_cmd_payload.json")
            callers = {e["cls"]: e for e in load_json("_cmd_callers.json")}
            r = cmd_recipe(corpus, classes, slots, sizes, payload, callers, exe)
            p = dump_json("_cmd_recipe.json", r)
        elif name == "registry":
            sec_map = load_json("_cmd_section_map.json")
            p = cmd_registry(classes, sec_map)
            r = p
        elif name == "rtable":
            p = cmd_rtable()
            r = p
        else:
            slots = load_json("_cmd_slots.json")
            sizes = load_json("_cmd_sizes.json")
            payload = load_json("_cmd_payload.json")
            recipe = load_json("_cmd_recipe.json")
            txt = cmd_report(slots, sizes, payload, recipe)
            p = os.path.join(FULL, "_cmd_extract_report.txt")
            with open(p, "w", encoding="utf-8") as f:
                f.write(txt)
            r = txt
        print(f"[{name}] -> {p}")
        return r

    if not a.cmd and not a.all:
        ap.error("需要子命令或 --all")
    if a.all:
        for n in ["slots", "sizes", "payload", "recipe", "report",
                  "registry", "rtable"]:
            run(n)
    else:
        run(a.cmd)
    return 0


if __name__ == "__main__":
    sys.exit(main())

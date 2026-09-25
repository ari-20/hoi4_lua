#!/usr/bin/env python3
"""vt_lookup.py — 从 1.19.3 hoi4.exe 现场解析 MSVC RTTI, 类名 <-> vtable 双向查找。

为什么需要它: ref/vt_rtti.json 与 ref/rtti_hierarchy.json 的 vtable 地址与
1.19.3 exe 全部错位 (见 OPEN_QUEUE T1), **不可直接采信地址**。但 exe 内的
RTTI 名字串是明文, 可现场解析, 结果与生产配方逐位吻合 (自检见 --selftest)。

原理 (MSVC x64 RTTI 链):
  vtable 符号地址 V 处:  [V-8] = Complete Object Locator (COL) 指针
  COL 布局:  +0 signature (0/1) | +4 offset | +8 cd | +12 TypeDescriptor RVA
  TypeDescriptor: +16 起为类名 C 串, 形如 ".?AV<Class>@@"

用法:
  python hoi4_lua/tools/vt_lookup.py --selftest
  python hoi4_lua/tools/vt_lookup.py --class CSetResearchCommand
  python hoi4_lua/tools/vt_lookup.py --vt 0x142994f40
  python hoi4_lua/tools/vt_lookup.py --dump-slot 0x142994f40 --slots 9,10
  python hoi4_lua/tools/vt_lookup.py --batch classes.txt --out tsv
"""
import argparse
import json
import struct
import sys

DEFAULT_EXE = r"D:\documents\workspace\dump\hoi4_1193\hoi4.exe"

# 行为槽契约。槽号 = vtable 索引 (vt[0] = 首个虚函数, COL 在 vt[-1])。
# CEffect / CTrigger 两族的槽名来自基族盲测定名成果 (CEffect 25 槽 / CTrigger 23 槽),
# 派生类的**实际行为**落在:
#   CEffect  -> 槽 13 ExecuteInternal (410 个派生覆写 = 每类实际行为)
#   CTrigger -> 槽 22 Evaluate         (纯虚; 槽 3 只是 scope 校验包装)
SLOT_CONTRACT = {
    "CEffect": {0: "ScalarDeletingDestructor", 1: "GetName", 2: "GetID",
                3: "Parse", 4: "ParseToken", 5: "IsAvailable?",
                6: "ParseTargetToken?", 7: "GetLocalisationVars?",
                8: "BuildTooltip", 9: "GetTooltipString", 10: "BuildGameTooltip?",
                11: "HasMultipleTooltipVars?", 12: "Execute(公共入口)",
                13: "ExecuteInternal(实际行为)", 14: "IsAvailable?"},
    "CTrigger": {0: "Dtor", 1: "GetKey", 2: "IsAssignTrigger",
                 3: "Evaluate(scope 包装)", 4: "AssignScopeTarget", 5: "Parse",
                 6: "ParseToken", 7: "Validate", 8: "GetScopeTargetID",
                 9: "GetScopeTargetUID?", 10: "GetScopeTargetObject?",
                 11: "GetTooltip", 12: "GetTooltipText", 13: "ValidateLate",
                 14: "GetSupportedScopeMask", 15: "GetSupportedTargetMask",
                 16: "IsScopeCompatible", 17: "ValidateAssignedScope",
                 18: "RegisterTrigger?", 19: "Traverse?", 20: "TraverseB?",
                 21: "GetDesc", 22: "Evaluate(纯虚谓词=实际行为)"},
    "CCommand": {2: "writer", 4: "reader", 9: "IsValid", 10: "Execute",
                 11: "GetTypeId", 13: "Clone", 22: "载荷 writer", 23: "载荷 reader"},
    "CPersistent": {1: "Save wrapper", 2: "该类 writer", 3: "Load wrapper",
                    4: "该类 reader"},
}


def undecorate(s):
    """".?AVCSetResearchCommand@@" -> "CSetResearchCommand"; 模板/命名空间原样保留内部形态。"""
    if not s:
        return s
    if s.startswith(".?AV"):
        s = s[4:]
    elif s.startswith(".?AU"):
        s = s[4:]
    if s.endswith("@@"):
        s = s[:-2]
    return s


class Exe:
    def __init__(self, path):
        self.buf = open(path, "rb").read()
        b = self.buf
        e = struct.unpack_from("<I", b, 0x3C)[0]
        nsec = struct.unpack_from("<H", b, e + 6)[0]
        opt = e + 24
        self.base = struct.unpack_from("<Q", b, opt + 24)[0]
        off = opt + struct.unpack_from("<H", b, e + 20)[0]
        self.secs = []
        for i in range(nsec):
            s = off + 40 * i
            nm = b[s:s + 8].rstrip(b"\0").decode("ascii", "replace")
            vsz, va, rsz, ra = struct.unpack_from("<IIII", b, s + 8)
            self.secs.append((nm, self.base + va, ra, vsz, rsz))
        self.by_name = {s[0]: s for s in self.secs}

    def va2off(self, a):
        for nm, va, ra, vsz, rsz in self.secs:
            if va <= a < va + max(vsz, rsz):
                return ra + (a - va)
        return None

    def off2va(self, o):
        for nm, va, ra, vsz, rsz in self.secs:
            if ra <= o < ra + rsz:
                return va + (o - ra)
        return None

    def u32(self, a):
        o = self.va2off(a)
        return struct.unpack_from("<I", self.buf, o)[0] if o is not None else None

    def u64(self, a):
        o = self.va2off(a)
        return struct.unpack_from("<Q", self.buf, o)[0] if o is not None else None

    def cstr(self, a):
        o = self.va2off(a)
        if o is None:
            return None
        end = self.buf.find(b"\0", o)
        return self.buf[o:end].decode("ascii", "replace")

    # ---- RTTI ----

    def cols_for_pattern(self, pat_bytes):
        """按原始修饰名模式搜索。pat_bytes 必须**从 `.?AV` 起** (TypeDescriptor
        名字字段的起点), 否则 TD 回推会偏。"""
        out = []
        pos = 0
        while True:
            i = self.buf.find(pat_bytes, pos)
            if i < 0:
                break
            pos = i + 1
            td = self.off2va(i) - 16           # TD 名字字段前 16 字节 = TD 起点
            rva = td - self.base
            if rva > 0xFFFFFFFF:
                continue
            needle = struct.pack("<I", rva)
            p = 0
            while True:
                q = self.buf.find(needle, p)
                if q < 0:
                    break
                p = q + 1
                co = q - 12
                if co < 0:
                    continue
                if struct.unpack_from("<I", self.buf, co)[0] not in (0, 1):
                    continue
                out.append(self.off2va(co))
        return sorted(set(out))

    def cols_for_name(self, name):
        """裸类名 -> [COL 地址]。模板/命名空间类请走 --decorated。"""
        return self.cols_for_pattern((".?AV" + name + "@@").encode())

    def vtable_for_col(self, col):
        """COL 地址 -> [vtable 符号地址] (vtable[-1] == COL)。"""
        needle = struct.pack("<Q", col)
        out = []
        p = 0
        while True:
            q = self.buf.find(needle, p)
            if q < 0:
                break
            p = q + 1
            vt = self.off2va(q + 8)            # 存 COL 的槽是 vt[-1]
            if vt:
                out.append(vt)
        return sorted(set(out))

    def vtables_for_class(self, name, decorated=False):
        """类名 -> [(vtable, col)]。
        decorated=False: name 是裸类名 (CSetResearchCommand) -> 搜 .?AV<name>@@
        decorated=True : name 是 MSVC 修饰体 (CMasteryTrigger@NDoctrines,
                         ?$CSetOrAddVictoryPointsEffect@$00) -> 搜 .?AV<name>@@
        容错: 嵌套模板的修饰名自身可能已以 `@` 结尾 (如
        ?$CVariableEffectBuilder@V?$CGetSupplyVehicles@VCVariableResolver@@@@),
        此时直接拼 `@@` 会多出终止符; 故首个模式无命中时再试原样形态。
        """
        cands = [(".?AV" + name + "@@").encode()]
        if name.endswith("@"):
            cands.append((".?AV" + name).encode())
        res = []
        for pat in cands:
            cols = self.cols_for_pattern(pat)
            if not cols:
                continue
            for col in cols:
                for vt in self.vtable_for_col(col):
                    res.append((vt, col))
            if res:
                break
        return res

    def class_for_vt(self, vt):
        """vtable 符号地址 -> (类名, COL)。类名已剥离 MSVC 修饰 (.?AV..@@)。"""
        col = self.u64(vt - 8)
        if not col:
            return None, None
        td = self.base + self.u32(col + 12)
        return undecorate(self.cstr(td + 16)), col

    def slots(self, vt, n=32):
        return [self.u64(vt + 8 * i) for i in range(n)]


def infer_family(cls):
    """按类名后缀推断族 (启发式; 不确定时用 --family 显式指定)。"""
    if not cls:
        return None
    for suf, fam in (("Command", "CCommand"), ("Effect", "CEffect"),
                     ("Trigger", "CTrigger")):
        if cls.endswith(suf):
            return fam
    return None


def fmt_slots(exe, vt, cls, n=32, family=None):
    fam = family or infer_family(cls)
    table = SLOT_CONTRACT.get(fam, {})
    out = []
    for i, fn in enumerate(exe.slots(vt, n)):
        if fn is None:
            break
        tag = ""
        if fn == 0x14253C3B8:
            tag = "  <- _purecall"
        elif fn == 0x14012A2C0:
            tag = "  <- _guard_check_icall_nop (CFG 空桩)"
        label = f"  [{table[i]}]" if i in table else ""
        out.append(f"  vt[{i:2d}] = {fn:#x}{label}{tag}")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", default=DEFAULT_EXE)
    ap.add_argument("--class", dest="cls")
    ap.add_argument("--decorated", action="store_true",
                    help="--class 传的是 MSVC 修饰名 (模板/命名空间类真名)")
    ap.add_argument("--vt", help="vtable 符号地址, 如 0x142994f40")
    ap.add_argument("--dump-slot", help="vtable 地址, 打印槽表")
    ap.add_argument("--slots", default="32", help="--dump-slot 打印槽数 (默认 32)")
    ap.add_argument("--batch", help="每行一个类名的文件")
    ap.add_argument("--out", default="text", choices=["text", "tsv"])
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()

    exe = Exe(a.exe)

    if a.selftest:
        # 生产配方锚: example_cmd.lua 的 research 行
        vt, col = None, None
        for v, c in exe.vtables_for_class("CSetResearchCommand"):
            if v == exe.base + 0x2994F40:
                vt, col = v, c
        ok = vt is not None
        print(f"[1] CSetResearchCommand vtable == BASE+0x2994F40 : {'OK' if ok else 'FAIL'}")
        if ok:
            s = exe.slots(vt, 16)
            print(f"[2] vt[9] (IsValid) == 0x1166BC0 : {'OK' if s[9] == exe.base + 0x1166BC0 else 'FAIL'} ({s[9]:#x})")
            print(f"[3] vt[10](Execute) == 0x115D2E0 : {'OK' if s[10] == exe.base + 0x115D2E0 else 'FAIL'} ({s[10]:#x})")
            nm, c2 = exe.class_for_vt(vt)
            print(f"[4] 反向 vt->类名 == CSetResearchCommand : {'OK' if nm == 'CSetResearchCommand' else 'FAIL'} ({nm})")
        return 0 if ok else 1

    if a.vt:
        vt = int(a.vt, 16)
        nm, col = exe.class_for_vt(vt)
        print(f"vtable {vt:#x}")
        print(f"  COL      = {col:#x}" if col else "  COL      = <无效>")
        print(f"  类名     = {nm}")
        print(f"  RVA      = {vt - exe.base:#x}")
        print(fmt_slots(exe, vt, nm, 24))
        return 0

    if a.dump_slot:
        vt = int(a.dump_slot, 16)
        nm, _ = exe.class_for_vt(vt)
        n = int(a.slots)
        print(f"vtable {vt:#x}  RVA {vt - exe.base:#x}  类名 {nm}")
        print(fmt_slots(exe, vt, nm, n))
        return 0

    names = []
    if a.cls:
        names = [a.cls]
    elif a.batch:
        names = [l.strip() for l in open(a.batch, encoding="utf-8") if l.strip()]

    if a.out == "tsv":
        print("class\tvtable_rva\tcol\tslot9\tclass_check")
        for nm in names:
            vts = exe.vtables_for_class(nm)
            if not vts:
                print(f"{nm}\t-\t-\t-\tNOT_FOUND")
                continue
            for vt, col in vts:
                got, _ = exe.class_for_vt(vt)
                print(f"{nm}\t{vt - exe.base:#x}\t{col:#x}\t{exe.u64(vt + 72):#x}\t{got}")
        return 0

    for nm in names:
        vts = exe.vtables_for_class(nm, decorated=a.decorated)
        print(f"{nm}:")
        if not vts:
            print("  NOT FOUND (名字不在 exe RTTI 明文里; 模板类请用 --decorated 传修饰名, "
                  "或试去命名空间短名)")
            continue
        for vt, col in vts:
            got, _ = exe.class_for_vt(vt)
            print(f"  vtable={vt:#x} (RVA {vt - exe.base:#x})  COL={col:#x}  反查={got}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

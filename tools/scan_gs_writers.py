import os, struct, sys

# scan_gs_writers.py — find the instruction(s) that write the gamestate
# singleton slot. Those writes ARE the session lifecycle events consumed by
# the DLL's DR hardware breakpoints (see src/hoi4_session.cpp); re-run this
# per game build and update SESSION_CTOR_WRITE / SESSION_DTOR_WRITE in
# src/hoi4_offsets.h.
#
# usage: python scan_gs_writers.py [hoi4.exe] [slot_rva]
#   hoi4.exe : positional, or env HOI4_EXE, or <HOI4_GAME_DIR>\hoi4.exe
#   slot_rva : default = 1.19.3.0-c01a3d50 (0x332F260 = OFF_GAMESTATE_PTR)

SLOT_RVA_DEFAULT = 0x332F260   # 1.19.3.0-c01a3d50

exe = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("HOI4_EXE")
if not exe:
    gd = os.environ.get("HOI4_GAME_DIR")
    exe = os.path.join(gd, "hoi4.exe") if gd else None
if not exe or not os.path.isfile(exe):
    raise SystemExit("usage: python scan_gs_writers.py <hoi4.exe> [slot_rva] "
                     "(or set HOI4_GAME_DIR / HOI4_EXE)")
slot_rva = int(sys.argv[2], 0) if len(sys.argv) > 2 else SLOT_RVA_DEFAULT

buf = open(exe, "rb").read()
e_lfanew = struct.unpack_from("<I", buf, 0x3C)[0]
assert buf[e_lfanew:e_lfanew+4] == b"PE\0\0"
coff = e_lfanew + 4
num_sec = struct.unpack_from("<H", buf, coff+2)[0]
opt_size = struct.unpack_from("<H", buf, coff+16)[0]
opt = coff + 20
imagebase = struct.unpack_from("<Q", buf, opt+24)[0]
sec0 = opt + opt_size
text = None
for i in range(num_sec):
    s = sec0 + 40*i
    name = buf[s:s+8].rstrip(b"\0").decode()
    vsize, vaddr, rsize, raddr = struct.unpack_from("<IIII", buf, s+8)
    if name == ".text":
        text = (vaddr, rsize, raddr)
if not text:
    raise SystemExit("no .text")
tva, trsize, traddr = text
slot_va = imagebase + slot_rva
print("imagebase=%X text va=%X raw=%X size=%X slot_va=%X" %
      (imagebase, tva, traddr, trsize, slot_va))

hits = []
end = traddr + trsize - 15
i = traddr
while i < end:
    b0, b1, b2 = buf[i], buf[i+1], buf[i+2]
    # REX.W(+B) mov r/m64, r64  -> 48/49 89 modrm(mod=00,rm=101)
    if b0 in (0x48, 0x49) and b1 == 0x89 and (b2 & 0xC7) == 0x05:
        disp = struct.unpack_from("<i", buf, i+3)[0]
        nxt = imagebase + tva + (i - traddr) + 7
        if nxt + disp == slot_va:
            hits.append((i, "mov [slot], reg%d" % ((b2 >> 3) & 7), 7))
        i += 7; continue
    # REX.W mov r/m64, imm32 (sign-ext)  -> 48/4C C7 modrm(/0, mod=00, rm=101)
    if b0 in (0x48, 0x4C) and b1 == 0xC7 and (b2 & 0xC7) == 0x05:
        disp = struct.unpack_from("<i", buf, i+3)[0]
        imm = struct.unpack_from("<i", buf, i+7)[0]
        nxt = imagebase + tva + (i - traddr) + 11
        if nxt + disp == slot_va:
            hits.append((i, "mov [slot], %d" % imm, 11))
        i += 11; continue
    i += 1

print("writers found:", len(hits))
for off, desc, ln in hits:
    va = imagebase + tva + (off - traddr)
    ctx = buf[off-16:off+16].hex(" ")
    print("  VA=%X (RVA=%X) len=%d  %s\n    ctx[-16:+16]: %s" % (va, tva + (off - traddr), ln, desc, ctx))

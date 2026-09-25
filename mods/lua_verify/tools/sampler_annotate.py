#!/usr/bin/env python3
"""sampler_annotate.py - annotate hoi4.profile_* output; render flame graphs.

Leaf histogram (hoi4.profile_top)
  live (default) : POST /lua `return hoi4.profile_top(N)` to the running game
  --file PATH    : annotate a saved top-lines file instead

Folded stacks (hoi4.profile_folded writes <logs>/profile_folded.txt)
  --fold PATH    : read folded "root;...;leaf count" lines
  --svg OUT.svg  : render a flame graph (needs --fold input or --live-folded)
  --live-folded  : fetch folded via POST /lua `return hoi4.profile_folded()`
                   (the DLL writes the file; we then read it from --fold PATH
                   or the default logs location)

Naming: hoi4.exe RVAs become VAs via image base 0x140000000 and are matched
against the decompiled corpus function headers (dump/full/hoi4_all.c);
a scan cache is kept beside the corpus. Foreign addresses (other DLLs)
stay as raw hex.

Usage
  python sampler_annotate.py                          # live leaf top 40
  python sampler_annotate.py --top 100 --min 20
  python sampler_annotate.py --file tmp_top.txt
  python sampler_annotate.py --fold profile_folded.txt --svg flame.svg
  python sampler_annotate.py --live-folded --svg flame.svg --minwidth 0.05
"""
import argparse
import bisect
import html
import json
import os
import re
import sys
import urllib.request
import zlib

WORKSPACE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                          "..", "..", "..", ".."))
CORPUS = os.path.join(WORKSPACE, "dump", "full", "hoi4_all.c")
CACHE = CORPUS + ".funcidx.tsv"
IMAGE_BASE = 0x140000000          # hoi4.exe 1.19.3.0 c01a3d50
DEFAULT_FOLDED = os.path.join(os.environ.get("USERPROFILE", "."),
    "Documents", "Paradox Interactive", "Hearts of Iron IV",
    "logs", "profile_folded.txt")

# ---------------------------------------------------------------- func index
def load_func_index(force_rescan=False):
    """sorted list of (va, name); cached as TSV beside the corpus."""
    if not force_rescan and os.path.exists(CACHE):
        try:
            with open(CACHE, "r", encoding="utf-8") as f:
                hdr = f.readline().strip()
                if hdr == f"#cache size={os.path.getsize(CORPUS)}":
                    pairs = []
                    for ln in f:
                        va, name = ln.rstrip("\n").split("\t", 1)
                        pairs.append((int(va), name))
                    return pairs
        except Exception as e:
            print(f"[cache unreadable ({e}); rescanning]", file=sys.stderr)
    print(f"[scanning {CORPUS} ...]", file=sys.stderr)
    data = open(CORPUS, "rb").read()
    pairs = []
    for m in re.finditer(rb"// === 0x([0-9A-Fa-f]+) (\S+) ===", data):
        pairs.append((int(m.group(1), 16), m.group(2).decode("ascii")))
    pairs.sort()
    tmp = CACHE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(f"#cache size={os.path.getsize(CORPUS)}\n")
        for va, name in pairs:
            f.write(f"{va}\t{name}\n")
    os.replace(tmp, CACHE)
    print(f"[indexed {len(pairs)} functions]", file=sys.stderr)
    return pairs


_INDEX = None
_VAS = None

def name_of(va, index_and_vas):
    """va -> (display_name, exact_bool). In-image va only."""
    index, vas = index_and_vas
    i = bisect.bisect_right(vas, va) - 1
    if i < 0:
        return f"0x{va:x}", False
    nva, name = index[i]
    if nva == va:
        return name, True
    return f"{name}+{va - nva:#x}", False


def make_name_resolver(index):
    vas = [p[0] for p in index]
    return (index, vas)

# ---------------------------------------------------------------- live fetch
def _post(host, path, data=None, ctype="text/plain"):
    req = urllib.request.Request(f"http://{host}{path}",
                                 data=(data.encode("utf-8") if data is not None else b""),
                                 method="POST",
                                 headers={"Content-Type": ctype})
    with urllib.request.urlopen(req, timeout=30) as r:
        body = json.loads(r.read().decode("utf-8"))
    if not body.get("ok"):
        raise RuntimeError(f"{path} failed: {body.get('result', body)}")
    return body["result"]


def post_lua(host, chunk):
    return _post(host, "/lua", chunk)


def fetch_live(host, top):
    try:
        return _post(host, f"/profile/top?n={top}")          # v2 thin endpoint
    except Exception:
        return post_lua(host, f"return hoi4.profile_top({top})")


def fetch_live_folded(host):
    try:
        return _post(host, "/profile/folded")
    except Exception:
        return post_lua(host, "return hoi4.profile_folded()")

# ---------------------------------------------------------------- leaf table
def parse_top(text):
    header, rows = {}, []
    for ln in text.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        if ln.startswith("total="):
            for kv in ln.split():
                k, _, v = kv.partition("=")
                header[k] = int(v)
            continue
        parts = ln.split()
        if len(parts) == 3 and parts[1] in ("rva", "rip"):
            rows.append((int(parts[0]), parts[1], int(parts[2], 16)))
    return header, rows


def do_leaf(args, index):
    text = (open(args.file, "r", encoding="utf-8").read() if args.file
            else fetch_live(args.host, args.top))
    header, rows = parse_top(text)
    if not rows:
        print("no rows; raw text was:\n" + text)
        return
    resolver = make_name_resolver(index)
    total_img = sum(c for c, kind, _ in rows if kind == "rva") or 1
    out = []
    for count, kind, val in rows:
        if kind == "rip":
            out.append((count, f"rip 0x{val:x}", None, None))
        else:
            disp, exact = name_of(IMAGE_BASE + val, resolver)
            out.append((count, disp, IMAGE_BASE + val, exact))
    out = [r for r in out if r[0] >= args.min]
    width = max((len(d) for _, d, _, _ in out), default=10)
    print(f"total={header.get('total', '?')}  functions={header.get('functions', '?')}"
          f"  shown={len(out)}  (pct of in-image samples)")
    print(f"{'count':>8}  {'pct':>6}  {'location':<{width}}  source")
    for count, disp, va, exact in out:
        pct = f"{100.0 * count / total_img:5.2f}%" if va else ""
        tag = ("rva" if exact else "nearest") if va else ""
        vas = f"0x{va:X} {tag}" if va else ""
        print(f"{count:>8}  {pct:>6}  {disp:<{width}}  {vas}")
    if args.csv:
        with open(args.csv, "w", encoding="utf-8") as f:
            f.write("count\tpct\tdisplay\tva\n")
            for count, disp, va, exact in out:
                pct = f"{100.0 * count / total_img:.2f}" if va else ""
                f.write(f"{count}\t{pct}\t{disp}\t{va or ''}\n")
        print(f"[csv -> {args.csv}]")

# ---------------------------------------------------------------- folded
def parse_folded(text):
    """-> (hdr dict, [(frames_root_first_list, count), ...])"""
    hdr, stacks = {}, []
    for ln in text.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        if ln.startswith("#"):
            for kv in ln[1:].split():
                k, _, v = kv.partition("=")
                if k:
                    try: hdr[k] = int(v)
                    except ValueError: hdr[k] = int(v, 16)   # base= is hex
            continue
        sp = ln.rsplit(" ", 1)
        if len(sp) == 2 and sp[1].isdigit():
            stacks.append((sp[0].split(";"), int(sp[1])))
    return hdr, stacks


def annotate_folded(stacks, index, base):
    """map absolute frame addresses to names via the runtime image base."""
    resolver = make_name_resolver(index)
    img_lo, img_hi = base, base + 0x3000000
    out = []
    for frames, count in stacks:
        names = []
        for tok in frames:
            try:
                va = int(tok, 16)
            except ValueError:
                names.append(tok)
                continue
            if img_lo <= va <= img_hi:
                nm, _ = name_of(IMAGE_BASE + (va - base), resolver)
                names.append(nm)
            else:
                names.append(f"0x{va:x}")
        out.append((names, count))
    return out

# ---------------------------------------------------------------- flame svg
class _Node:
    __slots__ = ("name", "value", "selfv", "children")

    def __init__(self, name):
        self.name = name
        self.value = 0
        self.selfv = 0
        self.children = {}


def build_tree(annotated):
    root = _Node("(root)")
    for frames, count in annotated:
        node = root
        node.value += count
        for fr in frames:
            if fr not in node.children:
                node.children[fr] = _Node(fr)
            node = node.children[fr]
            node.value += count
        node.selfv += count
    return root


def render_flame_svg(annotated, out_path, title="hoi4 main-thread profile",
                     total_samples=None, minwidth=0.1, width=1600, fh=16):
    """classic flame graph: root at bottom, frames grow upward."""
    root = build_tree(annotated)
    total = root.value or 1

    def maxdepth(node, d=0):
        m = d
        for c in node.children.values():
            m = max(m, maxdepth(c, d + 1))
        return m
    depth = maxdepth(root)
    h_header = 42
    svg_h = h_header + (depth + 1) * fh + 18

    def color_of(name):
        h = zlib.crc32(name.encode())
        r, g = 205 + (h >> 8) % 50, 80 + (h >> 16) % 110
        b = 40 + h % 60
        if name.startswith("0x"):                     # external frame
            return f"rgb(150,{140 + (h >> 8) % 40},{140 + (h >> 16) % 40})"
        return f"rgb({r},{g},{b})"

    parts = [
        f'<svg version="1.1" xmlns="http://www.w3.org/2000/svg" '
        f'width="{width}" height="{svg_h}" onload="init(evt)">',
        '<style>text{font-family:Verdana,sans-serif;font-size:12px;fill:black;}'
        '.tt{font-size:18px;font-weight:bold;}.st{font-size:11px;fill:gray;}'
        'rect:hover{stroke:black;stroke-width:0.5;cursor:pointer;}</style>',
        f'<rect x="0" y="0" width="{width}" height="{svg_h}" fill="rgb(245,244,240)"/>',
    ]
    t = html.escape(title)
    info = f"{total:,} stacks"
    if total_samples:
        info += f", total samples {total_samples:,}"
    parts.append(f'<text class="tt" x="10" y="20">{t}</text>')
    parts.append(f'<text class="st" x="10" y="36">{html.escape(info)}'
                 f' ; width=count share ; hover=frame info</text>')

    rows = []
    def layout(node, x, w, d):
        if w < minwidth:
            return
        y = h_header + (depth - d) * fh
        rows.append((x, y, w, node))
        cx = x
        for c in node.children.values():
            cw = w * c.value / node.value if node.value else 0
            layout(c, cx, cw, d + 1)
            cx += cw
    layout(root, 0, width, 0)

    for x, y, w, node in rows:
        if node is root:
            continue
        nm = node.name
        esc = html.escape(nm)
        pct = 100.0 * node.value / total
        parts.append(
            f'<g><title>{esc} ({node.value:,} stacks, {pct:.2f}%)</title>'
            f'<rect x="{x:.3f}" y="{y}" width="{w:.3f}" height="{fh - 1}" '
            f'fill="{color_of(nm)}"/>' )
        chars = int(w / 6.5)
        if chars >= 3:
            label = nm if len(nm) <= chars else nm[:chars - 1] + "…"
            parts.append(f'<text x="{x + 2:.3f}" y="{y + 12}">{html.escape(label)}</text>')
        parts.append('</g>')
    parts.append('</svg>')
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("".join(parts))
    print(f"[svg -> {out_path}]  frames={len(rows) - 1} depth={depth} total={total:,}")


def do_fold(args, index):
    path = args.fold
    if args.live_folded:
        res = fetch_live_folded(args.host)
        print(res)
        if not path:
            path = DEFAULT_FOLDED
    if not path:
        path = DEFAULT_FOLDED
    if not os.path.exists(path):
        print(f"folded file not found: {path}")
        return None
    hdr, stacks = parse_folded(open(path, "r", encoding="utf-8").read())
    if not stacks:
        print("no stacks in folded file")
        return None
    base = hdr.get("base")
    if not base:                                   # old dumps lack it
        try:
            base = int(post_lua(args.host, "return hoi4.to_number(hoi4.base())"))
            print(f"[base via live query: 0x{base:x}]")
        except Exception:
            base = IMAGE_BASE
            print(f"[no base in file or live; assuming static 0x{IMAGE_BASE:x}]")
    print(f"folded: {len(stacks)} unique stacks, samples={hdr.get('samples', '?')}, "
          f"stacks={hdr.get('stacks', '?')}, base=0x{base:x}")
    annotated = annotate_folded(stacks, index, base)

    # top-leaf summary from folded (leaf = last frame)
    leaf = {}
    for names, count in annotated:
        leaf[names[-1]] = leaf.get(names[-1], 0) + count
    total = sum(leaf.values()) or 1
    print(f"top leaves (of {total:,} stack samples):")
    for nm, cnt in sorted(leaf.items(), key=lambda kv: -kv[1])[:15]:
        print(f"  {cnt:>8}  {100.0 * cnt / total:5.2f}%  {nm}")

    if args.named_out:
        with open(args.named_out, "w", encoding="utf-8") as f:
            for names, count in sorted(annotated, key=lambda kv: -kv[1]):
                f.write(";".join(names) + f" {count}\n")
        print(f"[named folded -> {args.named_out}]")

    if args.svg:
        render_flame_svg(annotated, args.svg,
                         title=args.title or "hoi4 main-thread profile",
                         total_samples=hdr.get("samples"),
                         minwidth=args.minwidth)
    return annotated

# ---------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--host", default="127.0.0.1:17389")
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--min", type=int, default=1, help="drop leaf rows below this count")
    ap.add_argument("--file", help="annotate a saved profile_top text file")
    ap.add_argument("--csv", help="also write leaf rows to this TSV path")
    ap.add_argument("--fold", help="folded-stacks file (default: the logs one)")
    ap.add_argument("--live-folded", action="store_true",
                    help="ask the running game to dump folded first (stack mode)")
    ap.add_argument("--named-out", help="write name-annotated folded lines here")
    ap.add_argument("--svg", help="render flame graph SVG here (folded mode)")
    ap.add_argument("--title", help="flame graph title")
    ap.add_argument("--minwidth", type=float, default=0.1,
                    help="skip frames thinner than this many px (default 0.1)")
    ap.add_argument("--rescan", action="store_true", help="rebuild the corpus index cache")
    args = ap.parse_args()

    index = load_func_index(args.rescan)
    if args.fold or args.live_folded or args.svg:
        do_fold(args, index)
    else:
        do_leaf(args, index)


if __name__ == "__main__":
    sys.exit(main())

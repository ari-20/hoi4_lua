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
# user-dir root, NOT logs/ (the engine wipes logs/ on every game launch)
DEFAULT_FOLDED = os.path.join(os.environ.get("USERPROFILE", "."),
    "Documents", "Paradox Interactive", "Hearts of Iron IV",
    "profile_folded.txt")

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

# ---------------------------------------------------------------- semantics
# Name/module map for hoi4.exe functions. Machine-extracted only — the file is
# a reproducible function of (hoi4.exe, decompiled corpus):
#   tools/scan_symbols.py  ->  ref/func_names_1193.tsv
# Tiers in that file: sym (PE exports, lambda descriptors) > rtti (vtable
# slots, "Class::[slot]") > line (assert file:line, module tag only).
# Display rule: a name always wins; a bare sub_XXXX gets its module tag
# appended when one exists.
REF_FUNC_NAMES = os.path.join(WORKSPACE, "hoi4_lua", "ref", "func_names_1193.tsv")


def load_semantics(force_rescan=False):
    """-> (sem {va:name}, mods {va:'file.cpp:line'}) from the ref artifact.

    The artifact is machine-extracted by tools/scan_symbols.py; this
    loader never scans the book or the corpus itself.
    """
    sem, mods = {}, {}
    if not os.path.exists(REF_FUNC_NAMES):
        print(f"[ref missing: {REF_FUNC_NAMES} — run tools/scan_symbols.py]",
              file=sys.stderr)
        return sem, mods
    with open(REF_FUNC_NAMES, "r", encoding="utf-8") as f:
        for ln in f:
            if ln.startswith("#"):
                continue
            parts = ln.rstrip("\n").split("\t")
            if len(parts) < 2:
                continue
            va = int(parts[0])
            if parts[1]: sem[va] = parts[1]
            if len(parts) > 2 and parts[2]: mods[va] = parts[2]
    return sem, mods


def name_of(va, index_and_vas):
    """va -> (display_name, exact_bool). In-image va only.

    Layering: book semantic name > corpus name > corpus name + module tag.
    """
    index, vas, sem, mods = index_and_vas
    i = bisect.bisect_right(vas, va) - 1
    if i < 0:
        return f"0x{va:x}", False
    nva, name = index[i]
    semname = sem.get(nva)
    if nva == va:
        if semname:
            return semname, True
        mod = mods.get(nva)
        return (f"{name} [{mod}]" if mod and name.startswith("sub_") else name), True
    if semname:
        return f"{semname}+{va - nva:#x}", False
    return f"{name}+{va - nva:#x}", False


def make_name_resolver(index):
    vas = [p[0] for p in index]
    sem, mods = load_semantics()
    return (index, vas, sem, mods)

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
    """map absolute frame addresses to names via the runtime image base.

    Frames are normalized to FUNCTION granularity (the "+0xOFFSET" call-site
    suffix is stripped): sampled stacks record raw RIPs per frame, and without
    normalization every call site becomes its own tree node — the flame graph
    collapses into thousands of one-sample towers instead of merging.
    Pre-annotated tokens (from a --fold named file) get the same treatment.
    """
    resolver = make_name_resolver(index)
    _, _, sem, mods = resolver
    img_lo, img_hi = base, base + 0x3000000

    _RE_SUBNAME = re.compile(r"sub_1[0-9A-Fa-f]{8}\b")

    def norm(nm):
        """strip +0x call-site suffix, then promote sub_XXXX via the semantic
        map (pre-named tokens from a --fold file deserve the same layer)."""
        if "+0x" in nm:
            nm = nm.split("+", 1)[0]
        m = _RE_SUBNAME.match(nm)
        if m:
            va = int(m.group(0)[4:], 16)
            sn = sem.get(va)
            if sn:
                return sn
            if mods.get(va):
                return f"{nm} [{mods[va]}]"
        return nm

    out = []
    for frames, count in stacks:
        names = []
        for tok in frames:
            try:
                va = int(tok, 16)
            except ValueError:
                names.append(norm(tok))          # already-named token
                continue
            if img_lo <= va <= img_hi:
                nm, _ = name_of(IMAGE_BASE + (va - base), resolver)
                names.append(nm.split("+", 1)[0])
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


# ---------------------------------------------------------- interactive html
_FLAME_HTML_TMPL = """<!doctype html>
<meta charset="utf-8"><title>%(title_esc)s</title>
<style>
body{margin:0;background:#f5f4f0;font-family:Verdana,sans-serif;}
#bar{display:flex;gap:12px;align-items:center;padding:8px 12px;background:#22242c;color:#eee;
     font-size:13px;position:sticky;top:0;z-index:5;flex-wrap:wrap;}
#bar b{font-size:15px;}
#bar input{background:#111;color:#eee;border:1px solid #555;border-radius:3px;
           padding:3px 6px;width:260px;font-family:inherit;}
#bar button{background:#3a6ea5;color:#fff;border:0;border-radius:3px;padding:4px 10px;cursor:pointer;}
#bar button:hover{background:#4a7ec0;}
#stats{color:#9db8d2;}
#match{color:#ffd479;min-width:120px;}
#crumb{color:#8aa;}
#info{padding:4px 12px;font-size:12px;color:#333;background:#e8e6df;
      border-bottom:1px solid #ccc;min-height:16px;}
svg{display:block;background:#f5f4f0;}
.fr{cursor:pointer;stroke:#222;stroke-width:.4;}
.fr:hover{stroke:#000;stroke-width:1.2;}
.fr.hi rect{fill:#9955ee !important;}
text{font-size:12px;pointer-events:none;font-family:Verdana,sans-serif;}
</style>
<div id="bar">
  <b>%(title_esc)s</b>
  <span id="stats"></span>
  <input id="q" placeholder="search (regex, e.g. SupplySystem|140E2)" title="regular expression">
  <span id="match"></span>
  <button id="reset">reset zoom</button>
  <span id="crumb"></span>
</div>
<div id="info">hover a frame; click = zoom in, right-click = zoom out</div>
<svg xmlns="http://www.w3.org/2000/svg"></svg>
<script>
"use strict";
const RAW = %(data_json)s;
const FH = 18, MINW = 0.35, SVG_NS = "http://www.w3.org/2000/svg";
const svg = document.querySelector("svg");
const info = document.getElementById("info");
const stats = document.getElementById("stats");
const crumb = document.getElementById("crumb");
const matchEl = document.getElementById("match");
const qEl = document.getElementById("q");

// ---- tree ----
function mkNode(name, parent) { return {name, parent, value: 0, children: new Map(), _hi: false}; }
const root = mkNode("(root)", null);
for (const [key, c] of RAW) {
    let n = root; n.value += c;
    for (const fr of key.split(";")) {
        let ch = n.children.get(fr);
        if (!ch) { ch = mkNode(fr, n); n.children.set(fr, ch); }
        n = ch; n.value += c;
    }
}
root.parent = root;
let zoomNode = root;
let qRe = null;

function colour(name) {
    let h = 0;
    for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) | 0;
    h = Math.abs(h);
    if (name.startsWith("0x")) return `hsl(${(h * 37) %% 360},25%%,70%%)`;   // external
    return `hsl(${18 + (h * 13) %% 32},${62 + ((h >> 8) %% 28)}%%,${58 + ((h >> 16) %% 14)}%%)`;
}

function maxDepth(n, d) {
    let m = d;
    for (const c of n.children.values()) m = Math.max(m, maxDepth(c, d + 1));
    return m;
}

function pathOf(n) {
    const parts = [];
    for (let p = n; p && p !== root; p = p.parent) parts.unshift(p.name);
    return parts;
}

function markSearch(n, re) {
    let hit = 0;
    n._hi = re ? re.test(n.name) : false;
    if (n._hi) hit = n.value;   // inclusive share of current view
    let kids = 0, anyKid = false;
    for (const c of n.children.values()) {
        const [h, a] = markSearch(c, re);
        kids += h; anyKid = anyKid || a;
    }
    const selfPart = (n._hi ? n.value : 0);
    return [Math.min(n.value, selfPart + (n._hi ? 0 : kids)), anyKid || n._hi];
}

function applySearch() {
    const q = qEl.value.trim();
    try { qRe = q ? new RegExp(q, "i") : null; }
    catch (e) { matchEl.textContent = "bad regex"; return; }
    const [hit] = markSearch(zoomNode, qRe);
    matchEl.textContent = qRe ? `matched: ${hit.toLocaleString()} (${(100 * hit / Math.max(1, zoomNode.value)).toFixed(2)}%%)` : "";
    render();
}

function el(tag, attrs) {
    const e = document.createElementNS(SVG_NS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    return e;
}

function render() {
    const W = Math.max(600, window.innerWidth - 14);
    const depth = maxDepth(zoomNode, 0);
    const H = (depth + 1) * FH + 4;
    while (svg.firstChild) svg.removeChild(svg.firstChild);
    svg.setAttribute("width", W);
    svg.setAttribute("height", H);
    const zv = Math.max(1, zoomNode.value);

    function place(n, x, w, d) {
        if (w < MINW) return;
        const y = H - (d + 1) * FH;
        const g = el("g", {"class": "fr" + (n._hi ? " hi" : "")});
        const r = el("rect", {x: x.toFixed(3), y, width: w.toFixed(3), height: FH - 1,
                              fill: (n === zoomNode && n !== root) ? "#8a97aa" : colour(n.name)});
        g.appendChild(r);
        g.addEventListener("mousemove", () => {
            info.textContent = `${n.name} — ${n.value.toLocaleString()} stacks`
                + ` (${(100 * n.value / zv).toFixed(2)}%% of view)`;
        });
        g.addEventListener("click", (ev) => { ev.stopPropagation(); zoomNode = n; applySearch(); });
        g.addEventListener("contextmenu", (ev) => {
            ev.preventDefault(); ev.stopPropagation();
            zoomNode = n.parent || root; applySearch();
        });
        const chars = Math.floor(w / 6.8);
        if (chars >= 3) {
            const nm = n.name.length > chars ? n.name.slice(0, chars - 1) + "…" : n.name;
            const t = el("text", {x: (x + 3).toFixed(3), y: y + 13});
            t.textContent = nm;
            g.appendChild(t);
        }
        svg.appendChild(g);
        let cx = x;
        for (const c of n.children.values()) {
            const cw = w * c.value / n.value;
            place(c, cx, cw, d + 1);
            cx += cw;
        }
    }
    place(zoomNode, 0, W, 0);

    const p = pathOf(zoomNode);
    crumb.textContent = p.length ? "zoom: " + p.join(" / ").slice(-140) : "";
    stats.textContent = `${root.value.toLocaleString()} stacks`
        + (zoomNode !== root ? ` | view ${zoomNode.value.toLocaleString()} (${(100 * zoomNode.value / root.value).toFixed(2)}%%)` : "");
}

document.getElementById("reset").addEventListener("click", () => { zoomNode = root; applySearch(); });
qEl.addEventListener("input", applySearch);
window.addEventListener("resize", render);
svg.addEventListener("contextmenu", (ev) => ev.preventDefault());
svg.addEventListener("click", () => { zoomNode = root; applySearch(); });
render();
</script>
"""


def render_flame_html(annotated, out_path, title="hoi4 main-thread profile",
                      total_samples=None):
    """self-contained interactive flame HTML: click zoom / right-click out /
    regex search highlight / hover info. No external assets."""
    data = [[";".join(names), count] for names, count in annotated]
    info = title
    if total_samples:
        info += f" ({total_samples:,} samples)"
    html_doc = _FLAME_HTML_TMPL % {
        "title_esc": htmlmod_escape(info),
        "data_json": json.dumps(data, ensure_ascii=False, separators=(",", ":")),
    }
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html_doc)
    print(f"[html -> {out_path}]  stacks={len(data)}")


def htmlmod_escape(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;"))


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
    if args.html:
        render_flame_html(annotated, args.html,
                          title=args.title or "hoi4 main-thread profile",
                          total_samples=hdr.get("samples"))
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
    ap.add_argument("--svg", help="render static flame graph SVG here (folded mode)")
    ap.add_argument("--html", help="render interactive flame HTML here (zoom/search)")
    ap.add_argument("--title", help="flame graph title")
    ap.add_argument("--minwidth", type=float, default=0.1,
                    help="skip frames thinner than this many px (default 0.1)")
    ap.add_argument("--rescan", action="store_true", help="rebuild the corpus index cache")
    args = ap.parse_args()

    index = load_func_index(args.rescan)
    if args.fold or args.live_folded or args.svg or args.html:
        do_fold(args, index)
    else:
        do_leaf(args, index)


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.10"
# ///
"""The model's checks beyond scad-check.sh, runnable by anyone with OpenSCAD and uv. From the repository's root:

  uv run scripts/checks.py collisions     the five collision checks, the box both ways round, and the
                                          wires against everything in it
  uv run scripts/checks.py controls       every positive control in docs/checking.md and docs/wiring.md,
                                          re-measured
  uv run scripts/checks.py figures [--write] [NAME ...]
                                          every picture in docs/, each render's output read for errors -
                                          rendered aside, or over docs/ with --write
  uv run scripts/checks.py stats A.stl [B.stl]   an STL's size and shape; given two, whether they match

docs/checking.md and docs/wiring.md say what each check and control means; this file only runs them. The
controls are read from those pages' tables, so a page and its check cannot drift apart: a control that no
longer fails, or measures something other than what its page says, fails the run.

Why OpenSCAD's output is read and not only its exit code: a failed assert during a PNG or .echo export
still exits 0, and writes a blank picture. An STL export exits 1.

Exit status: 0 everything as expected, 1 anything else. OPENSCAD names the binary (default: openscad on PATH,
which must be the 2021.01 release the model is checked with); JOBS sets how many renders run at once.
"""
import hashlib
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODEL = "models/air-quality-monitor.scad"
WIRES = "models/assembly-views.scad"
OPENSCAD = os.environ.get("OPENSCAD") or shutil.which("openscad") or "openscad"
JOBS = int(os.environ.get("JOBS", max(1, (os.cpu_count() or 2) // 2)))

COLLISIONS = ["check_parts", "check_components", "check_insert", "check_slide", "check_cover_on"]

# Every picture in docs/: the file it is rendered from, and the camera and settings it is rendered with.
FIGURES = {
    "feature-map-back": ("models/feature-map.scad", ["-D", 'view="back"', "--imgsize=1800,1500", "--projection=o",
                         "--viewall", "--autocenter", "--camera=31,0,44,78,0,195,260"]),
    "feature-map-cover": ("models/feature-map.scad", ["-D", 'view="cover"', "--imgsize=1800,1500", "--projection=o",
                          "--viewall", "--autocenter", "--camera=31,0,44,100,0,15,260"]),
    "assembly-exploded": ("models/assembly-views.scad", ["-D", 'view="exploded"', "--imgsize=1800,1500",
                          "--projection=o", "--viewall", "--autocenter", "--camera=33,80,38,68,0,252,560"]),
    "assembly-open": ("models/assembly-views.scad", ["-D", 'view="open"', "--imgsize=1800,1500", "--projection=o",
                      "--viewall", "--autocenter", "--camera=33,0,38,78,0,195,260"]),
    "wiring-detail": ("models/assembly-views.scad", ["-D", 'view="open"', "-D", "detail=true", "--imgsize=1800,1350",
                      "--projection=o", "--camera=8,11,51,112,0,215,70"]),
    "board-measure": ("models/board-measure.scad", ["--imgsize=1800,1300", "--projection=o",
                      "--camera=35,22.3,0,0,0,0,152"]),
    "fits-map": ("models/fits/fits-map.scad", ["--imgsize=1600,1150", "--projection=o", "--viewall", "--autocenter",
                 "--camera=0,0,0,30,0,0,300"]),
    "sps30-measure": ("models/fits/sps30-measure.scad", ["--imgsize=1800,1300", "--projection=o", "--viewall",
                      "--autocenter", "--camera=0,0,0,86,0,0,300"]),
}
BLANK_BELOW = 15_000   # bytes: the blank pictures a failed assert left were 4-13 kB, the real ones 22 kB and up


# ---------------------------------------------------------------- STL: size and shape
def triangles(path):
    """The triangles of an ASCII or binary STL, as three (x, y, z) tuples each."""
    data = Path(path).read_bytes()
    if data[:5] == b"solid" and b"facet" in data[:400]:
        corners = [tuple(map(float, line.split()[1:4]))
                   for line in data.decode("ascii", "replace").splitlines() if line.strip().startswith("vertex")]
        return [corners[i:i + 3] for i in range(0, len(corners) - 2, 3)]
    count = struct.unpack("<I", data[80:84])[0]
    return [[tuple(f[k:k + 3]) for k in (0, 3, 6)]
            for f in (struct.unpack("<9f", data[84 + i * 50 + 12:84 + i * 50 + 48]) for i in range(count))]


def stl_stats(path):
    """Facets, volume, area, bounding box and a hash of the distinct corners - enough to tell two exports of
    the same solid from two different solids, where comparing the files' bytes cannot: OpenSCAD's facet order
    follows the source, not the shape."""
    tris = triangles(path)
    volume = sum((a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                  + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6 for a, b, c in tris)
    area = sum(math.dist((0, 0, 0), cross(sub(b, a), sub(c, a))) / 2 for a, b, c in tris)
    corners = {tuple(round(x, 3) + 0.0 for x in p) for t in tris for p in t}
    lo = [min(p[k] for p in corners) for k in range(3)] if corners else [0, 0, 0]
    hi = [max(p[k] for p in corners) for k in range(3)] if corners else [0, 0, 0]
    digest = hashlib.sha256(repr(sorted(corners)).encode()).hexdigest()[:16]
    return {"facets": len(tris), "volume": volume, "area": area, "lo": lo, "hi": hi, "corners": len(corners),
            "hash": digest}


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def describe(s):
    return (f"facets {s['facets']}  volume {s['volume']:.3f} mm3  area {s['area']:.3f} mm2  "
            f"box {[round(x, 3) for x in s['lo']]} .. {[round(x, 3) for x in s['hi']]}  "
            f"corners {s['corners']} #{s['hash']}")


def same_solid(a, b):
    """Two exports of one solid: the same volume, area, box and corners. The facet count may differ."""
    return (abs(a["volume"] - b["volume"]) < 1e-3 and abs(a["area"] - b["area"]) < 1e-3
            and all(abs(x - y) < 1e-4 for x, y in zip(a["lo"] + a["hi"], b["lo"] + b["hi"]))
            and a["hash"] == b["hash"])


# ---------------------------------------------------------------- OpenSCAD
def render(out, scad, args):
    """Run OpenSCAD from the repository's root; return its exit code and its whole output."""
    run = subprocess.run([OPENSCAD, "-o", str(out), *args, scad], cwd=ROOT, capture_output=True, text=True)
    return run.returncode, run.stdout + run.stderr


# Two parts that touch intersect in a solid of no volume, which CGAL calls "not a valid 2-manifold": expected
# from check_parts, and harmless in a control, where the volume is what is read.
DEGENERATE = "WARNING: Object may not be a valid 2-manifold"


def problems(log, allowed=()):
    """OpenSCAD's own errors and warnings - not the model's ECHO "WARNING: ..." design notes, which are
    reported by scad-check.sh and are a judgement call, not a failure."""
    return [line for line in log.splitlines()
            if re.match(r"(ERROR|WARNING):", line) and not line.startswith(tuple(allowed))]


def defines(settings):
    return [x for name, value in settings for x in ("-D", f"{name}={value}")]


def run_case(scad, selector, settings, tmp, ext="stl"):
    """Render one check to STL - or to .echo, for a view whose asserts are the check - and return (volume, or
    None when OpenSCAD wrote no solid; problems; the whole output). An .echo export writes an assert's ERROR
    line into the file, not to the console, so the file is read as well."""
    out = Path(tmp) / f"case-{uuid.uuid4().hex[:12]}.{ext}"
    _, log = render(out, scad, defines([selector, *settings]))
    if ext == "echo" and out.exists():
        log += "\n" + out.read_text(encoding="utf-8", errors="replace")
    volume = stl_stats(out)["volume"] if ext == "stl" and out.exists() else None
    return volume, problems(log, allowed=[DEGENERATE]), log


def part(name):
    """A check in the model: the file, and the part that selects it."""
    return MODEL, ("part", f'"{name}"')


def view(name):
    """A view in the assembly views: the file, and the view that selects it."""
    return WIRES, ("view", f'"{name}"')


def parallel(fn, items):
    with ThreadPoolExecutor(max_workers=JOBS) as pool:
        return list(pool.map(fn, items))


# ---------------------------------------------------------------- the checks
def collisions():
    """Each check intersects two things that must not meet: OpenSCAD must write nothing, or - for the parts
    against each other, which touch - a solid of no volume. The box both ways round: a check run one way
    only has passed a mirrored mistake before. The wires only the way they are laid out, the box as built."""
    cases = [(f"{name:17} outlet_at_left={side}", *part(name), [("outlet_at_left", side)])
             for side in ("false", "true") for name in COLLISIONS]
    cases.append(("check_wires       the box as built", *view("check_wires"), []))
    with tempfile.TemporaryDirectory() as tmp:
        results = parallel(lambda c: run_case(c[1], c[2], c[3], tmp), cases)
    failed = 0
    for (label, *_), (volume, bad, _) in zip(cases, results):
        if bad:
            verdict, failed = "FAIL  " + "; ".join(bad)[:200], failed + 1
        elif volume is None:
            verdict = "ok    empty"
        elif abs(volume) < 1e-3:
            verdict = f"ok    zero volume ({volume:.4f} mm3)"
        else:
            verdict, failed = f"FAIL  {volume:.3f} mm3", failed + 1
        print(f"{label:40} {verdict}")
    print(f"{len(cases) - failed} of {len(cases)} as they must be")
    return failed == 0


def documented_controls():
    """The controls the two pages list - docs/checking.md for the box, docs/wiring.md for the wire routes -
    as (label, file, selector, settings, expected, export), expected a volume in mm3 with the number of
    decimals the page gives it, or "assert"."""
    controls = []
    for cells, settings in table_rows("docs/checking.md", "## Positive controls"):
        check = next((c.strip("`") for c in cells if re.fullmatch(r"`check_[a-z_]+`", c)), None)
        measured = volume_in(cells[-1])
        if check and measured:
            controls.append((check, *part(check), settings, measured, "stl"))
        elif not check:
            controls.append(("check_parts", *part("check_parts"), settings, "assert", "stl"))
    for cells, settings in table_rows("docs/wiring.md", "## Checking the routes"):
        measured = volume_in(cells[-1])
        if "`check_wires`" in cells[-1] and measured:
            controls.append(("check_wires", *view("check_wires"), settings, measured, "stl"))
        elif cells[-1].startswith("an assert"):
            controls.append(("the open view", *view("open"), settings, "assert", "echo"))
    return controls


def table_rows(page, heading):
    """Each row of a table under the heading on the page that sets something: (its cells, its settings)."""
    for line in (ROOT / page).read_text(encoding="utf-8").split(heading, 1)[1].splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        settings = [setting(c) for c in cells if re.fullmatch(r"`[a-z_0-9]+ = [^`]+`", c)]
        if settings:
            yield cells, settings


def setting(cell):
    name, value = cell.strip("`").split(" = ", 1)
    return name, value


def volume_in(cell):
    """A volume a table cell gives - "237.9 mm³", or "`check_wires`: 4.8 mm³, all in the channel" - as
    (value, its number of decimals), or None."""
    found = re.search(r"([0-9.]+) mm³", cell)
    return (float(found.group(1)), len(found.group(1).partition(".")[2])) if found else None


def controls():
    """Each control breaks one thing on purpose; its check must catch it, by the volume the page gives, or
    its assert must fire. BLIND: it no longer fails - the check cannot see what it guards. MOVED: it fails,
    but by a different amount than the page says - the geometry changed, so the page is out of date."""
    cases = documented_controls()
    with tempfile.TemporaryDirectory() as tmp:
        results = parallel(lambda c: run_case(c[1], c[2], c[3], tmp, c[5]), cases)
    failed = 0
    for (check, _, _, settings, expected, _), (volume, bad, log) in zip(cases, results):
        label = f"{check:17} " + ", ".join(f"{n} = {v}" for n, v in settings)
        fired = "Assertion" in log
        if expected == "assert":
            verdict = "ok    assert" if fired else ("BLIND " + (f"{volume:.3f} mm3" if volume else "no assert"))
        elif fired:
            verdict = "MOVED an assert fired: " + "; ".join(bad)[:150]
        elif volume is None or abs(volume) < 1e-3:
            verdict = "BLIND nothing found"
        else:
            value, decimals = expected
            near = abs(volume - value) <= max(0.5 * 10 ** -decimals, 0.01 * value)
            verdict = (f"ok    {volume:.3f} mm3" if near else f"MOVED {volume:.3f} mm3, the page says {value}")
        failed += not verdict.startswith("ok")
        print(f"{label:58} {verdict}")
    print(f"{len(cases) - failed} of {len(cases)} as docs/checking.md and docs/wiring.md say")
    return failed == 0


def figures(args):
    """Every picture in docs/ - or those named - rendered into a scratch folder, or over docs/ with --write.
    A render with an error, or a picture as small as a blank one, fails; the open view's wire summary is
    printed, since its asserts run as it draws. Rendering the same model twice gives PNGs a few hundred
    bytes apart, so write them only when the model changed."""
    write = "--write" in args
    names = [a for a in args if a != "--write"] or list(FIGURES)
    with tempfile.TemporaryDirectory() as tmp:
        folder = ROOT / "docs" if write else Path(tmp)

        def one(name):
            scad, options = FIGURES[name]
            png = folder / f"{name}.png"
            _, log = render(png, scad, [*options, "--colorscheme=Tomorrow"])
            return name, png.stat().st_size if png.exists() else 0, problems(log), log

        results = parallel(one, names)
    failed = 0
    for name, size, bad, log in results:
        verdict = ("FAIL  " + "; ".join(bad)[:200] if bad else
                   f"FAIL  {size} bytes - blank?" if size < BLANK_BELOW else f"ok    {size} bytes")
        failed += not verdict.startswith("ok")
        print(f"{name:18} {verdict}")
        for line in log.splitlines():
            if line.startswith('ECHO: "wires:') and name == "assembly-open":
                print("                   " + line[7:-1])
    return failed == 0


def stats(paths):
    found = [stl_stats(p) for p in paths]
    for p, s in zip(paths, found):
        print(f"{p}: {describe(s)}")
    if len(found) == 2:
        same = same_solid(*found)
        print("the same solid" if same else "DIFFERENT solids")
        return same
    return True


COMMANDS = {"collisions": lambda rest: collisions(), "controls": lambda rest: controls(),
            "figures": figures, "stats": stats}


def main(argv):
    if not argv or argv[0] not in COMMANDS:
        print(__doc__)
        return 1
    return 0 if COMMANDS[argv[0]](argv[1:]) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

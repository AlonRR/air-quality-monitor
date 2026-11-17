# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""The model's property checks, run through scripts/checks.py: what docs/checking.md and docs/wiring.md
describe. Each test pins its denominator, so a check or control added to the model or a page changes a
test in the same commit; a geometry change that moves a control's volume fails test_controls first.

These render with OpenSCAD and take about a minute together."""
import subprocess
import sys

from conftest import ROOT


def run_checks(command):
    run = subprocess.run([sys.executable, "scripts/checks.py", command], check=False, cwd=ROOT,
                         capture_output=True, text=True, encoding="utf-8", errors="replace")
    lines = run.stdout.strip().splitlines()
    return run.returncode, lines[-1] if lines else "", run.stdout + run.stderr


def test_collisions(openscad):
    """The five collision checks, the box both ways round, and the wires against everything in it."""
    code, last, output = run_checks("collisions")
    assert (code, last) == (0, "11 of 11 as they must be"), output


def test_controls(openscad):
    """Every positive control the two pages list still fails, by the volume the page gives."""
    code, last, output = run_checks("controls")
    assert (code, last) == (0, "33 of 33 as docs/checking.md and docs/wiring.md say"), output


def test_lengths(openscad):
    """The wire lengths docs/wiring.md gives match the routes the model draws."""
    code, last, output = run_checks("lengths")
    assert (code, last) == (0, "10 of 10 as docs/wiring.md says"), output

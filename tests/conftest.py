# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""Makes scripts/checks.py importable as `checks`, and finds OpenSCAD for the tests that render."""
import os
import shutil
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))


@pytest.fixture(scope="session")
def openscad():
    """The OpenSCAD the checks will run. A missing one fails the test rather than skipping it: a skipped
    model test reads as a passed one."""
    found = os.environ.get("OPENSCAD") or shutil.which("openscad")
    if not found or not Path(found).exists() and not shutil.which(found):
        pytest.fail("OpenSCAD not found: put openscad on PATH, or name it in OPENSCAD")
    return found

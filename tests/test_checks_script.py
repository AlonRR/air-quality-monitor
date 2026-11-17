# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""scripts/checks.py's reading of the pages: the controls come from docs/checking.md and docs/wiring.md,
so a row it misreads is a control that silently stops running. No OpenSCAD needed."""
import checks
import pytest

CHECKING = """# Checking it

## Positive controls

| Check | Setting | Measured |
|---|---|---|
| `check_parts` | `part_fit = -0.6` | 237.9 mm³ |
| an assert | `bump_w = 30` | the assert fires |
"""

WIRING = """# Wiring

## Checking the routes

| Setting | What it breaks | Found |
|---|---|---|
| `z_cross = 45.5` | the crossing | `check_wires`: 4.8 mm³, all in the channel |
| `bend_r = 6` | the bend | an assert in the open view |
"""


@pytest.fixture
def pages(tmp_path, monkeypatch):
    (tmp_path / "docs").mkdir()
    (tmp_path / "docs" / "checking.md").write_text(CHECKING, encoding="utf-8")
    (tmp_path / "docs" / "wiring.md").write_text(WIRING, encoding="utf-8")
    monkeypatch.setattr(checks, "ROOT", tmp_path)
    return tmp_path / "docs"


@pytest.mark.parametrize("cell, expected", [
    ("237.9 mm³", (237.9, 1)),
    ("`check_wires`: 4.8 mm³, all in the channel", (4.8, 1)),
    ("0.614 mm³", (0.614, 3)),
    ("the assert fires", None),
])
def test_volume_in(cell, expected):
    assert checks.volume_in(cell) == expected


def test_setting():
    assert checks.setting("`key_xs = [6.25, 57]`") == ("key_xs", "[6.25, 57]")


def test_table_rows_reads_only_rows_that_set_something(pages):
    rows = list(checks.table_rows("docs/checking.md", "## Positive controls"))
    assert [settings for _, settings in rows] == [[("part_fit", "-0.6")], [("bump_w", "30")]]


def test_documented_controls_from_a_page(pages):
    controls = checks.documented_controls()
    assert [(c[0], c[3], c[4], c[5]) for c in controls] == [
        ("check_parts", [("part_fit", "-0.6")], (237.9, 1), "stl"),
        ("check_parts", [("bump_w", "30")], "assert", "stl"),
        ("check_wires", [("z_cross", "45.5")], (4.8, 1), "stl"),
        ("the open view", [("bend_r", "6")], "assert", "echo"),
    ]


def test_every_documented_control_row_is_run():
    """On the real pages: every row that sets something becomes one control, none dropped."""
    rows = (len(list(checks.table_rows("docs/checking.md", "## Positive controls")))
            + len(list(checks.table_rows("docs/wiring.md", "## Checking the routes"))))
    assert len(checks.documented_controls()) == rows == 33


@pytest.mark.parametrize("page, bad_row", [
    ("checking.md", "| `check_parts` | `part_fit = -0.6` | 237.9 mm3 |"),
    ("wiring.md", "| `z_cross = 45.5` | the crossing | `check_wires` finds it |"),
])
def test_a_control_row_it_cannot_read_fails(pages, page, bad_row):
    """A row that sets something but gives neither a volume nor an assert is a control nobody runs: it
    must stop the run, not drop out of it."""
    with (pages / page).open("a", encoding="utf-8") as f:
        f.write(bad_row + "\n")
    with pytest.raises(ValueError, match="cannot read"):
        checks.documented_controls()

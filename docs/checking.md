# Checking it

How to tell that the model is still right after a change. There are two layers: the repo's
`scad-check.sh` on each printed part, and five collision checks in the model, backed by its asserts.
The wire routes and their checks are on [Wiring](wiring.md).

Everything below except `scad-check.sh` runs from one script, with OpenSCAD 2021.01 and
[uv](https://docs.astral.sh/uv/), from the repository's root:

```sh
uv run scripts/checks.py collisions   # the five collision checks, the box both ways round; and check_wires
uv run scripts/checks.py controls     # every positive control below and on Wiring, re-measured
uv run scripts/checks.py figures      # every picture in docs/, each render read for errors
uv run scripts/checks.py lengths      # the wire lengths on Wiring, against the routes they come from
```

Each exits 1 if anything is not as this page says. `JOBS=4` runs four renders at once. `figures` renders
into a scratch folder; `figures --write` renders over the pictures in `docs/`. Rendering the same model
twice gives PNGs a few hundred bytes apart, so write and commit them only when the model changed.

Every check here has a **positive control**: a setting that breaks the thing being checked, with what it
measured. A check that has never been seen to fail is not yet evidence. If a control stops failing after
a change, the check has gone blind and needs a new control.

## Each printed part — `scad-check.sh`

Run from the repository's root:

```sh
P="0.2mm QUALITY @MK3 - no skirt, no brim, no crossing perimeter"
scad-tools/scripts/scad-check.sh models/air-quality-monitor-back.scad  "$P" "Inslogic ASA"
scad-tools/scripts/scad-check.sh models/air-quality-monitor-cover.scad "$P" "Inslogic ASA"
scad-tools/scripts/scad-check.sh models/fits/air-quality-monitor-fits.scad  "$P" "Inslogic ASA"
```

Each should report **one manifold part** and `fdm_*` values matching the profile: the back plate and the
cover each 68.7 × 76.3 mm on the bed.

- **Exit 2 is expected** for the back plate and the cover while `untested_fits` or `unmeasured` is not
  empty; exit 0 means both are clear, as they both are now. The clearance test reports neither, so
  it exits 0.
- `scad-check.sh` also fails a G-code with a skirt or a brim. The profile above has neither.
- **Always check through the three wrapper files, never through `air-quality-monitor.scad` itself.** The
  `part` line in the params file is also what you change to look at a part, and `scad-check.sh` takes no
  `-D`, so a check through the model silently checks whichever part is on screen.

## Collisions — in the model

`checks.py collisions` renders each to STL; by hand, from the repository's root:

```sh
openscad -o check.stl -D 'part="check_components"' models/air-quality-monitor.scad
```

**Run each with `outlet_at_left` set both ways** (add `-D outlet_at_left=true`). The model mirrors, and a
check run one way only has passed a mirrored mistake before. `check_parts` touches by design, so CGAL warns
that its zero-volume result is not a valid 2-manifold; that warning is expected there.

| Check | What it intersects | Must be |
|---|---|---|
| `check_parts` | the back plate with the cover | **zero volume** — they meet only where they touch: the cover's back edge on the plate, and the nut bosses' ends on the cover's screw bosses |
| `check_components` | both parts with everything inside: the SPS30; the SuperMini's PCB (less the clips' pinch, which is meant), its parts, USB-C shell, antenna loop and pole; the largest compliant plug's body, seated, with the board pushed against its stops; the column the SPS30's lead rises through; the SGP41 lying flat, less the bare strip and the bare ring round its hole where it bears; its screw's head; and the wall screws' heads behind the plate, all the way from entry to hung | **empty** |
| `check_slide` | the back plate with the SuperMini's way in: each of its pieces swept from in front of the box into its clips | **empty** |
| `check_insert` | the back plate with the SPS30's way in: its outline, nubs included, swept from its seat to the cover's front | **empty** |
| `check_cover_on` | the cover with its way on: everything inside the box — the SPS30, the SuperMini piece by piece, the SGP41 and its screw's head — swept back to the plate, the way each moves against the cover as the cover comes on | **empty** |

"Empty" means OpenSCAD writes no file; "zero volume" means the STL it writes has none.

## Positive controls

Each setting breaks one thing; the check, or an assert, must catch it. Measured 5 Oct 2026.

`checks.py controls` reads both tables from this page, and the wire routes' table from
[Wiring](wiring.md), and runs every row. It fails a control that no longer fails (**blind**: its check can no longer see what it guards) and one that fails by a different
amount than the table gives (**moved**: the geometry changed, so this page is out of date).

| Check | Setting | What it breaks | Measured |
|---|---|---|---|
| `check_parts` | `part_fit = -0.6` | the cover's features overlap the plate's | 237.9 mm³ |
| `check_parts` | `bump_z1 = 75` | the bump at the top into the cover's top wall | 14.4 mm³ |
| `check_parts` | `nut_boss_y1 = 21.5` | the nut bosses run into the cover's screw bosses | 190.5 mm³ |
| `check_components` | `z_f0 = 50` | the board lowered into the column the SPS30's lead rises through | 8.8 mm³ |
| `check_components` | `gy_post_y1 = 18.4` | the SGP41's post pushed up into the module | 6.2 mm³ |
| `check_components` | `gy_standoff_d = 5.6` | the post's top wider than the bare ring round the module's hole | 1.9 mm³ |
| `check_components` | `key_xs = [6.25, 57]` | the left keyhole moved under the SPS30's channel wall: its screw head runs into it | 90.8 mm³ |
| `check_components` | `clip_g_catch = 0.5` | the clips' catch pressing too far into the PCB | 0.61 mm³ |
| `check_components` | `usb_open_r = 1.3` | the USB-C opening's round ends tighter than the shell's | 4.4 mm³ |
| `check_components` | `gy_ch_zc = 44` | the SGP41 wires' channel lowered into the SPS30 | 57.5 mm³ |
| `check_slide` | `stop_x0 = 20` | the stops moved into the board's way in | 3.0 mm³ |
| `check_slide` | `clip_g_mouth = 0.6` | the clips' mouth narrower than the PCB | 0.59 mm³ |
| `check_insert` | `ch_x1 = 50` | the channel's wall moved into the SPS30's way in | 716 mm³ |
| `check_cover_on` | `usb_notch_y0 = 6.5` | the cover's USB-C slot closed behind the socket again, as the first printed cover was | 11.5 mm³ |
| `check_parts` | `usb_fill_h = 2.0` | the back plate's filler taller than the slot it stands in | 1.4 mm³ |
| `check_parts` | `fillet_clear = -0.5` | the fillets no longer cut back from the cover's walls, the plate's bump and the cover's bottom wall | 0.66 mm³ |

These fire an **assert** instead, which stops the render with an `ERROR: Assertion` line:

| Setting | What it breaks |
|---|---|
| `gy_yf = 19.8` | the SGP41's screw head reaches the cover's front |
| `gy_screw_l = 18` | the SGP41's pilot runs out of its post into the plate |
| `ch_notch = 16.6` | the SPS30 channel's wall left whole, within a gap of the SGP41's underside parts |
| `divider_from_inlet_end = 19.3` | the divider's middle moved so near the outlet grille that the gap leaves it less than 3 beads |
| `key_z1 = 25` | the keyholes run into the nut bosses below and the board's clips above |
| `key_shank_d = 5.5` | the keyholes' slots leave the wall screws' heads less than 1 mm to bear on each side |
| `cover_screw_l = 25` | an M3 × 25 through the cover's corner pokes out of the back plate |
| `cb_depth = 2.8` | the cover's screw heads stand proud of its front |
| `clasp_pinch = 0.6` | the clips' catch closes up |
| `clasp_len = 12` | the two back clips run into each other |
| `clip_reach = 3.0` | the clips reach further onto the board than `clip_room` allows |
| `bump_w = 30` | the U at the top reaches the antenna's pole |

**OpenSCAD exits 0 on a failed assert when it writes a picture or an `.echo` file**, and an `.echo`
export puts the `ERROR` line inside the file. Read the output, or render to STL, which does exit 1.

# Design — why the box looks like this

Most of the layout is decided by the SPS30, and Sensirion publishes the rules. Three more come from
this repository. This page lists them, then shows the layout they add up to.

## The rules

| Rule | Source |
|---|---|
| **Two inlets and one outlet, all on one 40.6 × 12.2 mm face.** The large slotted grille is the **outlet**; the two inlets sit at the other end, one of them wrapping round the edge | *Mechanical Design and Assembly Guidelines for SPS30*, §1 figure |
| **Couple that face to the room through a large opening, with minimal depth in front of it.** A constricted volume in front makes outlet air flow back into the inlets | guidelines §2.1 |
| **A tight seal between the inlet side and the outlet side** gives the best performance | guidelines §2.1 |
| **Openings facing down** is the best orientation — it avoids dust settling in the sensor | guidelines §2.2 |
| **Keep it away from heat sources such as microcontrollers, and below them** — convection from a warm board heats the sensor | guidelines §2.4 |
| **Do not cover the entire sensor surface** in an all-round casing, or it overheats | guidelines §3 |
| **Isolate it from airflow faster than 1 m/s** — so not in the fume fan's stream | guidelines §2.3 |
| **The metal housing is tied to GND and must stay electrically floating**; current through that link *"may damage the product and poses a safety risk through overheating"* | datasheet v2.0 §3 |
| **Connector on the face opposite the openings** | datasheet v2.0 §3 |
| **I2C lead under 20 cm** | datasheet v2.0 §3 |

From this repository:

- **The box sits outside the printer's enclosure.** The SGP41 is rated −10 to +50 °C and the SPS30 to
  +60 °C, against a chamber wanted at 40–60 °C ([chamber-sensor §3](https://github.com/AlonRR/3d-printing-toolkit/blob/main/docs/chamber-sensor/node-design.md#the-node-goes-outside-the-enclosure-3)).
  What those ratings mean is below.
- **A second box inside the chamber is possible, not decided** (Alon, 3 Oct 2026). There are two of
  each sensor, and it would pair with the chamber's air filter — measuring the chamber air out of the
  filter's draught, not built into its air path. Alon does not want to risk the sensors, so it waits
  on more thinking; this box, outside, is built first.
- **The SuperMini carries a 31 mm antenna-wire mod**, whose last 15 mm stand straight up from the
  board ([chamber-sensor §3x](https://github.com/AlonRR/3d-printing-toolkit/blob/main/docs/chamber-sensor/supermini-antenna.md#rescuing-them-the-31-mm-wire-mod-3x)). It needs free space in plastic, away
  from the SPS30's grounded metal case.

### Past the ratings

From the datasheets — the SGP41's §2.3–2.4 and the SPS30's (v2.0) §1.2 and §2.2. Neither part stops at
its limit: past it, accuracy goes first, then the part.

| | Performs best | Rated to | Past that |
|---|---|---|---|
| **SGP41** | −10 to 50 °C. Prolonged exposure outside it *"may reduce sensor performance"* | 55 °C, the absolute operating maximum | beyond 55 °C, *"may cause permanent damage"*; long periods at the limits *"may affect sensor performance and reliability"* |
| **SPS30** | 10 to 40 °C | 60 °C, the absolute operating maximum | beyond 60 °C, permanent damage is possible and operation is not guaranteed. The datasheet names a laser failure at very high temperatures, which the sensor flags in its status register. Its precision also drifts by typically 0.5 % of the reading per °C away from 25 °C |

Against the closed chamber — 45–46 °C through an ASA print, 47.5 °C at the peak of a bed anneal
([measurements](https://github.com/AlonRR/3d-printing-toolkit/blob/main/docs/chamber-sensor/measurements.md#closed-every-print-since-19-sep-2026)) —
the SPS30 is already above its best range, and the SGP41 is 2.5–5 °C below its 50 °C, before the box's
own heat, which is not measured. Heating the chamber towards 60 °C would take both past their ratings.

## The layout

Every rule points the same way. Stand the SPS30 on edge with its air face **down**, over a window in the
bottom wall; its connector is then **up**, at the outlet end. Lay the SuperMini **level above it**, just
over the lead, so the board's heat rises away from the sensor and its antenna's pole stands up into the
top of the box, away from the sensor's grounded case. Lay the SGP41 flat **beside** the SPS30, its
sensor about 2 mm behind vents in the cover's front.

![assembled, cover off](assembly-open.png)

As you face the box, cover off:

- **The SPS30** stands at the bottom centre, in a channel on the back plate, label towards you, its outlet
  on your right. A divider under its air face splits the inlet side from the outlet side.
- **The SuperMini** lies level across your right half, 54.8 mm up, component side up. Its USB-C end is in
  the right-hand wall; its antenna end points to the middle, and the antenna's pole stands 1 mm short of
  the top wall. It is held by its long edges — two clips on the plate take its back edge and a clasp on
  the cover its front edge — so the pins along both stay open from below.
- **The SGP41** lies flat low in the left-hand column, its sensor towards vents in the cover's front and
  its pins up, screwed from the front onto a post rising from the plate.
- **Two keyholes**, one in each side column beside the SPS30's top corners, hang the box on two wall
  screws.
- **The cover** locates at the top on a bump inside a U, and two M3 screws through its bottom corners,
  their heads flush, close it into nuts in the back plate.

**One large window, one divider.** The window is a single opening over the whole air face, split by a
single divider. The box does not have to line up with each grille; it only has to put the divider in
the blank gap between the two ends, which is one number to measure. The divider fills that gap, 4.05 mm
wide and 0.55 mm clear of the openings either side, and ends flush with the box's bottom edge — Sensirion's
own separating wall reaches the device's opening and stops there. It can be no wider: on the inlet side
the gap ends at the slot along the label face's edge, which is the sensor's second inlet.

**The SPS30 stands 2 mm off the plate, for cooling** (`sps_lift`). Three upright ribs hold its back off:
one at each end, against the channel's walls, and one behind the divider. Air comes in through the window
under the sensor, rises up the gap behind it and leaves into the compartment above, past the board and out
through the board's vents. The middle rib splits that gap the way the divider splits the window, so the
outlet's air rising behind the sensor stays on its own side until it is past the sensor's top. The box's depth is set by the
SuperMini's width, not the sensor, so the lift costs only air gap in front of the sensor — 5.6 mm is left,
against `front_gap_min`'s 2.5. What limits it is the sensor's plug, which moves forward with it: the
SGP41's wires pass just in front of the plug, and 2 mm leaves them 0.55 mm clear, where 3 mm ran into them. The SGP41 overhangs only the channel's wall beside it, never the sensor, so
the wall's notch for it may now reach past the sensor's back half: it still guides more than half the
sensor's depth there, and the full depth elsewhere.

**Every pin the node uses is among the first three at the board's USB-C end** — 5V, GND and 3V3 on its
front edge, GPIO5 and GPIO6 on its back edge. So the clips start past the back edge's second pin and the
clasp past the front edge's third, and nothing printed covers a pin that is soldered.

What each feature is for is in [Features](features.md); the SGP41's mount in
[The SGP41's mount](sgp41-mount.md); the USB-C end in [The USB-C end](usb-c-end.md).

## Left and right

**"Left" and "right" always mean as you face the box.** The model's frame is right-handed with Y
pointing out of the wall, so +X is your **left**. The layout above is for the SPS30 in hand, whose outlet
is on your right (`outlet_at_left = false`), so the USB-C cable leaves on your right too.

The model can mirror for a sensor the other way round. A real GY-SGP41 cannot be mirrored, so when the
box is, the model draws the module's mirror image first and it comes out the right way round.

## Printing without support

**The back plate prints on its back.** The keyholes are openings in its first layers. The channel
walls, clips, stop, the SGP41's post, rib and ledge, the bump and the wire channel's ribs are walls
standing on it; the wire channel's lips are 45° ledges at the ribs' tops, and the SGP41's pilot is an
upright hole down its post. The nut pockets open on the bed side, and each pocket's ceiling is bridged in
three layers — a slot the screw hole's width, then a square, then the round hole — so it needs no
support. Nothing overhangs: the SGP41 was first held on edge by a peg standing 2.7 mm sideways out of a
block, and that peg did not print, which is why it now lies flat.

**The cover prints front face down.** The window under the SPS30 is a notch open at the back edge, and
the vents in the front are holes in its first layers. The counterbores the screw heads sit in open on the
bed, and their floors are bridged the same three-layer way as the nut pockets. The partition, baffle,
clasp, stop and U are walls standing on the front. The USB-C slot in the right-hand wall is open at the
cover's back edge — its top on the bed — so it needs no bridge at all.

**No skirt, no brim, no draft shield.** Rounded corners in plan view (`corner_r`) keep ASA's corners
down instead.

## Fillets at the thin parts' roots

**For strength, a concave fillet runs along the root of each thin part**, where it meets the face it stands
on — `fillet_r`, 1 mm, about two beads, so a 0.9–1.35 mm part is roughly twice as thick where it bends.
Only in 90° inside corners; outside edges stay as they are. On the back plate: the SPS30 channel's walls,
the divider, the wire channel's ribs, the USB-C filler and the nut bosses. On the cover: the partition,
the U's arms, and all round the inside where the walls meet the front — the walls already meet each other
in a radius.

**Some corners stay sharp because something fits against them**, and those are deliberate: the channel
walls' inner faces, which the SPS30 stands 0.355 mm off; the lower wire rib's underside, `part_fit` over the
sensor; the USB-C filler's outside face and its edges in the cover's slot; the divider's top, which carries
the sensor. Each fillet is cut back `fillet_clear` (`part_fit`) from the cover's walls, the plate's bump
and the cover's bottom wall, and the cover's window, thinned USB-C wall and vents cut through the inside
one. [Checking it](checking.md) has the setting that proves those cut-backs are there.

**No fillet makes an overhang.** The back plate's widen down towards its bed, the cover's towards its front,
which is its bed, and the fillets under the cover's top wall run straight up it.

// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CERN-OHL-S-2.0
// Open hardware, made available under the CERN Open Hardware Licence v2 - Strongly Reciprocal
// (LICENSES/CERN-OHL-S-2.0.txt), without any express or implied warranty: see the licence for its conditions.

/*
The air-quality monitor's layout: every dimension that follows from the settings in
air-quality-monitor.params.scad, and the rules those dimensions must keep. Values, functions and asserts
only - no geometry. air-quality-monitor.scad includes this file and draws the parts from it.

It is included, never used: its names are the model's, and -D can override any of them, as the controls in
docs/checking.md do. Each value may use the settings and the values above it - top-level assignments are
worked out in order, so one that uses a later one gets undef.
*/
include <air-quality-monitor.params.scad>

eps = 0.01;   // the overlap that joins two solids by a face, not an edge

function hole_r(d) = d / 2 + fdm_hole_comp;
function whole(x) = abs(x - round(x)) < 1e-6;
function up_to_layer(y) = ceil(y / fdm_layer_h - 1e-6) * fdm_layer_h;

// =================================================================== derived: X (across the box)
ch_in_w  = sps_w + 2 * sps_nub + 2 * sps_fit;               // inside of the SPS30 channel
ch_out_w = ch_in_w + 2 * cradle_t;
// The two keyholes the box hangs by: an entry the screw's head passes, and above it a slot the thread
// slides up, so the head ends up behind the plate, bearing on it - a wall clock's keyhole, twice. One
// sits in each column beside the SPS30, so the board above can come down onto the SPS30's lead.
key_entry_d = key_head_d + 1.0;                             // the head passes it
key_slot_w  = key_shank_d + 0.6;                            // the thread slides along it; the head does not
// The cover's bottom corners are screwed into M3 nuts, pressed into hex pockets from the wall side.
nut_ac     = nut_af / cos(30);                              // the nut across its corners
function nut_pocket_r(fit) = nut_ac / 2 + fdm_hole_comp + fit / cos(30);   // the hex pocket, to its corners
nut_pock_r = nut_pocket_r(nut_fit);
nut_boss_d = 2 * nut_pock_r + 4 * fdm_extrusion_w;          // two beads round the pocket's corners
// Each column beside the channel holds a nut boss low down and a keyhole higher up, and the cover's wall.
col_w    = max(nut_boss_d + 2 * part_fit, part_fit + 2 * hole_r(key_entry_d) + gap);
W        = ch_out_w + 2 * col_w + 2 * wall;
ch_x0    = (W - ch_in_w) / 2;
ch_x1    = ch_x0 + ch_in_w;
sps_x0   = ch_x0 + sps_fit + sps_nub;                       // the sensor body, nominally centred
sps_x1   = sps_x0 + sps_w;
x_div    = sps_x1 - divider_from_inlet_end;                 // the inlets are at the high-X end
// The divider fills the blank gap between the inlets and the outlet grille, round its measured middle,
// divider_clear short of each, in whole beads. It can be no wider: the inlets' far end is the slot by the
// label face's edge, which is the sensor's second inlet. Alon, 4 Oct 2026, on the printed box: "a wall that
// sits flush with the back and better fills the gap".
divider_t = floor((2 * min(divider_from_inlet_end - sps_inlet_end, sps_outlet_from - divider_from_inlet_end)
                   - 2 * divider_clear) / fdm_extrusion_w + 1e-6) * fdm_extrusion_w;
div_clear_in  = divider_from_inlet_end - divider_t / 2 - sps_inlet_end;     // to the inlets' far end
div_clear_out = sps_outlet_from - (divider_from_inlet_end + divider_t / 2);  // to the outlet grille
key_xs   = [wall + part_fit + hole_r(key_entry_d), W - wall - part_fit - hole_r(key_entry_d)];

// The SPS30's lead: its plug sits on the connector face at the outlet end; the wires rise from it and bend
// over towards the board's pins. Nothing may stand in that column (photo 1, 2 Oct 2026).
lead_x0 = sps_x0 + conn_from;
lead_x1 = sps_x0 + conn_to;

// The board lies level, its USB-C end in the right-hand wall, which is thinned to port_wall over it so the
// socket's mouth reaches the outside face. A plug's body then never enters the wall, whatever its size.
sm_usb_x  = port_wall + part_fit;
sm_x0     = sm_usb_x;
sm_x1     = sm_x0 + sm_l;
sm_ant_x  = sm_x1;                                          // the PCB's antenna end
pole_in   = 1.5;                                            // the pole stands this far in from that end
usb_proud    = usb_overhang - port_wall - part_fit;         // the mouth, past the outside face, board at rest
usb_proud_in = usb_proud - pocket_fit;                      // the same, with a plug pushing the board against its stops
// The USB-C shell is a stadium - a rectangle with round ends - and the wall's opening is the same shape,
// part_fit clear all round. Alon, 3 Oct 2026: "round (or best we can do 3d printing) the usbc port hole".
usb_open_r = usb_shell_h / 2 + part_fit;                    // its ends' radius
usb_open_c = usb_shell_w / 2 - usb_shell_h / 2;             // its ends' centres, either side of the board's middle
// The cover goes on straight back onto the plate, and the shell stands out through the wall before it does,
// so the opening runs on, the shell's height, out to the cover's back edge: the shell slides along it.
// Alon, 4 Oct 2026, on the printed box: "cut the small area past -y the usbc slot in the cover and place a
// makeup to the slot on the back plate". The filler stands on the plate in that slot, behind the shell,
// part_fit clear of the slot's sides and of the shell, and closes the wall again.
usb_notch_y0 = back_t - eps;                                // where the slot opens, at the cover's back edge
usb_fill_h   = usb_open_r - part_fit;                       // the filler's half-height, the slot's less part_fit
// It is held by its long edges, not laid on a shelf, so the pins along them stay open from below. Its back
// edge presses from the front into two clips on the plate - each a lower jaw, and an upper one whose
// underside angles in from a wide mouth to a catch that pinches the PCB, and out again behind it, where the
// edge sits. Lying level with its component side up, its back edge carries GPIO5 and GPIO6 on its first
// two pins, so one clip is at the antenna end and the other just past the second pin. The cover's front
// clasp takes the front edge from its 4th pin, clear of 5V, GND and 3V3 on its first three.
pin_pitch = 2.54;                                           // the SuperMini's 0.1-inch pin pitch
sm_lip_x0 = sm_usb_x + pin_mid + 2 * pin_pitch;             // the cover's front clasp, from the 4th pin
stop_x0   = sm_ant_x + pocket_fit;                          // the stops, just past the antenna end
sm_lip_x1 = stop_x0;
clasp_x0  = sm_usb_x + pin_mid + pin_pitch / 2 + 0.5;       // the first clip's start, just past the second pin
clasp_xs  = [[clasp_x0, clasp_x0 + clasp_len],
             [sm_ant_x - clasp_len, sm_ant_x]];             // the two clasps' X ranges along the back edge

// =================================================================== derived: Y (out from the wall)
ledge_w = sps_fit + sps_nub + ledge;                        // what each ledge spans, wall to sensor
y_sps0  = back_t + sps_lift;                                // the SPS30's back, on its standoff ribs
y_sps1  = y_sps0 + sps_t;                                   // the SPS30's label face
y_b0    = back_t + pocket_fit;                              // the board's back long edge, by the plate
// The clips' upper jaws, from the plate out: a relief where the edge sits, the catch, and the mouth. Each is a
// gap over the PCB's underside.
clip_reach   = clip_room;                                   // all the room there is
clip_catch_y = back_t + clip_reach / 2;
clip_g_open  = sm_pcb_t + 2 * pocket_fit;                   // at the plate, behind the catch
clip_g_catch = sm_pcb_t - clasp_pinch;                      // at the catch: it pinches
clip_g_mouth = sm_pcb_t + 2 * pocket_fit + 0.4;             // at the tip, so the edge finds its way in
y_b1    = y_b0 + sm_w;                                      // its front long edge
y_bc    = (y_b0 + y_b1) / 2;
// The board's width now fills the depth: back edge by the plate, front edge in the cover's rim.
inner_d = max(sps_lift + sps_t + sps_fit + front_gap_min, pocket_fit + sm_w + pocket_fit + rib_t);
D       = back_t + inner_d + front_t;
y_in1   = D - front_t;                                      // inside face of the cover's front
// The channel walls stand 2 * gap proud of the SPS30's face. It goes in from the front - nothing on
// the plate overhangs it - and the cover's partition rib, sps_fit off its face, keeps it from tipping.
y_ch1   = y_sps1 + 2 * gap;

// =================================================================== derived: Z (up)
z_sps0  = wall;                       // the air face sits at the inside of the bottom wall: minimal depth to ambient
z_sps1  = z_sps0 + sps_h;
shelf_t = rib_t;                      // the clasps' lower jaws: printed upright, so a width in beads
z_f0    = z_sps1 + cable_zone_h + gap;   // their underside, just over the SPS30's lead
zu      = z_f0 + shelf_t;             // the PCB's underside
z_uc    = zu + sm_pcb_t + usb_shell_h / 2;   // the USB-C socket's centre: the shell sits on the component side
nut_bz  = wall + part_fit + nut_boss_d / 2;  // the nut bosses' centres, in each bottom corner
nut_bx  = [nut_bz, W - nut_bz];
// The keyholes: the hung heads' tops gap under the clasps, and under the room the wires to the board's
// back pins need; the slots key_level_tol longer, so one screw may sit that much lower than the other and
// its head still clear its entry.
key_travel = key_entry_d / 2 + key_head_d / 2 + 1.0 + key_level_tol;
key_z1  = min(z_f0, zu - back_wire_room) - gap - key_head_d / 2;   // where a screw is once the box hangs
key_z0  = key_z1 - key_travel;            // the entry's centre
H       = zu + ant_h + gap + wall;        // the pole stands under the top wall
// The cover's top locates on one bump in the middle of the plate's top, which stands out into a U hanging
// from the cover's top wall: two arms, part_fit either side of the bump and part_fit over it. They hold the
// cover's top in X and Z; the two bottom screws hold the cover on. The arms run from the cover's front
// to the plate, so on the cover's bed they stand as walls.
bump_x0  = W / 2 - bump_w / 2;
bump_x1  = W / 2 + bump_w / 2;
u_z0     = H - wall - u_drop;            // the U's arms' lower ends, and the bump's underside
bump_z1  = H - wall - part_fit;          // the bump's top

// =================================================================== the GY-SGP41: flat, behind the cover
// Alon, 3 Oct 2026, once the standoff it stood on edge on would not print: "make the sgp41 flat and raised
// up against the cover" (q34 "A"). It lies flat in the left-hand column, its sensor towards vents in the
// cover's front and its pins up. One M2.5 screw holds it from the front, through its mounting hole into a
// post rising from the plate; it lies on the post's top and on a rib under the bare strip along its bottom
// edge, and its bottom edge sits on a ledge. All three stand on the plate, so they print as walls, and the
// pilot is upright. The screw's head sits between the module and the cover, so the module is as far forward
// as that allows. Its edge towards the SPS30 reaches past the end of the SPS30's channel wall, which is
// notched there so the module's underside parts clear it by a gap.
gy_sensor_h = gy_t - gy_back;                   // the sensor, standing off its face
gy_parts_h  = gy_back - gy_pcb_t;               // the parts on its underside
gy_yf   = y_in1 - part_fit - gy_head_h;         // its face: the screw's head between it and the cover
gy_yu   = gy_yf - gy_pcb_t;                     // its underside, on the post and the rib
gy_yp   = gy_yu - gy_parts_h;                   // its underside's parts reach back to here
gy_x0   = W - wall - part_fit - pocket_fit - gy_w;   // its edge towards the SPS30: as far from it as the side wall allows,
                                                     // so the wire from its pin nearest the SPS30 clears the channel wall
gy_x1   = gy_x0 + gy_w;
// Which side its hole is on follows from which way round the module is. Facing the box, its sensor faces
// you with its pins up, and your right is -X: so a hole on the right is at the module's low-X edge, by the
// SPS30. The whole box is mirrored when the outlet is at the left, and a real module cannot be: so the
// canonical drawing takes the mirror image then, and comes out right after it.
gy_hole_lowx = gy_hole_right != outlet_at_left;
gy_z0   = wall + part_fit + nut_boss_d + part_fit + rim_t + pocket_fit;   // its bottom edge, on a ledge over the nut boss
gy_z1   = gy_z0 + gy_l;
gy_hx   = gy_hole_lowx ? gy_x0 + gy_hole_side : gy_x1 - gy_hole_side;   // its mounting hole
gy_hz   = gy_z0 + gy_hole_far;
gy_post_y1 = gy_yu;                             // the post's top, against the module's underside
gy_post_yw = gy_yp - gap;                       // where the post narrows, a gap short of the underside's parts
gy_rib_z1  = gy_z0 + gy_bare - gap / 2;         // the rib's top edge, short of the underside's nearest part
gy_pilot_depth = gy_screw_l - gy_pcb_t + 2 * fdm_layer_h;   // into the post from its top
ch_notch = gy_yp - gap;                          // the SPS30 channel wall's front, where the module overhangs it

// Its four wires leave its back by its pins, turn up the column behind it and, once level, cross over the
// SPS30's top-left corner in a short channel on the plate: a slot open to the front between two ribs, the
// wires side by side across its depth. They press in from the front past a 45-degree lip on each rib, and
// the lips hold them. The ribs print as walls, the lips as 45-degree ledges. Their lanes keep clear of the
// wall screw's head as they rise; each rises above its own pin, but none nearer the SPS30's channel wall
// than a wire's width.
gy_bend_r  = 3.0;                                             // the solid wire's tightest bend
gy_stub    = 1.0;                                             // straight out of a solder joint first
gy_pitch   = gy_wd + 0.34;                                    // the wires' spacing, centre to centre
gy_pin_pitch = 2.54;                                          // the module's 0.1-inch pin pitch
gy_pin_end   = 1.5;                                           // its first pin hole's centre from its end
gy_pin_in    = 1.3;                                           // the pin holes' centres from its top edge
// the pin holes along the module, SDA, SCL, GND, VIN from the end away from its mounting hole
function gy_pin_x(i) = gy_hole_lowx ? gy_x1 - gy_pin_end - i * gy_pin_pitch : gy_x0 + gy_pin_end + i * gy_pin_pitch;
gy_pin_z   = gy_z1 - gy_pin_in;
function gy_rise_x(i) = max(gy_pin_x(i), ch_x1 + cradle_t + gy_wd / 2 + 0.15);
gy_x_up    = min([for (i = [0 : 3]) gy_rise_x(i)]);            // the riser nearest the SPS30
gy_ch_lane = [for (i = [0 : 3]) back_t + key_slack + key_head_h + 0.1 + gy_wd / 2 + i * gy_pitch];
gy_ch_slot = gy_wd + 0.4;                                     // the slot, across: a wire, 0.2 either side
gy_ch_zc   = z_sps1 + part_fit + rib_t + gy_ch_slot / 2;      // its middle: the floor rib part_fit over the SPS30
gy_ch_x1   = gy_x_up - gy_bend_r - gap / 2;                   // it starts once the wires are level
gy_ch_x0   = gy_ch_x1 - gy_ch_len;
gy_ch_lip  = (gy_ch_slot - gy_ch_lip_gap) / 2;                // each lip's reach into the slot
gy_ch_y0   = gy_ch_lane[3] + gy_wd / 2 + 0.2;                 // where the lips begin
gy_ch_y1   = gy_ch_y0 + 2 * gy_ch_lip;                        // the ribs' front

// =================================================================== the cover's screws and their nuts
// The two bottom screws sit flush: each head in a counterbore in the cover's front, on a floor as thick as
// the front. The front is thinner than a head is tall, so a boss on its inside carries the floor, and the
// nut boss on the back plate stops where that boss starts - the screw clamps the two together.
cb_d     = cover_head_d + (screw_d - 3);   // the counterbore: the head, and the tested screw hole's allowance
cb_depth = up_to_layer(cover_head_h);    // the cover prints front face down: whole layers from the bed
cb_floor = front_t;
head_y   = D - cb_depth;                  // where a screw's head bears
cb_y0    = head_y - cb_floor;             // the cover boss's end, inside
nut_boss_y1 = cb_y0;                      // the nut boss's end, against it
// Pressed into a hex pocket from the wall side, the nut bears on a shoulder towards the cover - a
// bottom-inserted nut, the strongest of the ways a print holds one (docs/mechanical-design-review.md).
// The shoulder sits where the M3 x cover_screw_l, from its head, passes right through the nut.
nut_y1  = up_to_layer(head_y - cover_screw_l + nut_h + 2 * fdm_layer_h);   // the shoulder

// =================================================================== the rules
for (w = [["wall", wall], ["cradle_t", cradle_t], ["divider_t", divider_t], ["rib_t", rib_t],
          ["rim_t", rim_t], ["port_wall", port_wall], ["vent_rib", vent_rib]])
    assert(whole(w[1] / fdm_extrusion_w),
           str(w[0], " (", w[1], ") must be a whole number of ", fdm_extrusion_w,
               " mm beads - fdm-design-rules §1"));

for (t = [["back_t", back_t], ["front_t", front_t], ["the nut's shoulder", nut_y1], ["cb_depth", cb_depth]])
    assert(whole(t[1] / fdm_layer_h),
           str(t[0], " (", t[1], ") is printed flat, so it must be a whole number of ",
               fdm_layer_h, " mm layers"));

assert(wire_perpendicular,
       "the layout lies the board level so its antenna's pole stands up - it needs the pole off the component side");

assert(divider_t >= 3 * fdm_extrusion_w,
       str("the gap between the inlets (to ", sps_inlet_end, " mm) and the outlet grille (from ", sps_outlet_from,
           " mm) leaves room for a divider only ", divider_t, " mm wide round ", divider_from_inlet_end,
           " mm - check divider_from_inlet_end"));
assert(div_clear_in >= divider_clear - 1e-6 && div_clear_out >= divider_clear - 1e-6,
       str("the divider must sit in the blank gap between the inlets (to ", sps_inlet_end,
           " mm) and the outlet grille (from ", sps_outlet_from, " mm); it clears them by ",
           div_clear_in, " and ", div_clear_out, " mm"));
assert(x_div - divider_t / 2 > sps_x0 + ledge && x_div + divider_t / 2 < sps_x1 - ledge,
       str("the divider (at ", divider_from_inlet_end, " mm from the inlet end) does not fit between",
           " the two ledges - check divider_from_inlet_end"));

assert(key_slot_w >= 2 && gy_pilot_d >= 2 && screw_d >= 2,
       "a hole under 2 mm distorts or closes up - fdm-design-rules §2");

assert(y_ch1 <= y_in1 - part_fit,
       str("the SPS30 channel's walls (to ", y_ch1, ") reach the cover's front (", y_in1,
           ") - raise front_gap_min"));

assert(usb_proud_in >= -1e-6,
       str("plugging in pushes the board against its stops, and there the USB-C socket's mouth sits ",
           -usb_proud_in, " mm inside the wall - a plug's body would hit the wall before it seats.",
           " Thin port_wall, or tighten part_fit and pocket_fit"));
assert(y_bc - usb_plug_w / 2 >= 0,
       "the USB-C plug would hit the surface the box hangs on - the board sits too close to the wall");
assert(stop_reach - pocket_fit + gap <= ant_loop_free,
       str("the stops at the board's antenna end reach ", stop_reach - pocket_fit, " mm over it, and the",
           " antenna loop leaves only ", ant_loop_free, " mm free - reduce stop_reach"));
assert(sm_lip_over < sm_edge,
       "the cover's front lip would reach past the SuperMini's pad strip onto its parts - check sm_lip_over");
assert(clip_reach <= clip_room + 1e-6, "the back clips reach further onto the board than clip_room allows");
assert(clip_catch_y > y_b0 + 2 * fdm_layer_h,
       "the clips' catch must be over the PCB, past its edge, so it holds the board rather than its corner");
assert(sm_lip_x1 - sm_lip_x0 >= 2 * pin_pitch, "the cover's lip has no length - check pin_mid");
assert(clasp_xs[0][1] + gap <= clasp_xs[1][0],
       "the board's two back clasps run into each other - shorten clasp_len");
assert(clasp_pinch > 0 && clip_g_catch >= sm_pcb_t / 2,
       "the clips' catch must pinch the PCB, but not close up");

assert(key_head_d - 2 * hole_r(key_slot_w) >= 2 * 1.0,
       str("the keyholes' slots (", 2 * hole_r(key_slot_w), " mm as cut) leave the screws' ", key_head_d,
           " mm heads less than 1 mm to bear on each side - they could pull through"));
// signed: negative means the keyhole runs into what is below or above it
key_room_low  = key_z0 - hole_r(key_entry_d) - (wall + part_fit + nut_boss_d);
key_room_high = z_f0 - (key_z1 + key_head_d / 2);
key_room_gy   = key_z0 - hole_r(key_entry_d) - gy_z1;
assert(key_room_low >= gap && key_room_high >= gap,
       str("the keyholes must stand clear of the nut bosses below and the board's clasps above; they leave ",
           key_room_low, " and ", key_room_high, " mm"));
assert(key_room_gy >= gap,
       str("the left keyhole's entry reaches down to the SGP41 - it leaves ", key_room_gy, " mm"));

assert(cb_depth >= cover_head_h - 1e-6, "the cover's screw heads would stand proud of its front - deepen the counterbore");
assert(hole_r(cb_d) + 2 * fdm_extrusion_w <= nut_boss_d / 2,
       "the counterbore leaves the cover's boss less than two beads round it");
assert(head_y - cover_screw_l >= 2 * fdm_layer_h,
       str("an M3 x ", cover_screw_l, " through the cover's corner would poke out of the back plate"));
assert(head_y - cover_screw_l <= nut_y1 - nut_h,
       "the cover's screw stops short of passing right through its nut - raise the shoulder");
assert(nut_y1 + 2 * fdm_layer_h < nut_boss_y1, "the nut's shoulder reaches the cover's boss - the nut boss is too short");

assert(gy_yf + gy_head_h + part_fit <= y_in1 + 1e-6, "the SGP41's screw head would reach the cover's front");
assert(gy_yf + gy_sensor_h + part_fit <= y_in1 + 1e-6, "the SGP41's sensor would reach the cover's front");
assert(gy_x1 + pocket_fit <= W - wall - part_fit + 1e-6, "the SGP41 lying flat does not fit the column's width");
assert(gy_post_y1 - gy_pilot_depth >= back_t + 2 * fdm_layer_h,
       str("the SGP41's pilot would run out of the post into the wall side of the plate - shorten gy_screw_l"));
assert(gy_yp - ch_notch >= gap - 1e-6, "the SGP41's underside parts come within a gap of the SPS30's channel wall");
// The SGP41 overhangs the channel's wall, never the sensor (gy_x0 is past sps_x1), so the wall may be
// notched beside the sensor's front - as long as it still guides most of its depth.
assert(ch_notch >= y_sps0 + sps_t / 2,
       str("the channel's wall by the SGP41 is notched from ", ch_notch, " mm: it must still guide the SPS30 to",
           " at least half its depth, ", y_sps0 + sps_t / 2));
assert(gy_x0 > sps_x1 + sps_nub, "the SGP41 overhangs the SPS30 itself, not just its channel's wall");
assert(gy_z0 - pocket_fit - rim_t >= nut_bz + nut_boss_d / 2 + part_fit - 1e-6,
       "the SGP41's ledge comes down onto the nut bosses");
assert(gy_hole_d >= gy_screw_d + 0.1,
       str("the SGP41's mounting hole (", gy_hole_d, " mm) is too small for an M", gy_screw_d,
           " screw - use a smaller one and set gy_screw_d, gy_head_d and gy_head_h"));
assert(hole_r(gy_pilot_d) + 2 * fdm_extrusion_w <= gy_standoff_d / 2,
       "the post round the SGP41's pilot is thinner than two beads - widen gy_standoff_d");
assert(gy_standoff_d > gy_hole_d,
       "the SGP41's post is no wider than its mounting hole - the board would have nothing to rest on");
assert(gy_post_d >= gy_standoff_d, "the SGP41's post narrows the wrong way");

assert(bump_x0 - part_fit - rib_t - (sm_ant_x - pole_in + 0.5) >= gap,
       "the U at the top reaches the antenna's pole - narrow bump_w");
assert(u_drop > part_fit + 2 * fdm_extrusion_w, "the bump the cover's top locates on has no height");

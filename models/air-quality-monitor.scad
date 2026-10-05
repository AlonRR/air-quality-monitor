// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CERN-OHL-S-2.0
// Open hardware, made available under the CERN Open Hardware Licence v2 - Strongly Reciprocal
// (LICENSES/CERN-OHL-S-2.0.txt), without any express or implied warranty: see the licence for its conditions.

/*
The air-quality monitor: two printed parts. The cover's top locates on a bump on the back plate, inside a U
hanging from its top wall, and two M3 screws through its bottom corners go into nuts in the back plate.

  BACK PLATE   printed flat. Carries the two keyholes it hangs by, the channel the SPS30 is set into from
               the front, the divider under its air face, the two clips the SuperMini's back edge snaps into,
               the block the GY-SGP41 is screwed to on edge, the two nut bosses and the bump the cover's top
               locates on.
  COVER        printed front-face down. A five-sided shell.

Every opening is a hole in its part's first layers or a notch open at its back edge, except the cover's
USB-C opening and its side vents, which are holes in a wall bridged by at most 4 mm. The nut pockets'
ceilings are printed with the three-layer two-bridge technique (docs/fdm-design-rules.md §3c).

  part = "back"       this file as it stands - what scripts/scad-check.sh checks
  part = "cover"      air-quality-monitor-cover.scad sets it
  part = "assembly"   the two parts in place, with the components ghosted in. Not printable.

Settings are in air-quality-monitor.params.scad; every dimension they imply, and the rules those must keep,
in air-quality-monitor.layout.scad, which this file includes; this file draws the parts. Why the layout is
what it is - with a source for each rule - is in docs/design.md. The checks it carries, and their
controls, are in docs/checking.md.

Everything below is drawn the way the params file's photos settled it - the SPS30's outlet, its connector
and the board's USB-C end on your RIGHT as you face the box, which is low X - and mirrored whole when
outlet_at_left is set.
*/
include <air-quality-monitor.layout.scad>
use <lib/shapes.scad>

draw_model = true;

$fa = 2;
$fs = 0.4;

// =================================================================== geometry helpers
// The plain shapes - rrect, slab_xz, box3, cyl_y, cyl_x and the coves - are in lib/shapes.scad.

// ------------------------------------------------------------------ fillets
// Concave fillets at the roots of the thin features, for strength - only in 90-degree inside corners. Each
// is cut back fillet_clear from whatever it must not touch: the cover's walls, the plate's bump, and the
// cover's bottom wall beside the window. One value, so one setting breaks them all (docs/checking.md).
fillet_clear = part_fit;
// The lib's coves at this box's radius: along a straight root (p on the edge, u along the face away from
// the feature, v up the feature, w along the edge for len), and round a cylinder along Y.
module fillet_line(p, u, v, w, len) cove_line(p, u, v, w, len, fillet_r);
module fillet_ring_y(x, z, rc, y0) cove_ring_y(x, z, rc, y0, fillet_r);

// Slots through a face, spread across [a0, a1] - in the cover's front (X), or its side wall (Z).
module vent_slots(x0, x1, z0, z1)
    for (x = spread(x0, x1, vent_w, vent_rib))
        translate([x, y_in1 - eps, z0]) cube([vent_w, front_t + 2 * eps, z1 - z0]);
module side_vents(y0, y1, z0, z1)
    for (z = spread(z0, z1, vent_w, vent_rib))
        translate([W - wall - eps, y0, z]) cube([wall + 2 * eps, y1 - y0, vent_w]);

// The nut's pocket, from the wall side up to its shoulder, and over it the ceiling's three layers:
// a slot the screw hole's width right across the pocket's flats, then a square, then the round hole.
module nut_trap(x, z, r = nut_pock_r) {
    hr = hole_r(screw_d);
    translate([x, -eps, z]) rotate([-90, 0, 0]) rotate([0, 0, 30])
        cylinder(r = r, h = nut_y1 + eps, $fn = 6);
    translate([x - hr, nut_y1 - eps, z - r * cos(30)])
        cube([2 * hr, fdm_layer_h + eps, 2 * r * cos(30)]);
    translate([x - hr, nut_y1 + fdm_layer_h - eps, z - hr]) cube([2 * hr, fdm_layer_h + eps, 2 * hr]);
    cyl_y(x, z, hr, nut_y1 + 2 * fdm_layer_h - eps, nut_boss_y1 + eps);
}

// A bottom screw's way through the cover, from its face in: the counterbore its head sits flush in, then
// the clearance hole on through the boss. The cover prints front face down, so the counterbore's floor is
// a ceiling: its first layer bridges across leaving a slot the hole's width, its second across that
// leaving a square, and the round hole starts on the third - as over the nuts, with no support.
module cover_screw_hole(x, z) {
    hr = hole_r(screw_d);
    cr = hole_r(cb_d);
    cyl_y(x, z, cr, head_y, D + eps);
    translate([x - hr, head_y - fdm_layer_h, z - cr]) cube([2 * hr, fdm_layer_h + eps, 2 * cr]);
    translate([x - hr, head_y - 2 * fdm_layer_h, z - hr]) cube([2 * hr, fdm_layer_h + eps, 2 * hr]);
    cyl_y(x, z, hr, cb_y0 - eps, head_y - 2 * fdm_layer_h + eps);
}

// One of the board's two back clips, over c = [x0, x1] along its back edge: a lower jaw under the edge, and
// an upper jaw over its pad row whose underside angles in from the mouth to the catch - g_catch over the
// PCB's underside - and out again to the plate. Both stand on the plate, so on the bed they are walls; the
// catch's slope leans 30 degrees at most. The clearance test draws it with other catches.
module clip(c, g_catch = clip_g_catch) {
    box3([c[0], back_t - eps, z_f0], [c[1], y_b0 + clasp_low, zu]);
    translate([c[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(height = c[1] - c[0])
        polygon([[back_t - eps, zu + clip_g_open],
                 [clip_catch_y, zu + g_catch],
                 [back_t + clip_reach, zu + clip_g_mouth],
                 [back_t + clip_reach, zu + clip_g_mouth + rim_t],
                 [back_t - eps, zu + clip_g_mouth + rim_t]]);
    box3([c[0], back_t - eps, z_f0], [c[1], back_t + eps, zu + clip_g_mouth + rim_t]);
}

// The SGP41's mount, all standing on the plate: the post its screw goes into - wide, narrowing to
// gy_standoff_d where the module's underside parts are - the rib under the bare strip along its bottom
// edge, and the ledge that edge sits on. And the pilot, straight down into the post. The clearance test
// tries other pilots.
module gy_mount() {
    cyl_y(gy_hx, gy_hz, gy_post_d / 2, back_t - eps, gy_post_yw);
    cyl_y(gy_hx, gy_hz, gy_standoff_d / 2, gy_post_yw - eps, gy_post_y1);
    box3([gy_x0 + gap / 2, back_t - eps, gy_z0 - pocket_fit], [gy_x1 - gap / 2, gy_yu, gy_rib_z1]);
    box3([gy_x0, back_t - eps, gy_z0 - pocket_fit - rim_t], [gy_x1, gy_yf, gy_z0 - pocket_fit]);
}
module gy_pilot(d = gy_pilot_d) cyl_y(gy_hx, gy_hz, hole_r(d), gy_post_y1 - gy_pilot_depth, gy_post_y1 + eps);

// The SGP41 wires' channel over the SPS30's top-left corner: a floor rib and a roof rib standing on the
// plate, each with its lip at the front - a 45-degree ridge into the slot.
module gy_channel() for (k = [-1, 1]) let(zr = gy_ch_zc + k * gy_ch_slot / 2) {
    box3([gy_ch_x0, back_t - eps, k < 0 ? zr - rib_t : zr], [gy_ch_x1, gy_ch_y1, k < 0 ? zr : zr + rib_t]);
    translate([gy_ch_x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = gy_ch_x1 - gy_ch_x0)
        polygon([[gy_ch_y0, zr + k * eps], [gy_ch_y0 + gy_ch_lip, zr - k * gy_ch_lip], [gy_ch_y1, zr + k * eps]]);
}

// Mirror everything when the outlet - and so the connector, the board and its cable - is on the left.
module place() {
    if (outlet_at_left) translate([W, 0, 0]) mirror([1, 0, 0]) children();
    else children();
}

// =================================================================== the back plate, as installed
module back_plate() place() difference() {
    union() {
        // the plate
        slab_xz(0, W, 0, back_t, 0, H, corner_r);

        // the channel walls the SPS30 is set between, from the front. No lips: anything overhanging
        // its face would have to be slid past. Down to Z = 0, through the window, so the ledges join them
        // by a FACE - meeting along an edge only is not manifold (docs/openscad-basics, lesson 2).
        // The one by the SGP41 is notched to ch_notch where the module overhangs its front end.
        for (xw = [ch_x0 - cradle_t, ch_x1]) difference() {
            translate([xw, back_t - eps, 0]) cube([cradle_t, y_ch1 - back_t + eps, z_sps1]);
            if (xw == ch_x1 && ch_notch < y_ch1)
                box3([xw - eps, ch_notch, gy_z0 - pocket_fit - rim_t - gap], [xw + cradle_t + eps, y_ch1 + eps, gy_z1 + gap]);
        }

        // the ledges the sensor stands on, one under each end of the air face
        // out as far as the walls, so the two end level with each other
        translate([ch_x0 - cradle_t / 2, back_t - eps, 0]) cube([ledge_w + cradle_t / 2, y_ch1 - back_t + eps, z_sps0]);
        translate([ch_x1 - ledge_w, back_t - eps, 0]) cube([ledge_w + cradle_t / 2, y_ch1 - back_t + eps, z_sps0]);
        // the ribs the sensor stands on, sps_lift off the plate, so air rises behind it from the window: one
        // at each end of its back, against the channel's walls, and one behind the divider, which keeps the
        // outlet's side of that gap apart from the inlets'
        // the end ones reach in exactly as far as the ledges, so the rib and the ledge are one face
        for (r = [[ch_x0 - eps, sps_x0 + ledge], [sps_x1 - ledge, ch_x1 + eps],
                  [x_div - cradle_t / 2, x_div + cradle_t / 2]])
            box3([r[0], back_t - eps, 0], [r[1], y_sps0, z_sps1]);

        // the divider: a wall that also carries the middle of the sensor, through the window to the box's
        // bottom edge - divider_proud past it. It rises from the very back (Y = 0), so it starts on the bed.
        translate([x_div - divider_t / 2, 0, -divider_proud])
            cube([divider_t, y_in1 - part_fit, divider_proud + z_sps0]);

        // the board's two back clips
        for (c = clasp_xs) clip(c);
        // the back stop at its antenna end, which takes the push of plugging in
        box3([stop_x0, back_t - eps, z_f0], [stop_x0 + rim_t, y_b0 + stop_reach, zu + sm_pcb_t + 1]);

        // the filler in the cover's USB-C slot, behind the shell: a wall in the cover's wall's plane, its
        // end hollowed round the shell's end
        translate([0, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = port_wall) difference() {
            translate([back_t - eps, z_uc - usb_fill_h]) square([y_bc - usb_open_c - back_t + eps, 2 * usb_fill_h]);
            translate([y_bc - usb_open_c, z_uc]) circle(r = usb_open_r, $fn = 48);
        }
        // the SGP41's post, rib and ledge
        gy_mount();
        // the channel its wires cross the SPS30's top-left corner in
        gy_channel();

        // the nut bosses in the bottom corners
        for (x = nut_bx) cyl_y(x, nut_bz, nut_boss_d / 2, back_t - eps, nut_boss_y1);
        // the bump at the top the cover locates on
        box3([bump_x0, back_t - eps, u_z0], [bump_x1, back_t + bump_out, bump_z1]);
        // fillets at the thin features' roots
        plate_fillets();
    }
    // the nuts' pockets, open to the wall, and the screw holes over them
    for (x = nut_bx) nut_trap(x, nut_bz);
    // the SGP41's pilot, down into its post
    gy_pilot();
    // the keyholes: each an entry the wall screw's head passes, and the slot above it the head then
    // hangs over. Holes through the plate, so on the bed they are openings in the first layers.
    for (x = key_xs) {
        cyl_y(x, key_z0, hole_r(key_entry_d), -eps, back_t + eps);
        hull() for (z = [key_z0, key_z1]) cyl_y(x, z, hole_r(key_slot_w), -eps, back_t + eps);
    }
}

// =================================================================== the cover, as installed
module cover() place() {
    difference() {
        union() {
            difference() {
                slab_xz(0, W, back_t, D, 0, H, corner_r);
                // hollow it: four walls and a front
                slab_xz(wall, W - wall, back_t - eps, y_in1, wall, H - wall, max(corner_r - wall, 0));
            }
            // the cove all round the inside, where the walls meet the front. The walls meet each other in
            // corner_r - wall already.
            inner_cove();
        }
        // the window over the SPS30's air face - open at the back edge, so it is a notch, not a bridge
        translate([ch_x0 - cradle_t - part_fit, back_t - eps, -eps])
            cube([ch_in_w + 2 * (cradle_t + part_fit), y_in1 - back_t + eps, wall + 2 * eps]);
        // ... and the inside cove across it: there is no bottom wall there for the front to meet
        translate([ch_x0 - cradle_t - part_fit, back_t - eps, -eps])
            cube([ch_in_w + 2 * (cradle_t + part_fit), y_in1 - back_t + eps, wall + fillet_r + 2 * eps]);
        // the right-hand wall over the board's USB-C end, thinned from inside to port_wall over the board's
        // whole width and height - a notch open at the back edge. Its steps back to the full wall are 45
        // degrees, not square: pulling the plug loads this stretch of wall, and a crack would start at a
        // sharp inside corner.
        hull() {
            box3([port_wall, back_t - eps, zu - part_fit],
                 [wall + eps, y_b1 + pocket_fit + part_fit, zu + sm_t + part_fit]);
            box3([wall - eps, back_t - eps, zu - part_fit - (wall - port_wall)],
                 [wall + eps, y_b1 + pocket_fit + part_fit + (wall - port_wall),
                  zu + sm_t + part_fit + (wall - port_wall)]);
        }
        // the USB-C opening through it: the shell's stadium, part_fit clear, round at its front end and
        // running on out to the cover's back edge, so the cover slides on past the shell. The cover prints
        // front face down, so that edge is the slot's top on the bed: open, it needs no bridge.
        translate([-eps, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = port_wall + 2 * eps) hull() {
            translate([y_bc + usb_open_c, z_uc]) circle(r = usb_open_r, $fn = 48);
            translate([usb_notch_y0, z_uc - usb_open_r]) square([y_bc - usb_notch_y0, 2 * usb_open_r]);
        }
        // vents in the front: over the SGP41's lower half, where its sensor is, clear of the bottom
        // screw's boss below - and over the board
        vent_slots(gy_x0 + 1, gy_x1 - 1, max(gy_z0, nut_bz + nut_boss_d / 2 + gap), gy_z0 + gy_l / 2 + 2);
        vent_slots(max(sm_x0, wall + gap), min(sm_x1, W - wall - gap), zu + sm_t + gap, zu + sm_t + gap + 10);
        // the two bottom screws' counterbores and holes
        for (x = nut_bx) cover_screw_hole(x, nut_bz);
    }
    // the bosses behind them, which carry the counterbores' floors, the nut bosses' size. Standing on the
    // front, so on the cover's bed they are short columns.
    for (x = nut_bx) difference() {
        cyl_y(x, nut_bz, nut_boss_d / 2, cb_y0, y_in1 + eps);
        cover_screw_hole(x, nut_bz);
    }
    // the U at the top: two arms hanging from the top wall, either side of the plate's bump, from the
    // cover's front back to part_fit off the plate
    for (x = [bump_x0 - part_fit - rib_t, bump_x1 + part_fit])
        box3([x, back_t + part_fit, u_z0], [x + rib_t, y_in1 + eps, H - wall + eps]);
    // the partition between the inlet and outlet sides of the air gap in front of the sensor,
    // part_fit above the divider fin, which it slides past as the cover goes on
    translate([x_div - rib_t / 2, y_sps1 + sps_fit, z_sps0 + part_fit])
        cube([rib_t, y_in1 - y_sps1 - sps_fit + eps, sps_h - part_fit]);
    // the baffle that closes that air gap off from the compartment above, part_fit over the sensor's top.
    // With the partition it also keeps the SPS30 from tipping forward, sps_fit off its face.
    translate([ch_x0, y_sps1 + sps_fit, z_sps1 + part_fit])
        cube([ch_in_w, y_in1 - y_sps1 - sps_fit + eps, rib_t]);
    // the board's front clasp, from its 4th pin to its antenna end: a rim in front of its edge, a lip over
    // its pad strip and a ledge under it, pocket_fit clear - the front edge slips in as the cover goes on.
    // Ribs standing on the front, so on the cover's bed they are walls.
    box3([sm_lip_x0, y_b1 + pocket_fit, z_f0], [sm_lip_x1, y_in1 + eps, zu + sm_pcb_t + 2 * pocket_fit + rim_t]);
    box3([sm_lip_x0, y_b1 - sm_lip_over, zu + sm_pcb_t + 2 * pocket_fit],
         [sm_lip_x1, y_in1 + eps, zu + sm_pcb_t + 2 * pocket_fit + rim_t]);
    box3([sm_lip_x0, y_b1 - clasp_low, z_f0], [sm_lip_x1, y_in1 + eps, zu - pocket_fit]);
    box3([stop_x0, y_b1 - stop_reach, z_f0], [stop_x0 + rim_t, y_in1 + eps, zu + sm_pcb_t + 1]);
    // fillets at the roots of the U's arms and the partition
    cover_fillets();
}

// =================================================================== fillets, at the thin features' roots
// The back plate's, at the plate's front face (Y = back_t). On its bed the plate lies on its back, so each
// widens down towards the bed: no overhang.
module plate_fillets() {
    // the SPS30 channel's walls, on their outer faces only: inside, the sensor stands 0.355 off them on the
    // plate. From above the cover's bottom wall, which reaches to fillet_clear beside them under the window.
    zw = wall + fillet_clear;
    fillet_line([ch_x0 - cradle_t, back_t, zw], [-1, 0, 0], [0, 1, 0], [0, 0, 1], z_sps1 - zw);
    fillet_line([ch_x1 + cradle_t, back_t, zw], [1, 0, 0], [0, 1, 0], [0, 0, 1], z_sps1 - zw);
    // the ledges and the end ribs over them, on their inner faces - one face each - and the middle rib's
    // two sides above the divider: the corners seen through the window. Behind the sensor they stay a
    // millimetre short of it, which stands sps_lift off the plate.
    fillet_line([sps_x0 + ledge, back_t, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1], z_sps1);
    fillet_line([sps_x1 - ledge, back_t, 0], [-1, 0, 0], [0, 1, 0], [0, 0, 1], z_sps1);
    for (k = [-1, 1])
        fillet_line([x_div + k * cradle_t / 2, back_t, z_sps0], [k, 0, 0], [0, 1, 0], [0, 0, 1], z_sps1 - z_sps0);
    // the divider, on both sides: its top carries the sensor, its bottom is the box's bottom edge
    for (k = [-1, 1])
        fillet_line([x_div + k * divider_t / 2, back_t, 0], [k, 0, 0], [0, 1, 0], [0, 0, 1], z_sps0);
    // the SGP41 wires' channel: both sides of the slot, and over the top rib - not under the lower rib,
    // which is part_fit over the SPS30
    for (f = [[gy_ch_zc - gy_ch_slot / 2, 1], [gy_ch_zc + gy_ch_slot / 2, -1], [gy_ch_zc + gy_ch_slot / 2 + rib_t, 1]])
        fillet_line([gy_ch_x0, back_t, f[0]], [0, 0, f[1]], [0, 1, 0], [1, 0, 0], gy_ch_x1 - gy_ch_x0);
    // the USB-C filler, on its inner face: its outer face is the box's outside, and its top and bottom
    // stand in the cover's slot
    fillet_line([port_wall, back_t, z_uc - usb_fill_h], [1, 0, 0], [0, 1, 0], [0, 0, 1], 2 * usb_fill_h);
    // the back stop, which takes the push of plugging in: on its far side from the board only - the board's
    // end bears on the other
    fillet_line([stop_x0 + rim_t, back_t, z_f0], [1, 0, 0], [0, 1, 0], [0, 0, 1], zu + sm_pcb_t + 1 - z_f0);
    // the SGP41's ledge, a thin shelf out from the plate: under it - the rib stands on top of it
    fillet_line([gy_x0, back_t, gy_z0 - pocket_fit - rim_t], [0, 0, -1], [0, 1, 0], [1, 0, 0], gy_x1 - gy_x0);
    // round the nut bosses, cut back from the cover's walls, which they stand part_fit inside
    for (x = nut_bx) intersection() {
        fillet_ring_y(x, nut_bz, nut_boss_d / 2, back_t);
        box3([wall + fillet_clear, back_t - eps, wall + fillet_clear],
             [W - wall - fillet_clear, back_t + fillet_r + eps, H - wall - fillet_clear]);
    }
}

// The cover's, at its front's inside face (Y = y_in1) and, for the U, under the top wall. The cover prints
// front face down, so these widen towards the bed or run up it: no overhang.
module cover_fillets() {
    // the U's arms: both sides, at the front and under the top wall - cut back from the plate's bump
    // between them
    difference() {
        for (xa = [bump_x0 - part_fit - rib_t, bump_x1 + part_fit]) for (k = [0, 1]) {
            xf = xa + k * rib_t;
            s = 2 * k - 1;
            fillet_line([xf, y_in1, u_z0], [s, 0, 0], [0, -1, 0], [0, 0, 1], H - wall - u_z0);
            fillet_line([xf, back_t + part_fit, H - wall], [s, 0, 0], [0, 0, -1], [0, 1, 0], y_in1 - back_t - part_fit);
        }
        box3([bump_x0 - fillet_clear, back_t - eps, u_z0 - fillet_clear],
             [bump_x1 + fillet_clear, back_t + bump_out + fillet_clear, H]);
    }
    // the window's two front corners, where its sides meet the front
    for (s = [[ch_x0 - cradle_t - part_fit, 1], [ch_x1 + cradle_t + part_fit, -1]])
        fillet_line([s[0], y_in1, 0], [s[1], 0, 0], [0, -1, 0], [0, 0, 1], wall);
    // the front stop, the back stop's twin: on its far side from the board only
    fillet_line([stop_x0 + rim_t, y_in1, z_f0], [1, 0, 0], [0, -1, 0], [0, 0, 1], zu + sm_pcb_t + 1 - z_f0);
    // the partition, both sides, at the front
    for (k = [-1, 1])
        fillet_line([x_div + k * rib_t / 2, y_in1, z_sps0 + part_fit], [k, 0, 0], [0, -1, 0], [0, 0, 1], sps_h - part_fit);
}

// The cove where the cover's walls meet its front, inside, all the way round: slices fillet_r / 10 thick,
// each the inner outline less its inset at that depth, so the inset follows the corners' curves exactly.
module inner_cove(n = 10) {
    rc = max(corner_r - wall, 0);
    for (i = [0 : n - 1]) {
        s0 = i * fillet_r / n;
        sm = s0 + fillet_r / (2 * n);
        w  = fillet_r - sqrt(fillet_r * fillet_r - (fillet_r - sm) * (fillet_r - sm));
        top = (i == 0) ? eps : 0;
        translate([0, y_in1 - s0 + top, 0]) rotate([90, 0, 0]) linear_extrude(height = fillet_r / n + top)
            difference() {
                offset(delta = eps) translate([wall, wall]) rrect(W - 2 * wall, H - 2 * wall, rc);
                offset(r = -w) translate([wall, wall]) rrect(W - 2 * wall, H - 2 * wall, rc);
            }
    }
}

// =================================================================== the cover's way on
// The cover goes straight back onto the plate, over everything already on it. Relative to the cover, each
// part inside moves back to the plate as it comes on, so each is swept there here, piece by piece - a hull
// of the whole would fill in the gaps between them - and check_cover_on intersects the sweep with the
// cover as it sits. Alon, 4 Oct 2026, on the printed box: the USB-C socket stands out through the side
// wall, and the wall behind its opening ran into it, so the box could not close.
module cover_on_path(s = 0.02) place() {
    for (i = [0, 2, 3, 4]) hull() { sm_piece(i, s); translate([0, -D, 0]) sm_piece(i, s); }
    for (b = parts_boxes(s)) hull() { box3(b[0], b[1]); translate([0, -D, 0]) box3(b[0], b[1]); }
    hull() for (dy = [0, -D]) translate([0, dy, 0])
        box3([sps_x0 + s, y_sps0 + s, z_sps0 + s], [sps_x1 - s, y_sps1 - s, z_sps1 - s]);
    hull() for (dy = [0, -D]) translate([0, dy, 0])
        box3([gy_x0 + s, gy_yp + s, gy_z0 + s], [gy_x1 - s, gy_yf + gy_sensor_h - s, gy_z1 - s]);
    hull() for (dy = [0, -D]) translate([0, dy, 0]) cyl_y(gy_hx, gy_hz, gy_head_d / 2 - s, gy_yf + s, gy_yf + gy_head_h - s);
}

// =================================================================== the SPS30's way in
// The sensor goes in from the front, before the cover: its outline, nubs included, swept from its seat to
// the cover's front. Nothing on the back plate may stand in it - check_insert intersects the two.
module sps_insert_path() place()
    translate([sps_x0 - sps_nub, y_sps0 + 0.02, z_sps0 + 0.02])
        cube([sps_w + 2 * sps_nub, y_in1 - y_sps0, sps_h - 0.04]);

// =================================================================== the SuperMini, piece by piece
// Its parts' envelope as boxes: full depth between and beside the back clips, and where a clip is, only
// past the room it takes.
function parts_boxes(s) = let(
        y0 = y_b0 + sm_edge + s, y1 = y_b1 - sm_edge - s, z0 = zu + sm_pcb_t - s, z1 = zu + sm_t - s,
        xs = [sm_x0 + s, clasp_xs[0][0], clasp_xs[0][1], clasp_xs[1][0], clasp_xs[1][1], sm_x1 - s])
    concat([for (k = [0, 2, 4]) if (xs[k + 1] - xs[k] > 1e-6) [[xs[k], y0, z0], [xs[k + 1], y1, z1]]],
           [for (c = clasp_xs) [[c[0], back_t + clip_room + s, z0], [c[1], y1, z1]]]);
// Five pieces, so the slide-in check can sweep each one on its own.
module sm_piece(i, s) {
    if (i == 0)        // the bare PCB, level, held by its edges. The clips pinch it by clasp_pinch on purpose,
                       // so the checks - which draw it shrunk - take that much off its top as well.
        color("teal") box3([sm_x0 + s, y_b0 + s, zu + s], [sm_x1 - s, y_b1 - s, zu + sm_pcb_t - (s > 0 ? clasp_pinch : 0) - s]);
    else if (i == 1)   // its parts, up to the tallest, clear of the pad strip along each long edge - and, where
                       // the back clips are, of all the room clip_room says they have. Plain boxes, so that
                       // the slide-in check can sweep each one without filling in the clips' notches.
        color("teal") for (b = parts_boxes(s)) box3(b[0], b[1]);
    else if (i == 2)   // the USB-C shell, a stadium, overhanging the PCB through the wall's opening
        color("teal") hull() for (dy = [-1, 1])
            cyl_x(y_bc + dy * usb_open_c, z_uc, usb_shell_h / 2 - s, sm_usb_x - usb_overhang + s, sm_usb_x - s);
    else if (i == 3)   // the antenna loop, in the board's plane past its end
        color("orange") box3([sm_ant_x + s, y_b0 + ant_loop_free + s, zu + sm_pcb_t + s],
                             [sm_ant_x + ant_over - s, y_b1 - ant_loop_free - s, zu + sm_pcb_t + 1 - s]);
    else if (i == 4)   // the antenna's pole, standing up off the component side
        color("orange") translate([sm_ant_x - pole_in, y_bc, zu + sm_pcb_t + s])
            cylinder(r = 0.5 - s, h = ant_h - sm_pcb_t - 2 * s);
}

// The board's way in: each piece swept from in front, along Y, until its back edge is in the clips.
module sm_slide_path(s = 0.02) place() {
    for (i = [0, 2, 3, 4]) hull() { sm_piece(i, s); translate([0, D, 0]) sm_piece(i, s); }
    for (b = parts_boxes(s)) hull() { box3(b[0], b[1]); translate([0, D, 0]) box3(b[0], b[1]); }
}

// =================================================================== the components, for preview and checks
module components(shrink = 0) place() {
    s = shrink;
    color("silver") box3([sps_x0 + s, y_sps0 + s, z_sps0 + s], [sps_x1 - s, y_sps1 - s, z_sps1 - s]);
    for (i = [0 : 4]) sm_piece(i, s);   // the SuperMini
    // the body of the largest compliant plug, seated, with the board pushed against its stops. Its
    // face can come right up to the socket's mouth, so that is where it is drawn.
    color("dimgray") box3([-usb_proud_in - 20 + s, y_bc - usb_plug_w / 2 + s, z_uc - usb_plug_h / 2 + s],
                          [-usb_proud_in - s, y_bc + usb_plug_w / 2 - s, z_uc + usb_plug_h / 2 - s]);
    // the GY-SGP41 lying flat: the PCB and its sensor towards the cover, and behind it the parts on its
    // underside - less the bare strip along its bottom edge, where the rib bears, and the bare patch round
    // its mounting hole, where the post does
    color("green") {
        box3([gy_x0 + s, gy_yu + s, gy_z0 + s], [gy_x1 - s, gy_yf + gy_sensor_h - s, gy_z1 - s]);
        difference() {
            box3([gy_x0 + s, gy_yp + s, gy_z0 + gy_bare + s], [gy_x1 - s, gy_yu + s, gy_z1 - s]);
            cyl_y(gy_hx, gy_hz, gy_hole_bare_d / 2 - s, gy_yp, gy_yu + 2 * s);
        }
    }
    // the SGP41 screw's head, between the module and the cover
    color("silver") cyl_y(gy_hx, gy_hz, gy_head_d / 2 - s, gy_yf + s, gy_yf + gy_head_h - s);
    // the SPS30's plug and the column its lead rises through before it bends over
    color("orange") box3([lead_x0 + s, y_sps0 + s, z_sps1 + s], [lead_x1 - s, y_sps1 - s, z_sps1 + cable_zone_h - s]);
    // the wall screws' heads behind the plate, each all the way from its entry up to where it hangs,
    // standing off the wall by up to key_slack more than the plate is thick
    for (x = key_xs) color("silver") hull() for (z = [key_z0, key_z1])
        cyl_y(x, z, key_head_d / 2 - s, back_t + s, back_t + key_slack + key_head_h - s);
}

// =================================================================== what gets drawn
// Only when the box itself is drawn: the clearance test and the pictures include this file and say
// draw_model = false, and none of this is theirs to report.
if (draw_model) {
    if (len(unmeasured) > 0)
        echo(str("WARNING: ", len(unmeasured), " dimensions are placeholders, not measurements: ", unmeasured));
    if (len(untested_fits) > 0)
        echo(str("WARNING: these fits have not been tested in ASA on this printer: ", untested_fits));

    echo(str("air-quality monitor: ", W, " x ", H, " x ", D, " mm (width x height x depth, installed), and the ",
             "divider ", divider_proud > 0 ? str(divider_proud, " mm below") : "flush with its bottom edge"));
    echo(str("outlet at the ", outlet_at_left ? "LEFT" : "RIGHT", " end; divider at ", divider_from_inlet_end,
             " mm from the inlet end, ", divider_t, " mm wide, ", div_clear_in, " mm clear of the inlets and ",
             div_clear_out, " of the outlet"));
    echo(str("keyholes: ", key_xs[1] - key_xs[0], " mm apart, the screws ", key_z1, " mm up once hung; each entry ",
             2 * hole_r(key_entry_d), " mm and slot ", 2 * hole_r(key_slot_w), " mm as cut; set the heads ",
             back_t, " to ", back_t + key_slack, " mm off the wall"));
    echo(str("board: in its clasps ", zu, " mm up, its pole's tip ", zu + ant_h, " mm, the top wall's inside ", H - wall,
             "; SGP41 flat, its sensor ", y_in1 - (gy_yf + gy_sensor_h), " mm behind the cover's vents, held by an M",
             gy_screw_d, " x ", gy_screw_l, " in a ", gy_pilot_depth, " mm pilot down a ", gy_post_y1 - back_t,
             " mm post; its underside parts ", gy_yp - ch_notch, " mm off the notched channel wall"));
    echo(str("cover: two M3 x ", cover_screw_l, ", heads flush in ", 2 * hole_r(cb_d), " mm counterbores ", cb_depth,
             " deep, into nuts whose shoulder is ", nut_y1,
             " mm from the back; its top locates on a ", bump_w, " mm bump in a U"));
    echo(str("USB-C: the socket's mouth stands ", usb_proud_in, " to ", usb_proud + part_fit,
             " mm past the outside face; the plug's body clears the mounting surface by ", y_bc - usb_plug_w / 2, " mm"));
}

if (draw_model) {
    if (part == "back")
        rotate([90, 0, 0]) back_plate();
    else if (part == "cover")
        translate([0, 0, D]) rotate([-90, 0, 0]) cover();
    else if (part == "assembly") {
        back_plate();
        %cover();
        %components();
    }
    else if (part == "check_parts")
        intersection() { back_plate(); cover(); }
    else if (part == "check_components")
        intersection() { union() { back_plate(); cover(); } components(shrink = 0.02); }
    else if (part == "check_insert")
        intersection() { back_plate(); sps_insert_path(); }
    else if (part == "check_slide")
        intersection() { back_plate(); sm_slide_path(); }
    else if (part == "check_cover_on")
        intersection() { cover(); cover_on_path(); }
    else
        assert(false, str("unknown part \"", part, "\" - use back, cover or assembly"));
}

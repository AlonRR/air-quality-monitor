// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CERN-OHL-S-2.0
// Open hardware, made available under the CERN Open Hardware Licence v2 - Strongly Reciprocal
// (LICENSES/CERN-OHL-S-2.0.txt), without any express or implied warranty: see the licence for its conditions.

// The back plate, on its own, for scad-check.sh. Everything is in air-quality-monitor.scad; this
// only pins the part. It exists because `part` in the params file is also the line you change to VIEW
// a part, and scad-check.sh takes no -D: checked through air-quality-monitor.scad, the "back plate" check
// silently checked whatever part was on screen. Through this file it cannot.
include <air-quality-monitor.scad>
part = "back";

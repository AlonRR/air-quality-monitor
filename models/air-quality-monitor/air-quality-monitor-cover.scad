// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CERN-OHL-S-2.0
// Open hardware, made available under the CERN Open Hardware Licence v2 - Strongly Reciprocal
// (LICENSES/CERN-OHL-S-2.0.txt), without any express or implied warranty: see the licence for its conditions.

// The cover, on its own, for scripts/scad-check.sh. Everything is in air-quality-monitor.scad; this only
// picks the part. Assigning `part` after the include replaces it silently - that is the idiom, not a
// mistake (docs/openscad-basics, lesson 3 §7).
include <air-quality-monitor.scad>
part = "cover";

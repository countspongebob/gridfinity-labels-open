# Release Notes

Newest releases first. Each entry corresponds to a git tag (`vNNN`).
Both `imperial.scad` and `metric.scad` always share the same version number.

---

## v105 - Dome side-view orientation fix

Fixes the reversed button head reported during metric testing. Both files
changed identically (shared core); version headers bumped to 105.

The v104 regeneration shipped all four dome side views - `phillips_bolt_icon`,
`button_bolt_icon`, `carriage_bolt_icon`, `robertson_pan_icon` - mirrored:
flat edge outboard at head_x+3.5, dome curve tapering into the stem. This is
the second occurrence of this exact mistake; the first was in the pre-v99
baseline and was fixed in September 2025 with the code comment "Keep LEFT
half for proper dome orientation". The v104 regression also got codified into
SPECIFICATION.md section 5.3, which was written from the reversed code.

Changes:

- All four dome side views (both files): half-disc now centered at head_x+6
  keeping the left half - curve faces outboard, flat bearing face at
  head_x+6. Same footprint as v104 (head_x+3.5 to head_x+6), flipped.
- Dome stems moved head_x+5 to head_x+6: the stem butts the flat face
  directly. The v102-v103 taper-overlap gap workaround is obsolete for domes
  (flat-face half-height 2.5mm exceeds stem half-width 1.25mm; no notch, no
  gap possible).
- Rectangular, hex, countersunk, and specialty icons untouched.
- SPECIFICATION.md 5.3 rewritten with the correct dome rule plus an explicit
  regression warning; changelog entry added.

Related finding, no code change: the "button head bolt missing from
imperial" observation is a naming mismatch. Pre-v104 imperial builds
(including older published MakerWorld versions) list the type as "Button
head screw"; v104+ files list "Button head bolt" in both metric and
imperial. Same icon, renamed. Consider republishing the imperial MakerWorld
model from v105.

Verified by OpenSCAD renders of v104 vs v105 button and phillips icons in
both files: v105 shows the dome curving outboard with the flat face flush
against the stem.

## v104 — Metric Version + Master Specification

**Milestone release.**

### New: `metric.scad`
Derived from the imperial v103 shared core. Unit-layer changes only:
- Header: METRIC / ISO Metric Machine Screw Support
- `thread_spec`: M2, M2.5, M3, M4, M5, M6, M8, M10, M12, M14 (default M5)
- `length_input_mm = 16` — direct mm input, no 25.4 conversion
- `generate_metric_display_text()` replaces the imperial fraction table,
  producing standard callouts like `M5 x 16`
- Multi-label parser example table converted to metric specs

Verified: diff against imperial confirms the shared core (all 19 icons,
stems, base, batch mode, export modes) is byte-identical.

### New: `SPECIFICATION.md`
Single source of truth governing both code files: critical AI assistant
context, unit-agnostic architecture, calibrated values, complete icon
geometry reference (including the head/stem junction rules learned in
v102–v103), unit-specific layer definition, and synchronized versioning
rules.

### `imperial.scad`
Functionally unchanged from v103. Header bump only, per synchronized
versioning (both files always share the same version number).

---

## v103 — Head/Stem Gap Fix (System-Wide Audit)

Every icon's head/stem junction was audited for the dome-taper gap
(stem starting where the head profile is narrower than the 2.5 mm stem,
leaving a visible notch).

**Fixed** (stem start `head_x + 6` → `head_x + 5`):
- `phillips_bolt_icon`
- `carriage_bolt_icon`
- `button_bolt_icon` (its `scale([1,1,0.6])` affects Z only; the XY
  footprint is a standard tapering dome)

**Audited, no gap, untouched:** socket, torx, hex, all countersunk
variants, wood screws, nuts, washers, wall anchor, heat set insert.

---

## v102 — Robertson Pan/Flat Variants + Gap Fix

- Replaced "Robertson head bolt" with two specific variants:
  - **Robertson pan head** — square-recess top view, dome side view
  - **Robertson flat head** — square-recess top view, countersunk
    triangle side view (follows the Phillips countersunk pattern)
- First gap fix: Robertson pan stem starts at `head_x + 5`, overlapping
  the dome taper to eliminate the head/stem notch

---

## v101 — Robertson Head Bolt

- Added Robertson (square drive) bolt: 5 mm circle top view with
  centered 2.2 mm square recess, dome side view, standard stem

---

## v100 — Carriage Bolt

- Added carriage bolt: **solid circle** top view (carriage bolts have no
  tool relief), dome side view, standard stem

---

## v99 and earlier

Baseline mature system (imperial only). History in prior project
documentation.

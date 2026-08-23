# Release Notes

Newest releases first. Each entry corresponds to a git tag (`vNNN`).
Both `imperial.scad` and `metric.scad` always share the same version number.

---

## v110 - Default colors: white base, black content

Changes the default colors in both files: base_color #2C3E50 -> #FFFFFF
(pure white), content_color #FFFFFF -> #000000 (pure black). No gray
tones anywhere. Both remain customizer parameters, so any other
combination can still be set per-print.

No geometry change - color() affects preview/3MF part coloring only;
exported STL geometry is identical to v109.

## v109 - Side tabs restored, mounting holes removed

Restores the end tabs that hold the label in Gridfinity Extended bins
and removes the mounting holes. Both changes return label_base() to the
pre-v99 baseline: that baseline had tabs and no holes; the v104
regeneration silently swapped this (dropped the tabs, added two 1.5mm
holes) while keeping the batch h_spacing (label_length + 4) that exists
to make room for tabs - the orphaned spec note confirmed the regression.

### Changes (both files)

- label_base() grows two rectangular tabs, one centered on each end:
  1.0mm deep x 6.0mm wide x full label_thickness - the exact v99
  baseline geometry, taken from the archived imperial_v99.scad.
- New customizer params under Label Properties: enable_side_tabs
  (default TRUE), tab_depth (1.0), tab_width (6.0).
- Mounting holes removed; hole_diameter parameter deleted. Gridfinity
  Extended slots retain the label by its tabs.
- Tabs are part of the base: "Base only" export includes them,
  "Content only" is unaffected.

### Verification

- Tabs on: base bbox extends to +/-(label_length/2 + 1.0), tab spans
  y = -3..+3 on both ends; zero vertices at the former hole positions
  (all measured via STL).
- Batch mode: h_spacing already accounts for tabs - adjacent labels
  keep a 2.0mm gap between tab tips; no overlap.
- Both files compile clean; multi-label mode unaffected.

## v108 - Text auto-fit (MakerWorld overflow fix)

Fixes label text overrunning the label edges on MakerWorld. Two causes:

1. MakerWorld's customizer does not resolve "Roboto:style=Bold" and
   substitutes a wider font (~22%+ wider, different vertical metrics),
   shifting text down and past the edges.
2. Latent width bug independent of fonts: render_text() had no width
   constraint, so long strings ('1/4-20 x 1-1/4"' = 36.7mm, 'SPRING
   WASHER' = 42.5mm) overflowed the 35.8mm Small label even with Roboto.

### Fix (render_text, shared core)

- Vertical: valign="baseline" with the baseline pinned 1.5mm above the
  label's bottom edge - placement no longer depends on any font's
  ascent/descent metrics.
- Horizontal hybrid fit: estimated width from a per-character advance
  table calibrated ~10% above DejaVu Sans Bold (worst common fallback;
  OpenSCAD 2021.01 has no textmetrics()). When the estimate exceeds
  label_length - 8 (clear of mounting holes): condense x down to 80%,
  then shrink proportionally if still over. Short strings unchanged.
- Every fit action is echoed: TEXT-FIT: 'M10 x 35' condensed to 91%.

### Verification

Worst cases rendered on the Small label under a forced fallback font
and measured via STL bounding box - all text inside the hole-clearance
zone (max extent +/-12.9mm vs +/-14.4mm limit, baseline band well above
the bottom edge): 'M10 x 35' 91% condensed; '1/4-20 x 1-1/4"' 80% +
size 72%; 'SPRING WASHER' 80% + size 63%. Icons and label base
byte-identical to v107; text position intentionally moved.

## v107 - Flange hex bolts and flange nuts

Adds two hardware types to both files, motivated by metric flange-bolt
assortment kits: "Flange hex bolt" (dropdown, after Hex head bolt) and
"Flange nut" (after Lock nut; nut/washer-class, so its label text is the
thread alone).

### Icons

- Flange hex bolt top view: the 5mm circle (round flange) with a hex
  outline ring cut into it (3.6mm/2.8mm hex annulus, $fn=6) - hex head on
  a round flange, distinct from Hex head bolt's solid hex.
- Flange side views (bolt and nut): 2.5x4mm body plus a 1x5mm flange
  plate on the stem side. The bolt stem starts at head_x+7, butting the
  flange plate - plate half-height 2.5mm exceeds the 1.25mm stem
  half-width, so the Section 5.3 junction rule holds (no notch, no gap).

### Multi-label support

New type keys: `flange` (or `flangebolt`) and `flangenut`, e.g.
`flange: M6x16, M8x20; flangenut: M6, M8` - full names also accepted.

### Verification

- Ring cut confirmed via 2D projection contour test (3 contours: circle
  + hex outer + hex inner); preview-mode PNGs z-fight on the coplanar
  cuts exactly as they do on the existing nut/socket holes - render mode
  and prints are unaffected.
- Batch parse verified in both files (metric and imperial flange items,
  full-name keys, mixed-number imperial lengths).
- Default single-label output verified geometry-identical to v106 in
  both files (facet-set comparison).

## v106 - Multi-label mode made real (structured spec parser)

Replaces the fake multi-label "natural language prompt" with a working
structured parser in both files. v99-v105's `parse_multi_label_prompt()`
ignored its input entirely and returned a hardcoded example table - the
prompt field was decorative, and changing it changed nothing. OpenSCAD
cannot parse natural language; it can parse a structured string, and now
does.

### New grammar (paste into `multi_label_spec`, no code editing)

Groups separated by `;`, each group `type: item, item, ...`:

- Imperial: `socket: 1/4-20x1/2, 1/4-20x3/4, #8-32x1/2; nut: 1/4-20, #8-32; text: MISC`
- Metric: `button: M5x8, M4x12.5; washer: M5, M3; insert: M5`

Type keys (case-insensitive; full dropdown names also accepted):
phillips, socket, hex, button, torx, robertson (rpan), rflat, carriage,
phillips-csk, torx-csk, socket-csk, phillips-wood, torx-wood, anchor,
insert, nut, locknut, washer, springwasher, text. Imperial lengths take
fractions, mixed numbers, and decimals ("1/2", "1-1/4", "0.75"); metric
lengths take whole or decimal mm. Unknown types and malformed items are
skipped with a console warning, and every parsed label is echoed for
review before printing.

### Changes

- Customizer field renamed `multi_label_prompt` -> `multi_label_spec`
  (BREAKING for customizer presets saved with the old field name; default
  value reproduces the old hardcoded 11-label example exactly).
- New shared-core code, byte-identical in both files: string helpers
  (`_substr`, `_lc`, `_split`, `_trim`, `_num`, `_idx` - built on
  chr/ord/search; OpenSCAD has no regex), the type keyword table, and the
  grammar layer (`_parse_item`, `_parse_group`, `parse_multi_label_spec`).
- New unit layers: imperial `_norm_thread` / `_frac_in` / `_inches` /
  `_parse_len_mm` / `_display_text_for` (inch marks); metric equivalents
  (normalizes "m5" -> "M5").
- `label_content()` "Custom text" now renders a non-empty `display_text`
  in preference to `custom_text_only`, enabling `text:` batch items;
  single-label mode passes "" there, so its behavior is unchanged.
- `generate_multi_labels()` iterates `[0 : 1 : len-1]` so an empty parse
  renders nothing instead of hitting a degenerate range, and echoes the
  parsed label table.
- SPECIFICATION.md: new Section 7 (grammar, error handling,
  implementation notes); sections renumbered 7->8, 8->9, 9->10;
  unit-layer and custom-text notes updated.

### Verification

- Default `multi_label_spec` in each file parses to exactly the same 11
  labels the v105 stub hardcoded (verified via echo table and STL render).
- Edge cases exercised: mixed-number inches (1-1/4 -> 31.75mm), decimals,
  lowercase threads, full type names ("Robertson Pan Head"), unknown type
  groups and malformed items (skipped with warnings), text labels.
- Single-label default renders for both files verified geometry-identical
  to v105 (facet-set comparison; STL byte order is nondeterministic).

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

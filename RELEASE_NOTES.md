# Release Notes

Newest releases first. Each entry corresponds to a git tag (`vNNN`).
Both `imperial.scad` and `metric.scad` always share the same version number.

---

## v114 - Extrusion T-nut icons; heat insert side view redesigned

Three new hardware types for T-slot aluminum extrusion nuts (both
files, shared core), inserted after Flange nut in the dropdown:
Sliding T-nut, Drop-in T-nut, Hammer T-nut. All three are
nut/washer-class: icon plus thread text, no length.

### Icon design

All three styles share one side view, `tnut_side_profile()`: the
inverted-T slot cross-section (3.6 x 1.6mm base bar + 1.5 x 2.8mm neck
centered above it) - the family badge that reads "T-slot hardware".
The style is carried by the top view alone, each a 5mm-class body
centered at center_x - 2 with a d=2.5 threaded bore:

- Sliding T-nut: sharp-cornered 5 x 4.4mm rectangle (slides in from
  the extrusion end)
- Drop-in T-nut: 5.4 x 4.4mm pill, hull of two d=4.4 circles at
  x = +/-0.5 (rounded ends = inserts anywhere along the slot)
- Hammer T-nut: 5 x 4.4mm rectangle with the NW and SE corners cut at
  45 degrees (2.0mm-leg triangles, outset 0.1mm for robust booleans) -
  the hammer-head shape that rotates 90 degrees to lock

The bore is d=2.5 rather than the hex nuts' d=3 to keep >= 0.95mm
walls on the 4.4mm-tall rectangular bodies.

### Heat set insert side view redesigned

The v113 side view - four detached 1 x 4mm knurl bars - read as
generic hatching, not an insert. Replaced (both files) with the
actual heat-set insert silhouette: vertical axis, insertion end down,
two 3.2mm-wide knurl bands separated by a 2.2mm waist groove, the
bottom band tapering to a flat pilot tip. The ring top view
(4mm OD / 2.5mm bore) is unchanged, as are the module signature,
dispatch, and the `insert` batch key - metric labels read M3/M5 etc.,
imperial 1/4-20, #8-32 etc. as before.

### Multi-label batch keys

`tnut` (alias `tnut-slide`) -> Sliding T-nut, `tnut-drop` -> Drop-in
T-nut, `tnut-hammer` -> Hammer T-nut. Example:
`tnut: M5, M4; tnut-drop: M5; tnut-hammer: M6` (imperial:
`tnut: 1/4-20, 5/16-18`).

### Verification

- Content-only orthographic renders confirm all three top views and
  the shared inverted-T side profile, with open bores, in both files.
- Batch parser echo-verified for all four keys in both files.
- The new icon module block is byte-identical between metric.scad and
  imperial.scad.
- Regression: Standard nut, Socket head bolt, and Spring washer STLs
  compared v113 vs v114 - triangle sets identical (STL byte order
  varies with CGAL cache state; geometry does not).

## v113 - Vertical centering: content block no longer sits high

Labels printed with the icon/text block visibly nearer the top edge
than the bottom. Measured on a v112 Content-only STL (M5 x 16, Small
label): icon ink reached 0.375mm from the top edge while the text
baseline sat 1.5mm from the bottom - a 4:1 margin skew, ink midpoint
0.54mm above label center. Root cause: `icon_y_pos = label_width/4`
and the v108 baseline constant were each chosen independently; no spec
rule required the block to be centered, so nothing caught the skew.

### Fix (both files, shared core)

New constant next to the internal calculations:

    content_v_shift = -(1.5 - 0.375) / 2;  // -0.5625mm

applied to BOTH placements, so the block moves as one unit:

- `icon_y_pos = label_width/4 + content_v_shift` (+2.875 -> +2.3125)
- text baseline `y = -label_width/2 + 1.5 + content_v_shift` (-4.25 -> -4.8125)

The icon-text gap, the v108 baseline-pinning approach (font-metric
independent), and all x-geometry are unchanged. Expression form keeps
content_v_shift out of the customizer UI.

### Verification

Content-only STL bounding boxes (M5 x 16 Button head, Small label,
Roboto Bold): v112 ink y -4.30..+5.38 (margins 0.375 / 1.45, midpoint
+0.54mm); v113 ink y -4.87..+4.81 (margins 0.94 / 0.88, midpoint
-0.03mm). Orthographic before/after renders inspected. Both files
compile clean; multi-label sheet spot-checked.

A cautionary note now codified in spec Section 4.2: a first-cut
relayout derived from an assumed ~2.9mm cap height nearly shipped a
0.1mm icon-text gap - Roboto Bold digit ink at size 4 actually
measures ~4.0mm. Vertical placement changes must be verified by STL
measurement, never font-metric estimates.

### Known trade-offs

- Custom/override text with descenders (g j p q y) can reach
  ~0.1-0.2mm past the bottom edge under a worst-case substituted
  font; auto-generated hardware strings have no descenders.
- "Custom text"-only labels (no icon) shift down with the shared
  render_text(); centering text-only labels is a deliberate open item.


## v112 - Curve resolution fix: smooth round icons

Neither file set `$fa`/`$fs`/`$fn` globally, so every circle without an
explicit `$fn` rendered at OpenSCAD's defaults (`$fa=12`, `$fs=2`). At
icon scale that meant 8 segments for d=5 circles and the 5-segment
floor for d<=3: washers drew as octagons with pentagon bores, dome side
views as 4-facet arcs, nut and heat-insert bores as pentagons, and the
r=0.9 label-base corners as visible facets. The spec line "default
elsewhere" had codified the defect.

### Fix (both files)

Global curve resolution added to the customizer parameter block:

    $fa = 6;
    $fs = 0.25;

Adaptive `$fa`/`$fs` scales fragment count to feature size: d=5 heads,
domes, and washer rims get 60 segments; d=3 bores ~38; the r=0.9 label
corners ~23. Explicit per-call `$fn=6` overrides the globals, so every
intentional hex (Socket/Button recess, Hex head, Flange hex ring, nut
exteriors) is unchanged. No dimensions, positions, or module interfaces
changed; render time impact is negligible.

Affected geometry now smooth: Standard/Spring washer rims and bores;
dome side views (Phillips, Robertson pan, Carriage, Button); all round
head top views (Phillips x3, Robertson x2, Carriage, Socket x2, Button,
Torx x3, Flange hex outer flange); nut bores (Standard, Lock, Flange);
Heat set insert body and bore; torx star spoke tips; label-base corner
radii.

### Verification

- Exported mesh vertex counts match prediction: washer outer rim 60
  segments, bore 38 (was 8 and 5).
- Orthographic render comparison across icon types in both files:
  round features smooth, hex features still hexagonal.
- Both files compile clean in single-label and multi-label modes; the
  `$fa`/`$fs` block is byte-identical between the files per the
  shared-core rule.

### Spec changes

- "CRITICAL CONTEXT" `$fn` bullet rewritten: globals govern unmarked
  circles; intentional hexes must keep explicit `$fn=6`; do not add
  per-call `$fn` to round features or remove the globals.
- Section 2 table: `$fa / $fs = 6 deg / 0.25 mm` row added.
- Section 5.1: curve-resolution rule documented with the override list.

## v111 - Left side tab detachment fix

The v109/v110 left tab printed as a loose sliver, not attached to the
label. Confirmed in the exported mesh: the base exported as TWO
disconnected shells. The left tab's inner face - computed as
-label_length/2 - tab_depth plus the cube's tab_depth width - landed a
floating-point epsilon short of the body edge, so CGAL kept it a
separate solid; the right tab starts at exactly label_length/2 and
merged correctly, which is why only the left side failed.

### Fix (both files)

Each tab cube now overlaps 1mm INTO the label body (inner edge at
label_length/2 - 1 instead of label_length/2). Outer dimensions are
unchanged: tabs still extend tab_depth (1.0mm) past each end at
tab_width (6.0mm). A spec implementation rule was added: never place a
union feature edge-to-edge; always overlap.

### Verification

- Base-only export now one connected shell in both files (was 2);
  bbox unchanged at +/-(label_length/2 + 1.0).
- Full label compiles clean; content unaffected.

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

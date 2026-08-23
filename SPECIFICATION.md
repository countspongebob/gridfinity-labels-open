# Parts Bin Label Generator - Master Specification
## Version 108

This is the single source of truth for the Parts Bin Label Generator.
Two code files are generated from this specification:

- `imperial_vNNN.scad` - Imperial Version (fractional & machine screw support)
- `metric_vNNN.scad` - Metric Version (ISO metric machine screw support)

---

## CRITICAL CONTEXT FOR AI ASSISTANTS

This is a mature, production-tested system. Many "obvious improvements" have
been tried and failed. Read this entire specification before making changes.

**Before making any changes:**
- Assume existing code is working correctly unless specifically told otherwise
- Icon geometries are carefully calibrated - do not assume round icons are mistakes
- Dome side-view ORIENTATION is a known repeat-regression site: the curve
  faces AWAY from the stem, the flat bearing face touches the stem
  (Section 5.3). This has been reversed by mistake twice (pre-v99 baseline,
  v104 regeneration; fixed in v105). Verify orientation on every regeneration.
- Custom text handling for nuts/washers has specific behavior to preserve
- `$fn` values are intentional (6 for hex shapes; default elsewhere)

**When modifying:**
- Every change must be applied to BOTH the imperial and metric files
  (except changes within the unit-specific layer, Section 6)
- Preserve all existing parameter flows, especially `display_text`
- Never "optimize" the button head side view without explicit request
- Focus on adding NEW capabilities, not "fixing" existing working features
- Use whole integer version numbers only (v105, never v104.1)
- Both files always carry the SAME version number (synchronized versioning)
- Document every version in the changelog (Section 10) with rationale

**Common pitfalls to avoid:**
- Do not change icon module function names
- Do not modify bolt stem positioning without understanding the alignment
  system and the gap-fix rules (Section 5.3)
- Do not simplify the dual custom text field system
  (`custom_display_text` overrides auto-generation; `custom_text_only` is
  the fallback when hardware_type is "Custom text" - since v106 a
  non-empty `display_text` takes precedence there, which batch text
  labels depend on)

---

## 1. Architecture

The engine is unit-agnostic: all icons, stems, and layout calculations run on
`length_mm` internally. The unit system is a thin input/display layer:

```
[Unit-specific layer]           [Shared core - identical in both files]
thread_spec dropdown       -->  create_single_label()
length input + conversion  -->  label_base(), label_content()
display text generation    -->  render_hardware_icon() + 21 icon modules
multi-label item parsing   -->  bolt_stem(), render_text()
                                multi-label grammar + string helpers
```

Generation rule: the shared core (Sections 3-5) must be byte-identical
between the two files except for the fallback text expression noted in 6.3.

## 2. Calibrated Values (both files)

| Parameter | Value | Notes |
|---|---|---|
| label_width | 11.5 mm | |
| label_thickness | 0.8 mm | |
| corner_radius | 0.9 mm | |
| edge_chamfer | 0.2 mm | |
| raised_height | 0.2 mm | text_height when Raised |
| flush_height | 0.01 mm | text_height when Flush |
| hole_diameter | 1.5 mm | mounting holes at ±(label_length-2)/2 |
| Small label | 35.8 mm | label_units = 1 |
| Medium label | 77.8 mm | label_units = 2 |
| Large label | 119.8 mm | label_units = 3 |
| max_bolt_length | 20 × label_units | stems beyond this render split |
| Batch h_spacing | label_length + 4 | accounts for side tabs |
| Batch v_spacing | 15 mm | |
| Batch grid | 3 columns | |

## 3. Hardware Types (21 + Custom text + None)

Dropdown order (identical in both files):
Phillips head bolt, Socket head bolt, Hex head bolt, Flange hex bolt,
Button head bolt, Torx head bolt, Robertson pan head, Robertson flat head,
Carriage bolt, Phillips head countersunk, Torx head countersunk,
Socket head countersunk, Phillips wood screw, Torx wood screw, Wall anchor,
Heat set insert, Standard nut, Lock nut, Flange nut, Standard washer,
Spring washer, Custom text, None

Nut/washer-class types (icon only + thread text, no length):
Standard nut, Lock nut, Flange nut, Standard washer, Spring washer

## 4. Export & Color (both files)

- export_mode: Complete / Base only / Content only (dual-color workflow:
  base and content export separately for Bambu Studio / MakerWorld)
- base_color default #2C3E50, content_color default #FFFFFF
- Typography: Roboto Bold default, text_size 4.0, Raised/Flush modes

### 4.1 Text auto-fit (v108)

Renderer font substitution (MakerWorld's customizer does not resolve
"Roboto:style=Bold" and falls back to a wider font) changes both glyph
widths and vertical metrics, which shipped labels with text overrunning
the label edges. render_text() is therefore self-fitting:

- Vertical: valign="baseline", baseline pinned at label_width/2 - 1.5mm
  above the bottom edge (y = -label_width/2 + 1.5). Placement is
  independent of any font's ascent/descent metrics. Do NOT return to
  valign="center" - its position is font-dependent and regressed on
  MakerWorld.
- Horizontal: estimated width = text_size x sum of per-character
  advances from _adv() - a table calibrated ~10% ABOVE DejaVu Sans Bold
  (widest common fallback; OpenSCAD 2021.01 has no textmetrics()).
  Safe width: label_length - 8 (keeps text clear of the mounting
  holes). Hybrid fit: condense x down to 80% first, then shrink
  proportionally if still over. Short strings are untouched; every fit
  action is echoed as "TEXT-FIT: ...".
- Verified worst cases on the Small label under a forced fallback
  font: 'M10 x 35' (condensed 91%), '1/4-20 x 1-1/4"' (80% + size 72%),
  'SPRING WASHER' (80% + size 63%) - all inside the hole-clearance
  zone (measured via STL bounding box).

## 5. Icon Geometry Reference

### 5.1 Standard bolt icon pattern
- `head_x = -min(length_mm, max_bolt_length)/2 - 3` (bolts)
- `head_x = -min(length_mm, max_bolt_length)/2 - 2` (countersunk & wood screws)
- Top view (drive pattern) at head_x
- Side view (head profile) starts at head_x + 3.5 (bolts) or head_x + 4
  (countersunk); dome side views are centered at head_x + 6 (see 5.3)
- All icon geometry sits at z = label_thickness, extruded text_height

### 5.2 Drive patterns (top view, cut from 5mm circle)
- Phillips: cross, two 0.8mm-wide slots, 4mm span
- Socket / Button: 3mm hex ($fn=6)
- Hex head: solid 5mm hex ($fn=6), no cut
- Torx: 6-spoke star (torx_star, 2.5 size, 0.3 spoke dia)
- Robertson: centered 2.2mm square
- Carriage: NO cut - solid circle (no tool relief)
- Flange hex bolt: hex outline ring (3.6mm/2.8mm hex annulus, $fn=6) cut
  from the 5mm circle - reads as a hex head sitting on a round flange

### 5.3 Head/stem junction rules (gap fix v102-v103; orientation v105)
A stem must never start at an x-position where the head profile's half-height
is less than the stem half-width (1.25mm), or a visible notch appears.

- Dome side views (Phillips, Carriage, Button, Robertson pan) - ORIENTATION
  IS MANDATORY: the CURVED side faces outboard (toward the top view) and the
  FLAT bearing face sits at head_x+6, where the stem starts. Implementation:
  circle centered at head_x+6, keep the LEFT half via
  `translate([-5, -2.5, 0]) cube([5, 5, text_height])`; half-disc spans
  head_x+3.5 to head_x+6. Stem starts at head_x+6, butting the flat face
  (flat-face half-height 2.5mm > 1.25mm, so no notch and no gap - the
  v102-v103 taper-overlap workaround is obsolete for domes).
  REGRESSION WARNING: the mirrored form (flat face outboard, taper toward
  the stem, stem at head_x+5) is WRONG. It shipped in the pre-v99 baseline,
  was fixed, and was reintroduced in the v104 regeneration; v105 fixed it
  again. Never regenerate a dome side view with the cube on the +x side of
  the circle's center.
- Rectangular side views (Socket, Torx: 4mm cube; Hex: 3mm cube): stem
  overlaps the rectangle; head_x+6 (socket/torx) and head_x+5.5 (hex) are
  correct as-is.
- Flange side views (Flange hex bolt, Flange nut): 2.5x4mm body then a
  1x5mm flange plate on the stem side (bolt: body at head_x+3.5, plate at
  head_x+6, stem at head_x+7 butting the plate - plate half-height 2.5mm >
  1.25mm, no notch; nut: body at center_x+2, plate at center_x+4.5).
- Countersunk triangle ([0,-2.5],[3,0],[0,2.5] at head_x+4): stem at
  head_x + 5 overlaps the triangle. Correct as-is.
- Button head note: scale([1,1,0.6]) affects Z only; XY footprint is a
  standard dome, so the dome rule applies.

### 5.4 Specialty icons
- Wood screws: countersunk head + stem shortened by 2 + pointed tip polygon
- Wall anchor: 5 fins + optional stem when length_mm > 8
- Heat set insert: ring (4mm OD / 2.5mm ID) + 4 knurl bars
- Standard nut: hex ring + 3mm side rectangle
- Lock nut: standard nut + stepped second rectangle (nylon collar)
- Flange nut: hex ring top view + 2.5x4 body / 1x5 flange plate side view
- Standard washer: round ring + 1mm side bar
- Spring washer: split ring (0.8mm slot) + 1mm side bar

## 6. Unit-Specific Layer (the ONLY differences between files)

### 6.1 Imperial file
- Header: "Parts Bin Label Generator - IMPERIAL" / "Fractional & Machine Screw Support"
- thread_spec default "1/4-20"; dropdown: 1/4-20, 5/16-18, 3/8-16, 7/16-14,
  1/2-13, 9/16-12, 5/8-11, 3/4-10, 7/8-9, 1-8, #4-40, #5-40, #6-32, #8-32,
  #10-24, #12-24
- Length input: `length_inches = 0.75` with `length_mm = length_inches * 25.4`
- Display text: `generate_imperial_display_text()` - fraction lookup table
  covering 1/8" through 2" in 1/16" steps (plus 1-1/4, 1-1/2, 1-3/4, 2),
  falling back to decimal for custom lengths
- Helper: `imperial_to_mm(inches) = inches * 25.4`
- Multi-label unit layer: `_norm_thread()` accepts "1/4-20" / "#8-32"
  forms as typed; `_parse_len_mm()` parses fractional, mixed-number, and
  decimal inches ("1/2", "1-1/4", "0.75") x 25.4; `_display_text_for()`
  appends inch marks

### 6.2 Metric file
- Header: "Parts Bin Label Generator - METRIC" / "ISO Metric Machine Screw Support"
- thread_spec default "M5"; dropdown: M2, M2.5, M3, M4, M5, M6, M8, M10,
  M12, M14
- Length input: `length_input_mm = 16` with `length_mm = length_input_mm`
  (no conversion)
- Display text: `generate_metric_display_text(thread, length) =
  str(thread, " x ", length)` producing standard callouts like "M5 x 16"
- Multi-label unit layer: `_norm_thread()` requires M+number and
  normalizes "m5" -> "M5"; `_parse_len_mm()` parses whole/decimal mm;
  `_display_text_for()` yields "M5 x 8"
- Common stocked lengths for reference: 4, 5, 6, 8, 10, 12, 16, 20, 25,
  30, 35, 40, 45, 50 mm

### 6.3 Shared-core exception
In `label_content()`, the fallback text expression differs:
- Imperial: `str(thread, " x ", length_inches, "\"")`
- Metric:   `str(thread, " x ", length_input_mm)`

Nut/washer types display thread spec only (e.g. "1/4-20" / "M5") in both.

## 7. Multi-Label Batch Mode (real parser since v106)

Toggled by `enable_multi_label`. The `multi_label_spec` string is parsed
by `parse_multi_label_spec()` into a list of
`[type, thread, display_text, length_mm]` entries rendered on a 3-column
grid (h_spacing = label_length + 4, v_spacing = 15).

History: v99-v105 shipped a STUB. `parse_multi_label_prompt()` ignored its
"natural language" input entirely and returned a hardcoded example table -
OpenSCAD cannot parse natural language; the field was decorative. v106
replaced it with a structured grammar and renamed the customizer field
`multi_label_prompt` -> `multi_label_spec` (breaking: customizer presets
saved with the old field name lose that value).

### 7.1 Grammar

```
spec  := group { ";" group }
group := typekey ":" item { "," item }
```

Type keys (case-insensitive; full dropdown names from Section 3 also
accepted): phillips, socket, hex, flange (or flangebolt), button, torx,
robertson (or rpan), rflat, carriage, phillips-csk, torx-csk, socket-csk,
phillips-wood, torx-wood, anchor, insert, nut, locknut, flangenut, washer,
springwasher, text

Items:
- Bolt/screw types: `<thread>x<length>` (spaces allowed around "x").
  A bare `<thread>` is also accepted (icon with zero stem; label text is
  the thread alone) - useful for `insert: M5`.
- Nut/washer types: `<thread>` only.
- `text:` items are literal label text and cannot contain "," or ";".

Lengths - imperial: inches as "1/2", "3/4", "1", "1-1/4", "0.75";
metric: mm as "8" or "12.5". Threads - imperial as typed ("1/4-20",
"#8-32"); metric M+number, "m5" normalized to "M5".

Examples:
- Imperial: `socket: 1/4-20x1/2, 1/4-20x3/4; nut: 1/4-20, #8-32; text: MISC`
- Metric: `button: M5x8, M4x12.5; washer: M5, M3; insert: M5`

### 7.2 Error handling

Unknown type keys and malformed items are SKIPPED with an `echo()`
warning; every parsed label is echoed as `MULTI-LABEL: [type] text` so the
set can be reviewed in the console before printing.

### 7.3 Implementation notes

- OpenSCAD has no regex or split; helpers `_substr`/`_lc`/`_split`/
  `_trim`/`_num`/`_idx` are built on `chr()`/`ord()`/`search()`. These,
  the type keyword table, and the grammar layer (`_parse_item`,
  `_parse_group`, `parse_multi_label_spec`) are byte-identical in both
  files.
- The unit layer supplies `_norm_thread()`, `_parse_len_mm()`, and
  `_display_text_for()` (Section 6).
- Batch "Custom text" items flow through `display_text`:
  `label_content()` for "Custom text" renders `display_text` when
  non-empty, else `custom_text_only` (changed in v106; single-label
  behavior is unchanged and was verified geometry-identical to v105).

## 8. Versioning Rules

- Whole integers only; both files always share the same version number
- A change to the shared core (Sections 3-5) bumps both files and must be
  applied identically to both
- A change to only one unit layer (Section 6) still bumps BOTH files, with
  the unaffected file receiving only the header bump (keeps numbers locked)
- Documentation- or tooling-only changes (spec wording, release notes,
  release.sh) do NOT bump the code version
- Every version gets a changelog entry below and a changes-summary document

## 9. Repository & Release Workflow

Source of truth: https://github.com/countspongebob/gridfinity-labels-open

Repository files (all markdown docs use .md so GitHub renders them):
- `imperial.scad`, `metric.scad` - unversioned filenames; git tags (vNNN)
  carry the version
- `SPECIFICATION.md` - this document
- `RELEASE_NOTES.md` - one `## vNNN` entry per release, newest first
- `release.sh` - release automation (below)

**AI assistants: at the start of every version session, clone the repo and
work from HEAD - do not rely on project knowledge being current:**
`git clone https://github.com/countspongebob/gridfinity-labels-open`

Release procedure per version NNN:
1. AI session produces a single downloadable bundle named
   `gridfinity-labels-vNNN.zip` containing ALL release files:
   `imperial_vNNN.scad`, `metric_vNNN.scad`, `master_specification.md`,
   `vNNN_changes_summary.md` (markdown, single H1 title - release.sh
   demotes headings when inserting into RELEASE_NOTES.md), `RELEASE_NOTES.md`
   (only when seeded/restructured), and `release.sh` (only when changed)
2. User downloads the bundle, then runs `./release.sh NNN "summary"` which
   finds and extracts the zip from Downloads (falls back to loose files),
   copies contents into the repo, verifies version headers, updates
   RELEASE_NOTES.md, commits, tags vNNN, and pushes
3. User clicks "Sync now" on the project's GitHub source

## 10. Changelog

- **v108**: Text auto-fit (both files). MakerWorld's renderer substitutes
  a wider font for "Roboto:style=Bold", producing text overrunning the
  label edges (and long imperial strings overflowed the Small label even
  under Roboto - latent since the baseline releases). render_text() now
  pins the baseline 1.5mm above the bottom edge (valign="baseline",
  font-metric independent) and width-fits via a calibrated advance table:
  condense to 80%, then shrink (Section 4.1). Icons and label base
  unchanged; text placement intentionally differs from v107.

- **v107**: Flange hardware added (both files): "Flange hex bolt" (after
  Hex head bolt) and "Flange nut" (after Lock nut, nut/washer-class).
  Top views: flange bolt = 5mm circle with hex outline ring cut (5.2);
  flange nut = standard hex ring. Side views: 2.5x4 body + 1x5 flange
  plate; bolt stem at head_x+7 butting the plate per the 5.3 junction rule.
  Multi-label keys: flange / flangebolt, flangenut. Existing types
  verified geometry-identical to v106.

- **v106**: Multi-label mode made real (both files). v99-v105's "natural
  language prompt" was a stub: `parse_multi_label_prompt()` ignored its
  input and returned a hardcoded example table. Replaced with a
  structured grammar (Section 7) parsed by `parse_multi_label_spec()`;
  customizer field renamed `multi_label_prompt` -> `multi_label_spec`
  (breaking for saved presets). Shared-core additions: string helpers,
  type keyword table, grammar layer; unit layers add thread/length
  parsing (imperial fractions and mixed numbers supported).
  `label_content()` "Custom text" now prefers a non-empty `display_text`
  (enables batch text labels); `[0:1:len-1]` range guard added in
  `generate_multi_labels()`. Single-label default output verified
  geometry-identical to v105 for both files.

- **v105**: Dome side-view orientation fix (both files). v104 shipped all
  four dome side views (phillips, button, carriage, robertson pan) mirrored:
  flat edge outboard at head_x+3.5, curve tapering into the stem - the
  second occurrence of this exact mistake (first: pre-v99 baseline, fixed
  Sept 2025 with the comment "Keep LEFT half for proper dome orientation").
  Corrected to curve-outboard / flat-face-at-stem; dome stems moved
  head_x+5 → head_x+6 to butt the flat face. Section 5.3 rewritten - it had
  been authored FROM the reversed v104 code and codified the mistake.
  Naming note: imperial's "Button head screw" / "Phillips head screw" era
  ended before v104; both files now use "... head bolt". Older published
  imperial builds (e.g. MakerWorld) list "Button head screw" - same icon,
  earlier name.
- **v104**: Metric version introduced (Option A: separate file). Synchronized
  versioning established. Master specification created as single source of
  truth. Imperial code functionally unchanged from v103. (Post-release docs
  update: GitHub repo established as source of truth; RELEASE_NOTES.md and
  release.sh workflow added - no code change.)
- **v103**: Head/stem gap fix applied system-wide audit: phillips, carriage,
  button stems moved head_x+6 → head_x+5. Socket/torx/hex/countersunk
  audited, no gap, untouched.
- **v102**: "Robertson head bolt" replaced by "Robertson pan head" and
  "Robertson flat head". Gap fix introduced on Robertson pan.
- **v101**: Robertson head bolt added (square drive, 2.2mm square recess).
- **v100**: Carriage bolt added (solid circle top view - no tool relief).
- **v99 and earlier**: Baseline mature system; history in prior project docs.

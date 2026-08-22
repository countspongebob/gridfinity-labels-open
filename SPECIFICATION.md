# Parts Bin Label Generator - Master Specification
## Version 104

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
- Button head side view positioning is particularly sensitive
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
- Document every version in the changelog (Section 8) with rationale

**Common pitfalls to avoid:**
- Do not change icon module function names
- Do not modify bolt stem positioning without understanding the alignment
  system and the gap-fix rules (Section 5.3)
- Do not simplify the dual custom text field system
  (`custom_display_text` overrides auto-generation; `custom_text_only` is
  used exclusively when hardware_type is "Custom text")

---

## 1. Architecture

The engine is unit-agnostic: all icons, stems, and layout calculations run on
`length_mm` internally. The unit system is a thin input/display layer:

```
[Unit-specific layer]           [Shared core - identical in both files]
thread_spec dropdown       -->  create_single_label()
length input + conversion  -->  label_base(), label_content()
display text generation    -->  render_hardware_icon() + 19 icon modules
multi-label example table  -->  bolt_stem(), render_text()
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

## 3. Hardware Types (19 + Custom text + None)

Dropdown order (identical in both files):
Phillips head bolt, Socket head bolt, Hex head bolt, Button head bolt,
Torx head bolt, Robertson pan head, Robertson flat head, Carriage bolt,
Phillips head countersunk, Torx head countersunk, Socket head countersunk,
Phillips wood screw, Torx wood screw, Wall anchor, Heat set insert,
Standard nut, Lock nut, Standard washer, Spring washer, Custom text, None

## 4. Export & Color (both files)

- export_mode: Complete / Base only / Content only (dual-color workflow:
  base and content export separately for Bambu Studio / MakerWorld)
- base_color default #2C3E50, content_color default #FFFFFF
- Typography: Roboto Bold default, text_size 4.0, Raised/Flush modes

## 5. Icon Geometry Reference

### 5.1 Standard bolt icon pattern
- `head_x = -min(length_mm, max_bolt_length)/2 - 3` (bolts)
- `head_x = -min(length_mm, max_bolt_length)/2 - 2` (countersunk & wood screws)
- Top view (drive pattern) at head_x
- Side view (head profile) at head_x + 3.5 (bolts) or head_x + 4 (countersunk)
- All icon geometry sits at z = label_thickness, extruded text_height

### 5.2 Drive patterns (top view, cut from 5mm circle)
- Phillips: cross, two 0.8mm-wide slots, 4mm span
- Socket / Button: 3mm hex ($fn=6)
- Hex head: solid 5mm hex ($fn=6), no cut
- Torx: 6-spoke star (torx_star, 2.5 size, 0.3 spoke dia)
- Robertson: centered 2.2mm square
- Carriage: NO cut - solid circle (no tool relief)

### 5.3 Head/stem junction rules (gap fix, v102-v103)
A stem must never start at an x-position where the head profile's half-height
is less than the stem half-width (1.25mm), or a visible notch appears.

- Dome side views (Phillips, Carriage, Button, Robertson pan): the half-disc
  spans head_x+3.5 to head_x+6, tapering to a point. Stem MUST start at
  head_x + 5 (dome half-height there = 2.0mm > 1.25mm).
- Rectangular side views (Socket, Torx: 4mm cube; Hex: 3mm cube): stem
  overlaps the rectangle; head_x+6 (socket/torx) and head_x+5.5 (hex) are
  correct as-is.
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
- Multi-label parser example table uses imperial specs

### 6.2 Metric file
- Header: "Parts Bin Label Generator - METRIC" / "ISO Metric Machine Screw Support"
- thread_spec default "M5"; dropdown: M2, M2.5, M3, M4, M5, M6, M8, M10,
  M12, M14
- Length input: `length_input_mm = 16` with `length_mm = length_input_mm`
  (no conversion)
- Display text: `generate_metric_display_text(thread, length) =
  str(thread, " x ", length)` producing standard callouts like "M5 x 16"
- Multi-label parser example table uses metric specs
- Common stocked lengths for reference: 4, 5, 6, 8, 10, 12, 16, 20, 25,
  30, 35, 40, 45, 50 mm

### 6.3 Shared-core exception
In `label_content()`, the fallback text expression differs:
- Imperial: `str(thread, " x ", length_inches, "\"")`
- Metric:   `str(thread, " x ", length_input_mm)`

Nut/washer types display thread spec only (e.g. "1/4-20" / "M5") in both.

## 7. Versioning Rules

- Whole integers only; both files always share the same version number
- A change to the shared core (Sections 3-5) bumps both files and must be
  applied identically to both
- A change to only one unit layer (Section 6) still bumps BOTH files, with
  the unaffected file receiving only the header bump (keeps numbers locked)
- Documentation- or tooling-only changes (spec wording, release notes,
  release.sh) do NOT bump the code version
- Every version gets a changelog entry below and a changes-summary document

## 8. Repository & Release Workflow

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

## 9. Changelog

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

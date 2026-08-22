# Gridfinity Parts Bin Label Generator

Parametric, 3D-printable labels for hardware storage bins, built in
[OpenSCAD](https://openscad.org/). Each label pairs a recognizable hardware
icon (drive pattern + head profile + proportional-length stem) with a clear
text callout like `1/4-20 x 3/4"` or `M5 x 16`, and supports dual-color
printing so the icon and text pop against the label base.

Two ready-to-use generators are included:

| File | System | Threads | Length input |
|---|---|---|---|
| `imperial.scad` | Imperial | 1/4-20 … 1-8, #4-40 … #12-24 | inches (displays as fractions, 1/8"–2") |
| `metric.scad` | ISO Metric | M2 … M14 | millimeters |

Both share an identical core engine — same icons, same layout, same
calibration — and always carry the same version number.

**Print-ready on MakerWorld** (with online customizer):
[Imperial](https://makerworld.com/en/models/1792531-gridfinity-fractional-imperial-label-generator)
· [Metric](https://makerworld.com/en/models/3203391-gridfinity-metric-label-generator)

## Features

- **19 hardware types**: Phillips / socket / hex / button / Torx /
  Robertson (pan & flat) / carriage bolts, countersunk variants, wood
  screws, wall anchors, heat set inserts, nuts (standard & lock), and
  washers (standard & spring) — plus a free-form custom text mode
- **Accurate icons**: each bolt shows its drive pattern (top view), head
  profile (side view), and a stem whose length scales with the actual
  fastener length; extra-long fasteners render with a split stem
- **Three label sizes**: 35.8 mm, 77.8 mm, and 119.8 mm lengths
  (11.5 mm wide), sized for Gridfinity-style bin label slots
- **Dual-color printing**: export the base and the raised content as
  separate STLs (`Base only` / `Content only` modes) for multi-material
  printers or manual filament swaps — tested with Bambu Studio and
  published on MakerWorld
- **Batch mode**: generate a whole grid of labels in one pass with
  print-ready spacing
- **Customizer-friendly**: every option is exposed through OpenSCAD's
  Customizer panel — no code editing required

## Quick start

1. Install [OpenSCAD](https://openscad.org/downloads.html) (2021.01 or later)
2. Open `imperial.scad` or `metric.scad`
3. Open the Customizer (Window → Customizer) and pick your hardware type,
   thread spec, length, and label size
4. Press F6 to render, then F7 to export the STL

For a single-color print, leave `export_mode` on `Complete`. For two
colors, export twice — once with `Base only`, once with `Content only` —
and assign each STL its own filament in your slicer.

## Repository layout

| File | Purpose |
|---|---|
| `imperial.scad` / `metric.scad` | The two generators (unversioned filenames; git tags `vNNN` carry the version) |
| `SPECIFICATION.md` | Master specification — the single source of truth from which both code files are maintained |
| `RELEASE_NOTES.md` | Per-release change history, newest first |
| `release.sh` | Release automation (copies a release bundle into the repo, verifies version headers, commits, tags, pushes) |

## Versioning

Whole-integer versions (`v100`, `v101`, …), tagged in git. The imperial and
metric files are always released together at the same version — see
`SPECIFICATION.md` for the synchronized-versioning rules and
`RELEASE_NOTES.md` for what changed in each release.

## Contributing / modifying

Read `SPECIFICATION.md` first — especially the "Critical Context" section.
This is a mature, print-tested design: icon geometry, head/stem junctions,
and spacing values are deliberately calibrated, and the specification
documents the reasoning so changes can be made safely. Any change to the
shared core must be applied identically to both `.scad` files.

## License

[CC BY-NC-SA 4.0](LICENSE) — free to use, share, and adapt for
non-commercial purposes with attribution; derivatives must carry the same
license.

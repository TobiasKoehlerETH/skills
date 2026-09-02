---
name: kicad-export
description: Run a repeatable KiCad CLI validation and manufacturing-export workflow for a project. Use when ERC/DRC reports, BOMs, Gerbers, drill files, placement files, PDFs, 3D models, or review renders need to be produced.
---

# KiCad Manufacturing Export

Build the output package from the KiCad source files with a project-local
script. Use PowerShell or Python, keep the command order explicit, and write
all generated files under a separate build or release directory.

## Before exporting

1. Identify the project schematic, PCB, variants, output directory, KiCad
   version, and requested manufacturer or downstream format.
2. Read only the relevant command notes in [references](references/). Do not
   rely on remembered flags when the installed KiCad version may differ.
3. Run `kicad-cli version`, then ERC and DRC. Include warnings when the release
   policy requires them, refill zones before DRC when appropriate, and enable
   schematic-parity checks where supported.
4. Stop and report unresolved ERC/DRC violations before manufacturing export.
   Continue only when the user gives an explicit override and the package is
   clearly marked as conditional.

## Typical output set

Select only what the project needs, then verify each file was created:

- ERC and DRC reports in report format with project units.
- Schematic PDF or SVG and a review netlist.
- BOM using the requested preset and field mapping.
- Gerbers for the actual board layers, with DNP treatment matching the release
  policy.
- Excellon drill files with an explicitly chosen origin, units, and zero
  format.
- Placement data in CSV or another requested format, excluding DNP parts when
  required.
- PCB PDF/SVG, STEP, and rendered images when documentation or mechanical
  review calls for them.

The included [convert_position.py](scripts/convert_position.py) converts
KiCad's CSV placement headers to the common five-column placement form
`Designator, Mid X, Mid Y, Layer, Rotation`. Use it only after checking the
source CSV header and the receiving manufacturer's specification.

## Release checks

- Compare output filenames, layer count, units, origin, variants, and DNP
  handling with the release request.
- Open or render representative outputs. Check that PDFs and images are not
  clipped and that fabrication layers align.
- Keep the script, command output, reports, and a short manifest together so
  the package can be reproduced.
- Report exact output paths, tool versions, warnings, overrides, and any
  unverified manufacturer-specific assumptions.

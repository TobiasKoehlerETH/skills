---
name: kicad-bom
description: Resolve and review KiCad BOM items against electrical, mechanical, sourcing, and manufacturing requirements. Use when component metadata, part choices, or a manufacturer-ready BOM needs attention.
---

# KiCad BOM and Part Review

Start with the actual circuit and assembly requirements. Use a configured
parts-data connector or approved datasheet/web research when available; do not
invent stock, pricing, lifecycle, or specification data.

## Part review

- Ask for a missing package size or other constraint when it materially changes
  the result.
- For ceramic capacitors, check dielectric, temperature rating, applied-voltage
  derating, capacitance tolerance, and package size.
- For resistors, check power dissipation, voltage rating, tolerance, and noise
  requirements. Thin-film parts can be appropriate for sensitive analog paths,
  but do not apply that choice blindly.
- For inductors, check value, current rating, saturation current, DCR, losses,
  and footprint availability. Confirm the footprint matches the selected
  part.
- For RF matching networks, prefer suitable high-Q inductors and C0G/NP0
  capacitors unless the design requirements say otherwise.
- For ICs, validate the complete manufacturer part number and all electrical,
  package, thermal, and pin-compatible alternatives. A shortened schematic
  value is not sufficient evidence.

## KiCad data and BOMs

- Store MPN, Manufacturer, and any requested distributor identifiers using the
  project's established field names. Do not create near-duplicate fields when
  the exact fields exist.
- Generate the BOM from the schematic. Change a part number in the schematic,
  not by hand-editing the exported BOM; post-process only for agreed formatting.
- Treat distributor or assembler presets as configuration, not universal
  defaults. Confirm the requested manufacturer, columns, grouping, DNP policy,
  excluded-item policy, units, and delimiter before exporting.
- Preserve source/evidence notes in working data so every selected part can be
  traced back to a requirement or datasheet.

If a required preset or field is missing, report the gap and the exact project
configuration needed. Do not fabricate a manufacturer-ready file from an
unverified schema.

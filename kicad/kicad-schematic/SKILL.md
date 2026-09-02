---
name: kicad-schematic
description: Wire, reorganize, and review KiCad schematics from an existing design brief or component set. Use when schematic correctness, readability, connectivity, or low-level support circuitry needs work; do not use this skill to select exact parts unless that is explicitly requested.
---

# KiCad Schematic Work

Use this skill to turn an existing KiCad schematic into a correct, readable,
reviewable design. Start from the user's electrical intent, supplied
datasheets, and existing symbols.

## Boundaries

- Do not choose exact part numbers during a wiring task unless the user asks
  for part selection. Use a generic symbol or leave a short, visible note for
  an unresolved component.
- Keep every original pin number and pin name unchanged when cleaning up a
  symbol. Verify this deterministically after edits.
- Treat datasheets, reference designs, and project requirements as the source
  of truth. Record assumptions that are not directly supported by them.

## Schematic method

1. Inspect the project, existing symbols, sheets, net labels, and design rules
   before editing. Confirm the intended power domains and signal interfaces.
2. Use net labels for repeated or long-distance connections. Use short wires
   for local relationships such as decoupling, pull resistors, crystals, and
   regulator support parts.
3. Group larger functional blocks in simple labeled rectangles. Keep the
   default section-heading and annotation accent dark red when KiCad colors are
   available; use additional net colors only when they improve electrical
   readability.
4. Prefer a single sheet when the design remains legible. Split into
   hierarchical sheets when repetition, complexity, or the chosen project
   structure warrants it.
5. Keep related passives close to the device they support. Assign sensible
   standard-library footprints to placeholder passives unless the project
   already defines a different convention.
6. Compact excessive whitespace and fix misplaced, rotated, or overlapping
   text. The finished page should be easy to scan at normal zoom.

## Electrical review

Check power entry, rails, grounds, decoupling, pull-ups/pull-downs, clocks,
reset/boot pins, connector signals, and protection/filtering. For regulators,
oscillators, and similar support functions, follow the component's reference
design and operating limits. Consider capacitor DC-bias derating and the
upstream regulator's stability requirements.

## Evidence loop

Do not rely on file inspection alone for a layout-sensitive edit:

- Export a high-resolution schematic image or SVG and inspect the complete
  sheet plus focused views of dense blocks.
- Export a netlist and use it to verify the connections independently of the
  drawing.
- Run ERC when the project supports it. Resolve real violations; document
  intentional exceptions instead of hiding them.
- Repeat the visual and deterministic checks after cleanup. Revisit the whole
  sheet several times if the edit is substantial.

Report unresolved assumptions, intentional liberties, and remaining ERC or
symbol risks briefly at the end.

---
name: kicad-pcb-review
description: Review a KiCad PCB for connectivity, design-rule, visual, and mechanical problems. Use when a board layout needs a focused pre-fabrication review; pair with kicad-gerber-review for generated manufacturing files.
---

# KiCad PCB Review

Review the board from both the KiCad source and rendered evidence. A clean
render is useful evidence, but it does not replace DRC or project-specific
fabrication rules.

## Review sequence

1. Inspect the board, stackup, constraints, net classes, zones, footprints,
   board outline, and any project notes before making changes.
2. Run `kicad-cli pcb drc` with the project's board file. Review errors,
   warnings, exclusions, unconnected items, clearance violations, and
   schematic-parity results. Do not silently waive a violation.
3. Render relevant copper, mask, silkscreen, edge, and assembly layers as SVG
   or images. Check routing continuity, zone fills, via clearances, annular
   rings, plane splits, polarity marks, reference text, and board-edge
   alignment.
4. Render representative 3D views and close-ups. Check component overlap,
   enclosure or keepout interference, connector access, orientation, and
   missing or implausible 3D models.
5. Inspect high-risk regions individually: power conversion, fine-pitch
   devices, RF paths, mounting holes, board edges, connectors, thermal areas,
   and any hand-assembly features.

## Editing rules

- Preserve the user's layer stack, design rules, and footprint choices unless
  the requested change requires otherwise.
- Prefer fixing the source board over editing generated outputs.
- If a check depends on a manufacturer rule not present in the project, state
  the missing rule and ask for it or mark the result as conditional.

Finish with a concise findings list covering confirmed issues, checks passed,
and anything that could not be verified.

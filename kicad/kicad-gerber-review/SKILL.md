---
name: kicad-gerber-review
description: Inspect generated KiCad Gerbers and drill files for fabrication mistakes and obvious layer or alignment problems. Use when manufacturing outputs need visual verification before release.
---

# KiCad Gerber Review

Review the generated manufacturing package, not only the source PCB. Keep any
temporary regeneration in a separate directory so the user's release files are
not overwritten.

## Workflow

1. Locate the Gerbers, drill files, board outline, and any fabrication notes.
   If files are missing, generate a review-only set with `kicad-cli` into a
   separate temporary directory.
2. Render each relevant Gerber layer with a Gerber-capable viewer. `pygerber`
   is suitable when it is already available or can be installed in a project
   virtual environment.
3. Check layer names and polarity, board-edge continuity, copper-to-edge
   clearance, unexpected shorts or islands, via and drill alignment, solder
   mask openings, paste coverage, silkscreen clipping, and mirrored or
   missing layers.
4. Compare the rendered package with the source board and the intended layer
   stack. Confirm that drill units, origin, plated/non-plated intent, and
   fabrication options match the release notes.
5. Record evidence for every concern. A visual pass cannot prove all
   fabrication rules, so also reference DRC results and the manufacturer's
   current capability requirements when available.

Never edit Gerbers to repair a design mistake. Correct the KiCad source and
regenerate the complete package.

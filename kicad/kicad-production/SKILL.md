---
name: kicad-production
description: Export KiCad Gerbers and drill files into production subfolders named after each PCB, with a board-named ZIP and JLCPCB BOM/CPL CSVs for populated boards. Use for Gerber exports, fabrication packages, and JLCPCB production files; clean up all export helpers afterward.
---

# KiCad production export

Use this layout for KiCad Gerber/manufacturing exports unless the user explicitly requests another layout. These packaging and cleanup rules take precedence over generic export guidance that leaves build folders, project-local scripts, manifests, or reports behind. This skill works in both Codex and Claude Code without requiring another skill or plugin.

## Required result

For each selected `.kicad_pcb`, use its exact filename stem as the board name. Create `production` inside the directory containing that PCB, then one subdirectory named after the board:

```text
PCBs/
  controller.kicad_pcb
  adapter.kicad_pcb
  production/
    controller/
      controller-F_Cu.gbr     (actual Gerber names/extensions may differ)
      ...                    (remaining fabrication Gerbers and drill files)
      controller.zip
      controller-BOM.csv     (when there are populated components)
      controller-CPL.csv     (when there are populated components)
    adapter/
      ...
      adapter.zip
```

Keep all loose Gerbers and applicable drill files directly in the board directory, next to the ZIP. Put the BOM and CPL next to the ZIP, outside it. The ZIP contains only that board's fabrication Gerbers and drill files, directly at its root; no enclosing directory, BOM, CPL, helper, source, log, report, or nested ZIP. Do not add date/revision suffixes unless requested. For PCBs in different source directories, create `production` under each corresponding parent rather than inventing a shared root.

## Select and prepare

1. Identify the requested PCB files, matching schematics, assembly variant, and KiCad version. A folder-level request covers the boards directly in that folder; exclude backups, autosaves, lock files, and existing output folders. Recurse only when requested or clearly within scope. Ask only when board selection, variants, or assembly intent cannot be resolved from the request and source.
2. Use `kicad-cli version` and the installed command's `--help` before choosing flags. Prefer the CLI or an already available exporter. Keep the source designs unchanged; work on temporary copies if an operation needs to save/refill/upgrade a board. Include project settings and relative resources when copying a project.
3. Record the existing source/output file inventory and, for Git projects, current status. Create a uniquely named temporary working directory **outside the codebase**, preferably with Python `tempfile.TemporaryDirectory`. Put all per-run scripts, logs, intermediate CSVs, copied designs, validation reports, previews, and staging files there. Arrange cleanup with `try/finally` or an equivalent context manager before starting the export.
4. Check the board outline, enabled copper stack, zones, and DRC; check ERC and schematic/PCB parity when the matching schematic is available. Report unresolved manufacturing-relevant errors; do not call the package ready for manufacture while they remain. Apply any override already given by the user. Missing schematic alone does not prevent PCB fabrication export.

## Export each board

1. Generate into a fresh temporary staging folder, never by zipping an existing production directory. Export every enabled copper layer, front/back masks and silkscreens as applicable, and `Edge.Cuts`. Include paste layers when relevant to assembly/stencils. Do not export unrelated fabrication/user/courtyard/drawing layers by default or repeat the outline on every layer. Preserve copper for DNP components.
2. Generate Excellon drill data for all holes/slots, including plated and non-plated holes and any additional drill spans the board needs. Use millimetres, an explicit consistent origin across Gerber/drill/placement exports, and no accidental mirroring. Inspect actual enabled layers rather than assuming two layers. Do not require a drill file for a genuinely hole-free board.
3. If the board has populated components, generate `<board>-BOM.csv` and `<board>-CPL.csv` following [the JLCPCB assembly rules](references/jlcpcb.md). Respect the selected variant and DNP flags. Bare boards with only mechanical/graphic features need neither CSV. Do not silently treat through-hole-only boards as bare boards.
4. Verify the staged files and construct `<board>.zip` from an explicit list of newly generated Gerber and drill paths, with basenames as archive names. Confirm the ZIP opens, its CRC check passes, and its members exactly match the loose fabrication files by name and contents.
5. Publish the verified files to `production/<board>/`. Preserve the previous usable package until validation succeeds. On reruns, replace the board's previous generated outputs and remove obsolete outputs known to belong to that package, including obsolete BOM/CPL files when the board becomes bare. Preserve unrelated user files and other boards. If ownership of an existing file is unclear, do not delete it automatically. Do not leave backups or staging folders after successful replacement.

## Assembly and fabrication checks

- Verify every actual copper layer and the outline is present; check board dimensions and Gerber/drill alignment with a viewer or temporary render when available.
- Cross-check component designators, counts, values, footprints, populated variant, sides, millimetre coordinates, and rotations against the PCB. Reconcile BOM and CPL reference sets and explain intentional exclusions.
- Check polarity/pin 1 and bottom-side placement conventions. A syntactically valid CPL alone does not prove assembly orientation. Report unresolved part matching or rotation assumptions in the response.
- Do not upload to JLCPCB or place an order unless requested. Preparing these local files does not require another confirmation.

## Mandatory cleanup

**Remove every helper file and folder created for this export after the work, on both success and failure. The codebase must not accumulate export machinery.**

- Delete per-run helper scripts, raw BOM/position files, temporary project copies, DRC/ERC reports, logs, manifests, screenshots, render caches, `__pycache__`, temporary ZIPs, scratch folders, and staging/backup directories created by this run. Keep diagnostics in the conversation instead of leaving report files unless the user requested those deliverables.
- Prefer running installed skill resources in place, with bytecode generation disabled where appropriate; do not copy reusable helpers into the PCB repository. Installed skills and pre-existing project tools are not disposable export helpers.
- Track created paths explicitly. Remove only this run's helpers and known obsolete generated outputs. Never use blanket `git clean`, wildcard source-tree deletion, or recursive deletion of the PCB/project root. On Windows, resolve and check each absolute recursive-deletion target against the owned temporary root before deleting it with native PowerShell or Python.
- On failure, remove partial outputs created by this run and leave an existing valid production package intact. Do not erase existing user files as cleanup. If interruption or file locks prevent cleanup, identify the exact leftovers; do not claim cleanup succeeded.
- Finish by comparing the before/after inventory or Git status: only the requested production outputs (and any separately authorized changes) should remain. Report the board output paths, assembly omissions or unresolved issues, and whether helper cleanup completed.

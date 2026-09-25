# JLCPCB assembly CSV rules

Apply these rules when a PCB contains populated components. Source: JLCPCB's [KiCad BOM and CPL guide](https://jlcpcb.com/help/article/how-to-generate-the-bom-and-centroid-file-from-kicad), checked 2026-09-25. Consult current manufacturer guidance if an uploader rejects the format or assembly conventions change.

## Component population and BOM

Use the PCB to establish which components actually exist on this board, then enrich with matching schematic fields. A schematic can contain other boards, virtual parts, hierarchical instances, or multi-unit symbols: do not blindly export the entire schematic as this PCB's BOM. If there is no schematic, use available PCB footprint properties and report missing purchasing data.

Exclude DNP/DNF parts, unselected variants, and non-component graphics, mounting holes, fiducials, or tooling features. Respect BOM/position exclusion flags and report disagreements; do not silently include a part in one file while omitting it from the other. Preserve through-hole components when in assembly scope; do not use SMD-only filtering without a reason. If manufacturer assembly versus hand assembly is unclear and affects the list, ask rather than silently drop components.

Write UTF-8, comma-separated CSV with proper quoting and this header:

```csv
Comment,Designator,Footprint,JLCPCB Part #
```

- `Comment`: component value or exact manufacturer part description sufficient to identify the part.
- `Designator`: actual PCB references, such as `R1` or a quoted comma-separated list `"R1,R2"`. No ranges such as `R1-R5`. Emit each physical reference exactly once, not once per schematic unit.
- `Footprint`: actual package/footprint, preserving information needed to distinguish sizes and variants.
- `JLCPCB Part #`: the existing JLCPCB/LCSC `C` number. Check fields such as `LCSC Part #`, `LCSC`, `JLCPCB Part #`, and project-specific equivalents. Do not treat a manufacturer's part number as an LCSC number or invent stock codes.

Group only truly interchangeable parts with matching value, footprint, and purchasing identity. Components with different MPNs or LCSC codes must not be merged just because their value matches. When identity is incomplete, separate rows are safer than speculative grouping.

Missing LCSC codes do not justify fabricated data or silently omitted parts. Export the available information with blank codes, list unresolved references in the response, and state that part matching remains incomplete. Ask for a selection only when necessary; generating files does not authorize substituting components.

## CPL / pick and place

Write `<board>-CPL.csv` with exactly one row per component in the intended placement set and this header:

```csv
Designator,Mid X,Mid Y,Rotation,Layer
```

- Coordinates: component placement centre in **millimetres**, decimal point notation; keep precision from the export. Use the same declared origin as Gerbers/drills. Check custom footprint origins against the actual placement centre.
- `Rotation`: numeric degrees, normalized to `[0, 360)`, with JLCPCB-compatible orientation. Review pin 1/polarity, especially ICs, diodes, connectors, and asymmetric footprints. Do not assume a universal angle offset fixes every package.
- `Layer`: normalize front/top/F.Cu to `top`, back/bottom/B.Cu to `bottom`; reject unknown sides.
- Parse CSV with a real CSV parser, not string splitting. KiCad's headers typically include `Ref`, `PosX`, `PosY`, `Rot`, and `Side` (and may also include value/package fields). Explicitly map the required fields and validate numeric data, nonempty references, and uniqueness.
- Preserve the exporter coordinate convention unless a verified conversion is required. Do not apply `--bottom-negate-x`, mirror Y, or negate bottom rotations by habit. KiCad footprint conventions and JLCPCB library orientation can differ; use existing verified per-part corrections when available and disclose unverified orientations.

Use the same population set for BOM and CPL for automatic assembly. Reconcile any exception, such as explicitly designated hand-assembled components, with the user and explain it rather than changing the population silently. If all real components are DNP/excluded, report the empty assembly set instead of inventing placement rows.

## CLI starting points

These flags were checked against KiCad 10.0; inspect the locally installed `--help` before use. Output paths below belong in the run's external temporary directory.

```text
kicad-cli pcb export gerbers --layers <actual-layer-list> --use-drill-file-origin --check-zones --output <staging-dir> <board.kicad_pcb>
kicad-cli pcb export drill --format excellon --drill-origin plot --excellon-units mm --excellon-zeros-format decimal --excellon-separate-th --output <staging-dir> <board.kicad_pcb>
kicad-cli pcb export pos --format csv --units mm --side both --use-drill-file-origin --exclude-dnp --output <raw-position.csv> <board.kicad_pcb>
kicad-cli sch export bom --exclude-dnp --output <raw-bom.csv> <matching.kicad_sch>
```

The default schematic BOM fields do not include purchasing codes: inspect the actual field names and specify `--fields`/`--labels` or read the needed source properties. Export ungrouped data for filtering to the PCB before grouping. In KiCad 10, `--include-excluded-from-bom` is deprecated and has no effect; explicitly verify/filter excluded rows rather than assuming the default command does it. Where supported, apply the same selected `--variant` to Gerber, BOM, and placement commands. Never concatenate multiple variants into the same board-named output; clarify the requested variant if needed.

For PowerShell, use argument arrays or literal strings so `${...}` BOM field identifiers are not expanded by the shell. Use an existing compatible KiCad Python runtime if reading board properties through `pcbnew`; do not assume a general Python installation contains it.

#!/usr/bin/env python3
"""Convert a KiCad CSV placement export to a common five-column format."""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path
from typing import Sequence

REQUIRED_COLUMNS = {"Ref", "PosX", "PosY", "Rot", "Side"}
OUTPUT_COLUMNS = ["Designator", "Mid X", "Mid Y", "Layer", "Rotation"]


def convert_positions(source: Path, destination: Path) -> None:
    """Convert a KiCad placement CSV into a common manufacturing layout."""
    if not source.is_file():
        raise FileNotFoundError(f"Raw placement file was not created: '{source.name}'")

    with source.open(newline="", encoding="utf-8") as src, destination.open(
        "w", newline="", encoding="utf-8"
    ) as dst:
        reader = csv.DictReader(src)
        if reader.fieldnames is None or not REQUIRED_COLUMNS.issubset(reader.fieldnames):
            raise ValueError(
                f"Unexpected placement CSV header in '{source.name}': {reader.fieldnames!r}"
            )

        writer = csv.writer(dst)
        writer.writerow(OUTPUT_COLUMNS)

        for row in reader:
            side = (row["Side"] or "").strip().lower()
            if side in {"top", "front"}:
                layer = "T"
            elif side in {"bottom", "back"}:
                layer = "B"
            else:
                raise ValueError(f"Unexpected placement side for {row['Ref']!r}: {row['Side']!r}")
            writer.writerow([row["Ref"], row["PosX"], row["PosY"], layer, row["Rot"]])


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Convert KiCad's placement CSV to a common five-column format."
    )
    parser.add_argument(
        "source", type=Path, help="KiCad placement CSV, for example build/positions_raw.csv"
    )
    parser.add_argument(
        "destination", type=Path, help="Converted placement CSV, for example build/positions.csv"
    )
    args = parser.parse_args(argv)

    try:
        convert_positions(args.source, args.destination)
    except (OSError, csv.Error, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"Converted placements: {args.destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

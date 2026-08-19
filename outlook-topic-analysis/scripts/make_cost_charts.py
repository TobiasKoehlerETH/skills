#!/usr/bin/env python3
"""Create generic unit-cost and tooling-cost comparison charts from JSON."""

import argparse
import json
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import Patch


ACCENT_RED = "#ed1b2f"
GRID_GRAY = "#d9d9d9"


def load_records(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    return payload["suppliers"] if isinstance(payload, dict) and "suppliers" in payload else payload


def label(record):
    variant = record.get("variant")
    return record["manufacturer"] + (f" - {variant}" if variant else "")


def apply_style(ax, grid=False):
    ax.set_facecolor("white")
    if grid:
        ax.grid(True, axis="y", color=GRID_GRAY, linewidth=0.8)
    else:
        ax.grid(False)
    ax.set_axisbelow(True)
    ax.tick_params(direction="in", length=6, width=1.2, colors="black", labelsize=10)
    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_linewidth(1.2)
        spine.set_color("black")


def unit_cost_chart(records, quantities, output, show_grid=False):
    series = [(label(record), {int(p["quantity"]): float(p["unit_cost_usd"]) for p in record.get("unit_prices", [])}) for record in records]
    series = [(name, values) for name, values in series if any(q in values for q in quantities)]
    if not series:
        return

    fig, ax = plt.subplots(figsize=(8, 8), dpi=160, facecolor="white")
    apply_style(ax, grid=show_grid)
    ax.set_box_aspect(1)
    positions = list(range(len(quantities)))
    width = 0.82 / len(series)
    colors = ["#777777", "#555555", "#999999", ACCENT_RED, "#333333", "#888888"]
    handles = []
    for index, (name, values) in enumerate(series):
        offset = (index - (len(series) - 1) / 2) * width
        heights = [values.get(q, 0) for q in quantities]
        ax.bar([p + offset for p in positions], heights, width=width * 0.92, color=colors[index % len(colors)], edgecolor="black", linewidth=0.7)
        handles.append(Patch(facecolor=colors[index % len(colors)], edgecolor="black", label=name))
    ax.set_xticks(positions, [f"{q:g}" for q in quantities])
    ax.set_xlabel("Quoted quantity [pcs]", fontsize=14, labelpad=10)
    ax.set_ylabel("Unit cost [USD/pc]", fontsize=14, labelpad=12)
    ax.set_title("Unit Cost by Quantity", fontsize=15, fontweight="bold", pad=14)
    ax.legend(handles=handles, loc="upper left", bbox_to_anchor=(0.01, 0.99), fontsize=8, frameon=False, ncol=1)
    fig.savefig(output, dpi=220, facecolor="white", bbox_inches="tight")
    plt.close(fig)


def tooling_cost_chart(records, output, show_grid=False):
    values = [(label(record), record.get("tooling_cost_usd")) for record in records if record.get("tooling_cost_usd") is not None]
    if not values:
        return
    fig, ax = plt.subplots(figsize=(8, 8), dpi=160, facecolor="white")
    apply_style(ax, grid=show_grid)
    ax.set_box_aspect(1)
    positions = list(range(len(values)))
    ax.bar(positions, [value for _, value in values], color="#555555", edgecolor="black", linewidth=0.8)
    ax.set_xticks(positions, [name for name, _ in values], rotation=90, ha="center", va="top")
    ax.tick_params(axis="x", pad=9)
    ax.set_xlabel("Manufacturer", fontsize=14, labelpad=25)
    ax.set_ylabel("Tooling cost [USD]", fontsize=14, labelpad=12)
    ax.set_title("Tooling Cost by Manufacturer", fontsize=15, fontweight="bold", pad=14)
    fig.savefig(output, dpi=220, facecolor="white", bbox_inches="tight")
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--quantities", nargs="+", type=int, default=None)
    parser.add_argument("--grid", action="store_true")
    args = parser.parse_args()
    records = load_records(args.input)
    quantities = args.quantities or sorted({int(p["quantity"]) for r in records for p in r.get("unit_prices", [])})
    args.output_dir.mkdir(parents=True, exist_ok=True)
    unit_cost_chart(records, quantities, args.output_dir / "unit-cost-by-quantity.png", args.grid)
    tooling_cost_chart(records, args.output_dir / "tooling-cost-by-manufacturer.png", args.grid)


if __name__ == "__main__":
    main()

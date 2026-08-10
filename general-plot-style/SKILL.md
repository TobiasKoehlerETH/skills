---
name: general-plot-style
description: Create or restyle Matplotlib plots with a clean, square, mostly monochrome presentation style derived from prompt2. Use when Claude needs to turn arbitrary tabular or array-like data into polished static plots, especially for time series, x-y curves, fitted overlays, or peak-annotated charts, without depending on any fixed input schema.
---

# General Plot Style

Use this skill to apply a consistent plotting style, not to prescribe a specific dataset layout.

## Quick Start

1. Inspect the user request and the available data.
2. Choose the plot types that fit the task instead of forcing the original prompt2 chart set.
3. Build small helper functions so the style is applied consistently across every figure.
4. Save clean static outputs and, when the task is a local desktop script, keep interactive display behavior if the user asked for it.

Read [references/style-guide.md](references/style-guide.md) before writing or revising plotting code.

## Working Rules

- Use Matplotlib as the default plotting library.
- Treat the style as reusable across arbitrary datasets, file formats, and column names.
- Infer axis mappings from the actual task and data instead of assuming fixed fields.
- Keep axis labels extremely short and scientific: prefer `Repeatability [%FS]`, `Mass [g]`, `Time [s]`, `Counts`, `Delta [counts]`, or formulas with standard symbols.
- Always put units in square brackets in axis labels, for example `Weight [g]`, `Time [s]`, `Temperature [°C]`, `Repeatability [%FS]`, or `Δ Counts [counts]`. Use no brackets only for dimensionless labels such as `Counts`, `Index`, or `R²`.
- Use symbols and formulas where they improve precision, such as `Δ`, `μ`, `σ`, `ε`, `y = ax + b`, or `%FS`; avoid conversational labels like "red line is mean deviation".
- In Matplotlib exports, raw Unicode Greek/math symbols can render as `?` with some Windows fonts. Prefer mathtext for symbols, for example `$\\Delta$ Counts [counts]`, `$R^2$`, `$\\hat{c}$`, `$\\mu$`, and `$\\epsilon$`; visually inspect the exported image and replace any `?` glyphs before delivery.
- Preserve user-requested analytics such as peak markers, fitted lines, smoothing, or limits, but render them using the shared style.
- Prefer a small plotting module or a few helper functions over repeating style settings inline.
- Keep the script or notebook easy to tune: expose thresholds, colors, and line widths near the top of the plotting code.

## Recommended Helper Structure

Use helper functions like these when writing a script:

```python
def apply_plot_style(ax):
    ...

def add_title_and_subtitle(fig, ax, title, subtitle=""):
    ...

def save_figure(fig, output_path):
    ...
```

Add task-specific helpers only as needed, such as peak detection, smoothing, interpolation, or fit-report formatting.

## Plot Selection Guidance

- For time-series requests, use a single-axis line plot with time normalized only if that matches the task.
- For comparison or calibration requests, use a single x-y plot and overlay highlights like markers or a fitted line.
- For derived statistics, show them in a subtitle rather than cluttering the legend when practical.
- Avoid dual axes and subplot grids unless the user explicitly needs them.

## Validation

- Visually inspect saved figures when possible.
- Check that titles, subtitles, labels, and ticks are not clipped.
- Check that title and subtitle text never overlap. If a plot has both, reserve a top header band instead of stacking both strings at nearly the same axes coordinate.
- Keep the subtitle very close to the plot. If the subtitle-to-axes gap is larger than the title-to-subtitle gap, tighten the layout before delivery.
- Check that accent elements such as peak markers or fitted lines highlight the intended features.
- Tune spacing, annotation placement, and detection thresholds if the first result is visually noisy or misleading.

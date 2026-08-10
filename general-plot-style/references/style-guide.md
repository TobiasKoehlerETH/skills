# Style Guide

Use these rules to reproduce the plotting look from `prompt2` while staying independent of any specific input schema.

## Figure Defaults

- Create one figure per plot unless the user asks for a dashboard or subplot layout.
- Use `figsize=(7.0, 7.0)`.
- Use figure creation DPI `160`.
- Save PNG outputs at DPI `220` unless the task needs another format.
- Force a square plotting region with `ax.set_box_aspect(1)` for x-y scientific plots.
- Do not force a square axes box for categorical bar charts when it creates a large title/subtitle gap. Use explicit `subplots_adjust(...)` margins instead.

## Typography

Use:

```python
plt.rcParams["font.family"] = ["Segoe UI", "Arial", "sans-serif"]
```

Recommended sizing:

- Title font size `15`
- Title font weight `bold`
- Title/subtitle header band reserved above the axes
- Axis label font size `14`
- Tick label size `11`
- Subtitle slightly smaller than the title

## Scientific Text

Axis labels must be extremely short. Use the measured quantity plus units in brackets:

- `Repeatability [%FS]`
- `Weight [g]`
- `Time [s]`
- `Counts`
- `Δ Counts [counts]`
- `Error [g]`

Always use square brackets for units in axis labels. Examples: `Weight [g]`, `Time [s]`, `Temperature [°C]`, `Repeatability [%FS]`, and `Δ Counts [counts]`. Use no brackets only for dimensionless labels such as `Counts`, `Index`, or `R²`.

Use scientific notation, standard symbols, and formulas where they make the plot more precise:

- Prefer `Δ`, `μ`, `σ`, `ε`, `R²`, `%FS`, and `y = ax + b` over long descriptive phrases.
- Prefer subtitles such as `μ = 0.042 %FS, σ = 0.016 %FS` or `Δc = 410.73 m - 832.25, R² = 0.99875`.
- Prefer legends such as `μ`, `fit`, `stable`, `1 g`, or `20 g`.
- Avoid conversational wording such as `red line is mean deviation`, `counts over time`, or `displayed weight in grams`.
- Do not put method explanations in axis labels. Put compact methods in the subtitle or a caption-like summary file.
- For Greek letters, superscripts, hats, subscripts, and symbols in Matplotlib output, prefer mathtext strings such as `$\\Delta$ Counts [counts]`, `$R^2$`, `$\\hat{c}$`, `$\\mu$`, and `$\\epsilon$`. Visually inspect exports; if a glyph renders as `?`, replace it with mathtext or a plain ASCII fallback before delivery.

## Colors

- Figure background: white
- Axes background: white
- Main line color: black
- Accent color: `#ed1b2f`
- Grid color: `#d9d9d9`
- Spine, ticks, and labels: black

Reserve the accent red for meaningful overlays such as:

- Peak markers
- Fitted lines
- One highlighted reference curve

Do not use the accent color for everything.

## Axes and Grid

Apply these defaults in `apply_plot_style(ax)`:

```python
ax.set_facecolor("white")
ax.grid(True, color="#d9d9d9", linewidth=0.8)
ax.set_axisbelow(True)
ax.tick_params(
    direction="in",
    length=6,
    width=1.2,
    colors="black",
    labelsize=11,
)
for spine in ax.spines.values():
    spine.set_visible(True)
    spine.set_linewidth(1.2)
    spine.set_color("black")
```

## Lines and Markers

- Use black for the main data line.
- Use line width around `1.8` to `2.2`.
- Use `solid_capstyle="round"` for primary lines.
- Avoid point markers on dense data lines unless they encode something meaningful.
- Use `marker="v"` for peak markers when a downward triangle is visually appropriate.
- Use the accent red for fitted overlays and highlight markers.

Example:

```python
ax.plot(x, y, color="black", linewidth=2.0, solid_capstyle="round")
ax.plot(x_peak, y_peak, linestyle="none", marker="v", color="#ed1b2f", markersize=6)
```

## Titles and Subtitles

Give each plot one main title and optionally one subtitle.

Recommended pattern:

```python
def add_title_and_subtitle(fig, ax, title, subtitle=""):
    fig.tight_layout(rect=(0.04, 0.04, 0.98, 0.82 if subtitle else 0.86))
    axes_top = ax.get_position().y1
    subtitle_y = axes_top + 0.025
    title_y = subtitle_y + 0.045 if subtitle else axes_top + 0.04
    fig.suptitle(title, x=0.5, y=title_y, fontsize=15, fontweight="bold", ha="center")
    if subtitle:
        fig.text(0.5, subtitle_y, subtitle, ha="center", va="top", fontsize=11, color="black")
```

Do not place subtitle text at `y=1.0` to `1.03` in axes coordinates while also using `ax.set_title`; those two text systems can collide once the title, font, DPI, or export size changes. Use a compact figure-level title/subtitle band with about `0.03` to `0.04` normalized figure units between title and subtitle baselines. Keep the axes very close to the subtitle by placing title/subtitle from the final `ax.get_position().y1` after layout. A subtitle-to-plot gap larger than the title-to-subtitle gap is a layout bug to fix before delivery.

Use subtitles for compact metrics such as:

- Peak mean and standard deviation
- Fit slope, intercept, and RMSE
- Smoothing or preprocessing notes when the user should see them

## Layout

- Keep margins balanced.
- Call `fig.tight_layout(rect=...)` before saving when a figure-level title or subtitle is present.
- Do not call a later plain `fig.tight_layout()` after adding figure-level title/subtitle text, because it can remove the reserved header space.
- Reserve enough top margin for every title/subtitle pair without creating a tall empty band. For the default square figure, start with a top rect of about `0.82` when both are present and `0.86` with only a title, then place the text relative to the actual axes top.
- If title and subtitle still crowd the canvas, first wrap/shorten the subtitle or slightly reduce font size. Lower the axes top only as much as needed; never accept overlapping title text or a large blank gap between subtitle and plot.
- If the subtitle-to-axes gap is visibly larger than the title-to-subtitle gap, move the title/subtitle downward and the axes upward before delivery. For categorical bar charts, prefer `fig.subplots_adjust(top=...)` or a tighter `tight_layout(rect=...)`; do not rely on a large reserved header band.

## Data Independence Rules

- Do not assume fixed column names from prompt2.
- Map columns from the actual data source and request.
- Keep any normalization, smoothing, interpolation, or peak detection logic task-specific and explicit.
- If the user asks for analytics, expose the tuneable parameters near the top of the script.

## Minimal Reusable Skeleton

```python
import matplotlib.pyplot as plt

ACCENT_RED = "#ed1b2f"
GRID_GRAY = "#d9d9d9"


def apply_plot_style(ax):
    ax.set_box_aspect(1)
    ax.set_facecolor("white")
    ax.grid(True, color=GRID_GRAY, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.tick_params(direction="in", length=6, width=1.2, colors="black", labelsize=11)
    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_linewidth(1.2)
        spine.set_color("black")


def add_title_and_subtitle(fig, ax, title, subtitle=""):
    fig.tight_layout(rect=(0.04, 0.04, 0.98, 0.82 if subtitle else 0.86))
    axes_top = ax.get_position().y1
    subtitle_y = axes_top + 0.025
    title_y = subtitle_y + 0.045 if subtitle else axes_top + 0.04
    fig.suptitle(title, x=0.5, y=title_y, fontsize=15, fontweight="bold", ha="center")
    if subtitle:
        fig.text(0.5, subtitle_y, subtitle, ha="center", va="top", fontsize=11, color="black")


def make_figure():
    fig, ax = plt.subplots(figsize=(7.0, 7.0), dpi=160)
    apply_plot_style(ax)
    return fig, ax
```

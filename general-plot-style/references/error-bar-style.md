# Error-Bar Comparison Plot Style

Use this pattern for repeated sensor measurements taken at discrete reference
weights, setpoints, or calibration points. It is a sample style, not a fixed
axis policy: choose the visible groups, scale, and statistic to match the
request and the data.

## Visual pattern

- Plot each repeated reading at the exact x-coordinate of its reference
  weight. Do not add horizontal jitter when vertical alignment communicates
  repeatability.
- Use evenly spaced categorical x-positions when the primary purpose is to
  compare groups. Use numeric x-values when physical spacing or a calibration
  fit is part of the interpretation.
- For a compact accuracy plot, show one filled black marker per group at the
  group mean and black sample-standard-deviation error bars.
- Keep uncertainty bars visually light: `elinewidth` and `capthick` around
  `1.0–1.2`, with a wider `capsize` around `7–9` points. A marker size around
  `4–6` points keeps the mean visible without dominating the bars.
- Use a thin dashed gray horizontal zero-error line. Add major horizontal grid
  lines so small deviations can be read against the y-axis.
- If the user specifies an accuracy window, set symmetric y-limits around
  zero (for example, `[-2, 2] %FS`) and use matching major ticks. Do not infer
  an acceptance limit from the data.
- Keep the subtitle concise. Good examples are `n = 10` or
  `n = 10 per reference weight`; add a requested summary metric only when it
  improves interpretation.

## Statistics and definitions

Use the sample standard deviation for repeated measurements:

```python
mean = group.mean()
sd = group.std(ddof=1)
```

For signed full-scale accuracy error, use:

```python
error_pct_fs = (sensor_output - reference_weight) / fs_g * 100.0
```

Preserve the sign unless the user asks for absolute error. State the sign
convention in a subtitle or caption when it is not obvious from the request.

For a repeatability/calibration plot with a fitted line, fit the group means
when all groups have equal sample counts. A compact non-linearity metric is the
maximum absolute mean residual from the fitted line, normalized by full scale:

```python
x = np.asarray(reference_weights, dtype=float)
y = group_means.to_numpy()
slope, intercept = np.polyfit(x, y, 1)
residuals = y - (slope * x + intercept)
nonlinearity_pct_fs = np.max(np.abs(residuals)) / fs_g * 100.0
```

When a numeric x-axis is used, draw the fit as a thin dashed gray line from
zero to the maximum plotted output:

```python
fit_x = np.array([0.0, max_output], dtype=float)
ax.plot(
    fit_x,
    slope * fit_x + intercept,
    color="#8c8c8c",
    linewidth=1.4,
    linestyle=(0, (4, 3)),
    label="linear fit",
)
```

## Reusable error-bar snippet

This produces the mean marker and SD bars used by the sample accuracy plot:

```python
ax.axhline(
    0.0,
    color="#8c8c8c",
    linewidth=1.1,
    linestyle=(0, (4, 3)),
    label="zero error",
)
ax.errorbar(
    x_positions,
    means,
    yerr=standard_deviations,
    fmt="o",
    color="black",
    ecolor="black",
    elinewidth=1.1,
    capsize=8,
    capthick=1.1,
    markersize=5,
    markerfacecolor="black",
    markeredgewidth=1.1,
    label=r"mean $\pm$ SD",
    zorder=3,
)
ax.set_ylim(-2.0, 2.0)  # only when this accuracy window is requested
ax.set_yticks([-2.0, -1.0, 0.0, 1.0, 2.0])
ax.grid(True, axis="y", color="#d9d9d9", linewidth=0.9)
```

Do not add a mean/SD overlay to a raw repeatability plot when the requested
view is specifically the individual readings. Keep the fit and summary metric
separate from the raw observations so the distribution remains inspectable.

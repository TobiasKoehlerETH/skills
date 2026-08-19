# Generic normalized data schema

The chart helper accepts a JSON object with a `suppliers` array, or a bare array. Each item may contain:

```json
{
  "manufacturer": "Manufacturer A",
  "variant": "general packing",
  "country": "China",
  "website": "https://example.com",
  "tooling_cost_usd": 2400.0,
  "unit_prices": [
    {"quantity": 100000, "unit_cost_usd": 0.028},
    {"quantity": 500000, "unit_cost_usd": 0.027}
  ]
}
```

Rules:

- `manufacturer` is required for chart labels.
- `variant` is optional and is appended to the chart label when present.
- `tooling_cost_usd` is the canonical tooling/setup value used in the tooling chart. Put secondary tooling values in a separate variant record or document them in the report table.
- `unit_prices` contains only observed quantity/unit-cost pairs. Do not add interpolated quantities.
- Use `null` for missing values in machine data and `-` only when writing human-facing Markdown or a user-requested text table.
- Keep original currency, date, and source fields in a private extraction layer even if this compact chart schema uses normalized USD values.

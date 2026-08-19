# Worked example: tooling cost and series unit cost

This example models a supplier offer comparison for a low-height SMD contact spring. It demonstrates two outputs:

1. A grouped unit-cost chart for requested series quantities such as 100k and 500k units.
2. A separate tooling-cost comparison by manufacturer.

Example normalized records:

```json
[
  {
    "manufacturer": "Manufacturer A",
    "tooling_cost_usd": 2800,
    "unit_prices": [
      {"quantity": 30000, "unit_cost_usd": 0.10},
      {"quantity": 100000, "unit_cost_usd": 0.08}
    ]
  },
  {
    "manufacturer": "Manufacturer D",
    "variant": "general format",
    "tooling_cost_usd": 2420,
    "unit_prices": [
      {"quantity": 100000, "unit_cost_usd": 0.028},
      {"quantity": 500000, "unit_cost_usd": 0.027}
    ]
  },
  {
    "manufacturer": "Manufacturer D",
    "variant": "packaging variant",
    "tooling_cost_usd": 2420,
    "unit_prices": [
      {"quantity": 100000, "unit_cost_usd": 0.042},
      {"quantity": 500000, "unit_cost_usd": 0.038}
    ]
  },
  {
    "manufacturer": "Manufacturer E",
    "tooling_cost_usd": 2267,
    "unit_prices": [
      {"quantity": 100000, "unit_cost_usd": 0.0486},
      {"quantity": 500000, "unit_cost_usd": 0.0463}
    ]
  }
]
```

For a final report, keep tooling/setup, prototype/sample, production unit cost, packaging, freight, PPAP, and lead time in distinct fields. A tooling quote in EUR must be converted with a stated rate before it is compared with USD offers.

Run the chart helper with:

```bash
python scripts/make_cost_charts.py \
  --input example-tooling-costs.json \
  --output-dir output \
  --quantities 100000 500000
```

The output filenames are `unit-cost-by-quantity.png` and `tooling-cost-by-manufacturer.png`.

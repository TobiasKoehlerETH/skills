# Attachment review routing

Inspect the actual offer or source document whenever a message refers to an attachment.

- PDF: use the PDF skill; extract text for values and render pages for visual confirmation. Record page/table context in private working notes.
- Image: visually inspect at native resolution. Use OCR only as an aid; verify prices, decimals, units, and currency against the image.
- DOCX: use the documents skill and render when layout or tables carry meaning.
- XLSX/CSV: use the spreadsheets skill; preserve typed values and inspect relevant ranges.
- Other formats: inspect safely with an appropriate parser or record `-` if the value cannot be verified.

For each extracted number, retain a private provenance record:

```json
{
  "field": "unit_cost_usd",
  "value": 0.0427,
  "original_value": 0.037,
  "original_currency": "EUR",
  "conversion_rate": 1.1567,
  "source_attachment": "quotation.pdf",
  "source_location": "page 1 / pricing table",
  "confidence": "high"
}
```

If an email contradicts an attachment, prefer the dated formal quotation for price fields and flag the conflict for review. Do not silently merge prototype, production, packaging, tooling, freight, PPAP, and sample costs.

---
name: outlook-topic-analysis
description: "Search Outlook Inbox and Sent Items for a topic, inspect matching attachments, and produce a verified Markdown report, data table, and comparison charts."
---

# Outlook Topic Analysis

Use this skill when a user wants a reusable research pass over Outlook mail—such as finding all supplier offers, extracting prices from attached PDFs, comparing companies, or building a topic-specific report from received and sent correspondence.

The skill is topic-agnostic. The user supplies a topic, keywords, date/folder scope, and desired output location. A tooling-cost/unit-price comparison is the bundled worked example, not a restriction on other domains.

## Operating contract

- Search both received and sent mail when the user asks for all contacts, suppliers, quotes, or correspondence. Sent mail is essential for contacts that have not replied yet.
- Search newest-first, but retain older messages in the same conversation when they contain the offer, attachment, or context needed to interpret a newer follow-up.
- Use the Outlook access adapter in [outlook-access.md](references/outlook-access.md) and the bundled compatibility contract in [outlook-inbox-autopilot-bundle.md](references/outlook-inbox-autopilot-bundle.md). It is deliberately read-only: do not move mail, create drafts, send mail, delete mail, or change mailbox state.
- Search with the user's keywords plus topic synonyms. Record the exact search terms and scan scope in the working notes, not necessarily in the final report.
- Deduplicate by company/entity and conversation. Keep the newest quote for current values while retaining older values when they explain a change or remain commercially relevant.
- Inspect relevant attachments, not just message previews. Route PDFs through the PDF workflow, images through visual inspection/OCR as needed, and DOCX/XLSX through the appropriate document or spreadsheet workflow. See [attachment-review.md](references/attachment-review.md).
- Never invent a price, country, website, lead time, currency rate, or company identity. Use `-` in Markdown for missing values and document uncertainty when an identity is inferred.
- Normalize money to the user's requested currency using an explicit dated rate. Preserve original currency and conversion rate in working data so every converted number is auditable.
- Keep source/evidence fields in the internal extraction data even when the user asks to omit evidence columns from the final table.

## Workflow

1. Define the topic schema before extracting. Start with `entity/manufacturer`, `country`, `website`, `tooling/setup cost`, `sample/prototype cost`, `quantity`, `unit cost`, `lead time`, `currency`, `message date`, `attachment`, and `source message ID`. Add topic-specific fields only when the correspondence supports them.
2. Search Inbox, Sent Items, and any explicitly requested folders. Hydrate full bodies for promising matches and collect attachment names, dates, senders/recipients, and conversation IDs.
3. Build a candidate entity list from both sender/recipient identities and attachment content. Resolve aliases and domains before adding a new row.
4. Extract offer values from each attachment and reconcile them with the email body. Prefer the latest valid offer for the main row; retain competing variants as separate series or clearly labeled cells.
5. Enrich missing public company country/website only when requested or necessary to complete the requested columns. Use the official company website or web search, and distinguish verified from inferred values in working notes.
6. Produce the Markdown report, sorted by entity name unless the user specifies another order. Use typed/precise values, consistent currency, and `-` for missing values.
7. Produce a chart only from actual numeric observations. For quantity pricing, use the quantity/unit-cost mapping requested by the user; do not interpolate or estimate missing quantities. For tooling comparisons, use a clearly defined canonical tooling value and show variants separately when needed.
8. If an XLSX is requested, create a compact, user-editable workbook from the extracted data. Keep numbers typed as numbers, use formulas for derived totals, format currencies and quantities, freeze the header, and visually render the workbook before delivery.
9. Verify the report, charts, and workbook against the extracted rows and count. Re-open/render final artifacts, check for clipped labels, and copy only user-facing deliverables to the requested destination.

## Output conventions

Recommended deliverables:

- `<topic>-comparison.md`: normalized table plus concise methodology and embedded chart links.
- `<topic>-unit-cost-by-quantity.png`: unit-cost comparison at requested quantities.
- `<topic>-tooling-cost-by-manufacturer.png`: tooling/setup comparison by entity.
- `<topic>-data.xlsx`: typed extraction table when requested.

Use the scripts in `scripts/` when the input has been normalized to the generic JSON schema in [data-schema.md](references/data-schema.md). Read [tooling-cost-example.md](references/tooling-cost-example.md) when the topic resembles supplier tooling and series pricing.

## Safety and privacy

Mailbox access is read-only. Do not send replies or expose full confidential email bodies in a public report. Keep source IDs and attachment paths in private working data unless the user explicitly requests them. Do not upload mailbox content, attachments, or generated reports to a public remote unless the user explicitly authorizes that exact upload.

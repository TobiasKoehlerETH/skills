# Outlook access and the bundled Outlook skill

This skill composes with `Outlook Inbox Autopilot` when that skill and its Outlook connector are available. Reuse its read/search primitives (`query emails`, `get message`, and cross-folder search), but do not use its triage, move, draft, or send actions for topic analysis.

If the connector is unavailable and Outlook desktop is running, a read-only Outlook COM fallback can inspect:

- Inbox: default folder `6`, sorted by `ReceivedTime` descending.
- Sent Items: default folder `5`, sorted by `SentOn` descending.
- Message fields: subject, sender/recipients, dates, body, conversation ID when available, and attachment names.

Search the newest messages first, then hydrate the relevant thread or message. For sent messages, use recipients and domains to discover contacted entities that have not replied. Do not save credentials, alter read/unread state, move messages, create drafts, or send mail.

## Search template

Build a broad query from:

```text
<topic> OR <primary keyword> OR <synonym 1> OR <synonym 2>
```

Then inspect the full body and attachments for matches. Keep a private scan ledger with:

```json
{
  "folder": "Inbox|Sent Items|other",
  "message_id": "local-or-connector-id",
  "conversation_id": "optional",
  "date": "ISO-8601",
  "counterparty": "sender or recipient",
  "subject": "subject",
  "attachments": ["file.pdf"]
}
```

The ledger is for deduplication and audit. Do not paste full message bodies into the final report unless explicitly requested.

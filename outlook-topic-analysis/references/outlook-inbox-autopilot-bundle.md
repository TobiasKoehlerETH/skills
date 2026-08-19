# Bundled Outlook Inbox Autopilot compatibility

This reference is the bundled compatibility layer for the available `Outlook Inbox Autopilot` skill. It reuses the mailbox-search concepts exposed by that skill without inheriting its triage objective.

## Read-only operations used here

- Query or search Inbox, Sent Items, and explicitly requested folders.
- Hydrate a message when the preview does not contain the relevant content.
- Read sender/recipient, dates, conversation IDs, body text, and attachment metadata.
- Save an attachment to a temporary working directory for inspection.

## Operations intentionally not used

- Moving messages to triage folders.
- Creating replies or drafts.
- Sending messages.
- Deleting, marking read/unread, or changing categories.
- Sending Telegram or other external summaries containing mailbox content.

The topic-analysis skill is a research/extraction workflow, not an inbox-triage workflow. If both skills are available, load this skill after Outlook access is established and keep the mailbox unchanged throughout the analysis.

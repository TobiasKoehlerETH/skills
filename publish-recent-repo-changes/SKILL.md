---
name: publish-recent-repo-changes
description: Recursively inspect Git repositories below a user-specified folder, determine remote visibility, review proposed changes for information that must be neutralized before public release, and—only after explicit user confirmation at the end of a workday—create a new commit and push approved changes to the configured remote. Use for scheduled end-of-day repository reviews or requests to commit and publish recent local work.
---

# Publish Recent Repo Changes

Review and publish recent local Git changes from every repository below a user-specified root folder. The workflow is confirmation-first: inspect and report at the end of the workday, then commit and push only the repositories and changes the user explicitly approves.

## Workflow

### 1. Discover and filter repositories

- Ask for or use the folder path supplied by the user as the scope root. Recursively inspect all subfolders for Git repositories, while avoiding duplicate nested paths inside an already discovered repository.
- Do not modify anything during discovery.
- A repository qualifies when its working-tree files or local commits show activity during the requested lookback window. If no lookback is supplied, use the last seven days as the default. Do not count `.git` internals alone as user activity.
- Use the user's local timezone and the current date for the lookback cutoff. If the cutoff or repository activity is ambiguous, include the repository and explain why.

### 2. Inspect each qualifying repository

For every qualifying repository, collect:

- Absolute repository path.
- Current branch and configured remotes.
- Whether the repository is public, private, or unverifiable on its hosting provider. Use an authoritative provider CLI/API when available (for example, GitHub repository metadata), and record the evidence or explain why visibility could not be checked. Treat unverifiable visibility as potentially public for the privacy review.
- Uncommitted changes from `git status --short`.
- Whether the local branch is ahead of or behind its upstream, when an upstream exists.
- Recent local commit information and a concise diff/stat summary.
- Any untracked files, likely secrets, generated artifacts, or unusually large files that should not be staged automatically.

For every repository that may be published, review the exact outgoing content before requesting approval. For a public repository, this is a mandatory release gate; perform the same review for private repositories as a precaution. Inspect the working-tree diff, proposed staged diff, unpushed commits, and relevant untracked files. Check whether any content names or reveals:

- prices, costs, rates, margins, discounts, or other commercial figures;
- manufacturers or suppliers;
- internal processes, workflows, operational procedures, or other non-public methods; or
- customer company names or details that identify a customer.

Treat matches as neutralization candidates, not as permission to publish them. For each candidate, report the file and context, category, exposure risk, and a proposed generic replacement (for example, a role-based name, range, or abstracted process). Neutralize the content narrowly if the user approves that edit, then re-review the resulting diff. Do not stage or publish a public repository while a candidate is unresolved. If the user explicitly confirms that a candidate is safe to retain, include that exception in the approval summary. Never expose secrets or credentials; remove them from the proposed scope and report them separately.

Before asking for approval, present a compact per-repository summary and the exact proposed commit scope. Do not claim that tests passed unless tests were actually run.

### 3. Ask for confirmation

Always ask the user at the scheduled run time, even when there is nothing to publish. When there are changes, ask for explicit approval naming the repositories and files to be included, the verified visibility, and the outcome of the neutralization review. Do not interpret silence, a vague acknowledgement, or a request to review as approval. If visibility is unverifiable or a public-repository neutralization candidate remains unresolved, stop and request clarification rather than asking for publish approval as if the gate had passed.

Do not create commits, stage files, push, alter remotes, change branches, or otherwise mutate repository state before explicit approval. If the user approves only selected repositories, process only those repositories.

### 4. Commit and push after approval

For each approved repository:

1. Re-run discovery and `git status` immediately before staging so new edits are not silently included.
2. Re-check the selected remote's visibility and review the exact content that would be committed or pushed, including unpushed commits and approved untracked files. Repeat the neutralization check above; a newly public or newly exposed repository must pass the public-repository gate at this point.
3. If a candidate needs neutralization and the user has approved the replacement, apply only that narrowly scoped edit and review the diff again. If it is unresolved, stop without staging.
4. Stage only the approved files. Do not use a broad `git add -A` when it could include unrelated, sensitive, generated, or unreviewed files.
5. Show or verify the staged file list and diff summary, including confirmation that the neutralization review passed.
6. Create one new commit with a concise, descriptive message based on the actual changes. Do not amend existing commits.
7. Push only to a configured remote for the approved branch. If there are multiple remotes, no suitable remote, a detached HEAD, or no upstream branch, stop and ask which destination or branch to use. When the user specifically requests GitHub, verify that the selected remote points to GitHub.
8. Never force-push, delete branches, rewrite history, alter remotes, or use credential values in output.
9. Verify the result with local status and push output, then report the commit hash, repository, branch, remote, visibility, neutralization-review outcome, and any remaining changes.

If a commit or push fails, preserve the repository state, report the exact safe error summary, and do not retry with a destructive or history-rewriting option.

## Scheduled-task use

When this workflow is attached to a recurring task, run it at the user's stated end-of-workday time and in the user's local timezone. If no time is supplied, ask for it before creating the schedule. The scheduled prompt should recursively inspect the specified root folder and ask whether to proceed; it must not promise or perform an automatic commit or push without the user's explicit response.

## Completion criteria

Consider the workflow complete only after one of these outcomes:

- The user declines or does not approve, and no repository state changed.
- The approved repositories were committed and pushed successfully, with verification reported.
- A repository was safely skipped because its destination, branch, files, or credentials required clarification.

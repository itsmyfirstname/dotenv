---
description: Create a GitHub issue from a user summary, drafted in ASD-STE100
argument-hint: "<repo-URL-or-owner/name>"
---
Create a GitHub issue in the repository: $1

Work through these steps in order. Do not publish until the user approves the draft.

## Step 1 — Verify the repo

Derive `owner/name` from $1 (strip the `https://github.com/` host if present).
Run `gh repo view <owner/name> --json nameWithOwner`.
If this fails, stop and tell the user the repo is not reachable. Do not continue.

## Step 2 — Collect the summary

Ask the user for a summary of the issue. If they have not already given one, ask:

> "Give me a short summary of the issue: what is wrong or missing, and what
> should be true when it is fixed?"

## Step 3 — Fill the gaps

The issue needs three things: a clear summary, a scope (in / out), and
verifiable acceptance criteria. Compare the user's summary against the issue
template below.

- For each section you cannot write from what the user provided, ask a short
  question about the missing piece. Batch all questions into one message.
- Never invent facts to fill a gap. If the user cannot answer a gap, write
  "Open — needs decision" in that section instead of guessing.

## Step 4 — Draft

Write the issue body using the template below. Apply the ASD-STE100 rules to
every sentence. Also propose a title: one line, plain words, no ending
punctuation.

Show the user the complete draft (title + body) and ask for approval.
If the user requests changes, revise and show the new draft. Repeat until
the user approves.

## Step 5 — Publish

Once the user approves:

1. Write the approved body to a temp file (e.g. `/tmp/issue-body.md`).
2. Publish:
   ```bash
   gh issue create --repo <owner/name> --title "..." --body-file /tmp/issue-body.md
   ```
3. Report the issue URL to the user.

## Issue template

```markdown
## Summary

<!-- Two to four sentences. What is wrong or missing, and what should be
     true when it is fixed. One idea per sentence. -->

## Scope

### In Scope

<!-- Bullets. What this issue covers. One bullet per item. -->

### Out of Scope

<!-- Bullets. What this issue does NOT cover, so reviewers and implementers
     do not expand the work. Write "None" if there is nothing to exclude. -->

## Acceptance Criteria

<!-- Checkboxes. Each item states a result and how to check it.
     Example: "- [ ] Running `uv run pytest tests/test_workouts.py` passes."
     Every item must be verifiable by a person or a command. -->

## References

- <!-- Related issues, PRs, or docs, if any. Omit this section if there are none. -->
```

## ASD-STE100 rules (apply to every sentence of the draft)

- One idea per sentence. One action per sentence.
- Active voice. Subject-Verb-Object order.
- Short sentences (about 25 words or fewer).
- Use the STE approved word list (https://www.asd-ste100.org/): simple,
  one-meaning words. Never use a word with multiple meanings.
- No contractions. No idioms, metaphors, slang, jargon, or humor.
- No vague or hedging words (very, quite, rather, a bit, etc.).
- Present tense for desired end state. Past tense for completed actions.
- Spell out numbers one through nine. Use numerals for 10 and above.
  Always use a numeral with a unit of measure.
- Be concrete: name the real files, commands, endpoints, and values. No filler.

## Self-check before showing the draft

Re-read every sentence against the rules above. Check that each acceptance
criterion is verifiable. Fix any violation. Then show the corrected draft.

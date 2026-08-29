---
description: Local-only PR review — report critical/high bugs and vulnerabilities to the terminal only
argument-hint: "<PR-URL>"
---
Perform a **local-only** review of the pull request at: $1

Hard constraints for the entire task:
- **Read-only.** Never edit, create, or delete any file. Never commit, push,
  merge, or post anything to GitHub.
- **The gh CLI is the only tool for talking to GitHub**, and only read
  subcommands are allowed: `gh pr view`, `gh pr diff`, `gh pr checks`,
  `gh run list`, `gh run view`, `gh repo view`, and `gh api <GET route>`
  (no `-X POST/PUT/PATCH/DELETE`, no `-f`/`-F` fields). Forbidden: `gh pr
  merge`, `gh pr close`, `gh pr comment`, `gh pr review`, `gh pr edit`,
  `gh pr update-branch`, `gh issue` writes, `gh release` writes, and any
  other gh command that mutates state. No curl or web requests to
  GitHub.
- **Local git** is the workbench: read commands plus exactly one fetch of
  the PR ref (step 2). Do not check out, commit, rebase, or otherwise touch
  the user's current branch or working tree.
- **Output goes to the terminal only** (your reply). The report is never
  posted, commented, or saved.

## Step 1 — Validate the URL and resolve the PR

$1 must be a full http(s) URL to a pull request. If it is missing or not a
PR URL, stop and ask the user for the full PR URL. Do not guess a repo.

Run `gh pr view <url> --json number,title,state,baseRefName,headRefName,headRefOid,additions,deletions,files`.
If this fails, stop and report the error. Record: PR number, title, state,
base branch, head OID.

## Step 2 — Bring the PR head into local git (the only allowed mutation)

From the repository the URL points at:

```bash
git fetch origin pull/<number>/head:pr-review-<number>
git merge-base origin/<baseRefName> pr-review-<number>
```

Pin the review to the fetched head OID and the merge-base. Every line
reference in the report must be valid against those two refs.

## Step 3 — Review the diff locally

- `git diff <merge-base>...pr-review-<number> --stat`, then per-file diffs.
- Read whole files where a hunk needs surrounding context. Search freely
  (rg/grep) across the repo at the PR head.
- You may run the project's existing test suite or type checker to confirm a
  suspected finding. Never modify code to test a theory.

Hunt, in this order:
1. **Security** — authn/authz gaps, injection, secrets in code or logs,
   missing input validation, unsafe deserialization, SSRF/path traversal.
2. **Correctness** — logic errors, state corruption, error handling that
   swallows or misreports failures, races on shared state.
3. **Data integrity** — non-transactional multi-statement writes, constraint
   violations, migration mismatches.
4. **Contract breaks** — changed response shapes or status codes that break
   existing clients.

## Step 4 — Severity gate (critical and high only)

Report a finding **only** if it is critical or high:

- **Critical** — actively exploitable vulnerability (auth bypass, injection,
  RCE, secret exposure), silent data loss or corruption, or a guaranteed
  crash of a primary flow.
- **High** — wrong behavior in a primary flow under realistic conditions, a
  security weakness with high impact behind a specific condition, a broken
  API contract, or a race that corrupts shared state.

Every finding must state a **concrete trigger** — the inputs or steps that
reproduce it. If you cannot state a trigger, the finding does not meet the
bar. Drop it. Do not report style, naming, performance nits, missing tests,
speculative risks, or improvement suggestions, at any severity.

## Step 5 — Report (terminal only)

Output exactly this shape as your reply:

```
PR <number>: <title>  (<state>)
Head: <head OID>   Base: <baseRefName> @ <merge-base OID>
Diff: <N> files, +<additions> / -<deletions>

VERDICT: <"No critical or high findings." | "N finding(s): X critical, Y high.">

## Findings

### [<CRITICAL|HIGH>] <short name>
- Where: <file> L<start>-L<end> (endpoint/route if relevant)
- What: <2-4 sentences, concrete>
- Trigger: <exact inputs or steps that reproduce it>
- Impact: <who or what is harmed, and under what conditions>
- Evidence: <the offending lines, quoted>
- Fix: <one line>
```

Repeat the finding block for each finding. If there are none, write "None."
under Findings. End with one line of cleanup note: the local ref
`pr-review-<number>` can be deleted with
`git branch -D pr-review-<number>` when the user is done with it.

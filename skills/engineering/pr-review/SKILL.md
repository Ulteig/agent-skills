---
name: pr-review
description: Review-only analysis of a GitHub pull request by number. Use when the user wants a PR reviewed, says "review PR #N", or asks to vet a pull request before merge.
---

# PR Review

## Overview

Perform a structured, review-only analysis of a GitHub PR using a required PR number.

This skill focuses on:
- SOLID principle violations
- DRY violations (duplication and maintainability)
- Security vulnerabilities and reliability risks
- General best practices (error handling, performance, testing, readability)

## Required Input

- A PR number
- If missing or invalid, ask the user to provide it before continuing.

## Workflow

If a TODO system exists, create one todo for each item below before doing any work, and do not start until every todo exists:

1. Validate and resolve PR number
2. Preflight checks
3. Fetch PR metadata
3b. Check CI/CD status
4. Create an isolated git worktree
5. Gather the diff
6. Triage diff size and relevance
7. Load review checklists
8. Perform the review
9. Cleanup worktree and temp branch
10. Output review

### 1) Validate and resolve PR number

- Confirm input has a PR number
- Strip `#` and leading zeros to get the numeric PR id for commands (e.g., `#0042` -> `42`).
- If value resolves to 0, ask user to confirm a valid PR.

### 2) Preflight checks

- Confirm current directory is a git repository.
- Confirm `gh` is installed and authenticated for the target repo.
- If `gh` is unavailable or not authenticated:
  - tell user exactly what is missing (CLI/auth/repo access)
  - ask for permission to proceed with a local git-only review fallback (if possible)

### 3) Fetch PR metadata

Use GitHub CLI:

- `gh pr view <id> --json number,title,body,author,baseRefName,headRefName,url,files,commits`

Capture at least: `baseRefName`, `headRefName`, `title`, `url`, and changed file list.

Also evaluate the PR description (`body`):
- Does it explain the *why* behind the change (not just the *what*)?
- Does it reference a ticket, issue, or spec?
- Does it match what the code actually does?
- Flag a **P3 Low** finding if the description is missing, vague, or inconsistent with the implementation.

### 3b) Check CI/CD status

- `gh pr checks <id>`
- If any required checks are **failing**, record a **P0 Critical** finding and note that the PR is not merge-ready regardless of code quality.
- If checks are still **pending/running**, note this in the Coverage Notes section of the output.

### 4) Create an isolated git worktree for review (required)

The worktree is the review surface, not the diff source: it is where you read full files for context and grep the repo for duplication — all without touching the main working tree.

Suggested flow:

1. Determine repo root and use a deterministic path, e.g. `.worktrees/pr-review-<id>`.
2. Remove stale review artifacts from previous interrupted runs:
   - `git worktree remove .worktrees/pr-review-<id> --force 2>/dev/null || true`
   - `git branch -D pr-review-<id> 2>/dev/null || true`
3. Fetch the latest base branch ref used for diffing:
   - `git fetch origin <baseRefName>`
4. Fetch the PR head into a temporary local branch:
   - `git fetch --force origin pull/<id>/head:pr-review-<id>`
5. Create worktree from that branch:
   - `git worktree add <worktree_path> pr-review-<id>`
6. Run all review commands against that worktree (`git -C <worktree_path> ...` or equivalent).

### 5) Gather the diff

`gh pr diff` is the diff of record, because it matches what appears in the PR UI:

- `gh pr diff <id> --name-only`
- `gh pr diff <id>`

If `gh` is unavailable, fall back to a merge-base-anchored diff from the worktree:

1. `merge_base=$(git -C <worktree_path> merge-base origin/<baseRefName> HEAD)`
2. `git -C <worktree_path> diff --stat "$merge_base" HEAD`
3. `git -C <worktree_path> diff "$merge_base" HEAD`

Avoid `origin/<baseRefName>...HEAD` as the primary source because stale refs can produce noisy, misleading diffs.

### 5b) Triage diff size and relevance

Before deep review:

- Count changed files and estimate diff size from `gh pr diff <id> --name-only` and diff stat.
- If the diff is large, review file-by-file (or by directory) instead of loading the entire patch at once.
- Prioritize high-risk files first: auth/authz, data access, public API boundaries, and infra/config changes.
- De-prioritize low-signal generated artifacts (lockfiles, compiled output, snapshots), but still note them in coverage.

### 6) Load review checklists

- `references/solid-dry-checklist.md`
- `references/security-checklist.md`
- `references/best-practices-checklist.md`

### 7) Perform the review

Apply the checklists loaded in step 6 to every changed file. The step is complete only when every changed file has been run against all three checklists and every finding is recorded with a severity and file:line — not before.

Also check test coverage statically:
- For every new or modified production code file, verify that corresponding test additions or updates exist in the diff.
- If production code is changed with no accompanying test changes, flag it as a **P2 Medium** finding unless the code is clearly non-testable (e.g., config, generated files, infra scripts).

### 8) Cleanup worktree and temp branch (required, always)

Cleanup must run in a finally-style step, even if review fails or exits early.

- `git worktree remove <worktree_path> --force`
- `git branch -D pr-review-<id>` (if it exists)

If cleanup fails, report the exact command failure and remaining artifacts to the user.

## Severity model

- **P0 Critical**: merge-blocking vulnerability/correctness/data-loss risk
- **P1 High**: major reliability/security/design issue
- **P2 Medium**: maintainability or moderate risk issue
- **P3 Low**: nits, style, optional improvements

## Output format

Use this structure:

```markdown
## PR Review Summary

- **PR**: #0000 - <title>
- **Overall assessment**: [APPROVE / REQUEST_CHANGES / COMMENT]
- **Scope**: X files changed

---

## Findings

### P0 - Critical
- **[path/to/file.ext:line] [Security|SOLID|DRY|BestPractice]** Title
  - Why this is a problem
  - Evidence
  - Recommended fix

### P1 - High
...

### P2 - Medium
...

### P3 - Low
...

---

## Coverage Notes
- Areas reviewed
- Areas not fully verified (if any)

## Recommended Next Steps
1. ...
2. ...
```


## Completion behavior

- Default behavior is **review only**.
- Do **not** implement fixes unless the user explicitly requests implementation.

## Resources

| File | Purpose |
|------|---------|
| `references/solid-dry-checklist.md` | SOLID and DRY review prompts |
| `references/security-checklist.md` | Security vulnerability and concurrency checklist |
| `references/best-practices-checklist.md` | Reliability, quality, and maintainability checks |

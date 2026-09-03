---
name: pr-review
description: Review-only analysis of a GitHub pull request by number. Use when the user wants a PR reviewed, says "review PR #N", or asks to vet a pull request before merge.
---

# PR Review

Structured, review-only analysis of a GitHub PR. A PR number is required input: if it is missing or invalid, ask the user for it before doing anything else.

The review hunts four classes of finding:

- SOLID principle violations
- DRY violations (duplication and maintainability)
- Security vulnerabilities and reliability risks
- General best practices (error handling, performance, testing, readability)

## Severity model

Every finding carries exactly one severity:

- **P0 Critical**: merge-blocking vulnerability/correctness/data-loss risk
- **P1 High**: major reliability/security/design issue
- **P2 Medium**: maintainability or moderate risk issue
- **P3 Low**: nits, style, optional improvements

## Workflow

If a TODO system exists, create one todo for each of the ten steps below before doing any work, and do not start step 1 until every todo exists:

1. Validate the PR number
2. Preflight checks
3. Collect automated evidence
4. Evaluate PR metadata
5. Check CI/CD status
6. Create an isolated git worktree
7. Triage diff size and relevance
8. Perform the review
9. Cleanup worktree and temp branch
10. Output the review

### 1) Validate the PR number

- Confirm input has a PR number.
- Strip `#` and leading zeros to get the numeric PR id for commands (e.g., `#0042` -> `42`).
- If the value resolves to 0, ask the user to confirm a valid PR.

### 2) Preflight checks

All three are hard requirements; if any is missing, tell the user exactly what is missing (CLI/auth/repo access/Python) and stop — the review cannot proceed without them.

- Confirm the current directory is a git repository.
- Confirm `gh` is installed and authenticated for the target repo.
- Confirm a Python 3 interpreter is available (`python3`, `py`, or `python`).

### 3) Collect automated evidence

Run the bundled `scripts/collect_review_bundle.py` helper now. It is the single collector of mechanical evidence — PR metadata, CI status, the GitHub diff, changed-file triage, possible missing tests, and a small set of obvious static candidates such as credential-like literals — and steps 4, 5, and 7 read from its output rather than re-running `gh` commands.

- Linux/macOS: `python3 <skill-directory>/scripts/collect_review_bundle.py <id>`
- Windows: `py <skill-directory>/scripts/collect_review_bundle.py <id>`
- Any platform: `python <skill-directory>/scripts/collect_review_bundle.py <id>`

The helper writes `review-bundle.json` and `pr.diff` to a temporary directory unless `--output-dir` is supplied. `pr.diff` is the diff of record: it is the `gh pr diff` output and matches what appears in the PR UI. The helper does not modify the current working tree, create a branch, or replace the required review worktree. Static results (`candidateFindings`) are candidates only: verify them against the code and project context before reporting them as findings.

This step is complete only when `review-bundle.json` and `pr.diff` exist. If the helper fails, report its exact error to the user and stop — there is no manual fallback path. The helper never replaces the full-file review in step 8.

### 4) Evaluate PR metadata

From the bundle's `pr` object, capture at least: `baseRefName`, `headRefName`, `title`, `url`, and the changed file list (`scope.changedFiles`).

Also evaluate the PR description (`body`):

- Does it explain the *why* behind the change (not just the *what*)?
- Does it reference a ticket, issue, or spec?
- Does it match what the code actually does?
- Flag a **P3 Low** finding if the description is missing, vague, or inconsistent with the implementation.

### 5) Check CI/CD status

Read CI status from the bundle's `ci` object (`ci.failing`, `ci.pending`).

- If any required checks are **failing**, record a **P0 Critical** finding and note that the PR is not merge-ready regardless of code quality.
- If checks are still **pending/running**, note this in the Coverage Notes section of the output.

### 6) Create an isolated git worktree (required)

The worktree is the review surface, not the diff source: it is where you read full files for context and grep the repo for duplication — all without touching the main working tree.

1. Determine the repo root and use a deterministic path, e.g. `.worktrees/pr-review-<id>`.
2. Remove stale review artifacts from previous interrupted runs:
   - `git worktree remove .worktrees/pr-review-<id> --force 2>/dev/null || true`
   - `git branch -D pr-review-<id> 2>/dev/null || true`
3. Fetch the latest base branch ref used for diffing:
   - `git fetch origin <baseRefName>`
4. Fetch the PR head into a temporary local branch:
   - `git fetch --force origin pull/<id>/head:pr-review-<id>`
5. Create the worktree from that branch:
   - `git worktree add <worktree_path> pr-review-<id>`
6. Run all review commands against that worktree (`git -C <worktree_path> ...` or equivalent).

### 7) Triage diff size and relevance

Before deep review, using the bundle's `scope` (file count, additions/deletions) and `triage` (risk files, possible missing tests):

- If the diff is large, review file-by-file (or by directory) instead of loading the entire patch at once.
- Prioritize high-risk files first: auth/authz, data access, public API boundaries, and infra/config changes.
- De-prioritize low-signal generated artifacts (lockfiles, compiled output, snapshots), but still note them in coverage.

### 8) Perform the review

Load the three checklists, then apply all of them to every changed file:

- `references/solid-dry-checklist.md`
- `references/security-checklist.md`
- `references/best-practices-checklist.md`

Also check test coverage statically:

- For every new or modified production code file, verify that corresponding test additions or updates exist in the diff.
- If production code is changed with no accompanying test changes, flag it as a **P2 Medium** finding unless the code is clearly non-testable (e.g., config, generated files, infra scripts).

The step is complete only when every changed file in `pr.diff` has been run against all three checklists and every finding is recorded with a severity and file:line — not before.

### 9) Cleanup worktree and temp branch (required, always)

Cleanup must run in a finally-style step, even if the review fails or exits early.

- `git worktree remove <worktree_path> --force`
- `git branch -D pr-review-<id>` (if it exists)

If cleanup fails, report the exact command failure and remaining artifacts to the user.

### 10) Output the review

Deliver the report in this structure, then stop — this skill is review-only. Implement fixes only when the user explicitly requests implementation.

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

---
name: pr-review
description: Review a GitHub pull request by PR number with focus on SOLID, DRY, security vulnerabilities, and engineering best practices.
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

Normalization rule:
- Strip `#` and leading zeros to get the numeric PR value for CLI commands.

## Workflow

### 1) Validate and resolve PR number

- Confirm input has a PR number
- Convert to numeric PR id for commands (e.g., `#0042` -> `42`).
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

### 4) Create an isolated git worktree for review (required)

Use a temporary, PR-specific worktree so the main working tree remains untouched.

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

### 5) Gather diffs inside the worktree

Use GitHub as the primary diff source so the review matches what appears in the PR UI:

- `gh pr diff <id> --name-only`
- `gh pr diff <id>`

If `gh` diff is unavailable, use a merge-base-anchored local fallback:

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

Review every changed file with emphasis on:

1. **SOLID**
   - SRP, OCP, LSP, ISP, DIP design regressions
2. **DRY**
   - duplicated logic, duplicated constants, repeated query/data-mapping patterns
3. **Security**
   - injection, XSS, auth/authz gaps, secrets, unsafe deserialization, race conditions
4. **Best Practices**
   - error handling, test coverage impact, boundary conditions, performance, logging/observability

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

## What it does

`/pr-review` gives an existing GitHub pull request a review-only pass for SOLID, DRY, security, reliability, performance, testing, maintainability, and naming risks. It reads the PR in an isolated git worktree, so the current working tree is not the review surface and no fixes are made as part of the review.

The review remains a judgment task even when the mechanical work is automated. A bundled Python helper collects metadata, CI status, the diff, risk-file triage, and obvious static candidates; it produces evidence for the review rather than pretending that a pattern match is a finding.

## When to reach for it

- **Invocation mode.** Type `/pr-review`, or the agent reaches for it automatically when an existing GitHub PR needs vetting before merge.
- **Trigger boundary.** Reach for this when you have a PR number and need an independent review before merging. For a branch or local diff that is not yet a GitHub PR, use [`/code-review`](https://aihero.dev/skills-code-review) instead.

## Prerequisites

The review runs from a git repository with `git`, an authenticated `gh` CLI, access to the target repository, and a Python 3 interpreter. All are hard requirements: the bundled `collect_review_bundle.py` script is the single collector of mechanical evidence (metadata, CI status, the diff), and the review stops with an exact report of what is missing rather than falling back to manual collection.

## The evidence bundle

The leading idea is **evidence before judgment**. The helper writes a JSON bundle and the PR diff to a temporary directory without changing the current working tree. It can flag failing checks, high-risk paths, possible missing test changes, and credential-like literals.

Those outputs are candidate evidence only. The reviewer still reads the full changed files in the isolated worktree, applies every checklist, confirms file and line references, decides severity, and chooses the overall assessment. Static automation cannot establish business intent, authorization correctness, compatibility, or whether a suspicious value is a real secret.

## Naming

Naming gets its own pass rather than a line in the best-practices list. The leading rule is **domain over representation**: a name says what a value means in the problem (`users`, `priceBySku`), not how it is stored (`list`, `dataMap`). Each construct also has a grammar: functions and methods are verb phrases, booleans are predicates (`isActive`, `canRetry`), collections are plural nouns. The reviewer lists every identifier the diff declares or renames and checks each one, greps for the term the codebase already uses before accepting a new one, and proposes a concrete replacement for every finding. A name that lies about what the code does, or one on a public API or persisted schema, is P2; the rest are P3.

## Common questions

**Does the helper replace the review?**

No. It removes repetitive collection work, but it does not replace the full-file review or the judgment behind a finding and its severity.

**Will reviewing a PR change my current working tree?**

No. The required review surface is a temporary worktree, and the helper itself only writes its evidence bundle and diff to its output directory. The temporary worktree and branch are removed during cleanup.

**What if Python is not installed?**

The review stops at preflight and tells you exactly what is missing. The helper is the single source of the PR metadata, CI status, and diff, so there is no manual fallback path. Install a Python 3 interpreter and rerun.

## It's working if

- The output includes the PR title, URL, changed-file count, diff, and CI state.
- High-risk files and automated matches are treated as review leads, not unverified findings.
- Every changed file is considered against the SOLID/DRY, security, best-practices, and naming checklists.
- Naming findings name the identifier, the rule it breaks, and a replacement name.
- The final report contains line-specific evidence, severity, recommended fixes, coverage notes, and an overall assessment.
- The review worktree and temporary branch are gone when the review finishes.

## Where it fits

`/pr-review` is a standalone pre-merge review for an existing GitHub PR. Use [`/code-review`](https://aihero.dev/skills-code-review) for a local branch or fixed-point diff, and [`/pr-create`](https://aihero.dev/skills-pr-create) to open a PR after implementation. [`/ask-matt`](https://aihero.dev/skills-ask-matt) is the router over the whole set.

## What it does

`pr-create` opens a pull request on GitHub from your current branch. It gathers commit messages and the diff since the base branch, drafts a structured description from them, shows it to you for edits, then creates the PR via `gh pr create`.

The defining constraint: it derives the PR description from what is already in the branch — commit messages and changed files — rather than interviewing you about the work. You review and edit the draft before it ships.

## When to reach for it

You invoke this by typing `/pr-create` — the agent won't reach for it on its own. Use it after you have committed work to a branch and are ready to open a PR for review.

| Situation | Reach for |
| --- | --- |
| Work is committed, ready for review | `/pr-create` |
| Still building the feature | [implement](https://aihero.dev/skills-implement) or [tdd](https://aihero.dev/skills-tdd) |
| PR already exists and needs reviewing | [pr-review](https://aihero.dev/skills-pr-review) |
| Want to review local changes before a PR | [code-review](https://aihero.dev/skills-code-review) |

## Prerequisites

- You need the [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated for the target repository.
- The branch must be committed — uncommitted changes will be flagged but the skill will not include them in the PR.
- The branch should exist locally; if it hasn't been pushed yet, the skill will ask before pushing.

## What one run does

A run is four beats:

1. **Gather** — reads commit messages and diff summary since the base branch fork point.
2. **Draft** — composes a PR description with Summary, Changes, and Related sections.
3. **Review** — shows you the draft title and body for edits.
4. **Create** — pushes the branch if needed, then creates the PR via `gh pr create`.

## Draft structure

The drafted description follows three sections:

- **Summary** — one or two sentences on what the PR does, derived from commit messages. Use ASD-STE100 to describe it.
- **Changes** — bullet list of key changes - these are logical changes, not code changes.
- linked issue references extracted from commit messages (e.g., `Fixes #42`).

If a single well-written commit message covers the branch, it drives the summary directly. 

## Common questions

**What if my branch has many unrelated commits?**

The skill groups changes by theme rather than listing every commit. If the commits span genuinely separate concerns, consider splitting them into separate branches and PRs — one PR per vertical slice follows the same principle as [to-tickets](https://aihero.dev/skills-to-tickets).

**It picked the wrong base branch.**

The skill infers the base from upstream tracking (`@{u}`). If your branch tracks something unusual, tell it the target base when you invoke: `/pr-create --base develop`.


## It's working if

- The agent shows you a draft title and description before creating anything.
- The summary reads like a human wrote it — derived from your commits, not a raw diff dump.
- Related issues are linked when your commit messages reference them.
- A PR URL and number appear at the end.

## Where it fits

`pr-create` sits after [implement](https://aihero.dev/skills-implement) in the main flow — implement commits to a branch, pr-create opens the PR:

```txt
grill-with-docs → to-spec → to-tickets → implement → pr-create → pr-review
```

Its neighbour downstream is [pr-review](https://aihero.dev/skills-pr-review), which reviews an existing PR. They are separate skills because creating a PR and reviewing it are distinct human decisions — you open the PR when ready, and review it (or have someone else review it) afterward.

[ask-matt](https://aihero.dev/skills-ask-matt) is the router over the whole set.

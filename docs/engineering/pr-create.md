## What it does

`pr-create` opens a pull request on GitHub from your current branch. It gathers commit messages and the diff since the base branch, drafts a structured description from them, shows it to you for edits, then creates the PR via `gh pr create`.

The defining constraint is that it derives the PR description from what is already in the branch, including commit messages and changed files, rather than interviewing you about the work. You review and edit the draft before it ships.

## When to reach for it

You invoke this by typing `/pr-create`; the agent won't reach for it on its own. Use it after you have committed work to a branch and are ready to open a PR for review.

| Situation | Reach for |
| --- | --- |
| Work is committed, ready for review | `/pr-create` |
| Still building the feature | [implement](https://aihero.dev/skills-implement) or [tdd](https://aihero.dev/skills-tdd) |
| PR already exists and needs reviewing | [pr-review](https://aihero.dev/skills-pr-review) |
| Want to review local changes before a PR | [code-review](https://aihero.dev/skills-code-review) |

## Prerequisites

- You need the [GitHub CLI](https://cli.github.com/) (`gh`) installed and signed in for the target repository.
- The branch must be committed. Uncommitted changes will be flagged, but the skill will not include them in the PR.
- The branch should exist locally; if it hasn't been pushed yet, the skill will ask before pushing.

## What one run does

A run is four beats:

1. **Gather**: reads the commit messages and the diff summary since the point where your branch left the base branch.
2. **Draft**: writes a PR description with Summary, Changes, and Testing sections.
3. **Review**: shows you the draft title and body for edits.
4. **Create**: pushes the branch if needed, then creates the PR via `gh pr create`.

## Draft structure

The drafted description follows three sections:

- **Summary**: one or two sentences on what the PR does, written in plain English and derived from the commit messages.
- **Changes**: a bullet list of the key changes. Each bullet is a change in behavior ("The todo list now accepts due dates."), not a change in code (`TodoList.cpp:88: add due dates`).
- **Testing**: left blank for you to fill in.

If a single well-written commit message covers the branch, it drives the summary directly. A branch with many small commits is grouped by theme instead of listed one by one.

## Common questions

**What if my branch has many unrelated commits?**

The skill groups changes by theme rather than listing every commit. If the commits span genuinely separate concerns, consider splitting them into separate branches and PRs. One PR per vertical slice follows the same principle as [to-tickets](https://aihero.dev/skills-to-tickets).

**It picked the wrong base branch.**

The skill infers the base from upstream tracking (`@{u}`). If your branch tracks something unusual, tell it the target base when you invoke: `/pr-create --base develop`.


## It's working if

- The agent shows you a draft title and description before creating anything.
- The summary reads like a human wrote it because it is derived from your commits, not a raw diff dump.
- Each Changes bullet names something a reader can test, not a file and a line number.
- You are asked to fill in the Testing section, and for before and after screenshots when the change affects the front end.
- A PR URL and number appear at the end.

## Where it fits

`pr-create` sits after [implement](https://aihero.dev/skills-implement) in the main flow: implement commits to a branch, then pr-create opens the PR.

```txt
grill-with-docs → to-spec → to-tickets → implement → pr-create → pr-review
```

Its neighbour downstream is [pr-review](https://aihero.dev/skills-pr-review), which reviews an existing PR. They are separate skills because creating a PR and reviewing it are distinct human decisions. You open the PR when ready, and review it (or have someone else review it) afterward.

[ask-matt](https://aihero.dev/skills-ask-matt) is the router over the whole set.

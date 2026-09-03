---
name: pr-create
description: "Create a GitHub PR from the current branch with a well-crafted description."
disable-model-invocation: true
---

Create a pull request on GitHub from the current branch.

## Preflight

1. Confirm the current directory is a git repository.
2. Confirm `gh` is installed and authenticated.
3. If either check fails, tell the user what is missing and stop.

## Workflow

If a TODO system is available, create a todo list of the following items before continuing. Then follow each step.

### 1) Determine branch and base

- Current branch: `git branch --show-current`
- Remote: `git remote -v` (pick the first push remote, usually `origin`)
- Base branch: try to infer from upstream tracking (`git rev-parse --abbrev-ref @{u}`), or ask the user.

If the current branch is the same as the inferred base (e.g., both `main`), ask the user which branch to create the PR from and which branch it should target.

### 2) Check for uncommitted changes

- `git status --porcelain`: if non-empty, warn the user there are uncommitted changes and ask whether to proceed anyway.

### 3) Gather change information

Collect material for the PR description:

- **Commit messages** since the base branch fork point:
  - `merge_base=$(git merge-base origin/<baseBranch> HEAD)`
  - `git log "$merge_base..HEAD" --oneline --no-decorate`
  - If there's a single commit, use its full message: `git log -1 --format=%B`
- **Diff summary**: `git diff --stat "$merge_base" HEAD`
- **Changed files**: `git diff --name-only "$merge_base" HEAD`

### 4) Draft the PR description

Compose a description from the gathered information. Structure it as:

```markdown
## Summary

[One or two sentences summarizing what this PR does, derived from commit messages and the nature of the changes. Use ASD-STE100 to describe it.]
- Use the commit messages as the primary source because they encode author intent.
- If there's a single well-written commit message, let it drive the summary.
- If there are many small commits, group them by theme rather than listing each one.
- Show the draft to the user and ask for edits before proceeding.

## Changes

[Bullet list of the key changes, one per bullet, derived from individual commits and diff summary. These are logical changes, not code changes (e.g. "The todo list now accepts due dates.", not "TodoList.cpp:88 - Add due dates".]

## Testing

[Ask the user to fill out.]

### 5) Push the branch (if needed)

- Check if the branch exists on the remote: `git ls-remote origin <branchName>`
- If not present, push it: `git push origin <branchName> --set-upstream`
- Ask the user before pushing.

### 6) Create the PR

Use `gh pr create` with the drafted description:

```bash
gh pr create \
  --base <baseBranch> \
  --head <branchName> \
  --title "<PR title>" \
  --body-file <(echo "$DESCRIPTION")
```

- **Title**: derive from the first commit message's first line, or ask the user if commits are unclear.
- After creation, print the PR URL and number.

## Completion

Print the PR URL, number, and a brief summary of what was created.
Ask the user to fill out the testing section.
If this involves a front end change, ask the user to attach screenshots of before and after.

---
name: pr-create
description: "Create a GitHub PR from the current branch. Use when the user wants to open or create a pull request, says 'create a PR' or 'open a pull request', or when committed work on a branch is ready to put up for review."
---

Create a pull request on GitHub from the current branch.

## Preflight

1. Make sure that the current directory is a git repository.
2. Make sure that `gh` is installed and signed in.
3. If either check fails, tell the user what is missing and stop.

## Workflow

If a TODO system is available, create a todo list of the steps below before you continue. Then follow each step in order. Close each step as it is completed.

### 1) Find the branch and the base branch

- Find the current branch: `git branch --show-current`
- Find the remote: `git remote -v`. If there are multiple, ask the user which one to use.
- Find the base branch. Try the upstream tracking branch first: `git rev-parse --abbrev-ref @{u}`. If that fails, ask the user.

If the current branch and the base branch are the same (for example, both are `main`), ask the user which branch to create the PR from and which branch it should target.

### 2) Check for uncommitted changes

Run `git status --porcelain`. If the output is not empty, tell the user that uncommitted changes exist. Ask whether to continue anyway.

### 3) Gather information about the change

Collect this material for the PR description:

- **Commit messages** since the base branch and the current branch split:
  - Find the split point: `merge_base=$(git merge-base origin/<baseBranch> HEAD)`
  - List the commits: `git log "$merge_base..HEAD" --oneline --no-decorate`
  - If there is only one commit, use its full message instead: `git log -1 --format=%B`
- **Diff summary**: `git diff --stat "$merge_base" HEAD`
- **Changed files**: `git diff --name-only "$merge_base" HEAD`

### 4) Draft the PR description

Write the description from the material you gathered. Use this structure:

```markdown
## Summary

[One or two sentences that summarize what this PR does. Base them on the commit messages and the nature of the changes. Write them in plain English.]

## Changes

[A bullet list of the key changes, one change per bullet. Base it on the commits and the diff summary. Describe each change as a change in behavior (for example, "The todo list now accepts due dates."), not as a change in code (for example, "TodoList.cpp:88: add due dates").]

## Testing

[Leave this section for the user to fill in.]
```

When you write the summary:

- Use the commit messages as your main source. They carry the author's intent.
- If one commit message already explains the change well, let it drive the summary.
- If there are many small commits, group them by theme. Do not list each one.
- Show the draft to the user and ask for changes before you continue.

### 5) Push the branch, if needed

- Check whether the branch exists on the remote: `git ls-remote origin <branchName>`
- If it does not exist, ask the user before you push it: `git push origin <branchName> --set-upstream`

### 6) Create the PR

Run `gh pr create` with the description you drafted:

```bash
gh pr create \
  --base <baseBranch> \
  --head <branchName> \
  --title "<PR title>" \
  --body-file <(echo "$DESCRIPTION")
```

- **Title**: use the first line of the first commit message. If the commits do not make the title clear, ask the user.
- After you create the PR, print its URL and number.

## Completion

Print the PR URL, the PR number, and a short summary of what you created.

Ask the user to fill in the testing section.

If the change affects the front end, ask the user to attach before and after screenshots.

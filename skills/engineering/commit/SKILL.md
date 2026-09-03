---
name: commit
description: Commit the current working directory's changes with an intent-rich message derived from the patch and repository context.
disable-model-invocation: true
---

Create one **atomic commit** from the intended working-tree changes. Invoking this skill authorizes a commit, not an indiscriminate `git add`.

## 1. Establish the boundary

1. Confirm the current directory is a Git repository on a branch. If HEAD is detached, stop and tell the user.
2. Detect an in-progress merge, rebase, cherry-pick, or revert. Stop and name the operation; it owns the next commit.
3. Read the repository's Git instructions, then inspect:
   - `git status --short --branch`
   - the staged diff and stat
   - the unstaged diff and stat
   - the contents of relevant untracked files
4. Account for every changed path as **included**, **excluded**, or **suspicious**. Suspicious paths include likely secrets, generated output, vendored dependencies, binaries, and unexpectedly large files; surface them before staging.

The index is a deliberate boundary. If it already contains changes, treat the staged patch as the commit candidate and leave unstaged and untracked changes alone unless the user explicitly expands the scope. If the index is empty, infer the candidate from the working tree.

## 2. Make it atomic

State the single intent shared by every candidate hunk. Tests, documentation, and generated metadata belong when they directly support that intent.

If the candidate contains independent intents, propose a split and ask which one to commit now. One invocation creates one commit. Stage exact paths or hunks; preserve unrelated changes for a later commit.

This step is complete when every candidate hunk serves the stated intent and every other change remains outside the index.

## 3. Reconstruct intent

Build the commit's story from the strongest available evidence, in this order:

1. The user's explicit request and the current conversation.
2. The staged patch: behavior, tests, documentation, and removed behavior.
3. A linked ticket, spec, PR, ADR, or project context document when its identity is unambiguous.
4. The branch name, for issue identifiers and terse intent clues.
5. Recent commit messages, for house style only.

Treat the branch name as a clue, never as proof. Verify issue references before using them. Do not invent rationale that the evidence does not support.

Read enough recent history to detect the repository's subject style, use of Conventional Commits, scope vocabulary, body shape, and issue-footer conventions. Local convention outranks the fallback below.

## 4. Write the message

The subject names the outcome of the patch, not the act of editing it. Follow the repository's established form. When no clear convention exists:

- use an imperative subject of at most 72 characters;
- omit a trailing period;
- add a body only when the motivation, behavior, or trade-off is not obvious from the subject;
- explain **why** and the resulting behavior, not a file-by-file diff;
- include verified issue references as footers;
- mention tests only when their result is known from this session.

Use a Conventional Commit subject only when the repository's history consistently does. Never add `Closes`, `Fixes`, or another closing keyword unless the user requested that side effect or the local convention clearly requires it.

## 5. Commit the reviewed patch

1. Stage only the atomic candidate. Preserve any pre-existing staged boundary unless the user approved changing it.
2. Review `git diff --cached --check`, its stat, its file list, and the complete staged diff.
3. Reconcile that review with the path accounting from step 1. If the scope or message remains ambiguous, show the proposed scope and message and ask before committing.
4. Commit with the composed message, using a message file when it has a body.


## 6. Verify

Inspect the resulting commit and the new working-tree status. Report:

- the commit hash and subject;
- the paths committed;
- any changes left staged, unstaged, or untracked.

Completion means exactly one new commit contains every intended hunk and no unrelated hunk, and all remaining changes are named to the user.

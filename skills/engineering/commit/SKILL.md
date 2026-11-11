---
name: commit
description: Commit the changes in the current working directory with a message that states their intent, based on the patch and the repository context.
disable-model-invocation: true
---

Create one atomic commit from the changes that the user intends. An atomic commit contains one intent and nothing else. This skill gives you permission to commit.

## 1. Find the boundary

1. Make sure that the current directory is a Git repository and that HEAD is on a branch. If HEAD is detached, stop and tell the user.
2. Look for a merge, rebase, cherry-pick, or revert that is in progress. If you find one, stop and tell the user its name.
3. Read the Git instructions of the repository. Then read:
   - `git status --short --branch`
   - The staged diff and its stat
   - The unstaged diff and its stat
   - The contents of each relevant untracked file
4. Put each changed path into one of three groups: included, excluded, or suspicious. A suspicious path is a likely secret, generated output, a vendored dependency, a binary, or an unexpectedly large file. Show each suspicious path to the user before you stage anything.

The index (the staging area) is a boundary that the user set on purpose. The candidate is the set of changes that you plan to commit.

- If the index already contains changes, the staged patch is the candidate. Keep unstaged and untracked changes out of the commit unless the user explicitly expands the scope.
- If the index is empty, find the candidate in the working tree.

## 2. Make it atomic

Write down the one intent that every hunk in the candidate shares. A hunk is one block of changed lines in a diff. Tests, documentation, and generated metadata belong in the commit when they directly support that intent.

If the candidate contains more than one independent intent, propose a split. Then ask the user which intent to commit now. One run of this skill creates one commit. Stage exact paths or hunks. Keep unrelated changes in the working tree for a later commit.

This step is done when every hunk in the candidate serves the intent and every other change is outside the index.

## 3. Find the intent

Build the story of the commit from the evidence. Use the strongest evidence first, in this order:

1. The explicit request of the user and the current conversation.
2. The staged patch: new behavior, tests, documentation, and removed behavior.
3. A linked ticket, spec, PR, ADR, or project context document, if you can identify it with certainty.
4. The branch name, for issue identifiers and short clues about the intent.
5. Recent commit messages, for house style only.

The branch name is a clue, not proof. Make sure that each issue reference is correct before you use it. Write only the reasons that the evidence supports.

Read enough recent history to learn the style of the repository:

- The form of the subject line
- The use of Conventional Commits
- The scope words
- The shape of the body
- The form of issue footers

The local style takes priority over the default rules in step 4.

## 4. Write the message

The subject states the result of the patch, not the act of editing. Use the established form of the repository. If the repository has no clear style, use these default rules:

- Write the subject in the imperative mood, with 72 characters at most.
- End the subject without a period.
- Add a body only when the subject does not make the motivation, the behavior, or the trade-off clear.
- In the body, explain why the change exists and how the code behaves now. Describe the change as a whole, not file by file.

Use a Conventional Commit subject only if the history of the repository uses it consistently. A closing keyword such as `Closes` or `Fixes` closes the issue when the commit merges. Add one only if the user asked for it or the local style clearly requires it.

## 5. Commit the patch

1. Stage only the candidate. If the index already had staged changes, keep that boundary unless the user approved a change.
2. Read the output of `git diff --cached --check`, the stat, the file list, and the full staged diff.
3. Compare this output with the path groups from step 1. If the scope or the message is still unclear, show the proposed scope and message to the user. Ask before you commit.
4. Commit with the message. If the message has a body, pass it in a message file.

## 6. Inspect the result

Read the new commit and the new status of the working tree. Then report to the user:

- The commit hash and subject
- The paths in the commit
- Each change that is still staged, unstaged, or untracked

The skill is done when exactly one new commit contains every intended hunk and no unrelated hunk. You must also name every remaining change to the user.

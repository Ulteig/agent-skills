## What it does

`commit` turns the intended changes in your working directory into one atomic Git commit. It reads the staged and unstaged patch, untracked files, branch name, linked work, project documents, and recent history to recover both the change and the reason for it.

An existing index is treated as a deliberate boundary: staged work is committed without quietly sweeping in the rest of the working tree. When nothing is staged, the skill finds one coherent change and stages only that.

## When to reach for it

You invoke this by typing `/commit`; the skill won't run on its own. Reach for it when the work is ready and you want the repository history to preserve its intent, not merely the names of edited files.

| Situation | Reach for |
| --- | --- |
| One coherent change is ready to record | `/commit` |
| The implementation still needs checking | [code-review](https://aihero.dev/skills-code-review) first |
| Several unrelated changes are mixed together | `/commit` to identify the split, then one invocation per commit |
| The work is committed and ready for a pull request | [pr-create](https://aihero.dev/skills-pr-create) |
| A merge or rebase is currently conflicted | [resolving-merge-conflicts](https://aihero.dev/skills-resolving-merge-conflicts) |

## Prerequisites

Run it inside a Git repository on the branch that should receive the commit. A detached HEAD or an in-progress merge, rebase, cherry-pick, or revert must be resolved through that operation's own workflow first.

## Atomic history

**Atomic** is the governing word: every hunk in the commit serves one intent, and every unrelated hunk stays outside it. Tests and documentation can belong beside code because they prove or explain the same behavior. Two independent behaviors do not become one change merely because they happen to be present at the same time.

That boundary matters more than a clever subject line. A precise message attached to a mixed patch still leaves misleading history; a focused patch gives future readers one decision they can understand, revert, or carry forward.

## The patch tells what; context tells why

The diff is the strongest evidence for what changed, but it rarely carries the whole reason. The skill uses the conversation and verified tickets, specs, ADRs, or project documents to recover intent. The branch name contributes clues, while recent commits establish house style.

The result is an intent-rich [primary source](https://www.aihero.dev/ai-coding-dictionary/primary-source): a concise subject that names the outcome, with a body only when motivation or trade-offs would otherwise be lost. Local convention wins over a universal template, including whether the repository uses Conventional Commits.

## Common questions

**Does it only draft a message, or does it commit?**

It creates the commit. Typing `/commit` is the authorization to do so. It pauses only when the intended boundary is ambiguous, suspicious files appear, or Git reports a condition that needs your decision.

**Why did it leave my unstaged changes behind?**

Because a non-empty index is treated as your chosen boundary. This prevents carefully staged work from absorbing unrelated edits. If you intended the unstaged changes to join the same atomic change, say so when it presents the remaining status.

**Does it force Conventional Commits?**

No. It reads recent history and follows the repository's established subject, scope, body, and footer style. Conventional Commits are used only when that is already the clear house convention.

**Will it put every changed filename in the message?**

No. Git already stores the patch and its file list. The message preserves the outcome, motivation, and material decisions that the diff cannot explain by itself.

**Does it run the test suite before committing?**

It runs normal Git hooks but does not invent a validation regime. Test results are mentioned only when they are already known from the current work. Use [code-review](https://aihero.dev/skills-code-review) before `/commit` when the implementation still needs verification.

## It's working if

- `git show` contains one coherent change rather than every dirty file in the checkout.
- The subject describes the behavior or decision, not “update files” or “misc changes.”
- The body adds intent or trade-offs instead of narrating the diff.
- Unrelated staged, unstaged, and untracked changes are still present and explicitly reported.
- The message looks at home beside the repository's recent commits.

## Where it fits

`commit` is a reach-for-it-anytime standalone at the delivery boundary. Use it after implementation and [code-review](https://aihero.dev/skills-code-review), then use [pr-create](https://aihero.dev/skills-pr-create) when the branch is ready for review. The [implement](https://aihero.dev/skills-implement) flow already commits its own work; `/commit` covers work completed outside that flow or a deliberately staged follow-up.

[ask-matt](https://aihero.dev/skills-ask-matt) is the router over the whole set.

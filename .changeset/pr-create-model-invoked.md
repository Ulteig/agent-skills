---
"mattpocock-skills": minor
---

Make **`pr-create`** model-invoked, so the agent can open a pull request on its own once committed work on a branch is ready for review, without waiting for the human to type it.

- `SKILL.md` drops `disable-model-invocation: true`, and its description becomes model-facing with trigger phrasing ("Use when the user wants to open or create a pull request..."). `agents/openai.yaml` drops the matching `policy.allow_implicit_invocation: false`, so the skill is model-invoked in both harnesses.
- The skill still shows the drafted description and asks before pushing or creating the PR, so autonomous reach stays gated on human approval at the destructive steps.
- `pr-create` moves from **User-invoked** to **Model-invoked** in the top-level README and the engineering bucket README, and the `ask-matt` router now says the agent reaches for it whenever a committed branch is ready to go up for review.
- The docs page at `docs/engineering/pr-create.md` re-syncs its invocation-mode line.

---
"mattpocock-skills": minor
---

Make **`commit`** model-invoked, so the agent can create an atomic commit on its own once a coherent change is ready to record, without waiting for the human to type it.

- `SKILL.md` drops `disable-model-invocation: true`, and its description becomes model-facing with trigger phrasing ("Use when a coherent change is ready to record, when the user asks to commit..."). `agents/openai.yaml` drops the matching `policy.allow_implicit_invocation: false`, so the skill is model-invoked in both harnesses.
- `commit` moves from **User-invoked** to **Model-invoked** in the top-level README and the engineering bucket README, and the `ask-matt` router now says the agent reaches for it the moment a coherent change is ready to record.
- The docs page at `docs/engineering/commit.md` re-syncs its invocation-mode line.

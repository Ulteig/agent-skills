---
"mattpocock-skills": minor
---

Strengthen **`pr-review`** with the checks real reviews keep missing.

- The reviewer now reads the repo's own docs (`AGENTS.md`, `CLAUDE.md`, glossary, ADRs) and neighboring files before judging, treats each stated rule as an extra checklist item, and cites the file a finding comes from.
- It compares the PR to its linked ticket, so unrelated changes and missing asks surface, and lists leftover work under a **Follow-up tickets** section.
- When intent is unclear, a finding becomes a question in a new **Questions for the author** section instead of a claimed defect.
- Severity levels gain concrete examples, and formatting a linter or `.editorconfig` should catch is no longer reported.
- The checklists expand to cover magic values, data and API design, migrations and config hygiene, and test quality (a test that cannot fail is P2), plus new naming rules such as no number as a distinguishing word.
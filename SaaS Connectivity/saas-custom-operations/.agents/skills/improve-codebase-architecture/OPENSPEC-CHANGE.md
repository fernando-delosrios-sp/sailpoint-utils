# OpenSpec change packages

After grilling confirms shared understanding, write one change package for the picked candidate when the target repo has OpenSpec. Legacy mode: stop after grill — no folder.

Full artifact mapping and quality bar: same as **improve**'s [openspec-change.md](../improve/references/openspec-change.md) in repos that install both skills. When improve is absent, follow the table below.

## Artifacts (ferspec)

| File | ICA-specific emphasis |
|---|---|
| `.openspec.yaml` | `schema: ferspec` |
| `discovery.md` | Grill decisions; deepening scope; Language terms from report |
| `proposal.md` | Why deepen; capability deltas if behavioral contract changes |
| `design.md` | Before/after module shape; files; seam; tests that survive; STOP/drift |
| `specs/<capability>/spec.md` | Gherkin deltas — invoke **gherkin-authoring** when present |
| `tasks.md` | Apply plan: ordered checkboxes + Verification + Documentation + Changelog |

Slug: kebab-case from candidate title. Reconcile against non-archive `openspec/changes/`. Do not implement — hand off to `/opsx:apply` or **apply-code-changes**.

Optional `ARCHITECTURE-REVIEW.md` remains a report snapshot, not the executable artifact.

# OpenSpec change packages

When the target repo has OpenSpec (`openspec/config.yaml` or `openspec/specs/`), **change packages** replace standalone `plans/` files. The advisor writes `openspec/changes/<slug>/` — one folder per selected finding or grilled candidate. Do not also write `plans/NNN-*.md` on the same run.

Read the target `openspec/config.yaml` schema field and write that schema's artifacts. **ferspec** (common default) is below.

## Slug and reconcile

- Kebab-case slug from the finding title (e.g. `ci-run-tests`, `collapse-order-intake`).
- Before creating: list `openspec/changes/` excluding `archive/` — skip if the finding is already packaged; refresh in place when drifted.
- Record `git rev-parse --short HEAD` in `design.md` for drift detection.

## Artifacts (ferspec)

| File | Content |
|---|---|
| `.openspec.yaml` | `schema: ferspec` and `created: <YYYY-MM-DD>` |
| `discovery.md` | Scope in/out; Language terms (`draft` / `promote` / `conflicts-with-canonical`); Decisions (finding rationale, forks if any); Open questions (empty when locked); Scenarios discussed for specs |
| `proposal.md` | Why; What Changes; Capabilities; Impact; **Apply status** (durable — see below) |
| `design.md` | Context; Goals/Non-Goals; Decisions; current-state excerpts with `file:line`; repo conventions with exemplar paths; in/out of scope; STOP conditions; drift check command; git workflow |
| `specs/<capability>/spec.md` | At least one Gherkin delta — invoke **gherkin-authoring** when present. Thin deltas are fine for tooling/docs fixes |
| `tasks.md` | Checkbox execution plan mapped from [plan-template.md](./plan-template.md) — implementation groups, Verification, mandatory Documentation and Changelog groups |

**Section mapping from plan-template:**

- Status / Depends on / Issue → `proposal.md` **Apply status**
- "Why this matters" → `proposal.md` Why + `discovery.md` Scope
- "Current state", excerpts, conventions, vocabulary constraints → `design.md` Context + Decisions
- Scope in/out, STOP conditions, drift check, git workflow → `design.md`
- Steps, test plan, done criteria → `tasks.md` implementation groups + Verification section
- Maintenance notes → `design.md` Risks/Trade-offs or last task group note

Do **not** add an "OpenSpec prerequisite" step — the change package *is* the proposal.

## Quality bar

Same bar as plan-template "Quality bar — check before finishing":

- Executor has zero advisor-session context — everything needed is in the change folder.
- Every task verification is a command + expected result.
- Exact files and symbols, not "the relevant module."
- STOP conditions match this change's real risks.
- No secret values — locations and credential types only.
- Cite capability spec slugs/requirements the advisor actually read in recon.
- `proposal.md` ends with **Apply status**; **Depends on** is `none` or real slugs.

## Apply status (durable, per package)

Each change folder owns its own index row. Write this block at the **end** of `proposal.md` when creating the package; update it on execute / reconcile / `--issues`. Later sessions read this block — not chat.

```markdown
## Apply status

- **Status**: TODO
- **Depends on**: none
- **Issue**:
```

- **Status**: `TODO` | `IN PROGRESS` | `DONE` | `BLOCKED` | `REJECTED` (BLOCKED/REJECTED include a one-line reason on the same bullet).
- **Depends on**: other change **slugs** that must be DONE first, comma-separated, or `none`.
- **Issue**: GitHub URL after `--issues`; leave empty until then.

A dependency slug is **DONE** when any of these hold:

1. Its `proposal.md` **Apply status** is `DONE`, or
2. Every `tasks.md` checkbox is `[x]`, or
3. The folder is under `openspec/changes/archive/` (archive names are `YYYY-MM-DD-<slug>`).

If **Apply status** is missing (older packages), infer from (2) and (3) only.

After writing packages, **report the same table in chat** (execution order, edges, status). Chat is a summary. No `plans/README.md` in OpenSpec mode.

## Invocation remaps (OpenSpec only)

| Variant | Behavior |
|---|---|
| `plan <description>` | One change folder under `openspec/changes/<slug>/` |
| `review-plan <path>` | Critique `tasks.md` + delta specs against the quality bar; tighten in place |
| `execute <slug>` | Confirm folder exists and every **Depends on** slug is DONE (stop and name any that aren't). Invoke **apply-code-changes**; advisor reviews apply output — never edits source. Write this package's **Status** (`DONE` or `BLOCKED`) |
| `reconcile` | Walk open changes (exclude `archive/`): refresh drifted `design.md`/`tasks.md`; update each package's **Apply status**; report what's executable |
| `--issues` | Publish `proposal.md` + link to change folder per issue; write the URL into that package's **Issue** field |

Legacy mode: unchanged — `plans/` + [closing-the-loop.md](./closing-the-loop.md).

## Apply handoff

User or advisor runs `/opsx:apply <slug>` or invokes **apply-code-changes**. The advisor does not implement; it may review apply results when asked via `execute`.

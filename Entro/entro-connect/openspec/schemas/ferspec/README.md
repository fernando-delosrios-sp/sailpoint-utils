# ferspec Schema

Lean OpenSpec workflow for work that needs speccing. **Schema = what; skills = how.**

[![OpenSpec baseline](https://img.shields.io/badge/OpenSpec_baseline-1.4.1-0277bd)](#compatibility)

---

## Install

**Via openspec-init:** The skill copies this schema (step 2), then runs [INSTALL.md](./INSTALL.md) post-copy setup (step 3), config and specs (steps 4–5), and skills + verify (step 6).

**Update existing:** Invoke openspec-init (update path) — see [UPDATE.md](./UPDATE.md).

**Standalone:** See [INSTALL.md § Standalone manual install](./INSTALL.md#standalone-manual-install), then complete the remaining INSTALL.md sections.

Use `--schema ferspec` on new changes: `/opsx:new my-feature --schema ferspec`

---

## Purpose

A lean artifact graph: discovery → proposal / design / specs → tasks → apply. Matt Pocock skills for execution. Direct PR for bug fixes, typos, and config tweaks.

---

## Artifact DAG

```text
discovery ──┬──→ proposal ──→ specs (Gherkin) ──┐
            │                                  ├──→ tasks ──→ [apply]
            └──→ design ─────────────────────────┘

Dropped: plan, verify, retrospective, changelog artifact
Optional: skip grilling when scope is locked (write discovery.md manually)
Autonomous only: tracking.md (created at apply start)
Archive: manual via /opsx:archive — never part of apply
```

| Artifact | Role | Skill |
|---|---|---|
| discovery.md | Scope, Language, Decisions, Open questions, Scenarios | grill-with-docs → grilling + domain-modeling |
| proposal.md | Why, capabilities, impact | Extract from discovery |
| design.md | Structured architecture | Extract from discovery; c4-diagram when 3+ containers |
| specs/** | Gherkin delta specs | gherkin-authoring; promote Language → ubiquitous-language |
| tasks.md | Checkboxes + Documentation + Changelog | Mandatory; apply tracks this file |
| tracking.md | Issue ↔ change ↔ branch ↔ PR | Autonomous apply only |

Promoted Language terms → ubiquitous-language delta during specs phase; canonical
`openspec/specs/ubiquitous-language/spec.md` at archive — not in discovery or repo-root CONTEXT.md.

---

## Entry & exit gates

### Direct PR (skip opsx)

| Scenario | Use opsx? |
|---|---|
| New feature / capability / architectural / breaking change | ✅ Yes |
| Bug fix (no contract change) / test backfill / linter / typo / docs / config tweak | ❌ Direct PR |

### Verbal discovery → opsx

Grill verbally until all 5 promotion criteria hold (scope locked, forks resolved, deps mapped, acceptance criteria stateable, conversation converging). Then suggest `/opsx:propose` — wait for user ack.

See [templates/adopters/AGENTS.md.fragment.md](./templates/adopters/AGENTS.md.fragment.md) for agent routing.

---

## Apply phase

**Requires:** tasks · **Tracks:** tasks.md

Invoke **apply-code-changes** when installed; schema carries a minimal fallback. The skill uses the **OpenSpec adapter** by default; **Direct adapter** applies any folder with `tasks.md` (no OpenSpec required).

### Completion gate — verify-aligned (blocking)

Re-run after every verify-fix iteration until every row passes:

1. All tasks.md checkboxes `[x]` (including Documentation and Changelog)
2. Canonical test command from `tasks.md` exit 0; every Gherkin scenario → passing named automated test
3. Lint/format when `tasks.md` or repo docs name commands — zero new warnings from this change
4. `openspec validate --all --json` (from `planningHome.root`, with `--store` when set) — all valid
5. Design decisions reflected in specs (material drift = FAIL)
6. Documentation tasks reflect actual behavior
7. Changelog task complete (during apply, not archive)
8. `git status --porcelain` empty on verification ref

**Worktree:** squash `apply-<name>` → `ORIGINAL_BRANCH` on main repo before verify-aligned — never verify on the worktree checkout.

### Verify-fix loop (blocking)

Invoke **openspec-verify-change** or `/opsx:verify` on the verification ref; fix FAILs and warnings; re-run verify-aligned; repeat until ✅ PASS.

**Done when:** standalone `/opsx:verify` after apply would confirm PASS — not surface new FAILs or warnings. Apply owns verify-fix; never defer to the user.

Dropped as planning artifacts: plan, verify.md, retrospective — verify-fix still runs inside apply (no `verify.md` file required).

### Apply flow

```text
venue gate → bind → execute (incl. Changelog) → [worktree merge] → verify-aligned → verify-fix → handoff
```

- **local** — work on `ORIGINAL_BRANCH`; return control (single) or squash merge (subagent-per-group)
- **worktree** — ephemeral `apply-<name>`; squash merge to `ORIGINAL_BRANCH` at handoff
- **remote** — `FEATURE_BRANCH` + PR + issue link

Parallelism is agent-chosen (same criteria all venues). Archive is **never** part of apply.

### Archive (manual)

After PR merge or when interactive work is ready. User runs `/opsx:archive` themselves — **never** part of apply.

`/opsx:archive` MUST run the full sequence — sync, move, **commit**, gate. Archive is incomplete until the post-commit gate passes (including when re-running on a change already moved under `archive/` with uncommitted spec sync on disk).

```text
sync → archive move → commit archive output → post-commit gate
```

Load advisory steps first:

```bash
openspec instructions archive --change "<name>" --json
```

| Sub-step | Action |
|---|---|
| **A** | Built-in `/opsx:archive` steps 1–5: artifact/task checks, delta spec sync assessment, sync if chosen, move to `openspec/changes/archive/YYYY-MM-DD-<name>/` |
| **B** | **Commit archive output** (required — CLI does NOT commit): `git status --porcelain` → if non-empty, stage `openspec/specs/` + `openspec/changes/` (+ any sync paths) → invoke **git-commit** via Skill tool, or conventional commit manually if skill absent (e.g. `docs(openspec): archive <change-name> and sync specs`) |
| **C** | **Post-commit gate** (blocking): `git status --porcelain` empty; when change is under `archive/`, confirm latest commit includes synced specs and archive folder: `git log -1 --name-only -- openspec/specs/ openspec/changes/archive/` |

> Skipping **B** because `git-commit` is missing is a schema violation — use the manual fallback instead.

---

## Skills map

| Concern | Skill | Notes |
|---|---|---|
| Discovery | grill-with-docs, grilling, domain-modeling | Language → discovery.md |
| Design | c4-diagram | Optional; 3+ containers |
| Specs | gherkin-authoring | Gherkin delta specs |
| Apply | apply-code-changes | **Required for full apply UX**; schema has fallback |
| Verify-fix | openspec-verify-change (`/opsx:verify`) | Blocking inside apply before handoff |
| TDD | tdd | Optional invoke; gate requires tests green |
| Commits | git-commit | Apply + archive commit (archive manual fallback if absent) |
| Changelog | changelog-generator | During apply |
| PR (remote venue) | gh / issue-tracker doc | Via apply-code-changes |

---

## CLI cheat sheet

| Scenario | Command |
|---|---|
| New change | `/opsx:new <name> --schema ferspec` |
| One-shot planning | `/opsx:ff <name> --schema ferspec` |
| Continue planning | `/opsx:continue <name>` |
| Implement | `/opsx:apply <name>` |
| Re-run verify after interruption | `/opsx:verify <name>` (FAILs → apply verify-fix) |
| Archive (manual — sync + move + commit) | `/opsx:archive <name>` |
| Validate | `openspec validate --all --json` (cwd `planningHome.root`; append `--store` when set) |

---

## Versioning

| Identifier | Where | Meaning |
|---|---|---|
| Schema major | `schema.yaml: version: 1` | Graph contract — breaking changes bump this |
| Bundle release | [VERSION](./VERSION) | SemVer of this bundle |

Current bundle: **1.1.1**

---

## Compatibility

| ferspec | OpenSpec CLI | Baseline as of |
|---|---|---|
| v1 | ≥ 1.4.1 | 2026-08-16 |

---

## Related

- [schema.yaml](./schema.yaml) — machine-readable definition
- [plan.md](./plan.md) — design brief and implementation checklist
- [templates/](./templates/) — artifact templates

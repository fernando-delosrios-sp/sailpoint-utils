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

### Completion gate (blocking)

1. All tasks.md checkboxes `[x]`
2. Canonical test command exit 0
3. Every Gherkin scenario in delta specs → named automated test
4. `openspec validate --all --json` (from `planningHome.root`, with `--store` when set) — all valid
5. Design decisions reflected in specs (material drift = FAIL)
6. Changelog task complete (during apply, not archive)

### Apply flow

```text
venue gate (local | worktree | remote) → bind → execute (incl. Changelog) → gate → handoff
```

- **local** — work on `ORIGINAL_BRANCH`; return control (single) or squash merge (subagent-per-group)
- **worktree** — ephemeral `apply-<name>`; squash merge to `ORIGINAL_BRANCH` at handoff
- **remote** — `FEATURE_BRANCH` + PR + issue link

Parallelism is agent-chosen (same criteria all venues). Archive is **never** part of apply.

### Archive (manual)

After PR merge or when interactive work is ready:

```text
sync → archive change → commit archive output
```

User runs `/opsx:archive` themselves.

---

## Skills map

| Concern | Skill | Notes |
|---|---|---|
| Discovery | grill-with-docs, grilling, domain-modeling | Language → discovery.md |
| Design | c4-diagram | Optional; 3+ containers |
| Specs | gherkin-authoring | Gherkin delta specs |
| Apply | apply-code-changes | **Required for full apply UX**; schema has fallback |
| TDD | tdd | Optional invoke; gate requires tests green |
| Commits | git-commit | Spec drift warn + user ack |
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
| Archive (manual) | `/opsx:archive <name>` |
| Validate | `openspec validate --all --json` (cwd `planningHome.root`; append `--store` when set) |

---

## Versioning

| Identifier | Where | Meaning |
|---|---|---|
| Schema major | `schema.yaml: version: 1` | Graph contract — breaking changes bump this |
| Bundle release | [VERSION](./VERSION) | SemVer of this bundle |

Current bundle: **1.0.0**

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

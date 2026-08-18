# ferspec Update

Upgrade an existing **ferspec** install in a project that already has `openspec/config.yaml` with `schema: ferspec`.

> **openspec-init routing:** Invoke the **openspec-init** skill (update path). Steps U1–U7 in the skill run in order; this file adds ferspec-specific scope, migration notes, and verify. Source of truth for the new bundle is this skill's bundled `schemas/ferspec/` (matches the installed openspec-init skill version).

Fresh install: [INSTALL.md](./INSTALL.md). Standalone manual install: [INSTALL.md § Standalone manual install](./INSTALL.md#standalone-manual-install).

## Version signals

| Signal | File | Meaning |
|---|---|---|
| Graph contract | `schema.yaml` → `version:` | Artifact graph / PRECHECK breaking |
| Bundle release | [VERSION](./VERSION) | SemVer of templates, INSTALL, fragments |

**Hard-stop** when bundled graph `version` > local — read [Migration](#migration) below; require user ack before overwrite.

**Warn-only** when bundle [VERSION](./VERSION) major bumps but graph version is unchanged (prose/template changes).

## Compatibility (preflight)

| ferspec | OpenSpec CLI | Baseline as of |
|---|---|---|
| v1 | ≥ 1.4.1 | 2026-08-16 |

Block update when `openspec --version` is below the minimum above.

## What the update touches

| Path | Action | Gate |
|---|---|---|
| `openspec/schemas/ferspec/` | Full replace from bundled copy | Diff + ack before overwrite |
| `openspec/config.yaml` | Refresh rules and `operations.archive`; preserve `context:` and custom rules | Diff + ack |
| `AGENTS.md` / `CLAUDE.md` (project root) | Section diff/replace or append from `templates/adopters/AGENTS.md.fragment.md` | Diff + ack; never whole-file replace |
| Companion skills | Full `INSTALL.md` Skills list (idempotent) | Gate once before commands |
| `openspec/specs/**` | Never modify existing content | — |
| `openspec/changes/**` | Never modify | Warn on graph breaking bump |

Monolithic schema dir — take the whole new bundle or stay on the old one. No per-file opt-in.

## Agent routing refresh

Target files (when they exist):

- **Cursor / Codex / OpenCode**: `AGENTS.md`
- **Claude**: `CLAUDE.md`

Fragment: `openspec/schemas/ferspec/templates/adopters/AGENTS.md.fragment.md`

1. Scan for an existing section referencing ferspec workflow routing or superpowers-bridge-style entry gates.
2. If found → diff section against the bundled fragment → replace on ack.
3. If not found → offer to append fragment on ack.

## Migration

### Graph version unchanged (bundle VERSION patch/minor)

Prose and template updates only. In-flight changes under `openspec/changes/` remain valid. Re-running `/opsx:continue` or `/opsx:apply` on existing artifacts uses new template wording on next overwrite of that artifact.

### Graph version bump (future)

When `schema.yaml` `version` increases, this section will document:

- Artifact add/remove or `requires:` edge changes
- PRECHECK changes
- Manual steps for in-flight changes (if any)

**v1 → v1.x:** No migration required today.

## Verify (update)

Lighter than fresh init — run after U2–U5 (or skips with ack):

1. `openspec schema validate ferspec`
2. Required skills from [INSTALL.md § Skills](./INSTALL.md#skills-openspec-init-step-6) appear in the agent's available skills list
3. Confirm `openspec/specs/ubiquitous-language/spec.md` exists (or was seeded in U6)

**Optional smoke test** (user request or after graph version bump):

1. `/opsx:new test-ferspec --schema ferspec`
2. Confirm `openspec/changes/test-ferspec/` exists with ferspec planning artifacts
3. **Delete** the smoke-test change: `rm -rf openspec/changes/test-ferspec` — do not archive

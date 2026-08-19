# superpowers-bridge Update

Upgrade an existing **superpowers-bridge** install in a project that already has `openspec/config.yaml` with `schema: superpowers-bridge`.

> **openspec-init routing:** Invoke the **openspec-init** skill (update path). Steps U1–U7 in the skill run in order; this file adds bridge-specific scope, migration notes, and verify. Source of truth for the new bundle is this skill's bundled `schemas/superpowers-bridge/` (matches the installed openspec-init skill version).

Fresh install: [INSTALL.md](./INSTALL.md) and [README.md § Install](./README.md#install). For standalone clone-from-upstream install, see README — update always uses the bundled copy when routed through openspec-init.

## Version signals

| Signal | File | Meaning |
|---|---|---|
| Graph contract | `schema.yaml` → `version:` | Artifact graph / PRECHECK breaking |
| Bundle release | [VERSION](./VERSION) | SemVer of templates, INSTALL, fragments |

**Hard-stop** when bundled graph `version` > local — read [Migration](#migration) below; require user ack before overwrite.

**Warn-only** when bundle [VERSION](./VERSION) major bumps but graph version is unchanged.

## Compatibility (preflight)

| superpowers-bridge | OpenSpec CLI | Superpowers | Baseline as of |
|---|---|---|---|
| v2 graph | ≥ 1.4.1 | obra/superpowers v5.1.0+ | 2026-08-16 |

Block update when OpenSpec CLI is below minimum. Warn when Superpowers skills from `npx skills add obra/superpowers` are missing (refreshed in U5).

## What the update touches

| Path | Action | Gate |
|---|---|---|
| `openspec/schemas/superpowers-bridge/` | Full replace from bundled copy | Diff + ack before overwrite |
| `openspec/config.yaml` | Refresh rules; preserve `context:` and custom rules | Diff + ack |
| `CLAUDE.md` / `AGENTS.md` / tool rules | Section diff/replace or append from adopters fragment | Diff + ack; never whole-file replace |
| Companion skills | Full `INSTALL.md` Skills list (Superpowers + companions) | Gate once before commands |
| `openspec/specs/**` | Never modify existing content | — |
| `openspec/changes/**` | Never modify | Warn on graph breaking bump |

Monolithic schema dir — take the whole new bundle or stay on the old one.

## Agent routing refresh

Identify existing agent config per [INSTALL.md § Post-copy setup](./INSTALL.md#post-copy-setup-openspec-init-step-3):

- **Claude**: `CLAUDE.md` — prefer `templates/adopters/CLAUDE.md.fragment.<locale>.md` when present
- **Cursor / Codex / OpenCode / Antigravity**: `AGENTS.md` or `.cursor/rules/`
- **Windsurf**: `.windsurfrules`

Bundled fragments under `openspec/schemas/superpowers-bridge/templates/adopters/`:

- `AGENTS.md.fragment.md` (English workflow routing)
- `CLAUDE.md.fragment.md` / `CLAUDE.md.fragment.zh-TW.md` when upgrading Claude projects

For each file that exists:

1. Scan for an existing workflow-routing section referencing superpowers-bridge or OpenSpec + Superpowers routing.
2. If found → diff section against the bundled fragment → replace on ack.
3. If not found → offer to append on ack.

`<locale>`: infer from existing `CLAUDE.md` content (e.g. zh-TW for Traditional Chinese); default English (no suffix).

## Migration

### Graph version unchanged (bundle VERSION patch/minor)

In-flight changes (any phase: brainstorm / design / specs / …) remain valid when `requires:` edges, PRECHECKs, and artifact dependencies are unchanged. Existing `verify.md` / `retrospective.md` stay readable; re-running `/opsx:verify` or `/opsx:continue → retrospective` applies new template structure on next artifact overwrite.

### Graph version bump

When `schema.yaml` `version` increases, this section will document structural changes (artifact add/remove, `requires:` edges, PRECHECK changes) and manual steps for in-flight work.

## Verify (update)

Run after U2–U5 (or skips with ack):

1. `openspec schema validate superpowers-bridge`
2. Required skills from [INSTALL.md § Skills](./INSTALL.md#skills-openspec-init-step-6) appear in the agent's available skills list (including `obra/superpowers` bundle)
3. Confirm `openspec/specs/ubiquitous-language/spec.md` exists (or was seeded in U6)

No mandatory smoke-test change on routine updates. Offer `/opsx:new test-bridge --schema superpowers-bridge` + delete when user requests or after graph version bump.

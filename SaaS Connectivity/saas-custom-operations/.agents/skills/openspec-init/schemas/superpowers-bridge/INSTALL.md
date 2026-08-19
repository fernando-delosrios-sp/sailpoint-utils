# Superpowers Bridge Installation

Post-copy setup for the `superpowers-bridge` schema.

> **openspec-init routing:** Step 3 runs **Post-copy setup** only. Step 6 runs **Skills**, then **Verify** (after step 5). Do not re-copy the schema — openspec-init step 2 handles that. For standalone install (clone + copy), see [README.md](./README.md). For existing projects, use openspec-init **update path** — see [UPDATE.md](./UPDATE.md).

## Upgrading (openspec-init update path)

When `openspec/config.yaml` already exists with `schema: superpowers-bridge`, invoke **openspec-init** (update path) or follow [UPDATE.md](./UPDATE.md). Standalone upstream clone upgrade procedures in README are for non-openspec-init workflows only.

## Post-copy setup (openspec-init step 3)

### Identify target agent rules

Identify which AI tools the user works with by reviewing their `openspec init` selections or asking them.
Check the project root for corresponding configuration files:

- **Claude**: `CLAUDE.md`
- **Cursor**: `.cursor/rules/` or `AGENTS.md`
- **Windsurf**: `.windsurfrules`
- **Antigravity / OpenCode / Codex**: `AGENTS.md`

Prefer `AGENTS.md` when the project already has one; otherwise use the tool-specific file above.

### Insert workflow routing

For each configuration file that exists in the project:

1. Ask the user for permission to insert the workflow routing fragment.
2. Read the fragment from `openspec/schemas/superpowers-bridge/templates/adopters/AGENTS.md.fragment.md`.
3. Append this fragment as a new section to the end of the rule file.
   *(If a tool requires a specific format like JSON, adapt the content accordingly.)*

The fragment includes **agent communication** rules (plain English, succinct replies, one question at a time) and **workflow routing** for OpenSpec + Superpowers.

## Skills (openspec-init step 6)

Install **all** skills below. Do not stop after the Superpowers package — the schema also depends on companion skills and OpenSpec built-ins.

### Superpowers execution skills (required)

Provides brainstorming, planning, subagent execution, and branch completion:

```bash
npx skills add obra/superpowers
```

Confirm these skills are available after install:

| Skill | Used in |
|---|---|
| `brainstorming` | brainstorm artifact |
| `writing-plans` | plan artifact |
| `subagent-driven-development` | apply step 2 (executor) |
| `test-driven-development` | transitive via subagent-driven-development |
| `requesting-code-review` | transitive via subagent-driven-development |
| `finishing-a-development-branch` | apply step 6 (PR last) |

If any required skill above is missing, STOP and inform the user — the schema does not silently fall back.

**Optional — worktree path only** (required when the user chooses Worktree at apply step 1; PRECHECK in schema stops with Local/install offer if absent):

| Skill | Used in |
|---|---|
| `using-git-worktrees` | apply step 2 (isolated workspace — user chooses at step 1) |

### Companion skills from fernando-delosrios-sp/skills (required)

```bash
npx skills add fernando-delosrios-sp/skills --skill structured-choices
npx skills add fernando-delosrios-sp/skills --skill changelog-generator
npx skills add fernando-delosrios-sp/skills --skill git-commit
npx skills add fernando-delosrios-sp/skills --skill gherkin-authoring
npx skills add fernando-delosrios-sp/skills --skill c4-diagram
```

| Skill | Used in |
|---|---|
| `structured-choices` | user gates across workflow |
| `changelog-generator` | tasks.md Changelog group; apply step 2b |
| `git-commit` | apply step 5d (archive commit; manual fallback if absent) |
| `gherkin-authoring` | specs artifact (Gherkin scenario authoring) |
| `c4-diagram` | design and proposal phases (architecture diagrams) |

### OpenSpec built-in (verify availability)

`openspec-verify-change` is invoked during apply step 3 (verify-fix loop). It ships with OpenSpec — no separate install. The `/opsx:verify` slash command is its user-facing equivalent.

If unavailable, the verify artifact falls back to manual checks documented in `schema.yaml`.

## Verify (openspec-init step 6, after step 5)

Run after ubiquitous-language and domain specs exist (openspec-init step 5):

1. Run `openspec schema validate superpowers-bridge`.
2. Confirm each required skill from the Skills section appears in the agent's available skills list.
3. Confirm `openspec/specs/ubiquitous-language/spec.md` exists.

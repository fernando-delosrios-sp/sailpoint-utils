# Superpowers Bridge Installation

Follow these steps to complete the setup for the `superpowers-bridge` schema:

## 1. Identify Target Agent Rules

Identify which AI tools the user works with by reviewing their `openspec init` selections or asking them.
Check the project root for corresponding configuration files:

- **Claude**: `CLAUDE.md`
- **Cursor**: `.cursor/rules/` or `AGENTS.md`
- **Windsurf**: `.windsurfrules`
- **Antigravity / OpenCode / Codex**: `AGENTS.md`

Prefer `AGENTS.md` when the project already has one; otherwise use the tool-specific file above.

## 2. Insert Workflow Routing

For each configuration file that exists in the project:

1. Ask the user for permission to insert the workflow routing fragment.
2. Read the fragment from `openspec/schemas/superpowers-bridge/templates/adopters/AGENTS.md.fragment.md`.
3. Append this fragment as a new section to the end of the rule file.
   *(If a tool requires a specific format like JSON, adapt the content accordingly.)*

The fragment includes **agent communication** rules (plain English, succinct replies, one question at a time) and **workflow routing** for OpenSpec + Superpowers.

## 3. Install Required Skills

Install **all** skills below. Do not stop after the Superpowers package — the schema also depends on companion skills and OpenSpec built-ins.

### 3a. Superpowers execution skills (required)

Provides brainstorming, planning, worktree isolation, subagent execution, and branch completion:

```bash
npx skills add obra/superpowers
```

Confirm these skills are available after install:

| Skill | Used in |
|---|---|
| `brainstorming` | brainstorm artifact |
| `writing-plans` | plan artifact |
| `using-git-worktrees` | apply step 1 (isolated workspace) |
| `subagent-driven-development` | apply step 2 (executor) |
| `test-driven-development` | transitive via subagent-driven-development |
| `requesting-code-review` | transitive via subagent-driven-development |
| `finishing-a-development-branch` | apply step 6 (PR last) |

If any required skill is missing, STOP and inform the user — the schema does not silently fall back.

### 3b. Companion skills from fernando-delosrios-sp/skills (required)

```bash
npx skills add fernando-delosrios-sp/skills --skill changelog-generator
npx skills add fernando-delosrios-sp/skills --skill git-commit
npx skills add fernando-delosrios-sp/skills --skill gherkin-authoring
npx skills add fernando-delosrios-sp/skills --skill c4-diagram
```

| Skill | Used in |
|---|---|
| `changelog-generator` | tasks.md Changelog group; apply step 2b |
| `git-commit` | apply step 5d (archive commit; manual fallback if absent) |
| `gherkin-authoring` | specs artifact (Gherkin scenario authoring) |
| `c4-diagram` | design and proposal phases (architecture diagrams) |

### 3c. OpenSpec built-in (verify)

`openspec-verify-change` is invoked during apply step 3 (verify-fix loop). It ships with OpenSpec — no separate install. The `/opsx:verify` slash command is its user-facing equivalent.

If unavailable, the verify artifact falls back to manual checks documented in `schema.yaml`.

## 4. Verify Installation

1. Run `openspec schema validate superpowers-bridge`.
2. Confirm each required skill from §3a and §3b appears in the agent's available skills list.
3. Confirm `openspec/specs/ubiquitous-language/spec.md` exists (created during openspec-init).

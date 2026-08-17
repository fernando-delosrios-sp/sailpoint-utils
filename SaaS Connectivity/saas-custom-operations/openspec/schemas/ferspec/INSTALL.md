# ferspec Installation

Setup for the **ferspec** OpenSpec schema in a target project.

> **openspec-init routing:** Step 3 runs **Post-copy setup** only. Step 6 runs **Skills**, then **Verify** (after step 5). Do not re-copy the schema or run `openspec init` during those steps — openspec-init steps 1–2 handle CLI setup and schema copy. For existing projects, use openspec-init **update path** — see [UPDATE.md](./UPDATE.md).

## Upgrading (openspec-init update path)

When `openspec/config.yaml` already exists with `schema: ferspec`, do **not** re-run standalone manual install. Invoke **openspec-init** (update path) or follow [UPDATE.md](./UPDATE.md).

## Standalone manual install

For projects **not** using openspec-init:

```bash
# Run openspec init first if the project has no openspec/ directory
mkdir -p ~/your-project/openspec/schemas
npx --yes degit fernando-delosrios-sp/skills/skills/engineering/openspec-init/schemas/ferspec ~/your-project/openspec/schemas/ferspec
cd ~/your-project
openspec schema validate ferspec
openspec schemas   # confirm ferspec is listed
```

Then complete **Post-copy setup**, **Skills**, and **Verify** below.

## Post-copy setup (openspec-init step 3)

Check the project root for agent config:

- **Cursor / Codex / OpenCode**: `AGENTS.md`
- **Claude**: `CLAUDE.md`

When a file exists:

1. Ask the user for permission to append the routing fragment.
2. Read `openspec/schemas/ferspec/templates/adopters/AGENTS.md.fragment.md`.
3. Append as a new section at the end.

## Skills (openspec-init step 6)

Install from [fernando-delosrios-sp/skills](https://github.com/fernando-delosrios-sp/skills).

**Ask the user before running any install commands.** Recommend the full bundle below — skills reference each other, and skipping dependencies degrades behavior even when the schema still runs.

```bash
npx skills add fernando-delosrios-sp/skills --skill structured-choices
npx skills add fernando-delosrios-sp/skills --skill grill-with-docs
npx skills add fernando-delosrios-sp/skills --skill grilling
npx skills add fernando-delosrios-sp/skills --skill domain-modeling
npx skills add fernando-delosrios-sp/skills --skill architecture-decision-records
npx skills add fernando-delosrios-sp/skills --skill gherkin-authoring
npx skills add fernando-delosrios-sp/skills --skill c4-diagram
npx skills add fernando-delosrios-sp/skills --skill git-commit
npx skills add fernando-delosrios-sp/skills --skill changelog-generator
npx skills add fernando-delosrios-sp/skills --skill tdd
npx skills add fernando-delosrios-sp/skills --skill codebase-design
npx skills add fernando-delosrios-sp/skills --skill code-review
npx skills add fernando-delosrios-sp/skills --skill apply-code-changes
npx skills add fernando-delosrios-sp/skills --skill setup-matt-pocock-skills
```

| Skill | Phase | Invoked by |
|---|---|---|
| structured-choices | cross-cutting | model-invocation; user gates across workflow |
| grill-with-docs | discovery | schema.yaml |
| grilling | discovery | grill-with-docs |
| domain-modeling | discovery | grill-with-docs; Language format |
| architecture-decision-records | discovery | domain-modeling; grill-with-docs ADR side effects |
| gherkin-authoring | specs | schema.yaml |
| c4-diagram | design | schema.yaml |
| git-commit | apply | schema.yaml |
| changelog-generator | tasks, apply | schema.yaml; git-commit |
| tdd | apply | schema.yaml |
| codebase-design | apply | tdd (seam / interface vocabulary) |
| code-review | apply | tdd (post-implementation review) |
| apply-code-changes | apply | schema.yaml |
| setup-matt-pocock-skills | setup | user; once after skill install |

If the user skips skills from this list, note which phases lose skill-backed behavior and which fallbacks apply.

**Post-install setup** — run once after all skills above are installed:

Invoke `/setup-matt-pocock-skills` to scaffold issue tracker, domain docs, and triage label config under `docs/agents/`. Required for `code-review`, `tdd`, and optional `wayfinder`.

**Optional — pre-change planning** (not part of the ferspec change lifecycle; install when multi-session planning happens before `/opsx:new`):

```bash
npx skills add fernando-delosrios-sp/skills --skill wayfinder
npx skills add fernando-delosrios-sp/skills --skill search
```

| Skill | Phase | Invoked by |
|---|---|---|
| wayfinder | pre-change | user; uses grilling + domain-modeling |
| search | pre-change | wayfinder research tickets (`/research` → investigate) |

## Verify (openspec-init step 6, after step 5)

Run after ubiquitous-language and domain specs exist (openspec-init step 5):

1. `openspec schema validate ferspec`
2. Installed skills appear in the agent's available skills list
3. Confirm `openspec/specs/ubiquitous-language/spec.md` exists — terms marked `promote` in discovery become ubiquitous-language delta during specs phase; canonical merge at archive
4. Smoke-test change: `/opsx:new test-ferspec --schema ferspec`
5. Confirm `openspec/changes/test-ferspec/` exists with ferspec planning artifacts (proposal, discovery, design, specs, tasks). `tracking.md` is **not** created by `/opsx:new` — autonomous apply only. **Delete the smoke-test change** — `rm -rf openspec/changes/test-ferspec`. Do not archive; it has no spec deltas to merge.

## 1. c4-diagram skill

- [x] 1.1 Rewrite `.agents/skills/c4-diagram/SKILL.md` to emit a C4 flowchart (mermaid `flowchart`, C4 roles via shapes/`classDef`/subgraphs) into `design.md` §Architecture; keep the skill name; drop `.drawio` as output
- [x] 1.2 Replace `references/drawio-template.md`, `element-templates.md`, and `legend-template.md` with mermaid templates; update `agents/openai.yaml` description to mermaid, not draw.io

## 2. ferspec + config

- [x] 2.1 Update `openspec/schemas/ferspec/schema.yaml` design instruction and `templates/design.md` to require an inline C4 flowchart (no `diagrams/<change-name>.drawio`)
- [x] 2.2 Apply the same schema/template edits to `.agents/skills/openspec-init/schemas/ferspec/`
- [x] 2.3 Update `openspec/config.yaml` design rule so “C4 diagram” means C4 flowchart inline in `design.md`

## 3. entro-connect Intro C4

- [x] 3.1 Replace ASCII C4 in `.agents/skills/entro-connect/intro.md` with the Intro C4 mermaid fence (same topology: Operator, Agent + entro-connect, Skill catalog, Vendor CLI / MCP, Entro UI, Connector, Integration)
- [x] 3.2 Keep `skills/entro-connect/intro.md` in lockstep with `.agents/skills/entro-connect/intro.md`

## 4. Verification

- [x] 4.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 4.2 Named tests: ferspec design instruction does not require `.drawio`; c4-diagram skill does not instruct writing `.drawio`; both intro.md copies contain a mermaid `flowchart` fence and not the ASCII arrow sketch
- [x] 4.3 Named tests: existing `openspec/changes/**/diagrams/*.drawio` files still exist
- [x] 4.4 Run `openspec validate --all --json` and `.venv/bin/python -m pytest`

## 5. Documentation

- [x] 5.1 Add `openspec/specs/architecture-diagrams/spec.md` to README Specs list after apply (or a one-line pointer that C4s are mermaid in `design.md`)
- [x] 5.2 Skip Entro OpenAPI — no API contract change
- [x] 5.3 Skip CLI `--help` — no public CLI surface

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change via changelog-generator
- [x] 6.2 Confirm the entry names C4 flowchart as the default, Intro C4 as mermaid, and that existing `.drawio` files are left in place

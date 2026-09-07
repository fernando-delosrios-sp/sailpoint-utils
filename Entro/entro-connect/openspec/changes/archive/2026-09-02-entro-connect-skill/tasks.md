## 1. Catalog Connection details and Prep steps

- [x] 1.1 Extend `integration_catalog.py`: row `summary`; `connectionFields` `{name, secret, obtainedHow}`; `prepSteps` `{title, instruction, evidence}` on Setup method or row; Coverages MAY add `prepSteps`
- [x] 1.2 Validation: every row has `summary`, fields, and steps; Worker Group must not appear in `connectionFields`; no `command` on steps; no secret-shaped values; Coverage empty `prepSteps` means inherit
- [x] 1.3 Curate `summary`, `connectionFields`, and `prepSteps` for every target and Coverage from ingested pages at authoring time (text lives in JSON)
- [x] 1.4 Same writer emits Skill catalog `.agents/skills/entro-connect/integrations.json` (no markdown-path dependency for a Connect run) plus `documentation/integrations.json`
- [x] 1.5 Fail validation if Skill catalog is missing, stale vs catalog module targets, or lacks `summary` / fields / steps

## 2. entro-connect skill (initial)

- [x] 2.1 Author `.agents/skills/entro-connect/SKILL.md` (model-invoked; reads Skill catalog only; under 500 lines) using writing-for-agents
- [x] 2.2 Add disclosed files: `lock-target.md`, `intro.md` (ASCII C4, `summary`), `connector-deployment.md`, `modes.md`, `tools.md`, `session-log.md`
- [x] 2.3 Add `.gitignore` pattern `entro-*.md`; do not ignore `documentation/`
- [x] 2.4 Point AGENTS.md Agent skills at entro-connect; state the skill MUST NOT open `documentation/` pages

## 3. Verification (initial)

- [x] 3.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 3.2 Named tests for: every row has `summary`, `connectionFields`, `prepSteps`; Worker Group absent from JSON fields; Okta `obtainedHow`; Coverages omit `connectionFields`; AWS setup-method steps; Copilot Studio additive `instruction`; no `command` on steps
- [x] 3.3 Named tests: Skill catalog written with ingest index; every target present; Connect run data present without `documentation/` paths; gitignore `entro-*.md`
- [x] 3.4 Run `openspec validate --all --json` and confirm this change is valid

## 4. Documentation (initial)

- [x] 4.1 Update repo `README.md` for `summary` / fields / steps, Skill catalog path, Connect log gitignore, and that entro-connect does not read the documentation tree
- [x] 4.2 Skip Entro OpenAPI — no API contract change
- [x] 4.3 Update `documentation/README.md` and `integration_catalog.py` docstring (two JSON outputs; Worker Group global)
- [x] 4.4 Write `docs/adr/0001-entro-connect-catalog-and-skill.md` (Skill catalog copy, self-contained JSON, no documentation-tree dependency)

## 5. Changelog (initial)

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm the entry names self-contained Connection details and Prep steps, Skill catalog copy, the entro-connect skill, and that secrets stay out of agent context

## 6. Catalog contracts

- [x] 6.1 Extend `toolInstall` with presence check, Capability probe, auth-check, and Platform identity query; keep `authOnce` and install docs; record official source URL and retrieval date per probe
- [x] 6.2 Add Operator input schema (`key`, prompt, purpose, validation, optional default, `secret` false) and bind operator-chosen Connection details plus Worker Group to keys
- [x] 6.3 Add Typed action schema bound to Prep steps: preview or no-preview, mutation, target, expected change, verification, rollback or irreversible impact, secret-producing flag, source URL, retrieval date; pin external scripts with URL, version, checksum
- [x] 6.4 Validation: fail if Fit `preferred` path lacks complete Operator inputs, Typed actions, probes, auth-check, identity, verification, or reversal/impact; still reject `command` on Prep steps and secret-shaped values

## 7. Preferred-path authoring

- [x] 7.1 Author Operator inputs and Typed actions for Microsoft Ecosystem (including locked Coverages), Microsoft Teams, and Azure DevOps; pin any Entro onboarding script
- [x] 7.2 Author Operator inputs and Typed actions for AWS Setup methods and GitHub rows whose Fit `preferred` is `aws` (including Coverage extras)
- [x] 7.3 Author Operator inputs and Typed actions for GCP, Google Workspace, HashiCorp Vault, OCI, Okta, and Snowflake
- [x] 7.4 Author Operator inputs and Typed actions for Akeyless, GitLab, Jenkins, BuildKite, JFrog Artifactory, and Salesforce
- [x] 7.5 Correct Fit to `usable` or `none` with rationale for any path that cannot be evidenced from an official source; regenerate both JSON files

## 8. Skill rewrite

- [x] 8.1 Rewrite `SKILL.md` steps: Lock → create Connect log → Intro (collect names, persist brief, no-action-yet) → Operation mode → tools → Configuration plan → Prep → Connection details; gates named in that order; writing-for-agents
- [x] 8.2 Rewrite `intro.md` and `session-log.md`: same chat brief persisted (purpose, Coverages, topology, prerequisites, tools, names, fields, outline, safety boundary, C4); instructions-only batch still persists Intro; skip tools only
- [x] 8.3 Rewrite `modes.md`: hide automated unless complete Typed action plan; recommend topmost allowed mode; instructions persist full safe playbook
- [x] 8.4 Rewrite `tools.md`: Capability probe before install; reuse suitable tools; unsuitable → explain and gate exact upgrade; auth-check first; record Platform identity; confirm environment; Continue/check or Help loop; no login secret in session
- [x] 8.5 Add Prep/disclosure steps: persist Configuration plan; per-change preview when supported; Approve / adjust (inputs or remaining mode) / stop; name collision inspect-and-gate; secret-producing actions operator-executed; verification fail stops the plan

## 9. Verification

- [x] 9.1 Confirm canonical test command remains `.venv/bin/python -m pytest`
- [x] 9.2 Named tests for Operator inputs, Typed action completeness on Fit `preferred`, `toolInstall` probe/auth/identity fields, Fit downgrade when incomplete, no `command` on Prep steps
- [x] 9.3 Fixture replay of every remaining preferred path (presence, probe, auth-check, identity, plan, per-change disclosure, secret-producing operator step)
- [x] 9.4 Consented Microsoft Ecosystem dry-run against the ready non-production environment; record non-secret Platform identity and evidence in the Connect log
- [x] 9.5 Run `openspec validate --all --json` and confirm this change is valid

## 10. Documentation

- [x] 10.1 Update repo `README.md` for Intro-first Connect run, progressive Connect log, Operator inputs, Typed actions, and complete-plan automated bar
- [x] 10.2 Skip Entro OpenAPI — no API contract change
- [x] 10.3 Update `documentation/README.md` and `integration_catalog.py` docstring for Operator inputs, Typed actions, and `toolInstall` probes
- [x] 10.4 Update `docs/adr/0001-entro-connect-catalog-and-skill.md` (or a follow-on ADR) for complete-plan automation, Platform identity, and per-change disclosure
- [x] 10.5 Point AGENTS.md entro-connect line at Lock, persisted Intro, Operation mode, Connect log

## 11. Changelog

- [x] 11.1 Create or update changelog entry for this revision via changelog-generator
- [x] 11.2 Confirm the entry names persisted Intro before mode, tool probes, Platform identity, Operator inputs, Typed actions, and that secrets stay out of agent context

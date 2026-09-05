## 1. Catalog schema and AWS fill

- [x] 1.1 Extend `catalog_contracts.py` so `configureOnce` is an optional Tool install key: `command`, nested `check` (`command`, `sourceUrl`, `retrievedAt`), `suitableWhen`, `sourceUrl`, `retrievedAt`; fail validation if the object is present but incomplete or secret-shaped
- [x] 1.2 Add `configureOnce` on `TOOL_INSTALL["aws"]` in `integration_catalog.py`: `command` `aws configure sso`; `check.command` tests `AWS_CONFIG_FILE` or `$HOME/.aws/config` for `sso_session` or `sso_start_url` (not `credentials`); source AWS IAM Identity Center profile docs; `retrievedAt` `2026-09-03`
- [x] 1.3 Leave `az` (and other binaries) without `configureOnce`; omit it on `terraform` when that entry exists
- [x] 1.4 Regenerate ingest `documentation/integrations.json` and both Skill `tool-install.json` files from the catalog writer

## 2. Connect tools step

- [x] 2.1 Update `tools.md` in both skill trees: after failed auth-check, run Configure once check; skip wizard when suitable; operator-run `configureOnce.command` in every mode including automated; re-run auth-check; skip `authOnce` when then valid; inherit `configureOnce` from a locked tool with the same `authCheck.command` (prefer `aws`)
- [x] 2.2 Keep valid auth-check skipping both Configure once and login; keep Help diagnosing non-secret output; never accept a login secret; never run the wizard or `authOnce` in the agent
- [x] 2.3 Add at most one sentence to `SKILL.md` tools-step summary if the current one still says auth-check then `authOnce` only; keep both skill trees identical

## 3. Verification

- [x] 3.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 3.2 Named tests: AWS has complete `configureOnce`; `az` omits it; `terraform` omits it when present; incomplete `configureOnce` fails validation; writer copies the object into ingest `toolInstall` and both Skill Tool install files; check command does not mention `credentials`
- [x] 3.3 Named tests (skill-file assertions, both trees): valid session skips Configure once and login; unsuitable check requests the wizard operator-side in automated; suitable check skips wizard and requests `authOnce`; post-wizard valid auth skips `authOnce`; terraform inherit uses the AWS object; Help after login unchanged
- [x] 3.4 Run `openspec validate --change configure-once --json` and `.venv/bin/python -m pytest`

## 4. Documentation

- [x] 4.1 Update `README.md` and `documentation/README.md` / `integration_catalog.py` docstring if they list `toolInstall` fields, so they name optional Configure once
- [x] 4.2 Skip Entro OpenAPI — no API contract change
- [x] 4.3 No new ADR — design.md is the decision record for this additive field

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm the entry names optional Configure once, AWS `aws configure sso` before `aws sso login`, and that the wizard stays operator-run

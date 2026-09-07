## 1. Catalog schema

- [x] 1.1 Extend `ConfigureOnce` in `catalog_contracts.py` with an ordered `prompts` tuple of `{prompt, whereToFind}` and a `docsUrl`; serialise both in `configure_once_to_dict`
- [x] 1.2 Extend `configure_once_fields_present` so a present `configureOnce` must have a non-empty `prompts` list, `docsUrl`, and `prompt` plus `whereToFind` on every entry; keep rejecting secret-shaped values; keep omission valid

## 2. AWS prompt content

- [x] 2.1 Fill the `aws` `configureOnce.prompts` in `integration_catalog.py` in wizard order: SSO session name, SSO start URL, SSO region, registration scopes, account, role, CLI default client Region, CLI default output format, CLI profile name
- [x] 2.2 Write `whereToFind` for each: access portal permission set → Access keys → IAM Identity Center credentials (start URL and SSO region, with the Issuer URL alternative on AWS CLI 2.22.0+), `sso:account:access` default for scopes, target AWS account and a permission set that can create the Entro role, and operator choices for the CLI region, output, and profile name
- [x] 2.3 Set `configureOnce.docsUrl` to the AWS IAM Identity Center authentication page and confirm `sourceUrl` / `retrievedAt` against current AWS pages
- [x] 2.4 Regenerate `documentation/integrations.json` and both Skill `tool-install.json` files; confirm `terraform` and `az` still omit `configureOnce`

## 3. Connect tools step

- [x] 3.1 Update `tools.md` in both skill trees: the Configure once request lists the command, every cataloged prompt with its `whereToFind` in catalog order, and the `docsUrl`, then Continue / Help
- [x] 3.2 State in `tools.md` that the skill must not invent prompt guidance, must not collect wizard answers as Operator inputs, and must not write them to the Connect log; the inherited AWS object relays the AWS prompts
- [x] 3.3 Confirm both skill trees stay byte-identical

## 4. Verification

- [x] 4.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 4.2 Named tests: `configureOnce` without `prompts` fails validation; a prompt entry without `whereToFind` fails; AWS covers the nine prompts in order; start URL and SSO region name the access portal; `docsUrl` present; writer copies prompts into ingest `toolInstall` and both Skill Tool install files
- [x] 4.3 Named tests (skill-file assertions, both trees): the request relays prompts with sources and `docsUrl`; wizard answers are not Operator inputs and not logged; skip paths and the Terraform inherit rule are unchanged
- [x] 4.4 Run `openspec validate configure-once-prompts --type change --json` and `.venv/bin/python -m pytest`

## 5. Documentation

- [x] 5.1 Update `README.md`, `documentation/README.md`, and the `integration_catalog.py` docstring where they list Tool install fields, so they name Configure once prompts
- [x] 5.2 Skip Entro OpenAPI — no API contract change
- [x] 5.3 No new ADR — design.md is the decision record for this additive field

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change via changelog-generator
- [x] 6.2 Confirm the entry says the Configure once request now names where each wizard value comes from, with AWS as the filled example

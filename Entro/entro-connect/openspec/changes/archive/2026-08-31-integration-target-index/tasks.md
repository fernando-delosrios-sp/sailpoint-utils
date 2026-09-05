## 1. Target row model

- [x] 1.1 Replace `name` / `variant` on `IntegrationDefinition` with `tile` plus `target_selection` (None when the tile leads straight to one form), and make `documentation` a tuple of pages
- [x] 1.2 Add `setup_methods` and `authentication_methods` as tuples of `(name, documentation)` pairs
- [x] 1.3 Remove `connector_deployments` and `connector_documentation` from the row model, keeping `ALL_CONNECTOR_DEPLOYMENTS` only as the product-level topology list
- [x] 1.4 Update `integration_to_dict` to emit `tile`, `targetSelection`, `category`, `documentation`, `setupMethods`, `authenticationMethods`, `connectorRequirement`, `connectorEvidence`

## 2. Requirement evidence and validation

- [x] 2.1 Add a `ConnectorEvidence` type carrying `page`, `basis` (`worker-group-field-documented` | `complete-field-list-omits-worker-group`), and `quote`
- [x] 2.2 Fail validation when `connectorRequirement` is `required` or `not-required` and no evidence is present
- [x] 2.3 Fail validation when `basis` does not match the requirement value, and when `unknown` carries evidence
- [x] 2.4 Fail validation when the `(tile, targetSelection)` pair repeats across rows
- [x] 2.5 Extend `validate_integration_paths` to resolve every `documentation` entry, every setup and authentication method page, and every `connectorEvidence.page` against the documentation tree

## 3. Re-derive rows from the ingested docs

- [x] 3.1 Read the Add New Account navigation path on each onboarding page and record the tile label and in-form target selection for every row
- [x] 3.2 Collapse setup-method rows: AWS (CloudFormation + Manual Assume Role) to one AWS row; Microsoft Ecosystem absorbing Azure / Entra / M365 (both methods) and SharePoint / OneDrive; Google Cloud Platform (Service Account Key + Workload Identity Federation as authentication methods)
- [x] 3.3 Collapse GitLab to one row — self-managed is a form checkbox (`gitlab-onboarding.md`), not a target — and the two GitHub token rows into `GitHub Cloud - Legacy` with both token types as authentication methods
- [x] 3.4 Keep as distinct in-form targets: GitHub Cloud - New / Cloud - Legacy / Enterprise Server, BitBucket Cloud / Data Center, Atlassian Jira and Confluence (Cloud and Server), Slack Private App / Enterprise Grid App, File Shares Scanning SMB / SFTP (SSH) / WinRM
- [x] 3.5 Rename rows to the tile labels the docs print: `File Shares Scanning` for Remote File System, `Microsoft Ecosystem` for Azure / Entra / M365 and SharePoint
- [x] 3.6 Attach evidence to every row: cite the page and Worker Group field label for `required` rows, the complete field list for `not-required` rows, and set `unknown` with no evidence where the docs never settle it (including Microsoft Teams Messaging Risks and Wiz)
- [x] 3.7 Regenerate `documentation/integrations.json` and confirm no row asserts a requirement without resolvable evidence

## 4. Verification

- [x] 4.1 Confirm canonical test command: `python -m pytest`
- [x] 4.2 Rewrite `test_integrations_index_written_on_ingest` for the target-keyed shape, asserting the AWS row is single and `required`
- [x] 4.3 Replace `test_integrations_index_rejects_contradictory_connector_fields` with named tests for each delta scenario: required cites the documented field, not-required cites a complete field list, undocumented stays unknown, unproven claim fails validation, one target one row, in-form selections are distinct rows, authentication method does not create a row, targets named as Entro labels them, collapsed rows keep their documentation
- [x] 4.4 Add a glossary test that specs use Add New Account target, Setup method, and Authentication method, and that Integration variant is marked superseded
- [x] 4.5 Run `openspec validate --all --json` and confirm all items valid

## 5. Documentation

- [x] 5.1 Update `README.md` where it describes `integrations.json` fields to the target-keyed shape and the evidence rule
- [x] 5.2 Update `documentation/README.md` header text that describes the integration index
- [x] 5.3 Document the four connector topologies once at product level, outside the per-row data, and link the `entro-connector/` pages there
- [x] 5.4 Update `integration_catalog.py` module and helper docstrings, which currently say "onboarding form lists Worker Group" as the row rule

## 6. Changelog

- [x] 6.1 Create or update the changelog entry for this change via changelog-generator
- [x] 6.2 Confirm the entry states the corrected connector requirements, the row collapses (notably SharePoint into Microsoft Ecosystem), and the removal of the two connector fields

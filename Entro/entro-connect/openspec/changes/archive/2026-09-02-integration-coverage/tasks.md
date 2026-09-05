## 1. Coverage model and validation

- [x] 1.1 Add a Coverage type `{name, documentation}` and a `coverages` tuple on `IntegrationDefinition`; emit `coverages` from `integration_to_dict` (empty list when none)
- [x] 1.2 Default existing rows to `coverages=()` so the catalog still serializes
- [x] 1.3 Fail validation when a Coverage has an empty name, no documentation paths, a missing file under `documentation/`, or a duplicate name on the same row
- [x] 1.4 Extend `validate_integration_paths` to resolve every Coverage documentation path

## 2. Inventory from collapsed sections

- [x] 2.1 Microsoft Ecosystem: Coverages SharePoint / OneDrive and Copilot Studio citing those section pages; no Microsoft Copilot Studio tile row
- [x] 2.2 GitHub: Coverage Real-time scanning on all three GitHub target rows; Coverage Enterprise S3 log streaming on GitHub Cloud - New and GitHub Cloud - Legacy only
- [x] 2.3 CrowdStrike: one Coverage Falcon RTR citing the three RTR pages; Atlassian / Jira Cloud: Jira real-time scanning; SailPoint ISC: Aggregating Entro NHIs & AI agents
- [x] 2.4 Leave every other row's Coverage list empty (including Git clone scanning, Copilot chats, Defender, Teams secrets, Azure Hybrid, continuous Key Vault, Okta custom role)
- [x] 2.5 Regenerate `documentation/integrations.json`

## 3. Verification

- [x] 3.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 3.2 Named tests for: collapsed GitBook section becomes a Coverage; permission-group heading is not a Coverage; Git clone scanning is not a Coverage; other collapsed sections on their targets (GitHub RTS ×3, S3 not on Enterprise Server, Falcon RTR, Jira RTS, SailPoint aggregation); Coverage citation must resolve; empty Coverage list is valid; missing provider-list tile is not a target; index rows include `coverages`
- [x] 3.3 Glossary tests: specs use Coverage not feature; Add New Account target Notes name the provider list and missing-tile → Coverage
- [x] 3.4 Run `openspec validate --all --json` and confirm all items valid

## 4. Documentation

- [x] 4.1 Update repo `README.md` if it describes `integrations.json` fields, to include Coverages
- [x] 4.2 Update `documentation/README.md` index blurb to mention Coverages as children of a target
- [x] 4.3 Update `integration_catalog.py` module docstring to define Coverage vs target vs permission group

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm the entry names Coverage on the Integration index, Copilot Studio as Microsoft Ecosystem Coverage not a tile, and that permission-group-only surfaces are omitted

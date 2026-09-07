## 1. Drop connector fields from the catalog

- [x] 1.1 Remove `ConnectorRequirement`, `EvidenceBasis`, `ConnectorEvidence`, and related helpers from `integration_catalog.py`; drop those attributes from `IntegrationDefinition` and `_row`
- [x] 1.2 Stop emitting `connectorRequirement` and `connectorEvidence` from `integration_to_dict`
- [x] 1.3 Fail validation when either key is present on a row; stop resolving `connectorEvidence.page` as a documentation path
- [x] 1.4 Remove per-row connector arguments from every `INTEGRATIONS` entry (including formerly `unknown` Teams, Wiz, Salesforce, GDrive)

## 2. Regenerate index

- [x] 2.1 Regenerate `documentation/integrations.json` with neither connector key on any row

## 3. Verification

- [x] 3.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 3.2 Named tests for: index rows omit connector requirement keys; connector keys fail validation; formerly unknown rows match every other row; curated targets omit those keys
- [x] 3.3 Glossary tests: index specs do not use Connector requirement as a live term; Connector requirement and Requirement evidence are marked superseded
- [x] 3.4 Run `openspec validate --all --json` and confirm all items valid

## 4. Documentation

- [x] 4.1 Update repo `README.md` ingest blurb to drop `connectorRequirement` / `connectorEvidence`
- [x] 4.2 Update `documentation/README.md` and `ingest_docs.py` index blurb the same way; keep product-level Entro Connector topology links
- [x] 4.3 Update `integration_catalog.py` module docstring if it still mentions connector requirement

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm the entry states the index no longer records whether a connector is required, and that Docker / Helm / SaaS Perimeter stay product-level docs

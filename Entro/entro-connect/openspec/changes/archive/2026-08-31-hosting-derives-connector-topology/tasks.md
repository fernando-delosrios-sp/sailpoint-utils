## 1. Catalog hosting and derivation

- [x] 1.1 Add a `Hosting` type (`public` / `self-hosted` / `operator-selected`) and a `hosting` field on `IntegrationDefinition` and `_row`
- [x] 1.2 Add a derivation helper that maps hosting to Connector deployment (public → SaaS Perimeter; self-hosted → Docker Compose and Kubernetes Helm, Helm preferred when cluster-native; operator-selected → follow the form choice) and wire `ConnectorDeployment` / `CONNECTOR_TOPOLOGY_PAGES`
- [x] 1.3 Emit `hosting` from `integration_to_dict`; do not emit a topology list; keep rejecting `connectorRequirement` / `connectorEvidence` / topology keys
- [x] 1.4 Fail validation when `hosting` is missing or not one of the three values
- [x] 1.5 Assign `hosting` on every `INTEGRATIONS` entry from the operator rule and form docs (`operator-selected` for GitLab and n8n)

## 2. Regenerate index

- [x] 2.1 Regenerate `documentation/integrations.json` so every row has `hosting` and none has a topology list key

## 3. Verification

- [x] 3.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 3.2 Named tests for: every row carries a hosting value; unknown or missing hosting fails validation; public hosting derives SaaS Perimeter; self-hosted hosting derives Docker or Helm; operator-selected hosting follows the form; curated targets include hosting and still omit connector keys
- [x] 3.3 Glossary tests: index specs name Hosting not connector type; Hosting is defined; Connector deployment Notes state the derivation
- [x] 3.4 Run `openspec validate --all --json` and confirm all items valid

## 4. Documentation

- [x] 4.1 Update repo `README.md` ingest blurb to name `hosting` and that topology is derived, not stored
- [x] 4.2 Update `documentation/README.md` and `ingest_docs.py` index blurb the same way; keep product-level Entro Connector topology links
- [x] 4.3 Update `integration_catalog.py` module docstring to mention hosting

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm the entry states rows record hosting, topology is derived (SaaS Perimeter vs Docker/Helm), and Docker / Helm / SaaS Perimeter pages stay product-level docs

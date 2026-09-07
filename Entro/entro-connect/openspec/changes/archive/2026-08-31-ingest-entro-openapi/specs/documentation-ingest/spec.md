<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Entro API catalog is captured as an Entro OpenAPI snapshot

Documentation ingest SHALL fetch the Entro API catalog (`GET {endpoint}/v1/docs`) and write a full Entro OpenAPI snapshot as YAML at `documentation/api/openapi.yaml`. The snapshot MUST include all published paths. `servers[0].url` MUST be the endpoint used for the fetch. Default endpoint SHALL be `https://eval-api.entro.security`.

#### Scenario: Successful API catalog ingest

- **GIVEN** a reachable Entro API catalog at the configured endpoint and a valid API key in the environment
- **WHEN** API documentation ingest runs
- **THEN** `documentation/api/openapi.yaml` MUST contain OpenAPI 3 with the catalog’s published paths
- **AND** `servers[0].url` MUST equal the fetch endpoint (trailing slash stripped)

#### Scenario: Snapshot is the full catalog

- **GIVEN** the Entro API catalog includes operations outside Integrations (for example Risk or Entro API Keys)
- **WHEN** API documentation ingest writes the Entro OpenAPI snapshot
- **THEN** those operations MUST appear in the snapshot
- **AND** ingest MUST NOT drop paths to keep only Integrations

### Requirement: API ingest fails closed without a catalog

API documentation ingest MUST exit unsuccessful when `ENTRO_API_KEY` is missing or empty, when `GET {endpoint}/v1/docs` fails, or when the body is not a usable OpenAPI document with `paths`. It MUST NOT treat a missing, empty, or stale Entro OpenAPI snapshot as a successful run.

#### Scenario: Missing API key

- **GIVEN** `ENTRO_API_KEY` is unset or empty
- **WHEN** API documentation ingest starts
- **THEN** ingest MUST exit unsuccessful
- **AND** ingest MUST NOT write a successful Entro OpenAPI snapshot for that run

#### Scenario: API catalog fetch failure

- **GIVEN** `ENTRO_API_KEY` is set
- **WHEN** `GET {endpoint}/v1/docs` fails or returns a body without OpenAPI `paths`
- **THEN** ingest MUST exit unsuccessful
- **AND** ingest MUST NOT replace an existing snapshot with an empty document as success

### Requirement: Entro OpenAPI snapshot is redacted

Before writing the Entro OpenAPI snapshot, ingest SHALL replace GitHub PAT-shaped strings (`ghp_` and `github_pat_`) with the same placeholders used for GitBook page ingest.

#### Scenario: Example PAT in the catalog is redacted

- **GIVEN** the Entro API catalog JSON includes a `ghp_` shaped example string
- **WHEN** API documentation ingest writes `documentation/api/openapi.yaml`
- **THEN** the file MUST contain `ghp_<redacted>`
- **AND** the original `ghp_` token MUST NOT appear in the file

### Requirement: GitBook ingest does not fetch the Entro API catalog

GitBook documentation ingest SHALL remain a separate command. It MUST NOT request `{endpoint}/v1/docs` or require `ENTRO_API_KEY`.

#### Scenario: GitBook ingest stays key-free

- **GIVEN** `ENTRO_API_KEY` is unset
- **WHEN** GitBook documentation ingest runs against a GitBook markdown catalog
- **THEN** that run MUST NOT GET `/v1/docs`
- **AND** it MUST still be able to write the documentation tree when the catalog fetch succeeds

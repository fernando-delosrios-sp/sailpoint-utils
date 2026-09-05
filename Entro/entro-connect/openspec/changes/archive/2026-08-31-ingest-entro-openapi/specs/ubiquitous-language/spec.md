<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Entro API catalog terms

The glossary SHALL define Entro OpenAPI snapshot and Entro API catalog with the definitions in Term entries below. Documentation ingest Notes SHALL state that ingest covers both the GitBook markdown catalog and the Entro API catalog, and that the Entro OpenAPI snapshot is not a documentation-tree page.

#### Scenario: API ingest specs use canonical catalog terms

- **GIVEN** a change authors documentation-ingest requirements for the product API
- **WHEN** it names the committed OpenAPI file or the `{endpoint}/v1/docs` document
- **THEN** it MUST use Entro OpenAPI snapshot and Entro API catalog rather than swagger dump, portal HTML, or GitBook markdown catalog

#### Scenario: Documentation ingest names both sources

- **GIVEN** the glossary entry for Documentation ingest
- **WHEN** a reader uses that term after this change archives
- **THEN** the Notes MUST mention GitBook Integration pages and the Entro API catalog as ingest sources
- **AND** the Notes MUST NOT treat `documentation/api/openapi.yaml` as a documentation-tree page

## Term entries

### Term: Entro OpenAPI snapshot
**Context**: documentation-ingest
**Definition**: The committed OpenAPI 3 document of Entro’s product API, stored at `documentation/api/openapi.yaml` inside the documentation folder.
**Aliases**: none
**Notes**: Sibling of the documentation tree, not a cleaned-nav GitBook page. Do not call it a swagger dump or a portal scrape.

### Term: Entro API catalog
**Context**: documentation-ingest
**Definition**: The machine-readable API definition Entro serves at `{endpoint}/v1/docs` (OpenAPI 3 JSON), which the API docs portal loads after login.
**Aliases**: none
**Notes**: Not the GitBook markdown catalog, `llms.txt`, or HTML from apidocs.entro.security.

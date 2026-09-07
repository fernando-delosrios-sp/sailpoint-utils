## ADDED Requirements

### Requirement: Protected documentation credentials stay operator-controlled

Documentation ingest MUST read `ENTRO_DOCS_COOKIE` from the operator's local gitignored `.env` file or existing process environment. That value MUST be sent only as the HTTP `Cookie` header. Ingest MUST NOT accept cookie values as command-line arguments, print them, persist them in output, or expose `Cookie` or `Authorization` headers. It MUST fail before crawling when the value is missing or empty, and the failure text MUST include the operator cookie steps (browser login at `https://docs.entro.security/`, copy the `Cookie` header from a successful docs-host request, set `ENTRO_DOCS_COOKIE`, rerun).

#### Scenario: Missing protected-site credentials fail before network access
- **GIVEN** `ENTRO_DOCS_COOKIE` is missing or empty
- **WHEN** protected documentation ingest starts
- **THEN** ingest MUST exit unsuccessful before requesting the documentation site
- **AND** the error MUST tell the operator how to log in and export the session cookie
- **AND** the existing documentation tree MUST remain unchanged

#### Scenario: Credential material is absent from observable output
- **GIVEN** a local protected-site session cookie is available
- **WHEN** documentation ingest succeeds or fails
- **THEN** logs, errors, generated markdown, indexes, and fixtures MUST NOT contain the cookie value or a `Cookie` or `Authorization` header

### Requirement: Protected documentation site is the authoritative page source

Documentation ingest SHALL start at `https://docs.entro.security/` and use authenticated same-origin navigation to discover documentation pages. It MUST send `ENTRO_DOCS_COOKIE` as the `Cookie` header, normalize duplicate URL variants, visit each canonical page at most once, exclude account, authentication, logout, asset, and external URLs, and MUST NOT fall back to `entro.gitbook.io`.

#### Scenario: Authenticated navigation discovers documentation pages
- **GIVEN** a valid local session cookie and a protected start page with same-origin documentation links
- **WHEN** documentation ingest runs
- **THEN** each canonical same-origin documentation page MUST be considered once
- **AND** fragment, tracking-query, asset, account, logout, and external links MUST NOT become documentation pages

#### Scenario: Authentication rejection fails closed
- **GIVEN** the protected documentation site rejects the session cookie or returns a Descope or GitBook visitor-auth login challenge
- **WHEN** documentation ingest requests the start page
- **THEN** ingest MUST exit unsuccessful
- **AND** the error MUST tell the operator how to refresh and export the session cookie
- **AND** it MUST NOT request the former public GitBook catalog
- **AND** the existing documentation tree MUST remain unchanged

### Requirement: Documentation tree publication is atomic

Documentation ingest MUST stage converted markdown and generated indexes outside the current `documentation/` tree. It SHALL replace the current source-derived tree only when discovery is non-empty, all required page fetches and conversions succeed, secret redaction succeeds, and index validation succeeds.

#### Scenario: Complete crawl replaces the documentation tree
- **GIVEN** authenticated discovery finds at least one documentation page and every required page produces usable redacted markdown
- **WHEN** staged indexes validate successfully
- **THEN** ingest MUST publish the staged documentation tree as one completed snapshot

#### Scenario: Partial page failure preserves the previous tree
- **GIVEN** a valid documentation tree already exists
- **WHEN** one required page fails to fetch or convert during a new ingest
- **THEN** ingest MUST continue attempting the remaining discovered pages and report the failure
- **AND** the run MUST exit unsuccessful
- **AND** the existing documentation tree MUST remain unchanged

#### Scenario: Empty discovery is not published
- **GIVEN** authentication succeeds but discovery yields no usable documentation pages
- **WHEN** ingest validates the staged crawl
- **THEN** ingest MUST exit unsuccessful
- **AND** it MUST NOT replace the existing documentation tree

### Requirement: Protected-site ingest does not fetch the Entro API catalog

Protected-site documentation ingest SHALL remain a separate command. It MUST NOT request `{endpoint}/v1/docs` or require `ENTRO_API_KEY`.

#### Scenario: Protected-site ingest remains independent from API ingest
- **GIVEN** a valid protected-site session cookie and `ENTRO_API_KEY` is unset
- **WHEN** protected-site documentation ingest runs
- **THEN** that run MUST NOT GET `/v1/docs`
- **AND** it MUST still be able to publish the documentation tree when the protected crawl succeeds

## MODIFIED Requirements

### Requirement: Online documentation is captured

The project SHALL fetch Entro's protected online integration documentation into durable local markdown artifacts without aborting remaining page attempts when a single page fails. The protected crawl MUST return unsuccessful when any required page fails and MUST publish only a complete validated snapshot.

#### Scenario: Successful ingest of the integrations catalog
- **GIVEN** a valid local session cookie and reachable protected Entro integration documentation
- **WHEN** documentation ingest runs
- **THEN** the discovered Integration and onboarding pages MUST be stored locally in a form a later change can parse
- **AND** the published snapshot MUST contain usable content from at least one page

#### Scenario: Partial page failure
- **GIVEN** ingest is running and one required page returns no usable content
- **WHEN** that page fails
- **THEN** ingest MUST record the failure and continue attempting remaining pages
- **AND** the run MUST exit unsuccessful without publishing the staged snapshot

## REMOVED Requirements

### Requirement: GitBook ingest does not fetch the Entro API catalog

**Reason**: The public GitBook catalog is no longer the documentation-ingest source. The equivalent separation guarantee now applies to protected-site ingest.

**Migration**: Run the protected-site documentation command with local `ENTRO_DOCS_COOKIE` after browser login; continue running API catalog ingest separately with `ENTRO_API_KEY`.

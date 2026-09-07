# documentation-ingest

## Purpose

Extract Entro's published integration documentation into structured source material
that later specs and skills can use. Raw crawls are inputs, not the product.
## Requirements
### Requirement: Online documentation is captured

The project SHALL fetch Entro's online Integration documentation into a documentation tree under `documentation/` without aborting the whole run when a single page fails.

#### Scenario: Successful ingest of the integrations catalog

- **GIVEN** a documented GitBook markdown catalog URL for Entro Integration documentation
- **WHEN** documentation ingest runs
- **THEN** the cleaned nav of Providers and linked onboarding pages MUST be stored as a documentation tree a later change can parse

#### Scenario: Partial page failure

- **GIVEN** ingest is running and one page returns no usable content
- **WHEN** that page fails
- **THEN** ingest MUST record the failure and continue with remaining pages rather than discarding the entire run
- **AND** ingest MUST exit unsuccessful if any page failed

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

### Requirement: Integration tile identity

Ingest SHALL write a curated JSON index with exactly one row for each of the 58
unique Entro Select Provider tiles evidenced by the authoritative 2026-09-03
screenshot. Each row MUST use the exact UI tile label and MUST NOT carry
`targetSelection`. The tile label alone is catalog identity. Rows MUST NOT carry
connector deployment topologies or generic connector documentation, since those
describe the Entro Connector product rather than any one Integration. IDE
plugins, Entro Connector deployment docs, SSO setup, CLI utilities, and other
non-integration sections MUST NOT appear.

#### Scenario: Unique tile rows

- **GIVEN** the curated catalog is generated from the authoritative Select Provider evidence
- **WHEN** ingest writes the documentation tree
- **THEN** `integrations.json` MUST contain exactly 58 unique rows using exact UI tile labels
- **AND** no row MUST contain `targetSelection`
- **AND** excluded documentation sections MUST NOT appear as Integrations

#### Scenario: One tile, one row

- **GIVEN** several documented routes resolve to one Select Provider tile
- **WHEN** the Integration index is written
- **THEN** they MUST produce one tile row with evidenced Integration paths
- **AND** validation MUST fail if the exact tile label appears twice

#### Scenario: In-form choices are Integration paths

- **GIVEN** one tile offers several mutually exclusive connection-form choices
- **WHEN** the Integration index is written
- **THEN** those choices MUST be Integration paths on the one tile row
- **AND** they MUST NOT become separate rows

#### Scenario: Credential choice binds to a path

- **GIVEN** a tile whose form exposes mutually exclusive credential routes
- **WHEN** the Integration index is written
- **THEN** those routes MUST be Integration paths or part of compound path names
- **AND** they MUST NOT become separate rows or Authentication method dimensions

#### Scenario: Integrations are named as Entro labels them

- **GIVEN** a documentation section whose name differs from the Add New Account tile label
- **WHEN** the Integration index is written
- **THEN** the row MUST use the exact Select Provider tile label
- **AND** when the documented navigation path names a tile that exists on that list, the row MUST use that label

#### Scenario: Consolidated tile keeps its documentation

- **GIVEN** several documentation sections that resolve to one Integration tile
- **WHEN** those rows collapse into one
- **THEN** the surviving row MUST list every one of those documentation pages

#### Scenario: Missing provider-list tile is not an Integration

- **GIVEN** a GitBook section whose documented Add New Account path names a tile the provider list does not offer
- **WHEN** the Integration index is written
- **THEN** that section MUST NOT appear as an Integration row

### Requirement: Integration path

Each Integration row MUST declare zero or more `integrationPaths`. An Integration
path SHALL represent a mutually exclusive choice visible on that tile's Entro
connection form and SHALL own its Configuration tools, `connectionFields`,
`prepSteps`, Operator inputs, and Typed actions. A singleton path is implicit:
the thin index MUST omit `integrationPathNames` or list one name, and Connect MUST
NOT require a path gate. More than one path MUST be listed completely in
`integrationPathNames`.

#### Scenario: Multi-path tile exposes path names

- **GIVEN** the Amazon Web Services Integration row
- **WHEN** the Skill catalog index is generated
- **THEN** `integrationPathNames` MUST include CloudFormation, Terraform, and Assume Role

#### Scenario: Implicit singleton path

- **GIVEN** an Integration row has exactly one Integration path
- **WHEN** Connect prepares Lock
- **THEN** it MUST NOT require a separate path choice

### Requirement: Capture-required stub

A row with `captureRequired: true` MUST declare no Integration paths, prep steps,
or Typed actions and MUST cause Connect to stop before Lock for current
connection-form screenshots.

#### Scenario: Stub stops Connect

- **GIVEN** a capture-required Integration such as CircleCI
- **WHEN** an operator starts Connect for that tile
- **THEN** the agent MUST request current connection-form screenshots
- **AND** it MUST stop before Lock
- **AND** it MUST NOT open the Row catalog or run Typed actions

### Requirement: Integration index records hosting and derives connector deployment

Each Integration index row MUST carry `hosting` as exactly one of `public`,
`self-hosted`, or `operator-selected`. Validation MUST reject a row that omits
the key or uses any other value. Connector deployment topology MUST be derived
from hosting: `public` maps to SaaS Perimeter; `self-hosted` maps to Docker
Compose or Kubernetes Helm; `operator-selected` follows the operator's form
choice. Rows MUST NOT emit a stored topology list. Kubernetes Helm is the
preferred self-hosted topology when scanning is cluster-native.

#### Scenario: Every row carries a hosting value

- **GIVEN** the curated catalog of Integrations
- **WHEN** the Integration index is written
- **THEN** every row MUST contain `hosting` as `public`, `self-hosted`, or `operator-selected`

#### Scenario: Unknown or missing hosting fails validation

- **GIVEN** an Integration index row that omits `hosting` or sets it to a value other than the three allowed
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that row

#### Scenario: Public hosting derives SaaS Perimeter

- **GIVEN** a row whose `hosting` is `public`
- **WHEN** connector deployment is derived
- **THEN** the derived topology MUST be SaaS Perimeter
- **AND** the row MUST NOT contain a topology list key

#### Scenario: Self-hosted hosting derives Docker or Helm

- **GIVEN** a row whose `hosting` is `self-hosted`
- **WHEN** connector deployment is derived
- **THEN** the derived topologies MUST be Docker Compose and Kubernetes Helm
- **AND** the row MUST NOT contain a topology list key

#### Scenario: Operator-selected hosting follows the form

- **GIVEN** a target whose connection form lets the operator choose cloud or self-hosted (GitLab, n8n)
- **WHEN** the Integration index is written
- **THEN** that row MUST be `operator-selected`
- **AND** it MUST remain a single row
- **AND** derived topology MUST follow the operator's form choice rather than a stored list

### Requirement: Integration index omits connector requirement fields

Each Integration index row MUST NOT carry `connectorRequirement` or
`connectorEvidence`. A connector is always required for an Integration.
Validation MUST reject a row that includes either key. Rows MUST NOT carry connector
deployment topologies; those remain product-level Entro Connector documentation.

#### Scenario: Index rows omit connector requirement keys

- **GIVEN** the curated catalog of Integrations
- **WHEN** the Integration index is written
- **THEN** no row MUST contain `connectorRequirement` or `connectorEvidence`

#### Scenario: Connector keys fail validation

- **GIVEN** an Integration index row that includes `connectorRequirement` or `connectorEvidence`
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that row

#### Scenario: Formerly unknown rows match every other row

- **GIVEN** targets whose docs never named a Worker Group field (Microsoft Teams, Wiz, Salesforce, Google Workspace)
- **WHEN** the Integration index is written
- **THEN** those rows MUST omit the connector keys like every other target
- **AND** they MUST NOT be labelled unknown or not-required

### Requirement: Ingest output is distilled, not dumped

Downstream specs and skills SHALL use distilled integration-prep and connection-detail
instructions derived from ingest output, not wholesale copies of crawled pages.

#### Scenario: Distillation for an Integration

- **GIVEN** ingested documentation for an Integration
- **WHEN** a change authors integration-prep or connection-details material
- **THEN** the change MUST cite the ingest source and produce structured instructions rather than pasting the raw page

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

### Requirement: Integration-docs attachments are Skill-held

Ingest SHALL copy every GitBook file attachment linked from integration
documentation into both `entro-connect` skill trees as Skill-held onboarding
artifacts in the owning Integration tile's row folder. Integration
documentation SHALL mean pages under
`documentation/cloud-and-infrastructure/`,
`documentation/collaboration-and-saas/`, `documentation/code-and-ci-cd/`,
`documentation/ai-and-agents/`, `documentation/security-and-identity/`,
`documentation/container-registries/`, and `documentation/gemini-instructions/`.
Each artifact MUST be recorded on the Row catalog (and ingest Integration index)
with `skillPath` skill-root-relative under `integrations/`, `version`, SHA-256
`checksum`, and an Anonymous origin URL when the bytes came from GitBook.
A Local onboarding fork MUST also record `localFork` true and `originChecksum`.
Validation MUST fail when such a page links an attachment that is not skill-held
and checksummed, when the two skill trees differ, when an unforked pin's origin
bytes no longer match the skill copy, when a forked pin's `checksum` does not
match the Skill-held copy, or when `skillPath` is under `vendor/`. Validation
MUST NOT fail solely because a Local onboarding fork's origin bytes differ from
the Skill-held copy.

#### Scenario: GitBook attachment is committed in both skill trees

- **GIVEN** an integration documentation page that links a GitBook file attachment
- **WHEN** ingest writes the Skill catalog
- **THEN** both `entro-connect` skill trees MUST contain identical bytes at the recorded `skillPath`
- **AND** the catalog MUST record `checksum` as `sha256:` plus 64 hex digits of those bytes
- **AND** `skillPath` MUST be under that target's row folder

#### Scenario: Unpinned integration attachment fails ingest

- **GIVEN** an integration documentation page that links a GitBook attachment
- **AND** no Skill-held copy with a matching checksum exists
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

#### Scenario: Origin drift fails ingest

- **GIVEN** a Skill-held artifact whose catalog pin includes an Anonymous origin URL
- **AND** the pin is not a Local onboarding fork
- **AND** an anonymous GET of that URL returns bytes whose SHA-256 differs from the skill copy
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

### Requirement: Anonymous origin URL is the only valid remote pin

A catalog `originUrl` for a GitBook attachment SHALL be the object URL with
`?alt=media` and MUST NOT contain a `token` query parameter. Validation MUST
fail if a stored origin URL includes `token=` or if anonymous GET does not
return the file bytes (including a JSON metadata body without `alt=media`).
For an unforked pin, that GET MUST match `checksum`. For a Local onboarding
fork, that GET MUST be compared to `originChecksum`, not to `checksum`.

#### Scenario: Tokenized origin URL is rejected

- **GIVEN** a catalog pin whose `originUrl` includes `token=`
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

#### Scenario: Anonymous alt=media fetch is accepted

- **GIVEN** Azure onboarding publishes `Entro-Azure-Onboarding.ps1` on GitBook
- **WHEN** ingest records its origin
- **THEN** `originUrl` MUST use `?alt=media` and MUST NOT include `token=`
- **AND** an anonymous GET MUST return file bytes
- **AND** when the pin is not a Local onboarding fork the GET SHA-256 MUST equal `checksum`
- **AND** when the pin is a Local onboarding fork the GET SHA-256 MUST equal `originChecksum`

### Requirement: Local onboarding fork pins record originChecksum

A Skill-held pin with `localFork` true SHALL record `checksum` as SHA-256 of the
Skill-held bytes Connect runs and `originChecksum` as SHA-256 of the last
recorded anonymous GET of its Anonymous origin URL. Both values MUST be
`sha256:` plus 64 hex digits. Unforked pins MUST omit `localFork` and
`originChecksum`. Both skill trees MUST remain byte-identical at `skillPath`.
A Local onboarding fork MUST include a committed unified diff
`Entro-Azure-Onboarding.local.patch` beside the script in the Microsoft
Ecosystem row folder.

#### Scenario: Fork pin separates originChecksum from checksum

- **GIVEN** the Microsoft Ecosystem Automated PowerShell pin is a Local onboarding fork
- **WHEN** ingest writes the Skill catalog
- **THEN** the pin MUST set `localFork` true
- **AND** `checksum` MUST match the Skill-held script bytes
- **AND** `originChecksum` MUST be `sha256:` plus 64 hex digits
- **AND** `checksum` and `originChecksum` MAY differ

#### Scenario: Local patch file is skill-held beside the script

- **GIVEN** the Microsoft Azure onboarding script is a Local onboarding fork
- **WHEN** ingest has written both skill trees
- **THEN** both trees MUST contain identical `integrations/microsoft-ecosystem/Entro-Azure-Onboarding.local.patch`
- **AND** that file MUST be a unified diff against the origin bytes identified by `originChecksum`

### Requirement: Origin published notice for a Local onboarding fork

When a Local onboarding fork's anonymous GET SHA-256 equals `originChecksum`,
ingest validation MUST succeed even if that hash differs from `checksum`. When
the GET SHA-256 differs from `originChecksum`, ingest MUST NOT overwrite
Skill-held bytes, MUST still treat catalog checksums of the Skill-held copy as
valid, and MUST emit an origin-published notice that names keep-local versus
take-remote rebase. It MUST NOT ask a Connect operator. Keep-local MUST update
`originChecksum` to the new origin hash without changing Skill-held bytes.

#### Scenario: Unchanged origin with a fork succeeds silently

- **GIVEN** a Local onboarding fork pin
- **AND** an anonymous GET matches `originChecksum`
- **AND** that hash differs from `checksum`
- **WHEN** ingest validates the catalog
- **THEN** validation MUST succeed
- **AND** it MUST NOT emit an origin-published notice

#### Scenario: New origin on a fork notifies without replacing local bytes

- **GIVEN** a Local onboarding fork pin
- **AND** an anonymous GET SHA-256 differs from `originChecksum`
- **WHEN** ingest validates the catalog
- **THEN** validation MUST succeed
- **AND** Skill-held bytes MUST be unchanged
- **AND** ingest MUST emit an origin-published notice naming keep-local or take-remote
- **AND** it MUST NOT fetch or apply origin bytes at Connect time

### Requirement: Take-remote rebases the local patch

When the maintainer chooses take-remote for a Local onboarding fork, ingest SHALL
anonymous-GET the Anonymous origin URL into a temporary file, apply
`Entro-Azure-Onboarding.local.patch`, and on success write the result to both
skill trees, set `originChecksum` to the new origin hash, and set `checksum` to
the patched Skill-held bytes. On patch conflict it MUST stop without writing
Skill-held files.

#### Scenario: Successful rebase updates pin and both trees

- **GIVEN** the maintainer chose take-remote
- **AND** the local patch applies to the new origin bytes
- **WHEN** ingest rebases the Local onboarding fork
- **THEN** both skill trees MUST contain the patched script
- **AND** `originChecksum` MUST match the new origin GET
- **AND** `checksum` MUST match the patched Skill-held bytes

#### Scenario: Patch conflict stops rebase

- **GIVEN** the maintainer chose take-remote
- **AND** the local patch does not apply to the new origin bytes
- **WHEN** ingest attempts rebase
- **THEN** it MUST stop
- **AND** Skill-held bytes MUST remain the previous fork

### Requirement: In-page onboarding snippets are Skill-held

When an integration documentation page embeds an onboarding script body (a
fenced script or instructions to save named source), ingest SHALL capture those
bytes as a Skill-held onboarding artifact in both skill trees in the owning
row folder, checksum them, and record `captureSource` as that page path.
Validation MUST fail when a re-extraction of the same snippet no longer matches
the skill checksum or when `skillPath` is under `vendor/`.

#### Scenario: Embedded pre-check script is captured

- **GIVEN** an integration page that tells the operator to save an embedded shell or PowerShell body as a named file
- **WHEN** ingest writes the Skill catalog
- **THEN** that body MUST exist as a Skill-held file with a SHA-256 checksum in the owning row folder
- **AND** the pin MUST name the documentation page as `captureSource`

#### Scenario: Snippet drift fails ingest

- **GIVEN** a Skill-held snippet whose `captureSource` page still embeds a script body
- **AND** the embedded body SHA-256 differs from the skill copy
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

### Requirement: Every Prep step has owned coverage

Every Prep step on every Integration path SHALL bind exactly one of: a Typed
action that runs a Skill-held onboarding artifact, a Doc-derived Typed action,
an Operator-only classification that carries an authored `reason` and
`evidence`, or an Uncataloged classification that carries `evidence`. The
catalog writer MUST NOT supply a default `reason` for a step whose author wrote
none; such a step MUST be emitted as Uncataloged. A page that names a script or
package with no Anonymous origin URL MUST NOT receive a placeholder checksum.
Validation MUST fail if any Prep step binds more than one of those four, or
none of them.

#### Scenario: Silent Prep step fails validation

- **GIVEN** a Prep step with no Typed action, no Operator-only classification, and no Uncataloged classification
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

#### Scenario: Missing authored reason emits Uncataloged

- **GIVEN** a Prep step with no Typed action whose author supplied no `reason`
- **WHEN** the catalog writer emits that step
- **THEN** it MUST carry an Uncataloged classification with `evidence`
- **AND** it MUST NOT carry an `operatorOnly` block
- **AND** no generator-supplied default `reason` MUST appear anywhere in the emitted catalog

#### Scenario: Authored reason stays Operator-only

- **GIVEN** a Prep step with no Typed action whose author supplied a `reason`
- **WHEN** the catalog writer emits that step
- **THEN** it MUST carry an `operatorOnly` block with that authored `reason` and `evidence`
- **AND** it MUST NOT carry an Uncataloged classification

#### Scenario: Two classifications on one step fail validation

- **GIVEN** a Prep step carrying both an Uncataloged classification and an `operatorOnly` block
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

#### Scenario: Unpublished named script is not a fake pin

- **GIVEN** a documentation page that names `Entro-Onboard.ps1` without a GitBook attachment
- **WHEN** ingest writes Typed actions for that path
- **THEN** those actions MUST be Doc-derived, Operator-only, or Uncataloged
- **AND** the catalog MUST NOT record `sha256:verify-after-download`

### Requirement: Incomplete preferred Fit is rejected

A selectable Fit `preferred` path SHALL cover every selected Prep step. An
incomplete path MUST have Fit corrected to `usable` or `none` with rationale.
Validation MUST fail if Fit remains `preferred` without that complete plan.

#### Scenario: Preferred path has complete coverage

- **GIVEN** a selectable path whose Configuration tools include Fit `preferred`
- **WHEN** the Integration index is validated
- **THEN** every Prep step on that path MUST have a Typed action, an Operator-only classification, or an Uncataloged classification

#### Scenario: Incomplete preferred Fit is rejected

- **GIVEN** a path marked Fit `preferred` that has a Prep step binding none of the four coverage kinds
- **WHEN** the index is validated
- **THEN** validation MUST fail
- **AND** the author MUST correct Fit to `usable` or `none` with rationale before the catalog is accepted

### Requirement: GitBook markdown catalog is the ingest index

Documentation ingest SHALL use the GitBook markdown catalog (`llms.txt` and per-page `.md` URLs) as the sole index of pages to fetch. It MUST NOT treat HTML BFS results or `/pages/{hash}` card links as the page list.

#### Scenario: Catalog drives the page list

- **GIVEN** Entro Integration documentation is published at the documented GitBook space
- **WHEN** documentation ingest runs
- **THEN** the pages fetched MUST be those listed in the GitBook markdown catalog after cleaned nav is applied

#### Scenario: Catalog fetch failure

- **GIVEN** the GitBook markdown catalog cannot be retrieved
- **WHEN** documentation ingest starts
- **THEN** ingest MUST fail without treating an empty or stale documentation tree as a successful run

### Requirement: Cleaned nav is written as a documentation tree

Ingest SHALL write each kept page to the documentation folder using the catalog path after `/integrations/`, producing a documentation tree whose folders match GitBook sidebar groups.

#### Scenario: Successful tree write

- **GIVEN** a GitBook markdown catalog that includes sidebar groups such as `ai-and-agents` and `cloud-and-infrastructure`
- **WHEN** documentation ingest completes successfully
- **THEN** `documentation/` MUST contain one markdown file per cleaned-nav page at the catalog-relative path
- **AND** a README at `documentation/README.md` MUST list the kept pages in catalog order
- **AND** `documentation/integrations.json` MUST list the 58 curated Integration tiles and their path-owned data

#### Scenario: Integration index lists curated tiles

- **GIVEN** the curated catalog includes genuine Select Provider tiles and excludes IDE marketplace pages
- **WHEN** ingest writes the documentation tree
- **THEN** `integrations.json` MUST include each Integration with exact tile, category, documentation paths, and Integration paths
- **AND** excluded documentation sections MUST NOT appear as Integrations

#### Scenario: Leftovers are excluded

- **GIVEN** the catalog includes `gemini-instructions`, a Copy-of page, a title ending in " - Old", and unsuffixed `google-cloud-platform` plus `google-cloud-platform-1`
- **WHEN** cleaned nav is applied
- **THEN** ingest MUST omit gemini-instructions, Copy-of, " - Old", and unsuffixed `google-cloud-platform`
- **AND** ingest MUST keep `google-cloud-platform-1`

#### Scenario: Distinct `-1` slugs are kept

- **GIVEN** the catalog includes `cursor-entro-marketplace-1` titled as Visual Studio Code SailPoint Marketplace
- **WHEN** cleaned nav is applied
- **THEN** that page MUST be kept in the documentation tree

---

### Requirement: Integration index lists Optional capabilities

Each Integration row SHALL carry a list of `optionalCapabilities`. An Optional
capability is a non-core surface or feature that may add Configuration tools,
connection fields, Prep steps, or Typed actions only after just-in-time operator
consent. It MUST NOT be a Lock dimension. A capability name MUST be unique on its
tile and its cited documentation paths MUST exist. Permission-group headings
alone MUST NOT create an Optional capability. A tile with no optional features
MUST carry an empty list.

#### Scenario: Additional documented surface becomes an Optional capability

- **GIVEN** legacy GitBook sections for SharePoint / OneDrive and Microsoft Copilot Studio
  whose pages resolve to the Microsoft Ecosystem Integration
- **WHEN** the Integration index is written
- **THEN** the Microsoft Ecosystem row MUST list Optional capabilities named SharePoint / OneDrive
  and Copilot Studio
- **AND** those capabilities MUST cite ingested pages from those sections
- **AND** Microsoft Copilot Studio MUST NOT appear as an Integration tile

#### Scenario: Permission-group heading is not an Optional capability

- **GIVEN** Microsoft Ecosystem documentation that names optional Graph permission
  groups for Copilot chats, Defender, or Teams secrets without a GitBook section of
  their own
- **WHEN** the Integration index is written
- **THEN** those groups MUST NOT appear as Optional capabilities on the Microsoft Ecosystem row

#### Scenario: Product-level Git clone scanning is not an Optional capability

- **GIVEN** a Git clone scanning GitBook section that applies to GitHub, GitLab, and
  Bitbucket
- **WHEN** the Integration index is written
- **THEN** Git clone scanning MUST NOT appear as an Optional capability on those Integrations

#### Scenario: Other additional sections are Optional capabilities

- **GIVEN** ingested GitBook sections for GitHub real-time scanning, GitHub Cloud
  Enterprise S3 log streaming, CrowdStrike Falcon RTR, Jira real-time scanning, and
  SailPoint NHI aggregation
- **WHEN** the Integration index is written
- **THEN** each MUST appear as an Optional capability on the Integration that section
  belongs to
- **AND** GitHub real-time scanning MUST appear on the GitHub Integration
- **AND** GitHub Enterprise S3 log streaming MUST NOT appear on GitHub Enterprise Server

#### Scenario: Optional capability citation must resolve

- **GIVEN** an Integration index row whose Optional capability cites a documentation path
- **WHEN** the index is validated
- **THEN** validation MUST fail if that path is not a file in the documentation tree
- **AND** validation MUST fail if two Optional capabilities on the same row share a name

#### Scenario: Empty Optional capability list is valid

- **GIVEN** an Integration whose ingested pages are only core onboarding,
  permissions, and troubleshooting
- **WHEN** the Integration index is written
- **THEN** that row MUST carry an empty `optionalCapabilities` list
- **AND** validation MUST succeed for that field

---

### Requirement: Integration paths list Configuration tools

Each Integration path SHALL carry a non-empty list of Configuration tools. A tile
with no declared paths MAY carry shared tools, but row-level tools MUST NOT exist
when paths are declared. Each entry SHALL have a Fit of `preferred`, `usable`,
`env-backed`, or `none`. Each entry SHALL have a kind of `cli` or `mcp`; omitted
kind MUST mean `cli`. An entry whose Fit is not `none` and whose kind is `cli`
MUST name a `binary`. An entry whose Fit is not `none` and whose kind is `mcp`
MUST name an `id`. Configuration tools MUST NOT appear as rows of their own.
Validation MUST reject a row with an empty Configuration tool list, an unknown
Fit, or an unknown kind.

#### Scenario: Every target lists Configuration tools

- **GIVEN** the curated catalog of Integration paths
- **WHEN** the Integration index is written
- **THEN** each path MUST include a non-empty `configurationTools` list
- **AND** each entry MUST have a Fit of `preferred`, `usable`, `env-backed`, or `none`

#### Scenario: Preferred cloud CLIs are recorded

- **GIVEN** the Microsoft Ecosystem, AWS, and Google GCP Integration paths
- **WHEN** the Integration index is written
- **THEN** Microsoft Ecosystem MUST list `az` and `pwsh` with Fit `preferred`
- **AND** AWS MUST list `aws` with Fit `preferred`
- **AND** Google Cloud Platform MUST list `gcloud` with Fit `preferred`

#### Scenario: GitHub App install is usable not preferred

- **GIVEN** the GitHub Cloud - New Integration path whose documented prep uses Entro's GitHub App redirect
- **WHEN** the Integration index is written
- **THEN** that row MUST list `gh` with Fit `usable`

#### Scenario: Portal-only targets still list a tool

- **GIVEN** an Integration path with no usable official admin CLI and no first-party vendor MCP for Integration prep
- **WHEN** the Integration index is written
- **THEN** that row MUST list at least one Configuration tool with Fit `none`
- **AND** that entry MAY omit `binary` and `id`

#### Scenario: n8n lists a first-party MCP

- **GIVEN** the n8n Integration path
- **WHEN** the Integration index is written
- **THEN** that row MUST list a Configuration tool with kind `mcp`, `id` `n8n-mcp`, and Fit `usable`
- **AND** that row MUST NOT rely on Fit `none` as its only tool

#### Scenario: First-party MCP sits beside a CLI

- **GIVEN** the Microsoft Ecosystem and GitHub Cloud - New Integration paths
- **WHEN** the Integration index is written
- **THEN** Microsoft Ecosystem MUST list `az` and `pwsh` with kind `cli` (or omitted) and Fit `preferred`
- **AND** Microsoft Ecosystem MUST also list kind `mcp` with `id` `azure-mcp` and Fit `usable`
- **AND** GitHub Cloud - New MUST list `gh` with Fit `usable` and kind `mcp` with `id` `github-mcp`

#### Scenario: Configuration tools are not rows

- **GIVEN** two targets that both use `az`
- **WHEN** the Integration index is written
- **THEN** each target MUST remain its own row
- **AND** `az` MUST NOT appear as an Integration

### Requirement: Integration index carries a Tool install catalog

The Integration index document SHALL include a Tool install catalog object `toolInstall`
keyed by CLI `binary` or MCP `id`. Each entry SHALL record `authOnce`, a Credential
boundary, a `docsUrl`, and preferred install for Windows, macOS, and Linux. Each OS
install SHALL have a `method` and MAY have a `command`; Linux `command` MAY be null
when only the vendor documentation is honest. MCP entries SHALL use method
`mcp-config` on all three OS objects with a null `command`. `docsUrl` MUST be
present on the entry. The catalog MUST NOT put secret values in any field.

#### Scenario: Shared binaries are installed once

- **GIVEN** Microsoft Ecosystem, Microsoft Teams, and Azure DevOps all list `az`
- **WHEN** the Integration index is written
- **THEN** `toolInstall` MUST contain exactly one `az` entry
- **AND** that entry MUST include Windows, macOS, and Linux install objects and a `docsUrl`

#### Scenario: Auth once is recorded without secrets

- **GIVEN** a Tool install catalog entry for `aws`
- **WHEN** the Integration index is written
- **THEN** that entry MUST include `authOnce` (for example `aws sso login`)
- **AND** that entry MUST name a Credential boundary that is a CLI token cache or gitignored env file
- **AND** the entry MUST NOT contain API keys, tokens, or passwords

#### Scenario: jenkins-cli is not a global package

- **GIVEN** the Jenkins Integration path lists `jenkins-cli`
- **WHEN** the Integration index is written
- **THEN** the `jenkins-cli` Tool install catalog entry MUST describe obtaining the jar from the Jenkins controller
- **AND** it MUST NOT claim a Windows winget package id as the only install path

### Requirement: Optional capability Configuration tools are additive

An Optional capability MAY list extra Configuration tools. Tools on the locked
Integration path apply to that capability. An empty capability
`configurationTools` list MUST mean inherit only. Extra tools MUST follow the
same Fit and binary rules as path tools. Microsoft Copilot Studio MUST remain an
Optional capability of Microsoft Ecosystem and MUST NOT become a row because it
needs Configuration tools.

#### Scenario: Copilot Studio inherits Microsoft Ecosystem tools

- **GIVEN** Microsoft Ecosystem lists `az` and `pwsh` and Optional capabilities SharePoint / OneDrive and Copilot Studio
- **WHEN** the Integration index is written
- **THEN** those capabilities MUST NOT be required to repeat `az` and `pwsh`
- **AND** Copilot Studio MUST NOT appear as an Integration

#### Scenario: GitHub S3 log streaming adds aws

- **GIVEN** the GitHub path supports Optional capability Enterprise S3 log streaming
- **WHEN** the Integration index is written
- **THEN** that capability MUST list `aws` as an extra Configuration tool
- **AND** the GitHub Enterprise Server path MUST NOT list that capability

### Requirement: Configuration tool binaries resolve in the Tool install catalog

Validation MUST fail when a Configuration tool whose Fit is not `none` names a
CLI `binary` or MCP `id` absent from `toolInstall`. Validation MUST fail when
`toolInstall` contains a key that no path or Optional capability references. A `none` entry
without a `binary` or `id` MUST succeed.

#### Scenario: Missing install entry fails validation

- **GIVEN** a row lists `binary` `az` with Fit `preferred`
- **AND** `toolInstall` has no `az` key
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that binary

#### Scenario: Orphan install entry fails validation

- **GIVEN** `toolInstall` contains a binary no path or Optional capability lists
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that key

#### Scenario: Fit none without binary succeeds

- **GIVEN** a row lists a Configuration tool with Fit `none` and no `binary`
- **WHEN** the index is validated
- **THEN** validation MUST succeed for that entry

#### Scenario: MCP without id fails validation

- **GIVEN** a row lists a Configuration tool with kind `mcp`, Fit `usable`, and no `id`
- **WHEN** the index is validated
- **THEN** validation MUST fail and report that the MCP entry needs an `id`

### Requirement: Integration paths list Connection details

Each Integration path SHALL carry a `connectionFields` list of vendor-specific
Connection details. Shared tile fields MAY remain on the row, but row-level fields
MUST NOT duplicate path fields. Each item SHALL have `name`,
`secret` (boolean), and `obtainedHow` (how the operator gets the value, with no
secret value inlined). The list MUST NOT include Worker Group (Connector); that
field is a global rule. Environment, Display Name, and other Entro-owned labels
SHALL appear only when that target's connection form uses those labels. An
operator-chosen non-secret field SHALL also be an Operator input keyed from that
field. Validation MUST reject a missing list, an item without `name` or
`obtainedHow`, or a secret value in any field. Items MUST NOT require opening an
ingested documentation page.

#### Scenario: Every target lists connection fields

- **GIVEN** the curated catalog of Integration paths
- **WHEN** the Integration index is written
- **THEN** each path MUST include a `connectionFields` array
- **AND** each item MUST have `name`, `secret`, and `obtainedHow`

#### Scenario: Worker Group is not catalogued per row

- **GIVEN** any Integration path
- **WHEN** the Integration index is written
- **THEN** no `connectionFields` item MUST have the name Worker Group or Worker Group (Connector)

#### Scenario: Okta vendor fields are named

- **GIVEN** the Okta Integration path
- **WHEN** the Integration index is written
- **THEN** `connectionFields` MUST include Okta Domain and Client Id
- **AND** each of those items MUST include `obtainedHow` text sufficient without opening `documentation/`
- **AND** a client secret field MUST have `secret` true if the form collects one

#### Scenario: Optional capability fields are conditional

- **GIVEN** the Microsoft Ecosystem path supports the Copilot Studio Optional capability
- **WHEN** the Integration index is written
- **THEN** capability-specific `connectionFields` MUST apply only after consent
- **AND** the locked path MUST carry the baseline Azure connection-form fields

### Requirement: Integration paths list Prep steps

Each Integration path SHALL carry ordered `prepSteps`. A row that declares one or
more paths MUST NOT carry row-level `prepSteps`.
Each Prep step SHALL have `title`, `instruction` (what to do, distilled, no secret
values), and `evidence` naming the non-secret observable that the step is done.
Each row SHALL have a `summary` of what the Integration is, sufficient for the
skill intro without ingested pages. Optional capabilities MAY list additive
`prepSteps`; an empty capability list means inherit the locked path steps only.
Validation MUST reject a path without `prepSteps`, a missing `summary`,
a step without `instruction`, or a step that embeds a secret value. Prep steps
MUST NOT include a `command` field.

#### Scenario: Singleton path has Prep steps

- **GIVEN** an Integration with one implicit path
- **WHEN** the Integration index is written
- **THEN** that path MUST include a non-empty `prepSteps` list
- **AND** each step MUST have `title`, `instruction`, and `evidence`
- **AND** the row MUST include `summary`

#### Scenario: Integration paths own their steps

- **GIVEN** the AWS Integration with CloudFormation and Assume Role paths
- **WHEN** the Integration index is written
- **THEN** each Integration path MUST have its own `prepSteps` list
- **AND** the row MUST NOT also duplicate those lists at row level

#### Scenario: Copilot Studio adds permission steps

- **GIVEN** the Microsoft Ecosystem Copilot Studio Optional capability
- **WHEN** the Integration index is written
- **THEN** that capability MUST list `prepSteps` for the extra Graph permissions
- **AND** those steps MUST be additive to the parent Azure app Prep steps
- **AND** each capability step MUST include `instruction` text

#### Scenario: Commands are not stored on Prep steps

- **GIVEN** any Prep step in the Integration index
- **WHEN** the index is validated
- **THEN** the step MUST NOT contain a `command` field
- **AND** `evidence` and `instruction` MUST NOT contain a token-shaped secret

### Requirement: Integration index lists Operator inputs

Each Integration path SHALL list Operator inputs for every non-secret
naming or label decision the Connect run must collect (`key`, prompt, purpose,
validation, optional default, `secret` false). Typed actions and Connection
details SHALL reference those keys. Validation MUST reject a secret Operator
input and MUST reject a Fit `preferred` selectable path that needs a name the
catalog does not declare as an Operator input.

#### Scenario: Operator-chosen labels are typed inputs

- **GIVEN** a row whose Connection details include an operator-chosen Environment or Display Name
- **WHEN** the Integration index is written
- **THEN** that row MUST include an Operator input whose key binds to that field
- **AND** the input MUST have `secret` false

### Requirement: Integration paths list Typed actions for preferred Fit

A Fit `preferred` Integration path or Optional capability SHALL carry Typed
actions that cover every selected Prep step. Each Typed action SHALL include
preview metadata (or an explicit no-preview statement), mutation, target, expected
change, verification, rollback or irreversible-impact note, official source URL,
retrieval or version date, and whether the action produces a secret. External
scripts SHALL be pinned by URL, version, and checksum. Validation MUST fail if Fit
remains `preferred` without that complete plan. An incomplete path MUST have Fit
corrected to `usable` or `none` with rationale rather than remaining preferred.

#### Scenario: Preferred path has a complete action plan

- **GIVEN** a selectable path whose Configuration tools include Fit `preferred`
- **WHEN** the Integration index is validated
- **THEN** every Prep step on that path MUST have a Typed action
- **AND** validation MUST fail if any required action field is missing

#### Scenario: Incomplete preferred Fit is rejected

- **GIVEN** a path marked Fit `preferred` that lacks a Typed action for a Prep step
- **WHEN** the index is validated
- **THEN** validation MUST fail
- **AND** the author MUST correct Fit to `usable` or `none` with rationale before the catalog is accepted

### Requirement: Tool install catalog carries probes and identity

Each `toolInstall` entry SHALL include a presence check, a Capability probe,
an auth-check, and a Platform identity query, plus existing `authOnce`,
`credentialBoundary`, and install docs. The skill MUST execute only those
cataloged checks. Each probe and action SHALL record an official source URL and
retrieval or version date. An entry MAY also include Configure once; the skill
MUST execute only the cataloged Configure once check and MUST NOT invent a
session-config command.

#### Scenario: Azure CLI has an identity query

- **GIVEN** the `az` `toolInstall` entry
- **WHEN** the Skill catalog is written
- **THEN** it MUST include presence, Capability probe, auth-check, and Platform identity fields
- **AND** those fields MUST NOT require opening `documentation/`

#### Scenario: Configure once is optional on probes

- **GIVEN** a `toolInstall` entry that has complete probes and no `configureOnce`
- **WHEN** the catalog is validated
- **THEN** validation MUST succeed

### Requirement: Tool install MAY record Configure once

A `toolInstall` entry MAY include a nested `configureOnce` object whose only
field is `methods`, a non-empty ordered list of Authentication routes. Each
route SHALL carry `name`, `whenToPick`, `check` (`command`, `sourceUrl`,
`retrievedAt`), `suitableWhen`, `command`, `prompts`, `credentialBoundary`,
`docsUrl`, `sourceUrl`, `retrievedAt`, and `authOnce`, where `authOnce` MAY be
null to record that the route has no sign-in step. `whenToPick` SHALL state, in
non-secret prose, the situation in which an operator chooses that route.
`prompts` SHALL be a non-empty ordered list of `{prompt, whereToFind}` objects,
one per question that route's command asks, in the order it asks them; a prompt
MAY set `secret` to true. `prompt` SHALL be the label the command displays and
`whereToFind` SHALL be a non-secret statement of where the operator obtains that
value. A route `check.command` SHALL test for the presence of configuration by
name only, MUST NOT print matched lines, and MUST NOT read a credential value.
When `configureOnce` is present, the entry-level `authOnce` SHALL equal the
`authOnce` of one of its routes. The catalog writer SHALL emit that object on
both the ingest `toolInstall` map and both Skill Tool install files. Validation
MUST fail when `configureOnce` is present and `methods` is empty, when a route
omits any of those fields, when a route's `prompts` is empty, when a prompt
entry lacks `prompt` or `whereToFind`, when no route's `authOnce` matches the
entry-level `authOnce`, or when any field contains a secret-shaped value.
Validation MUST succeed when `configureOnce` is omitted and when a route sets
`authOnce` to null.

The `aws` entry MUST record two routes. The IAM user access keys route MUST use
`command` `aws configure`, a `check.command` that inspects the shared
credentials file for `aws_access_key_id`, `authOnce` null, and a
`credentialBoundary` naming the shared credentials file and its long-lived keys;
its prompts MUST cover the access key ID, the secret access key, the default
region, and the output format, the secret access key prompt MUST set `secret`,
and the access key prompts MUST name the IAM console or the credentials CSV as
the source. The IAM Identity Center route MUST use `command` `aws configure sso`,
a `check.command` that inspects the AWS config file (not the credentials file)
for `sso_session` or `sso_start_url`, `authOnce` `aws sso login`, and a
`credentialBoundary` naming the vendor CLI token cache; its prompts MUST cover
the SSO session name, SSO start URL, SSO region, registration scopes, account,
role, CLI default region, output format, and profile name, and the start URL and
SSO region entries MUST name the AWS access portal as the source. The `az` entry
MUST omit `configureOnce`. The `terraform` entry MUST omit `configureOnce`.

#### Scenario: AWS records Configure once without secrets

- **GIVEN** a Tool install catalog entry for `aws`
- **WHEN** the Integration index and Skill Tool install files are written
- **THEN** `configureOnce.methods` MUST contain a route with `command` `aws configure` and a route with `command` `aws configure sso`
- **AND** each route MUST carry its own `whenToPick`, `check`, `prompts`, `credentialBoundary`, and `docsUrl`
- **AND** the entry MUST NOT contain API keys, tokens, or passwords

#### Scenario: The access keys route records no sign-in

- **GIVEN** the `aws` IAM user access keys route
- **WHEN** the catalog is written
- **THEN** its `authOnce` MUST be null
- **AND** its `credentialBoundary` MUST name the shared credentials file holding long-lived keys
- **AND** its secret access key prompt MUST set `secret` to true

#### Scenario: Route checks never expose credential values

- **GIVEN** the `aws` route checks
- **WHEN** the catalog is written
- **THEN** the access keys check MUST test the shared credentials file for `aws_access_key_id` without printing matched lines
- **AND** the Identity Center check MUST target the AWS config file, not `credentials`

#### Scenario: AWS prompts name where each value comes from

- **GIVEN** the `aws` IAM Identity Center route
- **WHEN** the Integration index and Skill Tool install files are written
- **THEN** `prompts` MUST list the SSO session name, start URL, SSO region, registration scopes, account, role, CLI default region, output format, and profile name in wizard order
- **AND** the start URL and SSO region entries MUST name the AWS access portal
- **AND** the route MUST include a `docsUrl` for the vendor wizard page

#### Scenario: Azure CLI omits Configure once

- **GIVEN** a Tool install catalog entry for `az`
- **WHEN** the Integration index is written
- **THEN** that entry MUST NOT include `configureOnce`

#### Scenario: Terraform does not duplicate the AWS wizard

- **GIVEN** a Tool install catalog entry for `terraform`
- **WHEN** the Integration index is written
- **THEN** that entry MUST NOT include `configureOnce`

#### Scenario: Missing Configure once fields fail validation

- **GIVEN** a `toolInstall` entry whose `configureOnce` route omits `check.command` or `whenToPick`
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Configure once without prompts fails validation

- **GIVEN** a `toolInstall` entry whose `configureOnce` has an empty `methods` list
- **WHEN** the catalog is validated
- **THEN** validation MUST fail
- **AND** validation MUST also fail when a route's `prompts` is empty or a prompt entry omits `whereToFind`

#### Scenario: Entry-level auth-once must match a route

- **GIVEN** a `toolInstall` entry whose `configureOnce` routes name `aws sso login` and null
- **WHEN** the entry-level `authOnce` is some other command
- **THEN** validation MUST fail

### Requirement: Every integration documentation page is cited or waived

Every markdown page under the integration documentation folders SHALL be either cited by an
Integration row, one of its Integration paths, or one of its Optional capabilities,
or named in that catalog's Method waiver registry with a
non-empty reason. Integration documentation folders SHALL mean the same set the Skill-held
attachment requirement fixes: `documentation/cloud-and-infrastructure/`,
`documentation/collaboration-and-saas/`, `documentation/code-and-ci-cd/`,
`documentation/ai-and-agents/`, `documentation/security-and-identity/`,
`documentation/container-registries/`, and `documentation/gemini-instructions/`. A page that
no row cites MUST NOT be attributed to a row by folder or path proximity; it is an orphan
until cited or waived. Validation MUST fail when any such page is neither cited nor waived.

#### Scenario: Uncited integration page fails validation

- **GIVEN** an integration documentation page that documents an onboarding path
- **AND** no Integration row, Integration path, or Optional capability cites it
- **AND** no Method waiver names it
- **WHEN** the catalog is validated
- **THEN** validation MUST fail naming that page

#### Scenario: Multi-account automation page is observable

- **GIVEN** `cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation.md`
- **WHEN** the catalog is validated
- **THEN** the AWS row MUST cite that page or waive it with a reason
- **AND** validation MUST fail when it does neither

#### Scenario: Reverted curation fails rather than passes

- **GIVEN** a row that cites a page and carries a Documented method distilled from it
- **WHEN** that row's citation and its Method waiver are both removed
- **THEN** validation MUST fail because the page is orphaned
- **AND** the catalog MUST NOT validate as though the page did not exist

#### Scenario: Non-integration pages need no citation

- **GIVEN** Entro Connector topology, SSO setup, and IDE plugin pages outside the integration documentation folders
- **WHEN** the catalog is validated
- **THEN** those pages MUST NOT require a citation or a Method waiver

### Requirement: Cited pages carry a verified fork census

Each cited integration documentation page SHALL carry a Fork census listing the Documented
methods that page names. Each census entry SHALL bind to either an Integration path
the catalog carries or a Method waiver reason, and SHALL carry an
`evidence` quote of the page text that names that Documented method. Validation MUST confirm
each `evidence` quote occurs in the bytes of the page it is recorded against, and MUST fail
when a quote is absent, when an entry binds to a method name the row does not carry, or when
an entry has neither a method binding nor a waiver reason.

#### Scenario: In-page fork is bound to a method

- **GIVEN** a cited page that documents two ways to authenticate the same target
- **WHEN** the catalog is validated
- **THEN** the census MUST carry one entry per documented way
- **AND** each entry MUST name an Integration path the row carries or a Method waiver reason

#### Scenario: Stale evidence quote fails validation

- **GIVEN** a census entry whose `evidence` quote no longer appears in the cited page
- **WHEN** the catalog is validated
- **THEN** validation MUST fail naming the page and the missing quote

#### Scenario: Census entry cannot name an absent path

- **GIVEN** a census entry that binds to an Integration path name
- **AND** the row does not carry an Integration path with that name
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Documented AWS deployment options are censused

- **GIVEN** the AWS multi-account automation page naming CloudFormation StackSets and Terraform
- **WHEN** the catalog is validated
- **THEN** each MUST bind to an AWS Integration path or a Method waiver with a reason

### Requirement: Method waivers are explicit and reasoned

A Method waiver SHALL record the documentation page it applies to and a non-empty reason
stating why that page or Documented method is deliberately not bound to an
Integration path. Validation MUST fail when a waiver has a missing, empty, or
whitespace-only reason, and MUST fail when a waiver names a page that does not exist under
the integration documentation folders. A waiver MUST NOT be expressed as a bare flag.

#### Scenario: Waiver without a reason fails validation

- **GIVEN** a Method waiver whose reason is empty or whitespace
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Waiver for a missing page fails validation

- **GIVEN** a Method waiver naming a page that is not present under the integration documentation folders
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Reasoned waiver validates

- **GIVEN** a documented path the catalog deliberately does not carry as a method
- **AND** a Method waiver naming that page with a reason sentence
- **WHEN** the catalog is validated
- **THEN** validation MUST pass for that page

### Requirement: Curation bookkeeping stays out of the Skill catalog

Method waivers and fork census entries SHALL appear only in the ingest Integration index.
The Skill catalog thin index and every Row catalog MUST NOT carry Method waivers, fork
census entries, or documentation page paths, because Connect never opens `documentation/`.
Validation MUST fail when a Row catalog or the thin index carries any of them.

#### Scenario: Row catalog carries no waivers

- **GIVEN** a row whose curation includes Method waivers and a fork census
- **WHEN** the Skill catalog tree is written
- **THEN** the Row catalog MUST NOT contain waivers, census entries, or documentation paths
- **AND** the ingest Integration index MUST contain them

#### Scenario: Waiver leaking into the Skill catalog fails validation

- **GIVEN** a Skill catalog Row catalog that carries a Method waiver
- **WHEN** the Skill catalog is validated
- **THEN** validation MUST fail

### Requirement: Catalog completeness is asserted without vendor credentials

The catalog completeness invariant SHALL be enforced by the same validation function the
catalog writer calls and SHALL additionally be asserted by the repository test suite against
the committed documentation tree. The test suite assertion MUST NOT require
`ENTRO_DOCS_COOKIE` or any network access, so that a change which drops a Documented method
fails on the repository's canonical test command.

#### Scenario: Test suite catches a dropped method without a cookie

- **GIVEN** no `ENTRO_DOCS_COOKIE` in the environment
- **AND** a change that removes a row's citation of a documented onboarding page
- **WHEN** the canonical test command runs
- **THEN** a named test MUST fail

#### Scenario: Catalog writer enforces the same invariant

- **GIVEN** a catalog that violates page citation or fork census
- **WHEN** the catalog writer runs
- **THEN** it MUST return validation errors and MUST NOT write the Integration index or the Skill catalog trees

### Requirement: Catalog writer emits Skill catalog tree

`integration_catalog.py` SHALL write the ingest Integration index at
`documentation/integrations.json` as one JSON document of full rows (page paths
MAY remain). In the same run it SHALL write the Skill catalog in both
`entro-connect` skill trees as: a Skill catalog index at `integrations.json`; a
Tool install file at `tool-install.json` containing `toolInstall`; and one row
folder per Integration tile at `integrations/<kebab(tile)>/` with `catalog.json`
(the complete row object) and Skill-held artifacts beside it. The index SHALL
contain only `tile`, `summary`, `integrationPathNames`,
`optionalCapabilityNames`, `catalogPath`, and `captureRequired`. It MUST NOT
include `targetSelection`, `setupMethodNames`, `authenticationMethodNames`,
`coverageNames`, `prepSteps`, `typedActions`, `connectionFields`, or
`toolInstall`. `catalogPath` MUST be skill-root-relative and MUST exist. The
Skill catalog MUST NOT require markdown paths under `documentation/` for a
Connect run. Hand-edits of generated skill catalog files MUST be overwritten on
the next catalog write. Validation MUST fail if the tree is missing, if an
ingest target lacks a Row catalog, if index identity fields disagree with that
Row catalog, if the two skill trees differ, or if a skill tree still contains
`vendor/`.

_Rationale: ADR-0002 (apply)_

#### Scenario: Skill catalog tree is generated beside the ingest index

- **GIVEN** a successful catalog write
- **WHEN** `documentation/integrations.json` is regenerated
- **THEN** both skill trees MUST contain a Skill catalog index, a Tool install file, and one Row catalog per exact Integration tile
- **AND** `documentation/integrations.json` MUST remain one file of full rows

#### Scenario: Index is thin

- **GIVEN** a written Skill catalog index
- **WHEN** ingest validates the Skill catalog
- **THEN** each index entry MUST include `catalogPath` and `summary`
- **AND** no index entry MUST include `prepSteps`, `typedActions`, `connectionFields`, or `toolInstall`

#### Scenario: One folder per tile

- **GIVEN** GitHub Cloud - New, GitHub Cloud - Legacy, and GitHub Enterprise Server paths
- **WHEN** the Skill catalog is written
- **THEN** exactly one `integrations/github/catalog.json` MUST exist
- **AND** the index MUST list one GitHub tile with all three Integration path names

#### Scenario: Skill catalog is enough without the documentation tree

- **GIVEN** the Skill catalog tree and no `documentation/` markdown pages
- **WHEN** a Connect run Locks an Integration path
- **THEN** that Integration's Row catalog MUST include path-owned `summary`, `prepSteps.instruction`, and `connectionFields.obtainedHow`
- **AND** `tool-install.json` MUST include `toolInstall` for the locked Configuration tools

#### Scenario: vendor directory is rejected

- **GIVEN** a skill tree that still contains `vendor/`
- **WHEN** ingest validates the Skill catalog
- **THEN** validation MUST fail

---


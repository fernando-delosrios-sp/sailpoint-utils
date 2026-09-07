<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

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
- **AND** `documentation/integrations.json` MUST list curated Add New Account Integration variants with connector metadata

#### Scenario: Integration index lists curated variants

- **GIVEN** the curated catalog includes genuine Add New Account variants and excludes IDE marketplace pages
- **WHEN** ingest writes the documentation tree
- **THEN** `integrations.json` MUST include each variant with name, category, documentation path, and connector fields
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

## MODIFIED Requirements

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

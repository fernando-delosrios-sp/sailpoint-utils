<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Catalog writer emits a Skill catalog tree

`integration_catalog.py` SHALL write the ingest Integration index at
`documentation/integrations.json` as one JSON document of full rows (page paths
MAY remain). In the same run it SHALL write the Skill catalog in both
`entro-connect` skill trees as: a Skill catalog index at `integrations.json`; a
Tool install file at `tool-install.json` containing `toolInstall`; and one row
folder per Add New Account target at `integrations/<slug>/` with `catalog.json`
(today's complete row object) and Skill-held artifacts beside it. The index
SHALL list `tile`, `targetSelection`, `summary`, `setupMethodNames`,
`authenticationMethodNames`, `coverageNames`, and `catalogPath` for every ingest
target, and MUST NOT include `prepSteps`, `typedActions`, `connectionFields`, or
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
- **THEN** both skill trees MUST contain a Skill catalog index, a Tool install file, and one Row catalog per ingest tile and targetSelection pair
- **AND** `documentation/integrations.json` MUST remain one file of full rows

#### Scenario: Index is thin

- **GIVEN** a written Skill catalog index
- **WHEN** ingest validates the Skill catalog
- **THEN** each index entry MUST include `catalogPath` and `summary`
- **AND** no index entry MUST include `prepSteps`, `typedActions`, `connectionFields`, or `toolInstall`

#### Scenario: GitHub in-form selections are three folders

- **GIVEN** GitHub Cloud - New, GitHub Cloud - Legacy, and GitHub Enterprise Server
- **WHEN** the Skill catalog is written
- **THEN** each MUST have its own row folder and `catalog.json`
- **AND** the index MUST list three entries under tile GitHub

#### Scenario: Skill catalog is enough without the documentation tree

- **GIVEN** the Skill catalog tree and no `documentation/` markdown pages
- **WHEN** a Connect run Locks a target
- **THEN** that target's Row catalog MUST include `summary`, `prepSteps.instruction`, and `connectionFields.obtainedHow`
- **AND** `tool-install.json` MUST include `toolInstall` for the locked Configuration tools

#### Scenario: vendor directory is rejected

- **GIVEN** a skill tree that still contains `vendor/`
- **WHEN** ingest validates the Skill catalog
- **THEN** validation MUST fail

---

## MODIFIED Requirements

### Requirement: Integration-docs attachments are Skill-held

Ingest SHALL copy every GitBook file attachment linked from integration
documentation into both `entro-connect` skill trees as Skill-held onboarding
artifacts in the owning Add New Account target's row folder. Integration
documentation SHALL mean pages under
`documentation/cloud-and-infrastructure/`,
`documentation/collaboration-and-saas/`, `documentation/code-and-ci-cd/`,
`documentation/ai-and-agents/`, `documentation/security-and-identity/`,
`documentation/container-registries/`, and `documentation/gemini-instructions/`.
Each artifact MUST be recorded on the Row catalog (and ingest Integration index)
with `skillPath` skill-root-relative under `integrations/`, `version`, SHA-256
`checksum`, and an Anonymous origin URL when the bytes came from GitBook.
Validation MUST fail when such a page links an attachment that is not skill-held
and checksummed, when the two skill trees differ, when origin bytes no longer
match the skill copy, or when `skillPath` is under `vendor/`.

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
- **AND** an anonymous GET of that URL returns bytes whose SHA-256 differs from the skill copy
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

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

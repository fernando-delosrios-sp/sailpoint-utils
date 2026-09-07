## ADDED Requirements

### Requirement: Integration-docs attachments are Skill-held

Ingest SHALL copy every GitBook file attachment linked from integration
documentation into both `entro-connect` skill trees as Skill-held onboarding
artifacts. Integration documentation SHALL mean pages under
`documentation/cloud-and-infrastructure/`,
`documentation/collaboration-and-saas/`, `documentation/code-and-ci-cd/`,
`documentation/ai-and-agents/`, `documentation/security-and-identity/`,
`documentation/container-registries/`, and `documentation/gemini-instructions/`.
Each artifact MUST be recorded in the Integration index with `skillPath`,
`version`, SHA-256 `checksum`, and an Anonymous origin URL when the bytes came
from GitBook. Validation MUST fail when such a page links an attachment that is
not skill-held and checksummed, when the two skill trees differ, or when origin
bytes no longer match the skill copy.

#### Scenario: GitBook attachment is committed in both skill trees

- **GIVEN** an integration documentation page that links a GitBook file attachment
- **WHEN** ingest writes the Skill catalog
- **THEN** both `entro-connect` skill trees MUST contain identical bytes at the recorded `skillPath`
- **AND** the catalog MUST record `checksum` as `sha256:` plus 64 hex digits of those bytes

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

### Requirement: Anonymous origin URL is the only valid remote pin

A catalog `originUrl` for a GitBook attachment SHALL be the object URL with
`?alt=media` and MUST NOT contain a `token` query parameter. Validation MUST
fail if a stored origin URL includes `token=` or if anonymous GET does not
return the file bytes (including a JSON metadata body without `alt=media`).

#### Scenario: Tokenized origin URL is rejected

- **GIVEN** a catalog pin whose `originUrl` includes `token=`
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

#### Scenario: Anonymous alt=media fetch is accepted

- **GIVEN** Azure onboarding publishes `Entro-Azure-Onboarding.ps1` on GitBook
- **WHEN** ingest records its origin
- **THEN** `originUrl` MUST use `?alt=media` and MUST NOT include `token=`
- **AND** an anonymous GET MUST return the same SHA-256 as the skill copy

### Requirement: In-page onboarding snippets are Skill-held

When an integration documentation page embeds an onboarding script body (a
fenced script or instructions to save named source), ingest SHALL capture those
bytes as a Skill-held onboarding artifact in both skill trees, checksum them,
and record `captureSource` as that page path. Validation MUST fail when a
re-extraction of the same snippet no longer matches the skill checksum.

#### Scenario: Embedded pre-check script is captured

- **GIVEN** an integration page that tells the operator to save an embedded shell or PowerShell body as a named file
- **WHEN** ingest writes the Skill catalog
- **THEN** that body MUST exist as a Skill-held file with a SHA-256 checksum
- **AND** the pin MUST name the documentation page as `captureSource`

#### Scenario: Snippet drift fails ingest

- **GIVEN** a Skill-held snippet whose `captureSource` page still embeds a script body
- **AND** the embedded body SHA-256 differs from the skill copy
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

### Requirement: Every Prep step has owned coverage

Every Prep step on every Add New Account row SHALL bind exactly one of: a Typed
action that runs a Skill-held onboarding artifact, a Doc-derived Typed action,
or an Operator-only classification that carries `reason` and `evidence`. A page
that names a script or package with no Anonymous origin URL MUST NOT receive a
placeholder checksum. Validation MUST fail if any Prep step has neither a Typed
action nor an Operator-only classification.

#### Scenario: Silent Prep step fails validation

- **GIVEN** a Prep step with no Typed action and no Operator-only classification
- **WHEN** ingest validates the catalog
- **THEN** validation MUST fail

#### Scenario: Unpublished named script is not a fake pin

- **GIVEN** a documentation page that names `Entro-Onboard.ps1` without a GitBook attachment
- **WHEN** ingest writes Typed actions for that path
- **THEN** those actions MUST be Doc-derived or Operator-only
- **AND** the catalog MUST NOT record `sha256:verify-after-download`

### Requirement: Incomplete preferred Fit is rejected

A selectable Fit `preferred` path SHALL cover every selected Prep step. An
incomplete path MUST have Fit corrected to `usable` or `none` with rationale.
Validation MUST fail if Fit remains `preferred` without that complete plan.

#### Scenario: Preferred path has complete coverage

- **GIVEN** a selectable path whose Configuration tools include Fit `preferred`
- **WHEN** the Integration index is validated
- **THEN** every Prep step on that path MUST have a Typed action or an Operator-only classification

#### Scenario: Incomplete preferred Fit is rejected

- **GIVEN** a path marked Fit `preferred` that has a Prep step with no Typed action and no Operator-only classification
- **WHEN** the index is validated
- **THEN** validation MUST fail
- **AND** the author MUST correct Fit to `usable` or `none` with rationale before the catalog is accepted

---

## MODIFIED Requirements

<!-- No canonical documentation-ingest requirement is replaced in full; Skill-held
pins supersede in-flight URL-fetch pins from the unarchived entro-connect-skill
delta. -->

---

## REMOVED Requirements

---

## RENAMED Requirements

## ADDED Requirements

### Requirement: Skill-held onboarding terms

The glossary SHALL define Skill-held onboarding artifact, Anonymous origin URL,
Doc-derived Typed action, and Operator-only step with the definitions in Term
entries below. Specs that describe Connect script runtime SHALL use Skill-held
onboarding artifact rather than treating a GitBook URL as the bytes that run.

#### Scenario: Specs use Skill-held onboarding artifact

- **GIVEN** a change authors documentation-ingest or integration-prep requirements about vendor scripts, zips, or captured snippets
- **WHEN** it names the file Connect executes
- **THEN** it MUST use Skill-held onboarding artifact
- **AND** it MUST NOT describe GitBook download as Connect runtime

#### Scenario: Specs use Anonymous origin URL

- **GIVEN** a change authors ingest requirements about the remote address used to detect drift
- **WHEN** it names that address
- **THEN** it MUST use Anonymous origin URL
- **AND** it MUST NOT treat a URL that contains `token=` as valid

#### Scenario: Specs distinguish Doc-derived Typed action and Operator-only step

- **GIVEN** a Prep step that is not covered by a Skill-held file
- **WHEN** a spec names how that step is owned
- **THEN** it MUST use Doc-derived Typed action or Operator-only step
- **AND** it MUST NOT leave the step unnamed

---

## REMOVED Requirements

---

## RENAMED Requirements

---

## Term entries

### Term: Skill-held onboarding artifact
**Context**: documentation-ingest
**Definition**: A vendor-published file or in-page onboarding snippet stored under `vendor/` in both `entro-connect` skill trees, identified by skill-relative path and SHA-256.
**Aliases**: vendor script copy, skill-local script
**Notes**: Connect executes these bytes only. GitBook is not the runtime source. Not an Operator input, not a CloudFormation launch in the Entro wizard unless that wizard artifact is itself a harvested GitBook file.

### Term: Anonymous origin URL
**Context**: documentation-ingest
**Definition**: The GitBook `files.gitbook.io` object URL with `?alt=media` and no `token` query, used by ingest to detect drift against the Skill-held copy.
**Aliases**: none
**Notes**: Invalid if it contains `token=`. A 200 JSON metadata body (URL without `alt=media`) is not a successful file fetch. Not used at Connect time.

### Term: Doc-derived Typed action
**Context**: integration-prep
**Definition**: A Typed action whose mutation, verification, and rollback come from the vendor's documented CLI or API operation when no Skill-held onboarding artifact covers the Prep step.
**Aliases**: none
**Notes**: MUST NOT invent commands the vendor does not document. MUST NOT wrap an unpublished customer-supplied script as a pinned checksum.

### Term: Operator-only step
**Context**: integration-prep
**Definition**: A Prep step the project does not automate, because the platform exposes it only through its UI or because it mints a credential, carrying a recorded reason and the evidence the operator reports.
**Aliases**: none
**Notes**: Absence of a Typed action is this classification once reason is present, not an unwritten gap. Secret values stay with the operator.

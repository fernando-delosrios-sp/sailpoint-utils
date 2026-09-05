## ADDED Requirements

### Requirement: Local onboarding fork term

The glossary SHALL define Local onboarding fork with the definition in Term
entries below. Specs that describe the maintained Microsoft Azure onboarding
script SHALL use Local onboarding fork rather than Temporary script copy.

#### Scenario: Specs use Local onboarding fork

- **GIVEN** a change authors documentation-ingest or integration-prep requirements about the maintained Microsoft Azure onboarding script
- **WHEN** it names those Skill-held bytes
- **THEN** it MUST use Local onboarding fork
- **AND** it MUST NOT call that file a Temporary script copy

---

## MODIFIED Requirements

### Requirement: Skill-held onboarding terms

The glossary SHALL define Skill-held onboarding artifact, Anonymous origin URL,
Local onboarding fork, Doc-derived Typed action, Operator-only step, Temporary
script copy, Announcement, and Secret sink with the definitions in Term entries
below. Specs that describe Connect script runtime SHALL use Skill-held
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

#### Scenario: Specs use Temporary script copy

- **GIVEN** a change authors Connect runtime requirements about changing names or skipping a menu on a pinned script
- **WHEN** it names that disposable file
- **THEN** it MUST use Temporary script copy
- **AND** it MUST NOT describe an in-place edit of the Skill-held file

#### Scenario: Specs use Announcement not approval for automated

- **GIVEN** a change authors requirements about what automated says before it runs a change
- **WHEN** it names that message
- **THEN** it MUST use Announcement
- **AND** it MUST NOT describe it as an Approve gate

#### Scenario: Specs use Secret sink for agent-run secret output

- **GIVEN** a change authors requirements about where a secret-producing command's output goes under automated
- **WHEN** it names that destination
- **THEN** it MUST use Secret sink
- **AND** it MUST NOT describe the secret as entering agent context, chat, or the Connect log

#### Scenario: Minting a credential does not make a step Operator-only

- **GIVEN** a Prep step whose Typed action is `secretProducing`
- **WHEN** a spec names who executes it under automated
- **THEN** it MUST NOT classify that step as an Operator-only step
- **AND** Operator-only step MUST remain reserved for steps with no Typed action

---

## REMOVED Requirements

---

## RENAMED Requirements

---

## Term entries

### Term: Local onboarding fork
**Context**: documentation-ingest
**Definition**: A Skill-held onboarding artifact whose committed bytes are this project's maintained copy of a vendor-published file, identified by `localFork`, Skill-held `checksum`, and `originChecksum` of the last recorded anonymous origin GET.
**Aliases**: none
**Notes**: Connect runs `checksum` bytes only. Ingest compares origin GET to `originChecksum`. Not a Temporary script copy. This change applies the term to `Entro-Azure-Onboarding.ps1`.

### Term: Skill-held onboarding artifact
**Context**: documentation-ingest
**Definition**: A file or in-page onboarding snippet stored in the Integration's row folder in both `entro-connect` skill trees, identified by skill-relative path and SHA-256. It MAY be vendor-published bytes or a Local onboarding fork.
**Aliases**: vendor script copy, skill-local script
**Notes**: Connect executes these bytes only, or a Temporary script copy of them. GitBook is not the runtime source. Live home is the row folder, not `vendor/`. Not an Operator input.

### Term: Anonymous origin URL
**Context**: documentation-ingest
**Definition**: The GitBook `files.gitbook.io` object URL with `?alt=media` and no `token` query, used by ingest to detect origin change.
**Aliases**: none
**Notes**: Invalid if it contains `token=`. A 200 JSON metadata body (URL without `alt=media`) is not a successful file fetch. Unforked pins compare origin GET to the Skill-held copy. A Local onboarding fork compares origin GET to `originChecksum`. Not used at Connect time.

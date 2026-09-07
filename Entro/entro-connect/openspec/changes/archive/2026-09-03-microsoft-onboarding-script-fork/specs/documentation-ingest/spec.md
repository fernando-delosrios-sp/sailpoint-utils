## ADDED Requirements

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

---

## REMOVED Requirements

---

## RENAMED Requirements

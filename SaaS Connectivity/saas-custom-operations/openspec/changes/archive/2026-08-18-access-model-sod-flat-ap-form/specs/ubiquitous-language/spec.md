## ADDED Requirements

### Term: Flat access profile line

The glossary SHALL define **flat access profile line** as a single pre-rendered list row for a nested access profile on an access-model SoD policy side, showing the access profile name, access profile type tag, and an inline offending entitlement mention.

#### Scenario: Flat access profile line distinguishes removable unit

- **GIVEN** specs or README describe access-model SoD group column HTML for nested access profiles
- **WHEN** normative text names the presentation shape
- **THEN** the preferred term SHALL be **flat access profile line**
- **AND** nested AP tree SHALL NOT appear without a migration note

### Term: Offending entitlement mention

The glossary SHALL define **offending entitlement mention** as the inline phrase on a flat access profile line that names the policy-side entitlement display name(s) driving the violation (for example `— offending: payment_issue`).

#### Scenario: Offending entitlement mention on flat access profile lines

- **GIVEN** specs describe flat access profile lines on access-model SoD remediation forms
- **WHEN** normative text names the inline entitlement label phrase
- **THEN** the preferred term SHALL be **offending entitlement mention**

## MODIFIED Requirements

### Term: Type tag

**Context**: sod-form-html
**Definition**: The pill span denoting role, access profile, or entitlement on a line.
**Aliases**: none
**Notes**: Rendered via `renderTypeTag`; labels are lowercase (`role`, `access profile`, `entitlement`). On access-model SoD flat access profile lines, both access profile and entitlement type tags MAY appear on the same row (profile tag plus offending mention with entitlement tag).

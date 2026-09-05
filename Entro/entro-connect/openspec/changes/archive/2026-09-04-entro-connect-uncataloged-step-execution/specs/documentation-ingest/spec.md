## MODIFIED Requirements

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

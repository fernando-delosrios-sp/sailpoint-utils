## ADDED Requirements

### Requirement: Google Cloud Platform Console-manual actions are source-complete

Documentation ingest SHALL derive the Google Cloud Platform Console-manual
Configuration plan from the pinned Entro Terraform onboarding archive. The plan
MUST keep service-account creation separate from IAM grants, MUST provide a
generated and checksummed IAM grant artifact containing the archive's complete
custom organization role permission list and 12 predefined `roles/*` bindings,
and MUST provide generated API enablement for the archive's organization-project,
host-project, and billing-dependent defaults. The organization audit-log Prep
step MUST be classified as Operator-only with console instructions and
non-secret evidence. Ingest validation MUST fail when the source archive,
generated artifacts, checksums, catalog actions, Integration index, or the two
`entro-connect` Skill trees disagree.

#### Scenario: Available service-account name reaches exact IAM grants

- **GIVEN** the Google Cloud Platform Console-manual path and an available service-account name
- **WHEN** documentation ingest writes its Configuration plan
- **THEN** service-account creation MUST be a separate Typed action
- **AND** a later Typed action MUST run a generated checksummed IAM grant artifact
- **AND** that artifact MUST contain the pinned archive's complete custom organization role permissions and exactly 12 predefined `roles/*` bindings

#### Scenario: Existing service account stops before grants

- **GIVEN** the Google Cloud Platform Console-manual service-account name already exists
- **WHEN** the Connect plan performs its collision inspection
- **THEN** the service-account creation action MUST stop for operator resolution
- **AND** the generated IAM grant action MUST NOT run

#### Scenario: API enablement follows Terraform defaults

- **GIVEN** the pinned Entro Terraform onboarding archive defines default Google Cloud APIs
- **WHEN** documentation ingest generates the Console-manual API action
- **THEN** the action MUST include the organization-project and host-project defaults
- **AND** it MUST include billing-dependent defaults only under the archive's billing condition
- **AND** the plan MUST NOT introduce a Connect-time API-selection fork

#### Scenario: Organization audit logging remains operator-only

- **GIVEN** organization audit-log setup would require replacing the organization IAM policy through the documented command route
- **WHEN** documentation ingest writes the Google Cloud Platform Console-manual Prep steps
- **THEN** audit-log setup MUST be classified as Operator-only
- **AND** its instruction MUST direct the operator to the Google Cloud console
- **AND** its evidence MUST identify a non-secret observable configuration result

#### Scenario: Generated GCP artifacts drift from their source

- **GIVEN** a pinned Terraform role, permission, binding, or API default differs from the generated Google Cloud Platform onboarding artifacts
- **WHEN** documentation ingest validates the committed catalog
- **THEN** validation MUST fail
- **AND** it MUST identify the stale generated artifact or checksum

#### Scenario: Generated GCP outputs stay aligned

- **GIVEN** documentation ingest generates the complete Google Cloud Platform Console-manual plan
- **WHEN** it publishes the Integration index and Skill catalog trees
- **THEN** both `entro-connect` Skill trees MUST contain identical generated IAM and API artifact bytes
- **AND** their Row catalogs MUST record checksums matching those bytes
- **AND** their Typed actions MUST reference the generated artifacts they execute

#### Scenario: Rollback preserves shared API enablement

- **GIVEN** a Connect run created the service account and applied the generated IAM grants
- **WHEN** the operator follows the cataloged rollback
- **THEN** rollback MUST remove only the bindings and custom role created by the grant action
- **AND** it MUST delete the service account only when this run created it
- **AND** enabled APIs MUST remain enabled

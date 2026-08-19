# target-client/forms Delta

## ADDED Requirements

### Requirement: Form seed structural fingerprint

The isc forms module SHALL compute a deterministic SHA-256 fingerprint from the structural fields of a form definition seed: `formInput`, `formElements`, and optional `formConditions`. The fingerprint SHALL be derived from canonical JSON (stable key ordering, no insignificant whitespace). The fingerprint SHALL NOT include the seed human-readable `description` field.

#### Scenario: Same seed produces same fingerprint

- **GIVEN** a valid form definition seed object
- **WHEN** `computeFormSeedFingerprint` is invoked twice with equivalent structural content
- **THEN** both invocations SHALL return the same lowercase hex digest

#### Scenario: Structural change changes fingerprint

- **GIVEN** two seeds identical except for a change to `formElements`
- **WHEN** `computeFormSeedFingerprint` is invoked for each
- **THEN** the returned digests SHALL differ

### Requirement: Watermarked form definition description

The isc forms module SHALL compose form definition `description` values with a machine-readable watermark as the first line followed by optional human-readable text. The watermark line SHALL match `@form-seed-sha256:<64-char-lowercase-hex>` where the hex value equals the structural fingerprint of the supplied seed.

#### Scenario: Payload includes watermark prefix

- **GIVEN** a seed with human description `Example remediation form`
- **WHEN** `buildCreateFormDefinitionPayload` is invoked
- **THEN** the payload `description` SHALL begin with `@form-seed-sha256:` followed by the seed fingerprint
- **AND** SHALL include the human description after the watermark line

#### Scenario: Seed without human description

- **GIVEN** a seed with no `description` field
- **WHEN** `buildCreateFormDefinitionPayload` is invoked without a caller description override
- **THEN** the payload `description` SHALL contain only the watermark line

### Requirement: Watermark parsing

The isc forms module SHALL parse a form definition description and extract the embedded seed fingerprint when the first line matches `@form-seed-sha256:<64-char-lowercase-hex>`. When the prefix is absent or malformed, parsing SHALL return no fingerprint.

#### Scenario: Valid watermark parsed

- **GIVEN** a description whose first line is `@form-seed-sha256:` followed by a 64-character lowercase hex digest
- **WHEN** watermark parsing runs
- **THEN** the parser SHALL return that digest

#### Scenario: Legacy description without watermark

- **GIVEN** a description with no `@form-seed-sha256:` prefix
- **WHEN** watermark parsing runs
- **THEN** the parser SHALL return no fingerprint

## MODIFIED Requirements

### Requirement: Form definition ensure-by-name

The isc forms module SHALL provide `ensureFormDefinitionByName` that searches for a form definition by name. When a definition exists, the function SHALL fetch it by id, compare the parsed description watermark to the fingerprint of the supplied template seed structure, and SHALL reuse the existing definition id when they match. When the watermark is missing or mismatched, the function SHALL patch the definition from the supplied template and return the same id. When no definition exists, the function SHALL create one from the template and return the new id.

#### Scenario: Existing definition reused

- **GIVEN** a form definition named `{formName}` already exists in the tenant with a description watermark matching the template fingerprint
- **WHEN** `ensureFormDefinitionByName` is invoked with that name and template
- **THEN** the function SHALL return the existing definition id
- **AND** SHALL NOT invoke create or patch APIs

#### Scenario: Existing definition with stale watermark patched

- **GIVEN** a form definition named `{formName}` exists with a missing or mismatched description watermark
- **WHEN** `ensureFormDefinitionByName` is invoked with name, owner id, and create template
- **THEN** the function SHALL patch the definition using the supplied template
- **AND** SHALL return the existing definition id

#### Scenario: Missing definition created from template

- **GIVEN** no form definition named `{formName}` exists
- **WHEN** `ensureFormDefinitionByName` is invoked with name, owner id, and create template
- **THEN** the function SHALL create a form definition using the supplied template with runtime name `{formName}`
- **AND** SHALL return the new definition id

#### Scenario: Form definition get failure

- **GIVEN** search returns a definition id but `getFormDefinitionByKeyV1` rejects
- **WHEN** `ensureFormDefinitionByName` performs the watermark check
- **THEN** the function SHALL throw `ConnectorError` describing the form definition read failure

#### Scenario: Form definition patch failure

- **GIVEN** an existing definition with a stale watermark
- **AND** `patchFormDefinitionV1` rejects
- **WHEN** `ensureFormDefinitionByName` attempts refresh
- **THEN** the function SHALL throw `ConnectorError` describing the form definition patch failure

### Requirement: Custom Forms API error surfacing

The isc forms module SHALL surface Custom Forms API failures as `ConnectorError` with a message describing the operation context and HTTP status when available.

#### Scenario: Form definition create failure

- **GIVEN** `createFormDefinitionV1` rejects or returns no definition id
- **WHEN** `ensureFormDefinitionByName` is invoked
- **THEN** the function SHALL throw `ConnectorError` describing the form definition failure

#### Scenario: Form instance create failure

- **GIVEN** `createFormInstanceV1` rejects with an HTTP error or returns no `standAloneFormUrl`
- **WHEN** `createStandaloneFormInstance` is invoked
- **THEN** the function SHALL throw `ConnectorError` describing the form instance failure
- **AND** SHALL include the HTTP status in the message when the underlying client exposes it

#### Scenario: Form search SDK rejection

- **GIVEN** `searchFormDefinitionsByTenantV1` rejects with an axios or SDK error
- **WHEN** `ensureFormDefinitionByName` performs the search step
- **THEN** the function SHALL throw `ConnectorError` rather than propagating a raw axios error

#### Scenario: Form definition get SDK rejection

- **GIVEN** `getFormDefinitionByKeyV1` rejects with an axios or SDK error during watermark check
- **WHEN** `ensureFormDefinitionByName` is invoked for an existing definition
- **THEN** the function SHALL throw `ConnectorError` rather than propagating a raw axios error

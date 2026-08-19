## ADDED Requirements

### Requirement: Persist-output guard

The operation schema codegen SHALL fail with a non-zero exit status when an `OperationSignature.output` field is never persisted by the operation module. Detection SHALL collect the object-literal keys passed as the second argument of `ctx.persist(...)` calls in the operation entry module and compare them to the declared `output` field set. Fields declared in `output` but absent from the persisted-key set SHALL cause the failure, and the error SHALL report the operation module path and the offending field names. A module MAY mark a persisted-but-dynamically-built key with a `// persist-dynamic: <key>` comment to register it as intentionally persisted.

#### Scenario: Never-persisted output field fails codegen

- **GIVEN** an operation declares `output` field `items-scanned` that no `ctx.persist(...)` call writes
- **WHEN** `npm run codegen:schemas` runs
- **THEN** the script SHALL exit with non-zero status
- **AND** SHALL report the module path and the field `items-scanned`

#### Scenario: Fully-persisted output passes

- **GIVEN** every field in an operation's `output` appears as a key in at least one `ctx.persist(...)` object literal in the entry module
- **WHEN** `npm run codegen:schemas` runs
- **THEN** the guard SHALL pass for that operation

#### Scenario: Dynamic persist key registered by marker

- **GIVEN** an operation persists a key built dynamically and marks it with `// persist-dynamic: <key>`
- **WHEN** the guard evaluates that operation
- **THEN** the marked key SHALL be treated as persisted
- **AND** SHALL NOT trigger a guard failure

---

## MODIFIED Requirements

### Requirement: Account schema generation

The generator SHALL produce `templates/account-schema.json` compatible with ISC create-source-schema request shape, using semantic attribute names from registered operation output interfaces. Only `OperationSignature.output` (persisted attributes) SHALL contribute schema attributes; operation response envelope or summary fields SHALL NOT appear as account schema attributes.

#### Scenario: Core attributes always present

- **GIVEN** registered operations exist
- **WHEN** account schema is generated
- **THEN** the schema SHALL include attributes `id`, `status`, and `date`
- **AND** SHALL set `identityAttribute` to `id`
- **AND** SHALL set schema `name` to `account`

#### Scenario: Operation output attributes merged

- **GIVEN** a registered operation declares output fields `summary` and optional `step`
- **WHEN** account schema is generated
- **THEN** the schema SHALL include `summary` and `step` attributes
- **AND** SHALL NOT include reserved framework keys `sourceId` as operator-facing schema attributes

#### Scenario: Response summary fields excluded

- **GIVEN** a registered operation declares persisted output field `form-url` and response summary field `items-scanned`
- **WHEN** account schema is generated
- **THEN** the schema SHALL include `form-url`
- **AND** SHALL NOT include `items-scanned`

#### Scenario: Only registered operations included

- **GIVEN** operations are discovered via auto-registration or manual index.ts registration
- **WHEN** account schema is generated
- **THEN** only discovered operations SHALL contribute output fields to the schema

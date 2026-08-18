# Ubiquitous Language Specification

## Purpose
Shared domain vocabulary for this project. All specs, design docs, code identifiers,
and user-facing copy MUST align with the terms defined here.

## Requirements

### Requirement: Glossary maintenance

The project SHALL maintain an authoritative glossary of domain terms with unambiguous
definitions, preferred spellings, and known aliases.

#### Scenario: New term introduced in a change

- **GIVEN** a change proposal introduces a new domain concept or renames an existing one
- **WHEN** the change is approved for implementation
- **THEN** the term MUST be added or updated in this spec before the change archives

#### Scenario: Term used in a spec

- **GIVEN** a capability spec references a domain noun or verb
- **WHEN** the term is not yet defined in this glossary
- **THEN** the author MUST add the definition here or reuse an existing term instead

### Requirement: Consistent naming

Implementation artifacts (types, functions, API fields, database columns, UI labels)
SHALL use glossary terms verbatim unless a documented alias applies.

#### Scenario: Code review against glossary

- **GIVEN** an implementation uses a domain label visible to other systems or users
- **WHEN** the label differs from the glossary preferred spelling without an alias entry
- **THEN** the implementation MUST be corrected or the glossary MUST be updated first

### Requirement: Bounded context boundaries

When the same word means different things in different areas, each meaning MUST be
listed as a separate entry with its bounded context noted.

#### Scenario: Homonym disambiguation

- **GIVEN** two subsystems use the same word with different meanings
- **WHEN** both meanings appear in specs or code
- **THEN** each meaning MUST have its own glossary entry naming the bounded context

### Requirement: SoD form HTML vocabulary

The project glossary SHALL include terms for unified SoD remediation form HTML styling introduced by the sod-form-html library and consuming operations.

#### Scenario: SoD form HTML term

- **GIVEN** specs or code refer to shared HTML builders for SoD remediation forms
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **SoD form HTML** as HTML string assembly for ISC form DESCRIPTION content under `src/lib/sod-form-html/`

#### Scenario: Outcome panel term

- **GIVEN** specs describe green or red group column backgrounds after side selection
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **outcome panel** as the keep/remove fate wrapper applied after remediation side selection

#### Scenario: Side HTML variant term

- **GIVEN** specs describe pre-rendered group column HTML strings
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **side HTML variant** as one of `plain`, `asKept`, or `asRemoved` for a policy side at form launch

#### Scenario: Type tag term

- **GIVEN** specs describe inline access kind pills on list lines
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL define **type tag** as the pill span denoting role, access profile, or entitlement on a line

### Requirement: logUrl term

The glossary SHALL define logUrl as the optional invoke-config URL that receives structured JSON log events from the custom-operation framework when set.

#### Scenario: logUrl used in specs and config

- **GIVEN** documentation or specs refer to external log delivery configuration
- **WHEN** naming the invoke config field or related types
- **THEN** the preferred spelling SHALL be logUrl
- **AND** aliases log endpoint or remote logger URL SHALL NOT be used in normative text without an alias entry

### Requirement: operationName core attribute term

The glossary SHALL define **operationName core attribute** as the framework-managed STRING account attribute on the DelimitedFile result source that stores the custom command name (`context.commandType`) that last wrote the account.

#### Scenario: operationName used in specs and persist output

- **GIVEN** documentation or specs refer to the invoking custom command on a result account
- **WHEN** naming the persisted account attribute or related framework types
- **THEN** the preferred spelling SHALL be operationName
- **AND** aliases commandType attribute or operation field SHALL NOT be used in normative text without an alias entry

### Requirement: Form email recipients term

The glossary SHALL define **form email recipients** as the multi-value persist output listing email addresses for ISC workflow Send Email `recipientEmailList` after SOD form launch operations.

#### Scenario: Preferred persist key spelling

- **GIVEN** specs or code name the recipient email persist output on `custom:sod-remediation` or `custom:access-model-sod-remediation`
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred attribute suffix SHALL be `form-email-recipients` (plural)
- **AND** the deprecated singular `form-email-recipient` SHALL NOT appear in normative text without a migration note

#### Scenario: Type is string array

- **GIVEN** documentation describes the form email recipients persist field
- **WHEN** the type is stated
- **THEN** it SHALL be described as `string[]` suitable for multi-value STRING account attributes with `isMulti: true`

### Requirement: Access model scan summary term

The glossary SHALL define **scan summary** as the rollup counters returned on the successful `custom:access-model-sod-remediation` invoke response via `ctx.res.send`, comprising `access-model-sod-remediation:access-items-scanned`, `access-model-sod-remediation:violations-found`, and optional `access-model-sod-remediation:forms-skipped` and `access-model-sod-remediation:forms-persist-failed`. The scan summary SHALL NOT be persisted as a result-source account on `requestId`.

#### Scenario: Scan summary term

- **GIVEN** specs or code refer to rollup counts from an access-model scan invoke
- **WHEN** normative text names the delivery mechanism
- **THEN** it SHALL use **scan summary** for the invoke response payload
- **AND** SHALL NOT describe rollup counters as a parent or summary result-source account on `requestId`

### Requirement: Access model SoD remediation term

The glossary SHALL define **access model SoD remediation** as the proactive catalog scan custom operation that detects intrinsic SoD violations on enabled roles and access profiles and creates policy-owner remediation forms via `custom:access-model-sod-remediation`.

#### Scenario: Preferred command spelling

- **GIVEN** specs or code name the access-model scan operation
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred command SHALL be `custom:access-model-sod-remediation`
- **AND** the deprecated `custom:access-sod-remediation` SHALL NOT appear in normative text without a migration note

#### Scenario: Persist namespace spelling

- **GIVEN** documentation names persist output keys for the access-model scan operation
- **WHEN** the prefix is stated
- **THEN** child per-form keys SHALL use prefix `access-model-sod-remediation:`
- **AND** scan rollup counters SHALL be described as **scan summary** on the invoke response, not as persisted attributes on `requestId`
- **AND** the deprecated prefix `access-sod-remediation:` SHALL NOT appear in normative text without a migration note

#### Scenario: SoD form HTML shared usage

- **GIVEN** documentation describes which operations use shared sod-form-html builders
- **WHEN** the access-model scan operation is listed
- **THEN** it SHALL name `custom:access-model-sod-remediation` alongside `custom:sod-remediation`

## Term entries

### Term: SoD form HTML
**Context**: sod-form-html
**Definition**: HTML string assembly for ISC form DESCRIPTION content under `src/lib/sod-form-html/`.
**Aliases**: none
**Notes**: Shared by `custom:sod-remediation` and `custom:access-model-sod-remediation`.

### Term: Outcome panel
**Context**: sod-form-html
**Definition**: The keep/remove fate wrapper applied after remediation side selection, using green for kept and red for removed.
**Aliases**: none
**Notes**: Appears only in `asKept` and `asRemoved` side HTML variants.

### Term: Side HTML variant
**Context**: sod-form-html
**Definition**: One of `plain`, `asKept`, or `asRemoved` for a policy side at form launch.
**Aliases**: none
**Notes**: Pre-rendered into formInput STRING fields; seed formConditions swap visibility on selection.

### Term: Type tag
**Context**: sod-form-html
**Definition**: The pill span denoting role, access profile, or entitlement on a line.
**Aliases**: none
**Notes**: Rendered via `renderTypeTag`; labels are lowercase (`role`, `access profile`, `entitlement`).

### Term: Scan summary
**Context**: connector-operations / access-model-sod-remediation
**Definition**: Rollup counters returned on the successful `custom:access-model-sod-remediation` invoke response via `ctx.res.send` (`access-items-scanned`, `violations-found`, optional `forms-skipped` and `forms-persist-failed`).
**Aliases**: none
**Notes**: Not persisted on result-source identity `requestId`; child accounts at `{requestId}:{accessItemId}:{policyId}` hold per-form workflow outputs.

### Term: Form email recipients
**Context**: connector-operations
**Definition**: Multi-value persist output listing email addresses for ISC workflow Send Email `recipientEmailList` after SOD form launch operations.
**Aliases**: none
**Notes**: Persist key suffix `form-email-recipients` (`string[]`, `isMulti: true`) on `custom:sod-remediation` and `custom:access-model-sod-remediation`.

### Term: logUrl
**Context**: custom-operation-framework / connector-config
**Definition**: Optional invoke-config string URL. When non-empty, the framework POSTs one JSON log event per logger call to that URL in addition to writing human-readable lines to stdout.
**Aliases**: none
**Notes**: Not declared in connector-spec.json sourceConfig in v1; supplied at invoke time via config.logUrl on workflow or spcx payloads.

### Term: operationName core attribute
**Context**: custom-operation-framework
**Definition**: Mandatory framework-managed STRING attribute on the result source account schema; populated automatically on persist with the full custom command name (e.g. `custom:sod-remediation`).
**Aliases**: none
**Notes**: Not part of `OperationSignature.output`; distinct from prefixed operation output keys such as `sod-remediation:formUrl`.

<!-- Add terms using this pattern:

### Term: <Preferred Name>
**Context**: <bounded context or "global">
**Definition**: <one or two sentences>
**Aliases**: <comma-separated alternatives, or "none">
**Notes**: <optional examples, anti-patterns, related terms>

-->

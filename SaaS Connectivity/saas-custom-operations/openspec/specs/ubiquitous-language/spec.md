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

#### Scenario: Flat access profile line term

- **GIVEN** specs or README describe access-model SoD group column HTML for nested access profiles
- **WHEN** normative text names the presentation shape
- **THEN** it SHALL define **flat access profile line** as a single pre-rendered list row for a nested access profile on an access-model SoD policy side
- **AND** nested AP tree SHALL NOT appear without a migration note

#### Scenario: Offending entitlement mention term

- **GIVEN** specs describe flat access profile lines on access-model SoD remediation forms
- **WHEN** normative text names the inline entitlement label phrase
- **THEN** it SHALL define **offending entitlement mention** as the inline phrase naming the policy-side entitlement display name(s) driving the violation

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

### Requirement: Persistable email body term

The glossary SHALL define **persistable email body** as a compact HTML string intended for DelimitedFile/STRING account attributes and ISC workflow Send Email bodies, bounded by `ISC_STRING_ATTRIBUTE_MAX_LENGTH` (256).

#### Scenario: Preferred term for compact workflow email HTML

- **GIVEN** documentation refers to HTML stored on a result account for workflow email delivery
- **WHEN** distinguishing it from in-form DESCRIPTION HTML
- **THEN** the preferred term SHALL be **persistable email body**
- **AND** SHALL NOT call that content SoD form HTML or situation summary panel without qualification

### Requirement: Unquoted href CTA term

The glossary SHALL define **unquoted href CTA** as an HTML anchor whose `href` value is not wrapped in quotes, kept DelimitedFile/`provisionAsCsv`-safe when URLs contain no spaces.

#### Scenario: Preferred spelling for form email links

- **GIVEN** specs describe the remediation or reminder link inside a persistable email body
- **WHEN** naming the link construction convention
- **THEN** the preferred term SHALL be **unquoted href CTA**
- **AND** normative examples SHALL NOT require quoted `href="..."` attributes

### Requirement: Form notification envelope term

The glossary SHALL define **form notification envelope** as the workflow-facing companion to a launched standalone form instance: form URL, plain-text email subject (**form email header**), compact HTML email body (**form email body** / persistable email body), and **form email recipients**.

#### Scenario: Preferred term for the four-field companion

- **GIVEN** documentation describes the set of persist fields used by Notification workflows after form launch
- **WHEN** naming that set as a unit
- **THEN** the preferred term SHALL be **form notification envelope**
- **AND** SHALL NOT invent alternate umbrella names (e.g. form email bundle) in normative text

### Requirement: Form email header term

The glossary SHALL define **form email header** as the plain-text subject line persisted as `{slug}:form-email-header` for ISC workflow Send Email subject binding.

#### Scenario: Preferred persist key spelling for subject

- **GIVEN** specs name the email subject persist output after form launch
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred attribute suffix SHALL be `form-email-header`

### Requirement: Form launch term

The glossary SHALL define **form launch** as the choreographed sequence that ensures a tenant form definition from an operation seed, creates a standalone assigned form instance for a recipient, and produces a **form notification envelope** for persist/workflows.

#### Scenario: Preferred term for ensure-create-notify choreography

- **GIVEN** documentation describes the shared ensure-definition then create-instance then notification pairing
- **WHEN** naming that choreography
- **THEN** the preferred term SHALL be **form launch**
- **AND** SHALL NOT use ambiguous **form service** for the shared orchestrator in normative text

### Requirement: Operation response term

The glossary SHALL define **operation response** as the typed payload a custom operation returns via `ctx.res.send`, an envelope comprising `name` (operation/command name), `status`, `responses` (the native identities persisted during the invoke), and `summary` (per-operation response detail typed from `OperationSignature['response']`). The operation response SHALL NOT be persisted and SHALL NOT contribute attributes to the result-source account schema.

#### Scenario: Operation response term

- **GIVEN** specs or code name the typed `ctx.res.send` payload of a custom operation
- **WHEN** normative text names that envelope
- **THEN** it SHALL use **operation response**
- **AND** SHALL distinguish it from the persisted **operation output** that feeds the account schema

#### Scenario: Operation response excluded from account schema

- **GIVEN** documentation describes what propagates to the result-source account schema
- **WHEN** the operation response is mentioned
- **THEN** it SHALL state that operation response fields are NOT account schema attributes

### Requirement: Response id list term

The glossary SHALL define **response id list** as the `responses: string[]` field on the operation response — the native identities written via `ctx.persist` during the invoke, enabling callers to correlate the response to result-source accounts.

#### Scenario: Response id list term

- **GIVEN** specs or code name the array of persisted identities on the operation response
- **WHEN** normative text names that field
- **THEN** it SHALL use **response id list** for the `responses` concept
- **AND** SHALL describe its values as native identities, not ISC account UUIDs

### Requirement: Access model scan summary term

The glossary SHALL define **scan summary** as the access-model-specific instance of the general **operation response** summary: the rollup counters returned on the successful `custom:access-model-sod-remediation` invoke response via `ctx.res.send`, comprising `access-model-sod-remediation:access-items-scanned`, `access-model-sod-remediation:violations-found`, and optional `access-model-sod-remediation:forms-skipped` and `access-model-sod-remediation:forms-persist-failed`. Optional `forms-skipped` SHALL count violations skipped because the child persist account already exists. The scan summary SHALL be delivered as the operation response `summary`, SHALL NOT be persisted as a result-source account on `requestId`, SHALL NOT be declared in `OperationSignature['output']`, and SHALL NOT appear as a result-source account schema attribute.

#### Scenario: Scan summary term

- **GIVEN** specs or code refer to rollup counts from an access-model scan invoke
- **WHEN** normative text names the delivery mechanism
- **THEN** it SHALL use **scan summary** for the operation response summary payload
- **AND** SHALL NOT describe rollup counters as a parent or summary result-source account on `requestId`

#### Scenario: Scan summary is an operation response summary

- **GIVEN** documentation relates scan summary to the general vocabulary
- **WHEN** the terms are compared
- **THEN** **scan summary** SHALL be described as the access-model instance of **operation response** summary
- **AND** SHALL NOT be declared in `OperationSignature['output']` nor appear on the account schema

### Requirement: Access item owner term

The glossary SHALL define **access item owner** as the IDENTITY-typed primary owner of a catalog access item (role or access profile). For `custom:access-model-sod-remediation`, the access item owner is the form instance recipient and the sole source of `form-email-recipients`.

#### Scenario: Access item owner is form audience

- **GIVEN** documentation describes who receives access-model SoD remediation forms
- **WHEN** the ubiquitous language spec is read
- **THEN** it SHALL use **access item owner**
- **AND** SHALL NOT describe the form recipient as the SoD policy owner

#### Scenario: Distinct from form definition owner

- **GIVEN** documentation distinguishes form definition ownership from form instance recipient
- **WHEN** the terms are compared
- **THEN** **access item owner** SHALL mean the catalog item owner used as form recipient
- **AND** SHALL NOT mean the access-token identity that owns the shared form definition on create

### Requirement: Access model SoD remediation term

The glossary SHALL define **access model SoD remediation** as the proactive catalog scan custom operation that detects intrinsic SoD violations on enabled roles and access profiles and creates access-item-owner remediation forms via `custom:access-model-sod-remediation`.

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

### Requirement: Parent request id term

The glossary SHALL define **parent request id** as the `requestId` supplied on a `custom:access-model-sod-remediation` invoke. It prefixes child persist identities `` `${requestId}:{accessItemId}:{policyId}` `` and is stored on form instances as `formInput.parentRequestId` for traceability.

#### Scenario: Parent request id naming

- **GIVEN** specs or code correlate access-model scan forms to their launching invoke
- **WHEN** normative text names the scan invoke identifier on form instances
- **THEN** it SHALL use **parent request id** for the scan `requestId` concept
- **AND** the form field SHALL be spelled `parentRequestId`

### Requirement: Child persist account idempotency term

The glossary SHALL define **child persist account idempotency** as skipping launch of an access-model SoD remediation form and skipping child persist when a result-source account already exists for child persist identity `` `${requestId}:{accessItemId}:{policyId}` `` on the operation source — without querying form instance state.

#### Scenario: Child persist idempotency naming

- **GIVEN** specs describe access-model scan idempotency on retry or concurrent invoke
- **WHEN** normative text names the skip signal
- **THEN** it SHALL use **child persist account idempotency**
- **AND** SHALL NOT describe idempotency as dependent on ASSIGNED form instance state

### Requirement: Child persist identity term

The glossary SHALL define **child persist identity** as the result-source native identity `` `${requestId}:{accessItemId}:{policyId}` `` where per-violation access-model SoD remediation outputs are persisted after form launch.

#### Scenario: Child persist identity naming

- **GIVEN** specs or code refer to per-violation result-source account keys for the access-model scan
- **WHEN** normative text names that key pattern
- **THEN** it SHALL use **child persist identity**

### Requirement: Form name vocabulary

The glossary SHALL define **form name** as the tenant-visible Custom Forms definition name (`formName`) shared by `custom:access-model-sod-remediation` (ensure-from-seed) and `custom:access-model-sod-remediation-apply` (lookup). The same string selects the same form definition.

#### Scenario: Form name term

- **GIVEN** specs describe apply or scan identifying the shared remediation form definition
- **WHEN** normative text names the operator-facing field
- **THEN** it SHALL use **form name**
- **AND** SHALL map it to the input field `formName`
- **AND** SHALL NOT treat `formDefinitionId` as the apply invoke field

### Requirement: Form definition id vocabulary

The glossary SHALL define **form definition id** as the ISC Custom Forms identifier of the form definition that spawned a form instance (`formDefinitionId`). It is the only supported filter on the tenant form instance list. For `custom:access-model-sod-remediation-apply`, the handler SHALL obtain it by looking up **form name**; it SHALL NOT be a required apply invoke input.

#### Scenario: Form definition id term

- **GIVEN** specs describe listing form instances for apply
- **WHEN** normative text names the list filter
- **THEN** it SHALL use **form definition id**
- **AND** SHALL describe it as the resolved list filter, not the apply invoke field
- **AND** SHALL NOT use `formId` as the preferred spelling

### Requirement: Access model SoD remediation apply term

The glossary SHALL define **access model SoD remediation apply** as the custom operation `custom:access-model-sod-remediation-apply` that applies a completed access-model SoD remediation form decision to the ISC catalog access item under review.

#### Scenario: Preferred command spelling

- **GIVEN** specs or README describe applying a completed access-model SoD remediation form
- **WHEN** normative text names the apply operation
- **THEN** the preferred command SHALL be `custom:access-model-sod-remediation-apply`
- **AND** persist output keys SHALL use prefix `access-model-sod-remediation-apply:`

#### Scenario: Distinct from identity sod remediation

- **GIVEN** documentation lists SoD remediation operations
- **WHEN** access model catalog apply is described
- **THEN** it SHALL distinguish **access model SoD remediation apply** from `custom:sod-remediation` identity violation response

#### Scenario: Apply inputs

- **GIVEN** specs describe invoke input for access model SoD remediation apply
- **WHEN** normative text names required fields
- **THEN** it SHALL require `formInstanceId` and **form name** (`formName`)
- **AND** SHALL note persist identity remains `{formInstanceId}`
- **AND** SHALL NOT require `formDefinitionId` as invoke input

### Requirement: Log detail map term

The glossary SHALL define log detail map as the optional named key-value object passed as the second argument to ctx.log methods, serialized to the external log event detail field after redaction and JSON-safe normalization.

#### Scenario: log detail map used in specs

- **GIVEN** a spec or README describes structured ctx.log attachments
- **WHEN** referring to the second argument object
- **THEN** the preferred term SHALL be log detail map

---

### Requirement: JSON-safe detail normalization term

The glossary SHALL define JSON-safe detail normalization as the framework step that removes or replaces detail values that cannot be JSON-encoded before console formatting and logUrl POST.

#### Scenario: JSON-safe normalization used in specs

- **GIVEN** a spec describes detail handling before external POST
- **WHEN** referring to circular reference and function omission
- **THEN** the preferred term SHALL be JSON-safe detail normalization

---

### Requirement: Pretty console formatting term

The glossary SHALL define pretty console formatting as the multiline human-readable stdout layout for framework log events with a requestId headline and labeled detail blocks.

#### Scenario: pretty console formatting used in specs

- **GIVEN** a spec describes stdout layout for ctx.log
- **WHEN** referring to multiline per-key inspect output
- **THEN** the preferred term SHALL be pretty console formatting

### Requirement: SoD form context panel vocabulary

The project glossary SHALL include terms for unified SoD remediation form upper-panel content and ISC admin deep linking introduced by aligned context panels.

#### Scenario: Context panel term

- **GIVEN** specs or README describe the upper form section explaining the conflict and required recipient action
- **WHEN** normative text names that section
- **THEN** it SHALL define **context panel** as the “What we found / What we need from you” upper DESCRIPTION content
- **AND** SHALL distinguish it from group column preview sections

#### Scenario: ISC UI link term

- **GIVEN** specs or code render anchors to ISC admin routes from form HTML
- **WHEN** normative text names those anchors
- **THEN** it SHALL define **ISC UI link** as an admin UI anchor built from invoke `apiUrl` without hardcoded domains

#### Scenario: UI origin term

- **GIVEN** specs describe deriving the tenant UI base URL from loopback `apiUrl`
- **WHEN** normative text names that base URL
- **THEN** it SHALL define **UI origin** as the protocol and host used to prefix ISC admin UI paths

### Requirement: disableLinks input vocabulary

The project glossary SHALL define **disableLinks** as the optional boolean custom-operation input that suppresses ISC UI links in remediation form HTML for a single invoke when set to true.

#### Scenario: disableLinks term

- **GIVEN** specs or README describe opting out of admin deep links on `custom:access-model-sod-remediation` or `custom:sod-remediation`
- **WHEN** normative text names that input
- **THEN** it SHALL use **disableLinks**
- **AND** SHALL define it as suppressing ISC UI links in form HTML without removing form URL or email remediation CTA outputs

## Term entries

### Term: Form name
**Context**: connector-operations / access-model-sod-remediation / access-model-sod-remediation-apply
**Definition**: The tenant-visible Custom Forms definition name (`formName`) that identifies the shared access-model SoD remediation form.
**Aliases**: formDefinitionId (rejected as apply invoke input)
**Notes**: Scan ensures the definition from seed; apply looks up the existing definition by this name then lists instances by the resolved form definition id.

### Term: Form definition id
**Context**: connector-operations / access-model-sod-remediation-apply / target-client/forms
**Definition**: The ISC Custom Forms identifier of the form definition that spawned a form instance (`formDefinitionId`).
**Aliases**: formId (rejected shorthand)
**Notes**: Internal list filter for tenant form instances. Apply obtains it via form name lookup; it is not an apply invoke field. Distinct from `formInstanceId`.

### Term: Access model SoD remediation apply
**Context**: connector-operations / access-model-sod-remediation-apply
**Definition**: The custom operation that reads a completed access-model SoD remediation form instance and mutates the referenced role or access profile in the ISC catalog per `remediationSide`.
**Aliases**: none
**Notes**: Required inputs are `formInstanceId` and `formName`; persist identity is `{formInstanceId}`.

### Term: disableLinks
**Context**: connector-operations / access-model-sod-remediation / sod-remediation
**Definition**: Optional boolean custom-operation input that, when `true`, suppresses ISC UI links in remediation form HTML for that invoke (plain escaped entity names; no admin anchors).
**Aliases**: none
**Notes**: Does not remove `*:form-url` or the email remediation-form CTA. Omitted or `false` keeps linked behavior when UI origin resolves.

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
**Notes**: Rendered via `renderTypeTag`; labels are lowercase (`role`, `access profile`, `entitlement`). On access-model SoD flat access profile lines, both access profile and entitlement type tags MAY appear on the same row (profile tag plus offending mention with entitlement tag).

### Term: Flat access profile line
**Context**: sod-form-html / access-model-sod-remediation
**Definition**: A single pre-rendered list row for a nested access profile on an access-model SoD policy side, showing the access profile name, access profile type tag, and an inline offending entitlement mention.
**Aliases**: none
**Notes**: Rendered via `renderEntitlementTree`; replaces nested AP entitlement bullet trees on access-model SoD remediation forms.

### Term: Offending entitlement mention
**Context**: sod-form-html / access-model-sod-remediation
**Definition**: The inline phrase on a flat access profile line that names the policy-side entitlement display name(s) driving the violation (for example `— offending: payment_issue`).
**Aliases**: none
**Notes**: Comma-separates multiple side-matching entitlements from the same nested access profile on one row.

### Term: Scan summary
**Context**: connector-operations / access-model-sod-remediation
**Definition**: Rollup counters returned on the successful `custom:access-model-sod-remediation` invoke response via `ctx.res.send` (`access-items-scanned`, `violations-found`, optional `forms-skipped` and `forms-persist-failed`). Optional `forms-skipped` counts violations skipped because the child persist account already exists.
**Aliases**: none
**Notes**: Not persisted on result-source identity `requestId`; child accounts at `{requestId}:{accessItemId}:{policyId}` hold per-form workflow outputs.

### Term: Form email recipients
**Context**: connector-operations
**Definition**: Multi-value persist output listing email addresses for ISC workflow Send Email `recipientEmailList` after SOD form launch operations.
**Aliases**: none
**Notes**: Persist key suffix `form-email-recipients` (`string[]`, `isMulti: true`) on `custom:sod-remediation` and `custom:access-model-sod-remediation`.

### Term: Persistable email body
**Context**: persistable-email / connector-operations
**Definition**: Compact HTML string intended for DelimitedFile/STRING account attributes and ISC workflow Send Email bodies, bounded by `ISC_STRING_ATTRIBUTE_MAX_LENGTH` (256).
**Aliases**: none
**Notes**: Distinct from in-form DESCRIPTION HTML (`sod-form-html`).

### Term: Unquoted href CTA
**Context**: persistable-email
**Definition**: HTML anchor whose `href` value is not wrapped in quotes, kept DelimitedFile/`provisionAsCsv`-safe when URLs contain no spaces.
**Aliases**: none
**Notes**: Used in persistable email bodies that link to a standalone form URL.

### Term: Form notification envelope
**Context**: form-notification / connector-operations
**Definition**: Workflow-facing companion to a launched standalone form instance: form URL, form email header, form email body, and form email recipients.
**Aliases**: form email bundle (do not use in normative text)
**Notes**: Persist suffixes `form-url`, `form-email-header`, `form-email-body`, `form-email-recipients`.

### Term: Form email header
**Context**: connector-operations
**Definition**: Plain-text subject line persisted as `{slug}:form-email-header` for ISC workflow Send Email subject binding.
**Aliases**: none
**Notes**: none

### Term: Form launch
**Context**: form-launch / connector-operations
**Definition**: Choreography that ensures a tenant form definition from an operation seed, creates a standalone assigned form instance for a recipient, and produces a form notification envelope.
**Aliases**: form service (do not use for the shared orchestrator)
**Notes**: Persistence and recipient policy stay with the operation handler.

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

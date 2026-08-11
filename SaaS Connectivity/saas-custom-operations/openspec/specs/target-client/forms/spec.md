# target-client/forms Specification

## Purpose

Documents ISC Custom Forms integration helpers and empirically verified form-definition authoring constraints for the connector's generic forms client and seed templates.
## Requirements
### Requirement: Generic form definition seed loading

The isc forms module SHALL load a form definition seed template from a caller-supplied path or bundled JSON object. The loader SHALL NOT hardcode operation-specific seed filenames or default descriptions.

#### Scenario: Seed loaded from bundled object

- **GIVEN** a caller provides a valid seed object with `formElements`
- **WHEN** `loadFormSeed` is invoked
- **THEN** the loader SHALL return parsed seed fields including `formInput`, `formElements`, and optional `formConditions`

#### Scenario: Missing formElements rejected

- **GIVEN** a seed object without `formElements`
- **WHEN** `loadFormSeed` is invoked
- **THEN** the loader SHALL throw an error indicating the seed is invalid

### Requirement: Form definition ensure-by-name

The isc forms module SHALL provide `ensureFormDefinitionByName` that searches for a form definition by name and creates one from a caller-supplied template when absent. The function SHALL NOT patch existing definitions.

#### Scenario: Existing definition reused

- **GIVEN** a form definition named `{formName}` already exists in the tenant
- **WHEN** `ensureFormDefinitionByName` is invoked with that name
- **THEN** the function SHALL return the existing definition id
- **AND** SHALL NOT invoke create or patch APIs

#### Scenario: Missing definition created from template

- **GIVEN** no form definition named `{formName}` exists
- **WHEN** `ensureFormDefinitionByName` is invoked with name, owner id, and create template
- **THEN** the function SHALL create a form definition using the supplied template with runtime name `{formName}`
- **AND** SHALL return the new definition id

### Requirement: Standalone form instance create

The isc forms module SHALL provide `createStandaloneFormInstance` that creates an assigned standalone form instance and returns `standAloneFormUrl`.

#### Scenario: Standalone instance created

- **GIVEN** a valid form definition id, recipient identity id, source id, and formInput map
- **WHEN** `createStandaloneFormInstance` is invoked
- **THEN** the function SHALL set `standAloneForm: true` and state `ASSIGNED`
- **AND** SHALL set `createdBy.type` to `SOURCE`
- **AND** SHALL return the `standAloneFormUrl` from the create response

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

### Requirement: Forms client available on context

The connector SHALL expose configured CustomFormsApi methods on `RequestContext.sdk.forms` for the duration of each custom operation invocation.

#### Scenario: Forms client configured

- **GIVEN** a custom operation receives valid apiUrl and token in its input envelope
- **WHEN** the handler accesses ctx.sdk.forms
- **THEN** the client SHALL be configured for search/create form definitions and create form instances

### Requirement: DESCRIPTION element HTML rendering

ISC Custom Forms DESCRIPTION elements SHALL render `config.description` as HTML. Authors MAY combine static HTML fragments with `{{$.form.input.<key>}}` interpolation in the same description string. Verified against ISC tenant rendering (Aug 2026).

#### Scenario: formInput interpolation in description

- **GIVEN** a DESCRIPTION element with `description` set to `{{$.form.input.situationSummaryHtml}}`
- **AND** launch-time formInput supplies a value for that key
- **WHEN** the form instance is rendered
- **THEN** ISC SHALL substitute the formInput value into the description
- **AND** SHALL render the result as HTML

#### Scenario: Static HTML block elements

- **GIVEN** a DESCRIPTION element whose description contains static HTML using block elements `<p>`, `<ul>`, `<ol>`, and `<li>`
- **WHEN** the form instance is rendered
- **THEN** ISC SHALL preserve those block elements in the rendered output

#### Scenario: Inline emphasis and styling

- **GIVEN** a DESCRIPTION element whose description contains `<strong>`, `<em>`, `<s>`, `<span style="...">`, and nested combinations thereof
- **WHEN** the form instance is rendered
- **THEN** ISC SHALL preserve inline tags and inline `style` attributes including `text-decoration`, `font-size`, `color`, and `background-color`

#### Scenario: Code and links

- **GIVEN** a DESCRIPTION element whose description contains `<code>` and `<a href="..." target="..." rel="..." title="...">`
- **WHEN** the form instance is rendered
- **THEN** ISC SHALL preserve `<code>` formatting
- **AND** SHALL preserve link `href`, `target`, `rel`, and `title` attributes

#### Scenario: List item alignment and styling

- **GIVEN** a DESCRIPTION element whose description contains list items with inline styles `text-align`, `list-style-type`, and `line-height`
- **WHEN** the form instance is rendered
- **THEN** ISC SHALL preserve those inline styles on the corresponding elements

#### Scenario: Nested ordered lists

- **GIVEN** a DESCRIPTION element whose description contains nested `<ol>` elements including a parent `<li style="list-style-type: none;">` wrapping a child list
- **WHEN** the form instance is rendered
- **THEN** ISC SHALL preserve the nested list structure

#### Scenario: Avoid double paragraph wrapping on interpolated HTML

- **GIVEN** a formInput value that already contains a top-level `<p>...</p>` wrapper
- **AND** the DESCRIPTION template wraps the same interpolation in an outer `<p>{{$.form.input.<key>}}</p>`
- **WHEN** the form instance is rendered
- **THEN** browsers SHALL normalize invalid nested `<p>` markup into sibling paragraphs including empty `<p></p>` elements
- **AND** form seed authors SHALL NOT wrap interpolations that already supply block-level HTML in an additional `<p>` element



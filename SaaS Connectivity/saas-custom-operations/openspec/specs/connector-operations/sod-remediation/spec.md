# connector-operations/sod-remediation Specification

## Purpose
TBD - created by archiving change operation-layer-boundaries. Update Purpose after archive.
## Requirements
### Requirement: SOD remediation launch operation

The connector SHALL register a custom command `custom:sod-remediation` that prepares an ISC form instance for SOD violation remediation and SHALL NOT execute corrective revokes or mitigating-control application. Implementation SHALL reside under `src/operations/sod-remediation/` with entry module `index.ts`.

#### Scenario: Operation invoked with required inputs

- **GIVEN** `custom:sod-remediation` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `violationId`, `formName`, and standard `requestId`
- **THEN** the handler SHALL fetch the violation, ensure the form definition identified by `formName` exists, create a standalone form instance, and persist namespaced output fields `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, and `sod-remediation:form-email-recipients`

#### Scenario: Recipient defaults to violation owner

- **GIVEN** a violation whose owner identity ID is `owner-a`
- **AND** input does not include `owner`
- **WHEN** `custom:sod-remediation` creates a form instance
- **THEN** the form instance recipient SHALL be identity `owner-a`

#### Scenario: Recipient override via owner input

- **GIVEN** input includes `owner` set to identity ID `owner-b`
- **WHEN** `custom:sod-remediation` creates a form instance
- **THEN** the form instance recipient SHALL be identity `owner-b` regardless of the violation owner

#### Scenario: Form definition created once by name

- **GIVEN** no form definition named `{formName}` exists in the tenant
- **WHEN** `custom:sod-remediation` is invoked with that `formName`
- **THEN** the handler SHALL create a form definition from the bundled seed template in `src/operations/sod-remediation/seed/` using `{formName}` as the definition name
- **AND** subsequent invocations with the same `formName` SHALL reuse the existing definition without patching it

#### Scenario: Form definition owner is access token identity

- **GIVEN** connector config includes a valid access token whose resolved identity ID is `token-owner-id`
- **AND** no form definition named `{formName}` exists in the tenant
- **AND** the violation owner identity ID is `violation-owner-id` where `violation-owner-id` differs from `token-owner-id`
- **WHEN** `custom:sod-remediation` creates the form definition from seed
- **THEN** the form definition owner SHALL be identity `token-owner-id`
- **AND** SHALL NOT use `violation-owner-id` as the form definition owner

#### Scenario: Form definition owner offline fallback

- **GIVEN** invoke runs in offline mode without `apiUrl` and without `token`
- **AND** no form definition named `{formName}` exists
- **WHEN** `custom:sod-remediation` creates the form definition from seed
- **THEN** the form definition owner SHALL use the connector's offline canned owner identity
- **AND** SHALL NOT attempt JWT token identity resolution

#### Scenario: Owner email resolved for workflow delivery

- **GIVEN** the resolved form instance recipient identity ID is `owner-a`
- **AND** the public identity record for `owner-a` has email `owner-a@example.com`
- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `sod-remediation:form-email-recipients` SHALL be `['owner-a@example.com']`

#### Scenario: Email subject header output

- **GIVEN** a violation for identity `Alice Example`
- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `sod-remediation:form-email-header` SHALL be plain text suitable for workflow email subject lines
- **AND** SHALL include the violating identity display name

#### Scenario: Email summary includes remediation form link

- **GIVEN** a successful launch producing form URL `https://tenant.example/form/1`
- **WHEN** the handler persists operation output
- **THEN** `sod-remediation:form-email-body` SHALL include an HTML link to the remediation form URL
- **AND** form launch input `situationSummaryHtml` SHALL NOT include the remediation form link

#### Scenario: Output contract is minimal

- **GIVEN** a successful launch
- **WHEN** the handler completes
- **THEN** operation output persisted via `ctx.persist` SHALL include only `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, and `sod-remediation:form-email-recipients` as typed output fields
- **AND** SHALL NOT require output fields `formInstanceId`, `violationId`, `formName`, `formDefinitionId`, or `recipientName`

#### Scenario: Workflow-friendly form keys

- **GIVEN** the seed form definition used for SOD remediation
- **WHEN** a recipient submits the form
- **THEN** submitted `formData` SHALL expose user keys `action`, `remediationSide`, `control`, and `comments`
- **AND** launch-time keys `violationId`, `targetIdentityId`, `groupAAccessSearch`, and `groupBAccessSearch` SHALL be populated on the form instance `formInput` at create time and SHALL NOT require hidden form elements or `formData` pass-through
- **AND** SHALL NOT include hidden keys `groupARevokePayload` or `groupBRevokePayload`

#### Scenario: Single-side corrective selection

- **GIVEN** the user selects `action` value `Correct`
- **WHEN** the form is submitted
- **THEN** `formData.remediationSide` SHALL be exactly one of `groupA` or `groupB`

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/sod-remediation/index.ts` declares `command: 'custom:sod-remediation'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:sod-remediation` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

### Requirement: SOD access path resolution

The sod-remediation operation SHALL resolve each conflicting entitlement on a violation side into a display list that includes the entitlement and any access profile or role assigned to the target identity that grants that entitlement. Access path resolution logic SHALL reside under `src/operations/sod-remediation/` and SHALL NOT be part of the generic isc integration layer.

#### Scenario: Entitlement-only side

- **GIVEN** a conflicting entitlement held directly by the target identity
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the entitlement
- **AND** the side warning text SHALL use the standard corrective-removal message

#### Scenario: Access profile or role on side

- **GIVEN** a conflicting entitlement granted via an access profile or role assigned to the target identity
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the access profile or role in addition to the entitlement
- **AND** the side warning text SHALL state that removing profile- or role-level access may affect other functions of the user

#### Scenario: Hidden access search string per side

- **WHEN** form input is assembled for launch
- **THEN** each side SHALL produce an ISC access-item search filter joining **revocable** resolved path item ids with ` OR ` in the form `id:{uuid}`
- **AND** SHALL NOT include ids for access path items marked not revocable

#### Scenario: Single-item side search string

- **GIVEN** a violation side with one revocable resolved access path item
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL be `id:{itemId}` without an ` OR ` suffix

#### Scenario: Mixed revocable and non-revocable items on side

- **GIVEN** a conflicting entitlement granted via an assigned role on the same side
- **AND** the entitlement line is marked not revocable
- **AND** the role line is marked revocable
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL include only the role id
- **AND** SHALL NOT include the entitlement id

#### Scenario: Entitlement-only revocable side unchanged

- **GIVEN** a violation side with conflicting entitlements and no assigned access profile or role granting them
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL include each entitlement id joined with ` OR `

### Requirement: SOD controls and violation data at launch

The sod-remediation operation SHALL fetch violation details and tenant compensating controls at launch using isc pre-SDK HTTP clients and SHALL assemble operation-specific form input from the results.

#### Scenario: Controls listed at launch

- **WHEN** `custom:sod-remediation` prepares form input
- **THEN** the handler SHALL list tenant compensating controls via the isc controls client
- **AND** SHALL set form launch input indicating whether any controls exist (`hasControls`)

#### Scenario: Empty controls hides mitigate path

- **GIVEN** tenant compensating controls list is empty
- **WHEN** the form instance is created
- **THEN** form input SHALL indicate mitigation is unavailable
- **AND** the situation summary SHALL note that no compensating controls are configured

### Requirement: Situation summary HTML format

The sod-remediation operation SHALL build `sod-remediation:form-email-body` as HTML suitable for workflow email bodies. The same HTML SHALL populate `situationSummaryHtml` formInput for in-form DESCRIPTION rendering. Violation-derived dynamic text SHALL be HTML-escaped and SHALL NOT embed unescaped user-controlled markup. The in-form `situationSummaryHtml` SHALL append a single emoji legend footer decoding icon suffix meanings.

#### Scenario: Email-oriented HTML structure

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** operation output `sod-remediation:form-email-body` SHALL include a top-level heading, labeled identity/policy/violation fields, grouped access-path lists, and an optional note when no compensating controls exist
- **AND** SHALL use semantic HTML elements such as `h2`, `h3`, `p`, `strong`, `ul`, `li`, and `em`

#### Scenario: Dynamic values escaped

- **WHEN** `custom:sod-remediation` assembles the situation summary
- **THEN** violation-derived text in both `sod-remediation:form-email-body` and `situationSummaryHtml` SHALL escape `&`, `<`, `>`, and `"` characters

#### Scenario: Form input reuses operation summary without email-only link

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** `situationSummaryHtml` SHALL equal the shared situation summary HTML without the remediation form link
- **AND** persisted output `sod-remediation:form-email-body` SHALL equal that same HTML plus the remediation form link

#### Scenario: Seed interpolates summary without extra wrapper

- **GIVEN** the bundled SOD remediation seed template
- **WHEN** the ctx-summary DESCRIPTION element is inspected
- **THEN** its `description` SHALL be exactly `{{$.form.input.situationSummaryHtml}}` without an additional surrounding wrapper element

#### Scenario: Situation summary includes emoji legend

- **WHEN** `situationSummaryHtml` is assembled
- **THEN** it SHALL append one emoji legend footer decoding revocability, keep recommendation, and privileged icons
- **AND** group column HTML variants SHALL NOT include the legend footer

### Requirement: ISC keep recommendation annotation

The sod-remediation operation SHALL fetch ISC keep recommendations for each resolved access path item on the violation target identity at launch using the Recommendations API. Items whose recommendation is `YES` SHALL be annotated for display as recommended to keep using a keep star icon suffix. Items whose recommendation is `MAYBE`, `NO`, or `NOT_FOUND` SHALL NOT receive a keep star.

#### Scenario: Batch keep recommendations at launch

- **GIVEN** resolved access paths for Group A and Group B
- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** the handler SHALL request keep recommendations for all unique access items across both sides in a single batch call
- **AND** SHALL map each response back to the corresponding access path line by item id and type

#### Scenario: YES shows keep star

- **GIVEN** the Recommendations API returns `YES` for a role on Group B
- **WHEN** form input and situation summary HTML are rendered
- **THEN** that role line SHALL include a keep star icon suffix without inline explanatory text on the line
- **AND** the situation summary legend SHALL decode the keep star meaning
- **AND** SHALL NOT include a connector revoke recommendation star

#### Scenario: MAYBE does not show keep star

- **GIVEN** the Recommendations API returns `MAYBE` for an entitlement
- **WHEN** HTML is rendered
- **THEN** that line SHALL NOT include a keep star
- **AND** SHALL NOT count toward side correction logic as a keep recommendation

#### Scenario: Recommendations API failure degrades silently

- **GIVEN** the Recommendations API call fails or times out
- **WHEN** `custom:sod-remediation` completes launch
- **THEN** the handler SHALL proceed without keep stars or side correction hint
- **AND** SHALL NOT surface an error message to the form recipient

### Requirement: Side correction recommendation

When keep recommendations exist on exactly one violation group, the sod-remediation operation SHALL recommend correcting the opposite group. When both groups have at least one `YES` keep recommendation or neither group has any `YES`, the operation SHALL emit no side correction recommendation.

#### Scenario: Recommend correct Group A

- **GIVEN** Group A has no items with keep recommendation `YES`
- **AND** Group B has at least one item with keep recommendation `YES`
- **WHEN** form input and situation summary are assembled
- **THEN** the operation SHALL recommend correcting Group A
- **AND** SHALL expose `recommendedSideToCorrect` value `groupA` in launch context suitable for workflow consumption

#### Scenario: Recommend correct Group B

- **GIVEN** Group A has at least one item with keep recommendation `YES`
- **AND** Group B has no items with keep recommendation `YES`
- **WHEN** form input and situation summary are assembled
- **THEN** the operation SHALL recommend correcting Group B

#### Scenario: No side recommendation when symmetric

- **GIVEN** both Group A and Group B have at least one `YES` keep recommendation
- **WHEN** HTML is rendered
- **THEN** the operation SHALL NOT display a side correction recommendation

#### Scenario: Side hint in form and email

- **GIVEN** a side correction recommendation is computed
- **WHEN** form input and operation output are produced
- **THEN** the side hint SHALL appear in group column DESCRIPTION HTML and in `situationSummaryHtml` and `sod-remediation:form-email-body`

### Requirement: Privileged access indicator

The sod-remediation operation SHALL annotate entitlement access path lines with a privileged indicator when entitlement metadata marks the entitlement as privileged.

#### Scenario: Privileged entitlement badge

- **GIVEN** entitlement metadata indicates an entitlement is privileged
- **WHEN** access path HTML is rendered
- **THEN** that entitlement line SHALL include a privileged icon suffix without inline explanatory text on the line
- **AND** the situation summary legend SHALL decode the privileged icon meaning

#### Scenario: Missing privileged metadata

- **GIVEN** entitlement privileged metadata is unavailable
- **WHEN** access paths are rendered
- **THEN** lines SHALL render without a privileged badge
- **AND** launch SHALL still succeed

### Requirement: Access path revocability annotation

The sod-remediation operation SHALL annotate each resolved access path with workflow-actionable revocability derived from path expansion. Entitlements on a side that also includes an access profile or role granting that entitlement SHALL be marked not directly revocable and SHALL include a named grantor reference. Entitlements on entitlement-only sides SHALL be marked revocable. Connector revoke recommendation SHALL NOT be shown in owner-facing HTML.

#### Scenario: Entitlement-only side

- **GIVEN** a violation side with conflicting entitlements and no assigned access profile or role granting them
- **WHEN** access paths are resolved
- **THEN** each entitlement line SHALL be marked revocable
- **AND** SHALL NOT display a connector revoke recommendation star

#### Scenario: Entitlement with named role grantor

- **GIVEN** a conflicting entitlement granted via role "B2B Buyer" on the same side
- **WHEN** access paths are resolved and HTML is rendered
- **THEN** the entitlement line SHALL be marked not directly revocable with reason granted-via-role
- **AND** the reason text SHALL name the grantor as granted via B2B Buyer role
- **AND** the role line SHALL be marked revocable without a connector revoke star in HTML

#### Scenario: Entitlement with role on side

- **GIVEN** a conflicting entitlement granted via an assigned role on the same side
- **WHEN** access paths are resolved
- **THEN** the entitlement line SHALL be marked not directly revocable with reason granted-via-role
- **AND** the role line SHALL be marked revocable without owner-visible connector revoke star

#### Scenario: Revoke payload includes revocability metadata

- **WHEN** form input is assembled for launch
- **THEN** each side revoke payload item SHALL include `revocable`, optional `reason`, optional `grantedVia`, and optional `keepRecommendation`
- **AND** `recommendedRevoke` SHALL reference the highest-priority revocable item for workflow use without owner-visible star

#### Scenario: Revoke payload includes keep metadata

- **WHEN** form input is assembled for launch
- **THEN** each side revoke payload item SHALL include `revocable`, optional `reason`, optional `grantedVia`, and optional `keepRecommendation`
- **AND** `recommendedRevoke` MAY remain for workflow use without owner-visible star

### Requirement: Group column outcome panel variants

The sod-remediation operation SHALL pre-render three HTML variants per policy side at form launch and populate corresponding formInput STRING fields. Outcome panels SHALL appear only after the recipient selects a remediation side.

#### Scenario: Six group HTML formInput fields

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** formInput SHALL include `groupAContentsHtml`, `groupAContentsHtmlAsKept`, `groupAContentsHtmlAsRemoved`, `groupBContentsHtml`, `groupBContentsHtmlAsKept`, and `groupBContentsHtmlAsRemoved`
- **AND** the plain variants SHALL NOT include outcome panel wrappers

#### Scenario: Plain variants shown before selection

- **GIVEN** the bundled seed form definition with formConditions for group column DESCRIPTION elements
- **WHEN** the recipient has not selected `remediationSide`
- **THEN** the seed SHALL show plain `groupAContentsHtml` and `groupBContentsHtml` DESCRIPTION elements
- **AND** SHALL NOT show `AsKept` or `AsRemoved` variants

#### Scenario: Outcome variants shown after Group A selection

- **GIVEN** the recipient selects `remediationSide` value `groupA`
- **WHEN** formConditions evaluate
- **THEN** Group A column SHALL show `groupAContentsHtmlAsRemoved` with red outcome panel styling
- **AND** Group B column SHALL show `groupBContentsHtmlAsKept` with green outcome panel styling
- **AND** plain variants SHALL be hidden

#### Scenario: Outcome variants shown after Group B selection

- **GIVEN** the recipient selects `remediationSide` value `groupB`
- **WHEN** formConditions evaluate
- **THEN** Group B column SHALL show `groupBContentsHtmlAsRemoved` with red outcome panel styling
- **AND** Group A column SHALL show `groupAContentsHtmlAsKept` with green outcome panel styling

#### Scenario: Flat horizontal list topology preserved

- **WHEN** group column HTML is rendered for any variant
- **THEN** access paths on each side SHALL render as a flat unordered list without nested access-profile grouping

### Requirement: Revocability HTML display with emojis

The sod-remediation operation SHALL render access path annotations in HTML using space-separated UTF-8 emoji icon suffixes on each line in group column form input and in operation `sod-remediation:form-email-body` output. Lines SHALL use shared type tags for access kind. When UI origin is available, access path display names in group column HTML SHALL link to the corresponding ISC admin UI routes. Inline revocability and keep recommendation text labels SHALL NOT appear on lines; meanings SHALL be conveyed by the situation summary legend footer only.

#### Scenario: Group column HTML form input

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** each group side SHALL produce plain, asKept, and asRemoved HTML variants in `groupColumnsHtmlPlain`, `groupColumnsHtmlWhenGroupARemoved`, `groupColumnsHtmlWhenGroupBRemoved`, and B-side equivalents
- **AND** plain variants SHALL contain type tags and icon suffixes without outcome panel wrappers
- **AND** asKept and asRemoved variants SHALL wrap the same line content in green and red outcome panels respectively
- **AND** the bundled seed SHALL render those keys in conditional DESCRIPTION elements for group A and group B columns

#### Scenario: Group column HTML form input variants

- **WHEN** `custom:sod-remediation` assembles form input
- **THEN** formInput SHALL include group column HTML STRING fields covering plain and outcome variants for each side
- **AND** seed formConditions SHALL swap visible DESCRIPTION elements when `remediationSide` changes

#### Scenario: Icon suffixes on lines

- **GIVEN** a revocable access path line with keep recommendation `YES`
- **WHEN** HTML is rendered
- **THEN** the line SHALL include space-separated `⭐` and `✅` icon suffixes
- **AND** SHALL NOT include inline text `Revocable` or `Recommended to keep` on the line

#### Scenario: Linked path line names when online

- **GIVEN** UI origin is available and a path line has id and type `ENTITLEMENT`
- **WHEN** group column HTML is rendered
- **THEN** the entitlement display name SHALL be wrapped in an entitlement admin UI link

#### Scenario: Email summary parity

- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `sod-remediation:form-email-body` SHALL include the same access path icon suffixes and side correction hint as the group column HTML line content without entity admin deep links
- **AND** `situationSummaryHtml` SHALL additionally include the emoji legend footer

### Requirement: SOD remediation context panel layout

The bundled sod-remediation form seed SHALL present a single upper context panel DESCRIPTION interpolating `situationSummaryHtml`. The panel SHALL use user-facing section copy structured as “What we found” and “What we need from you”. The seed SHALL NOT include a separate static identity/policy/violation metadata DESCRIPTION that duplicates content from `situationSummaryHtml`.

#### Scenario: Single ctx-summary element

- **GIVEN** the bundled sod-remediation seed template
- **WHEN** the context section is inspected
- **THEN** exactly one DESCRIPTION element SHALL interpolate `{{$.form.input.situationSummaryHtml}}`
- **AND** the seed SHALL NOT define element id `ctx-identity`

#### Scenario: User-facing section label

- **GIVEN** the bundled sod-remediation seed context section
- **WHEN** the section label is inspected
- **THEN** it SHALL NOT contain the phrase `policy violation detection`

#### Scenario: Call to action in summary

- **WHEN** `situationSummaryHtml` is assembled for a violation with compensating controls available
- **THEN** the “What we need from you” block SHALL instruct the recipient to choose Correct or Mitigate and select a remediation side

---


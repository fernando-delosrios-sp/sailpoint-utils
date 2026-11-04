---
name: isc-workflows-developer
description: Develop and review Identity Security Cloud workflows.
disable-model-invocation: true
version: 0.3.0
metadata:
  updated: 2026-09-15
  author: "@ryan-mcnulty"
---

# ISC Workflows Developer

Develop and review ISC workflows using the actual trigger schema, workflow definition, and current
SailPoint documentation. Separate trigger admission from workflow control flow:

- Use a trigger filter to decide whether an event should start the workflow.
- Use Choice steps for legitimate branching after the workflow starts.
- Move an initial Choice into the trigger only when its sole purpose is to discard irrelevant events.

## Start With Evidence

Before proposing a fix:

1. Identify the workflow surface: Workflow Builder, exported definition, import request, execution
   details, or trigger subscription.
2. Identify the trigger ID and retrieve its current input schema.
3. Distinguish observed evidence from assumptions. Prefer the supplied definition and execution input
   over screenshots or remembered field names.
4. Consult current SailPoint documentation when behavior, schemas, limits, action versions, or API
   request shapes matter. Quote numeric limits, API version prefixes, batch sizes, and UI caps from
   those pages, not from this skill or from memory:
   - Event trigger filters:
     `https://developer.sailpoint.com/docs/extensibility/event-triggers/filtering-events/`
   - Workflow triggers:
     `https://documentation.sailpoint.com/saas/help/workflows/workflow-triggers.html`
   - Workflow actions:
     `https://documentation.sailpoint.com/saas/help/workflows/workflow-actions.html`
   - Loop operators:
     `https://documentation.sailpoint.com/saas/help/workflows/workflow-operators.html#loop-operators`
   - Trigger schemas and APIs:
     `https://developer.sailpoint.com/docs/api/triggers`
5. State what must still be verified when the user has not supplied enough evidence. Do not invent
   payload fields, action outputs, limits, or product support.

Redact tenant names, tokens, secrets, identity data, and other sensitive values from examples and
diagnostic artifacts. Never send real tenant data to a third-party JSONPath tester.

## Review Workflow

Review in this order so production risks are not hidden by cosmetic feedback:

1. **Trigger admission** — Does the trigger fire only for relevant events? Can an initial discard-only
   Choice become a trigger filter?
2. **Correctness** — Do paths match the trigger and action schemas? Are branches, error paths, and loop
   semantics correct?
3. **Scale** — Are queries bounded? Are outputs and loop inputs small? Could event volume or retries
   create a runaway workflow?
4. **Security** — Are secrets externalized? Are HTTP destinations, authentication, and exposed data
   appropriate?
5. **Compatibility** — Are action versions supported, and will an upgrade change fields, rendering, or
   output paths?
6. **Maintainability** — Only after the above, comment on names, layout, duplication, and readability.

Label findings by severity:

- **Critical** — exposed secret, unsafe external call, runaway execution, or likely production outage.
- **High** — incorrect filter/path, unbounded processing, broken branch, or unsupported action behavior.
- **Medium** — brittle design, avoidable cost, weak error handling, or migration risk.
- **Low** — naming, formatting, visual organization, or minor simplification.

## Trigger Export Shape

Trigger filters use Jayway JSONPath against the raw event payload. A workflow runtime path such as
`$.trigger.action` commonly maps to `$.action` in the trigger filter, but confirm that mapping against
the trigger's current input schema.

When correcting exported workflow JSON, use the event trigger shape expected by that import/export
surface:

```json
"trigger": {
  "type": "EVENT",
  "attributes": {
    "id": "idn:post-provisioning",
    "filter.$": "$[?(@.action == 'Access Request')]"
  }
}
```

If the user supplies a compact trigger reference:

```json
"trigger": {
  "triggerType": "EVENT",
  "triggerId": "idn:post-provisioning"
}
```

explain that the filter belongs in the trigger configuration. Do not imply that changing the compact
fragment alone creates a complete, importable workflow.

Execution or internal debug views may represent the same filter differently:

```json
"filter": "$.changes[?(@.attribute == \"cloudLifecycleState\" && @.oldValue != null && @.newValue == \"terminated\" && @.oldValue != @.newValue)]"
```

Recognize the intent, but normalize the field only after identifying the target surface. Do not copy an
internal execution representation into an import request without checking the API schema.

## Workflow Import JSON

When producing importable JSON:

- Confirm the current import endpoint and request schema.
- Preserve required metadata, trigger configuration, steps, and references.
- Return the complete payload only when the schema is known; otherwise label the output as a
  definition or snippet.
- Preserve unrelated fields unless the user asks for broader cleanup.
- Never reproduce plaintext credentials from the source workflow.
- After import, retrieve or re-export the saved workflow and verify trigger attributes, `filter.$`,
  action versions, credentials, scopes, and expression escaping.

## Trigger Filter Design

Move a first Choice into the trigger when one branch immediately exits or does nothing and the other
continues. Keep the Choice when both branches perform meaningful work or when the decision depends on
data fetched after the trigger.

Translate common comparators into trigger JSONPath:

- `StringEquals` on `$.trigger.foo` -> `$[?(@.foo == 'value')]`
- `StringStartsWith` -> use regex, for example `$.items[?(@.name =~ /^Prefix.*$/)]`
- `StringContains` -> use `contains`, for example `$[?(@.name contains 'value')]`
- Numeric comparisons -> use JSONPath numeric operators, for example `$[?($.changes.length() > 0)]`
- Non-empty array -> use the documented `length()` function, for example
  `$.items[?(@.values.length() > 0)]`.
- Array element match -> use `[*]` or a filtered array instead of hard-coded `[0]` unless the event
  contract requires the first element.

Quote strings consistently. If the value contains a single quote, use double quotes in the JSONPath and
escape as needed in JSON.

Trigger filters determine whether the workflow starts; they do not trim or reshape the payload. If a
trigger does not support filters, identify that limitation and recommend a different trigger,
subscription, or design. A first-step Choice can reduce downstream work but is not equivalent because
the workflow has already started.

Validate every proposed filter with SailPoint's JSONPath evaluator, the SailPoint CLI evaluator, or
the currently documented trigger-subscription filter-validation endpoint. Use representative sanitized
payloads and test:

- a matching event;
- a near-miss that must not match;
- missing or null optional fields when relevant;
- multiple array elements, including a match outside index `0`.

After saving or importing, verify that the persisted trigger contains the intended filter. UI test
executions may not exercise trigger admission in the same way as live events, so state which path was
tested.

## JSONPath and Template Evaluation

- Trigger filters use Jayway JSONPath. Workflow action fields may use a different JSONPath/template evaluator, so validate expressions in the context where they run.
- In `.$` fields, use raw JSONPath such as `$.trigger.identity.id`.
- In string/template fields, use interpolation such as `{{$.trigger.identity.id}}`; otherwise the path may be treated as literal text.
- Prefer `Choose variable`/expression-aware fields when the UI offers them.
- For property names with special characters, use bracket notation, for example `$.hTTPRequest.body['@odata.count']`.
- Avoid wildcard paths like `$.*.body` across branches when precise branch outputs are known. Use unique variable names and explicit paths.

- In `Define Variable`, select the source through `Choose Variable` so the export contains
  `variableA.$`; typing a JSONPath into a text field stores a literal string. Inside a loop, reference
  the current item as `$.loop.loopInput`. A filtered projection returns an array, so index after the
  projection for a scalar, for example `.id[0]`, and guard zero and multiple matches.
- To insert an object or array into an HTTP JSON body, append `.JSON()` and leave the interpolation
  unquoted, for example `"members": {{$.getMembers.body.JSON()}}`. Quoting converts it to a string, so
  use quoted interpolation only for scalar strings. `.JSON()` serializes data and does not reshape it;
  it cannot map `["a", "b"]` into objects.
- For an exact array-value branch, filter and compare `length()`, for example
  `$.items[?(@ == 'Failed')].length() > 0`, or filter a status property such as `@.status` for object
  arrays. Guard missing or null arrays separately.
- An optional form value may be absent, JSON `null`, an empty string, or the literal text `"null"`.
  Inspect the execution input to tell them apart. Verify a path exists before a transform, because an
  unresolved JSONPath may be transformed as literal text. Use `Is null` for JSON null and string
  comparisons only for strings.
- A concatenate error such as `variable B must be a string` proves the resolved value was not a scalar
  string. Inspect the rendered step input and compare a known-good execution before claiming a runtime
  regression. Treat an interpreter change as a hypothesis until evidence supports it.

## Output Data and Payload Size

Do not assume that complete action responses remain available to later steps or execution logs. Check
the action's current output schema and the saved execution data.

- Reference every downstream field explicitly, or select it in `Additional Output Data`.
- Build against the actual action response schema, not screenshots or old execution output.
- Keep action outputs small. Large payloads can fail or stall executions; cite a specific error code
  only when it appears in the user's evidence or current documentation.
- Avoid workflows that scan the tenant, fetch thousands of objects, then filter inside the workflow.
  Narrow the trigger/query before the workflow starts or move bulk processing outside workflows.
- `Get Accounts` retains account IDs and the fields required by downstream steps, plus extra account
  attributes explicitly selected in `Additional Output Data`. When attributes are missing, inspect the
  saved action's `resultSelector` and every downstream field reference. Adding a `Wait` or other delay
  does not change output retention, so do not recommend it as a fix. When two executions differ,
  compare their persisted workflow versions and scheduled action inputs before treating the difference
  as timing-related or as a runtime defect.
- POST responses that feed loop input can be trimmed independently of GET trimming. Missing
  downstream fields may be trimming rather than an HTTP failure, and `Test Workflow` can still show
  the full output. Confirm the currently documented HTTP Request output-handling behavior and any
  tenant flags before recommending a rollback.

## Action Versions and Secrets

Inspect action versions and authentication whenever the definition is available.

- Prefer the latest supported action version unless there is a documented incompatibility.
- Recommend upgrading older HTTP actions only after confirming the currently supported version and its
  migration requirements.
- Treat hardcoded client secrets, bearer tokens, API keys, passwords, or private credentials in
  workflow JSON as a security issue, and recommend rotating any credential that was already exposed.
- Use Parameter Storage or the currently documented secret-storage mechanism when supported.
- After upgrading an action version, re-check field names, authentication configuration, request body
  rendering, URL params, scopes, and output paths because version upgrades can change shape or
  evaluation behavior.
- If an old action version must remain, document why, minimize exposed secret material, and recommend a
  migration path.

## Common Trigger Filter Patterns

`idn:post-provisioning`, action equals Access Request:

```json
"filter.$": "$[?(@.action == 'Access Request')]"
```

`idn:post-provisioning`, attribute request value starts with a prefix:

```json
"filter.$": "$.accountRequests[*].attributeRequests[?(@.attributeValue =~ /^Gerente Atendimento Operacional - Agência.*$/)]"
```

`idn:native-change-account-updated`, any entitlement added:

```json
"filter.$": "$.accountChangeTypes[?(@ == 'ENTITLEMENTS_ADDED')]"
```

`idn:native-change-account-updated`, actual entitlement `added` array is non-empty:

```json
"filter.$": "$.entitlementChanges[?(@.added.length() > 0)]"
```

Treat these as starting points, not universal templates. Confirm the trigger schema and evaluator support
before recommending them.

### Lifecycle State Triggers

Use separate triggers for joiners and rehires. Current public documentation states that
`Identity Attributes Changed` does not detect a `cloudLifecycleState` transition from null to active,
so a single attribute-change trigger silently misses joiners.

- Joiners: `Identity Created`, filtered to an active lifecycle state.
- Rehires: `Identity Lifecycle State Changed`, filtered on `newLifecycleState` active plus the
  applicable old states.

A tenant test observed `Identity Lifecycle State Change Processed` emitting `previousState.name` null
to `newState.name` active for a net-new identity. Treat that as observed tenant behavior, not a
documented contract; validate it live before adopting a one-trigger design.

## Loop Context Rules

Prefer looping over a small, bounded defined variable rather than directly over Search, List Identities,
or another potentially large action output.

Use this pattern:

1. Fetch or compute only the records needed.
2. Transform them into a small, bounded defined variable.
3. Loop over that defined variable.

Avoid these patterns:

- Looping directly over Search results.
- Looping directly over List Identities output.
- Looping over any action output that may contain hundreds or thousands of objects.
- Passing large action outputs through loop context just to filter inside the loop.

If the workflow needs many objects, narrow the query, fetch specific objects by ID, paginate only when
the workflow model supports it safely, or move bulk processing outside ISC workflows.

Variable scope rules:

- Loops execute with their own context. Pass only the variables the loop needs.
- Do not rely on deterministic parent-variable updates from a parallel loop.
- Use serial loops when the workflow needs ordered updates, accumulator-style variables, or
  break-on-first-match behavior.
- If the desired logic is "send one email after any match", set a defined variable in a serial loop and
  branch once after the loop, rather than sending from every non-matching iteration.

Loop limits, status, and failures:

- A For Loop is finite. Look up the current Serial Loop input limit and `Test Workflow` iteration cap
  in the loop-operators documentation; do not quote remembered numbers. Those two limits differ, so a
  test run that stops early is not proof of a hang or of the live input cap.
- `Break Loop` takes effect only when execution reaches it. It does not cancel an inner action that is
  already waiting, such as a `Wait` or `Form` step.
- A loop can record child errors in `loopOutput.failureItems` while the parent step still reports
  Success, because the next path does not branch on failures. Parent completion does not prove that
  every item succeeded. Inspect both `successfulItems` and `failureItems`, and add an explicit check
  after the loop when any child failure must fail the workflow.
- A Serial Loop executes as a generated child workflow. Parent history may stop at the Serial Loop
  `ActivityTaskStarted` event and never name the active inner step. Capture the generated child
  `workflowId` and `runId` from that event together with the parent `requestId`, then search the child
  execution for the active inner action. Check expected long-running steps such as `Wait` or `Form`
  before diagnosing a stalled iterator.

## HTTP and External Calls

- Design HTTP actions to be idempotent; retries and circuit breakers can cause repeated attempts or
  delayed failures.
- Do not create unbounded retry loops by pointing catch/error paths back to the same HTTP action without
  a stop condition.
- Capture status code and response body fields needed for later decisions in `Additional Output Data`.
- Workflows run from SailPoint cloud, not through the Virtual Appliance. For private/internal APIs, use
  a supported public endpoint, connector/PAG action, or integration pattern that matches network
  requirements.
- Confirm current support before recommending mTLS, client certificates, private connectivity, or a
  specific authentication mode.

When a documented ISC route returns 404, confirm the current OpenAPI path and expected authentication
error statuses first. A published route that stays unavailable across tenants is a routing, enablement,
or documentation-drift hypothesis: collect org, region, environment, exact host, sanitized response,
timestamp or tracking ID, and workflow/execution IDs, then escalate. Do not substitute an internal
browser route such as `/gov-multi-auth/.../public/...`; those are stateful, session-dependent
password-reset APIs, not supported workflow integrations.

### Windows Server and PAG

The `Windows Server` action does not use IQService and does not upload a temporary `.ps1`. Consult
the current Windows Server action documentation, then identify whether the failure is cloud-to-PAG
delivery or target remoting. The script must already exist at an absolute local path; mapped drives
and UNC paths are unsupported.

## Approvals Configuration

Approval behavior resolves from a configuration hierarchy, not from the workflow action. `GET` reads
configuration and `PUT` changes it: read the full configuration, preserve unrelated fields, change only
the target block, write it back, and verify with a follow-up `GET`.

Separate approval timeout from requested-access duration:

- `requireEndDate` and `maxPermittedAccessDuration` belong to access-item request configuration. They
  control the requested access, not how long an approval may stay unresolved.
- Unresolved approval expiration belongs to the Generic Approvals `timeoutConfig`. For one
  entitlement, use the currently documented Generic Approvals config resource for
  `{entitlementId}` / `ENTITLEMENT`. For all access requests, use `ACCESS_REQUEST_APPROVAL` /
  `APPROVAL_TYPE`.
- Access-item configuration overrides broader configuration. Timeout changes affect only newly
  submitted requests, so approvals that are already pending do not change. Confirm any UI or API
  timeout maximum from current documentation before quoting it.
- The `Approval Policy` action leaves `autoApprove` unset so sp-approvals resolves the hierarchy.
  Configure all Adaptive Approval policies at `CUSTOM_ACCESS_REQUEST_APPROVAL:APPROVAL_TYPE`; do not
  use `ACCESS_REQUEST_APPROVAL:APPROVAL_TYPE` for this action. No per-workflow UI or supported hidden
  JSON override exists.
- Older executions may show a prior WPS boolean mapping (`true` to `DIRECT`, `false` to `OFF`). Do
  not read historical execution input as current behavior.
- `activity error` is an action-execution wrapper, not a Generic Approval Policy denial. Diagnose the
  nested error. Successful generic approvals appear under Approvals → Other.

## Forms and Interactive Processes

- The `Form` action generates its task link and appends it after the configured Notification Body and
  Reminder Body. That URL is not exposed as a JSONPath or Velocity variable, and Form notifications
  do not use a standard EmailTemplate. Placement cannot currently be customized; treat it as a product
  enhancement request. Do not invent a URL path or a Send Email step that references the generated
  form-task URL.
- An array input expects objects or maps. Array Value and Array Label are evaluated relative to each
  item, for example `$.value` and `$.label`. Preserve or re-fetch an upstream object list, or reshape
  the data through a bounded HTTP/API source before the Form action. `Define Variable` has no
  documented object/array map constructor.
- Form text-field REGEX validation rejects lookahead, lookbehind, and backreference constructs even
  when an external PCRE or JavaScript tester accepts them, so password-style complexity cannot be
  enforced in one form regex. Apply complex validation after submission or use the password policy.
- Form conditions and fields sharing one technical key can normalize alternative inputs first.
- When a user must revise generated input without reopening the launcher, a bounded Serial While Loop
  is appropriate. Keep the body small: collect canonical form values, derive one candidate, check
  existence against the authoritative target, and show confirmation only when available.
- On conflict or Edit, end the current iteration while the loop condition stays true, and break only
  after successful creation or explicit cancellation. Bound attempts or elapsed time, and handle a
  duplicate from the create operation as a retryable conflict; lookup and creation are not atomic.

## Workflow Chaining and Interactive Status

Identify the user-facing surface before promising consolidated status:

- A `Form Submitted` trigger starts only after submission is already complete, and an
  `Interactive Process` stays open only while its owning parent workflow runs.
- `External Trigger` child executions are asynchronous and have independent execution IDs. Their
  status does not automatically roll into the parent and does not extend the parent.

To keep a native Interactive Process In Progress, the parent must stay open and perform bounded status
checks for every child execution, with explicit timeout and failure paths. For long-running
orchestration, use a correlation ID and an external status store; that record cannot keep the native
process open after the parent ends. Do not use unbounded polling, which can create a runaway workflow.

## Certification Campaign Routing

ISC has no IIQ-style Certifier Rule for deriving campaign reviewers from arbitrary identity
attributes. Distinguish campaign generation from activation: generate the campaign without activating
it, trigger on `Campaign Generated` while it is STAGED, resolve and group assignments by identity
campaign certification ID plus destination reviewer, verify every reassignment task, and activate only
after all routing succeeds. Activating first makes initial reviewers receive notifications and exposes
an incorrectly routed active campaign when a bulk step partially fails.

Look up current synchronous and async reassignment request sizes in the Identity Certification
reassignment API docs. For large heterogeneous assignments, prefer bounded external or PAG
orchestration: Serial Loop input is limited (see the loop-operators docs) and reassignment is not
atomic.

## Product Surface Limits

- Confirm Identity History `from` semantics in the current historical-identity-events API docs. Treat
  a documented upper-bound as expected behavior, not a broken filter. For a lower cutoff, omit `from`,
  filter each item's timestamp, and paginate using the documented page contract.
- The built-in `Manage Access` action does not expose Create Access Request's
  `requestedItems[].accountSelection`, and Access Profile Multiple Account Options do not apply to
  access requests. For account-targeted grants, use the supported Create Access Request API with
  explicit `accountSelection`, or redesign as automatic assignment. Do not debug unsupported input as
  missing tenant configuration.
- Workflow History indexes trigger and step input as serialized `attributes.input`. Search can match
  that text, but it does not flatten arbitrary nested keys into report columns, and saved-search
  subscriptions are not a JSON reporting engine. For structured recurring audit exports, retrieve
  execution history, parse it externally, and persist it before the documented retention window
  expires.

## Runaway Workflow Guardrails

Treat high-volume triggers as production-risky:

- Add trigger filters before enabling workflows on broad triggers like identity/account changes.
- Avoid scheduled workflows that list all identities/groups/accounts and then loop through the full
  result.
- Retrieve current tenant and product limits before quoting exact loop, action, execution, or payload
  limits. Do not treat `limit: 0` as safely unbounded.
- If investigating a runaway or stuck workflow, collect tenant/org, region, environment, workflow ID,
  workflow execution IDs, trigger ID, filter, and whether it was a test execution.
- Termination/disablement endpoints are mitigation tools for runaway workflows, not normal
  customer-facing cancellation features.

## Troubleshooting Checklist

When diagnosing a workflow issue:

- Confirm the trigger emitted an event and the trigger filter matched before debugging later steps.
- Compare live execution input with Test Workflow input; trigger filters may not be honored by UI test flows.
- Collect execution JSON/CSV while available; workflow execution history is time-limited.
- Check whether output trimming explains missing fields before assuming the upstream API returned less data.
- For imported workflows, verify trigger attributes, filters, credentials, scopes, and expression escaping after save.
- Prefer persisted evidence over screenshots. An Interactive Trigger can appear in Builder but be
  absent from the saved workflow, and Manager then shows Trigger as `--`. Confirm with an export or
  the currently documented workflow GET endpoint after save. Diagnose that persistence defect only
  when the workflow uses an Interactive Trigger and the persisted definition lacks it. A generic
  `Test Workflow` `Not Found` error alone is insufficient evidence.
- For environment-specific HTTP differences, diff the exported saved definitions and compare each
  execution's scheduled action input: persisted URL, method, body, headers, authentication reference,
  and action version. Pasted intended values are secondary evidence.
- When an API filter looks broken, reproduce it directly against the supported API first, then verify
  the workflow action passed the selected value in its scheduled input. For identity history, test
  `eventTypes=<selectedType>` and inspect every returned `eventType`.

## Response Formats

For a filter correction, provide:

1. The corrected `filter.$`.
2. A trigger snippet if the target JSON surface is known.
3. The exact structural change, such as removing a discard-only initial Choice and changing the start
   step.
4. A brief explanation of path translation.
5. Matching and non-matching validation cases.

For a workflow review, provide:

1. A one-paragraph assessment.
2. Findings ordered by severity, each with evidence, impact, and a concrete recommendation.
3. A concise corrected snippet or patch only where it clarifies the recommendation.
4. Open questions and verification steps.

For troubleshooting, provide:

1. The most likely failing stage: trigger, filter, action, branch, loop, output retention, or external
   call.
2. Evidence supporting and contradicting the hypothesis.
3. The smallest next diagnostic step.
4. A fix only when the evidence is sufficient; otherwise clearly label it as a hypothesis.

Keep responses concise, preserve unrelated workflow structure, and distinguish documented behavior
from recommendations. Cite current public docs for numeric limits, batch sizes, API versions, and UI
caps.

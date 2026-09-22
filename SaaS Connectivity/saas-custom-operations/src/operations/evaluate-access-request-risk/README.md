# custom:evaluate-access-request-risk

## Purpose

Scores an access request and persists the highest risk tier. It does not choose approvers, approve, or deny. Three bundled workflows apply that tier to different Identity Security Cloud contracts.

Dimensions are not read. Role risk uses the role, its access profiles, and entitlements returned by the role and access-profile APIs.

## Command

`custom:evaluate-access-request-risk`

## Risk rules

The highest tier wins.

| Object                                          | High                                                                    | Medium                                                        | Low                                       |
| ----------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------- |
| Role or access profile                          | Risk metadata `iscRisk` is `critical` or `high`                         | Risk metadata is `medium`                                     | Anything else, including no Risk metadata |
| Entitlement (`considerPrivilege` true, default) | Effective privilege is `HIGH`, or Risk metadata is `critical` or `high` | Effective privilege is `MEDIUM`, or Risk metadata is `medium` | Anything else                             |
| Entitlement (`considerPrivilege` false)         | Risk metadata is `critical` or `high`                                   | Risk metadata is `medium`                                     | Anything else                             |

A role or access profile is then scored again through its entitlements. Wrapped access profiles are scored with the same role/access-profile rule before their entitlements.

## Input

| Field               | Required | Description                                                                                                                                                                                                                   |
| ------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `requestedItems`    | No\*     | `{ id, type, name? }` from the trigger. `type` is `ROLE`, `ACCESS_PROFILE`, or `ENTITLEMENT`. An array, a single object, or a JSON string of either — ISC collapses a one-element `$.trigger.requestedItems` to a bare object |
| `accessRequestId`   | No\*     | Used only when `requestedItems` is omitted. Status rows must include the access-item id                                                                                                                                       |
| `considerPrivilege` | No       | Default `true`. When `false`, entitlement scoring ignores `privilegeLevel.effective` and uses Risk metadata only                                                                                                              |

\* One of the two is required. When both are set, `requestedItems` is used.

`requestId` is the **risk persist identity**. The handler writes that value verbatim. Bundled workflows
set it to `evaluate-access-request-risk:{accessRequestId}` plus a **wrapper discriminator**:
`:submitted`, `:dynamic`, or `:dynamic-approval`.

## Output (persisted)

The result account uses the **risk persist identity**, which is the invoke `requestId`. Bundled
workflows send `evaluate-access-request-risk:{accessRequestId}:dynamic` (and the other discriminators)
so the three wrappers do not collide. The handler does not add a prefix of its own.

| Field                                            | Description                                                                                             |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `evaluate-access-request-risk:tier`              | `High`, `Medium`, or `Low`                                                                              |
| `evaluate-access-request-risk:situation-summary` | Human-readable verdict and evaluated-object counts, with no object names or ids                         |
| `evaluate-access-request-risk:contributing-ids`  | Machine-readable comma-separated ids of the winning risk drivers, truncated to the account string limit |

The **risk situation summary** is plain text for an approver; workflows do not parse it. A **risk driver**
is any evaluated role, access profile, or entitlement paired with the tier its own attributes earn. A
**winning risk driver** is one whose tier matches the request's final tier. The **deciding rule** says why
that driver reached the tier: **effective privilege** from `privilegeLevel.effective`, or **Risk metadata**
from `iscRisk`. Only entitlements can be decided by effective privilege; roles and access profiles are
always decided by Risk metadata. A driver matching both rules is attributed to effective privilege only.

Examples:

-   `High: 2 of 6 entitlements scored High (1 by effective privilege, 1 by Risk metadata). Evaluated 1 role, 2 access profiles, 6 entitlements.`
-   `Low: nothing scored Medium or High. Evaluated 1 role, 2 access profiles, 6 entitlements.`

Names and ids do not appear in the risk situation summary. Use
`evaluate-access-request-risk:contributing-ids` when a machine-readable identifier list is needed. A
container is counted as evaluated but is not a risk driver for a nested object's tier: if a clean role
contains a High entitlement, the entitlement is the High risk driver and the role appears only in the
evaluated tally.

Lookup failures throw. The result account is `failed`, not a silent `Low`, and failure accounts use the
same risk persist identity as successful results.

## Invoke examples

| Payload                                                                                             | Use                  |
| --------------------------------------------------------------------------------------------------- | -------------------- |
| [`payloads/evaluate-access-request-risk.json`](../../../payloads/evaluate-access-request-risk.json) | Offline local invoke |

```bash
npm run call:op -- payloads/evaluate-access-request-risk.json
```

Offline ids: `offline-ent-high`, `offline-ent-medium`, `offline-ent-low`, `offline-role-wrapped`, `offline-ap-low`. Any other id fails.

## PAT scope requirements

The workflow access token must allow:

-   Get role, list role entitlements
-   Get access profile, list access profile entitlements
-   Get entitlement
-   List access request status, only when `requestedItems` is omitted
-   Result source account persist

## Bundled workflows

Import the workflow, set **Configuration**, then subscribe or attach it as described. All three are imported disabled.

| Workflow                                                                                                                                                                          | Contract                                                                                                                                                                                                          |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`workflows/Access Request Pre-Check - Risk analysis and in-flight SOD.json`](../../../workflows/Access%20Request%20Pre-Check%20-%20Risk%20analysis%20and%20in-flight%20SOD.json) | [Access Request Submitted](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-submitted) event trigger. Approves or denies on risk tier and in-flight SoD                  |
| [`workflows/Dynamic Approver - Risk analysis.json`](../../../workflows/Dynamic%20Approver%20-%20Risk%20analysis.json)                                                             | [Access Request Dynamic Approval](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval). Adds the approver you pick per tier, or none where you pick nobody |
| [`workflows/Dynamic Approval Workflow - Risk analysis.json`](../../../workflows/Dynamic%20Approval%20Workflow%20-%20Risk%20analysis.json)                                         | Native Access Request Submitted trigger plus one Approval Policy per risk tier. Set this workflow as the access item Approval Type                                                                                |

Shared Configuration on every workflow:

| Variable                            | JSON path                                         | Purpose                                                                                                               |
| ----------------------------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| API URL                             | `$.configuration.aPIURL`                          | Tenant API base URL, no trailing slash                                                                                |
| SaaS Custom Operations Source Name  | `$.configuration.saaSCustomOperationsSourceName`  | Result source name                                                                                                    |
| SaaS Custom Operations Connector ID | `$.configuration.saaSCustomOperationsConnectorID` | Platform connector id                                                                                                 |
| Consider Privilege                  | `$.configuration.considerPrivilege`               | `true` (default) includes entitlement `privilegeLevel.effective`. `false` scores entitlements from Risk metadata only |

The Access Request Pre-Check workflow also has **Inflight Only** (`$.configuration.inflightOnly`, default `true`): when `true`, `custom:preventive-sod-check` reports only inflight SoD violations. Set it to `false` to include existing active violations as well.

On **Get Access Token**, set HTTP basic authentication to the workflow OAuth client (`client_credentials`). Do not paste the client secret into the exported JSON.

Each workflow's **Read Risk Result** filter must match the `requestId` sent on **Call Evaluate Risk**:

-   Access Request Pre-Check - Risk analysis and in-flight SOD: `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:submitted`
-   Dynamic Approver - Risk analysis: `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic`
-   Dynamic Approval Workflow - Risk analysis: `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval`

Deploy the connector and re-import all three bundled Risk Approval workflows in one maintenance window.
After re-import, re-apply Configuration values and the **Get Access Token** basic-auth reference.

### Access Request Pre-Check - Risk analysis and in-flight SOD

Subscribe the Access Request Submitted event trigger to this workflow's external trigger URL. Response type **Async**. Set a response deadline long enough for the role and entitlement reads, plus the SoD predict call.

This workflow runs two checks and answers once. It scores risk with `custom:evaluate-access-request-risk`, then checks in-flight separation of duties with [`custom:preventive-sod-check`](../preventive-sod-check/README.md) in request mode. **Inflight Only** defaults to `true`, so only violations _this request_ would introduce count. Set it to `false` to also flag existing active violations.

**Decision Variables** holds the answer while the workflow builds it: `Approved` starts `true`, `Message` starts as a placeholder. Four Mutation steps are the entire policy, and each one can change both:

| Step                     | Ships as | Comment it writes                                                           |
| ------------------------ | -------- | --------------------------------------------------------------------------- |
| Set Low risk decision    | approve  | Tier plus the risk situation summary                                        |
| Set Medium risk decision | approve  | Tier plus the risk situation summary                                        |
| Set High risk decision   | approve  | Tier plus the risk situation summary                                        |
| Set violation decision   | deny     | Replaces the risk comment with the risk tier plus the SoD situation summary |

The SoD step runs after the risk step, so it has the last word. **Set evaluation failed decision** catches every failed token, an invoke that returns `"status":"failed"` in an HTTP 200 body (**Invoke failed?** for risk, **SoD invoke failed?** for SoD), a failed result read, an unknown risk tier, and a missing SoD result — it denies, and setting `Approved` to `true` there is the one switch that makes the pre-check fail open. A check that produced no answer never counts as a passing one: **SoD result present?** tests the situation summary rather than the violation flag, because that flag is legitimately `false` on a clean request. **Callback approved** and **Callback denied** send `Approved` and `Message`; neither has a policy of its own.

The comment is written to read as a sentence. `evaluate-access-request-risk:situation-summary` already opens with the tier, so the tier steps do not restate it, and the SoD step replaces the risk comment rather than appending to it — otherwise a denial trails a sentence that said the request passed.

The only other Configuration variables are **Approver Name**, default `Workflow`, sent as the callback `approver`, and **Inflight Only**, default `true`. Use an existing identity username for Approver Name if Access Request Decision is also subscribed.

**A boolean does not survive a workflow variable.** Define Variable stores `Approved` and `Sod Has Violation` as real booleans, but the moment an Update Variable step writes one, workflow state holds the string `"true"` or `"false"` — quoting the literal in the export makes no difference. So the two steps that read a decision variable back, **Approved?** and **In-flight SoD violation?**, compare it with `StringEquals` against `"true"`. `BooleanEquals` there matches nothing and silently takes the default branch: it denies every approval and lets every violation through. Any boolean you add to this workflow is read back as a string.

Findings move by the same rule. Strings (`Risk Tier`, `Risk Summary`, `Sod Summary`) are copied straight out of the reads. The violation flag is not: **SoD flag set?** compares `preventive-sod-check:has-violation` on the account, where Get Accounts hands it back as a genuine boolean, and **Set SoD violation true** / **false** then write the variable. That keeps the `BooleanEquals` on the account read, which is the one place it is correct.

The trap repeats one layer out, in the request body, where the trigger _does_ validate the type. `"approved.$": "$.defineVariable.approved"` renders as the string `"true"` and the trigger rejects it. That is why the send is split: **Approved?** picks between **Callback approved** and **Callback denied**, each carrying a hardcoded `true` or `false`. Branch and hardcode any boolean an HTTP step has to send.

This subscription is tenant-wide. A deny stops later dynamic approval, because [dynamic approval runs only after this callback approves](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval).

### Dynamic Approver - Risk analysis

Subscribe Access Request Dynamic Approval the same way (Async, external URL, deadline).

This workflow adds **at most one extra approver, or none**, depending on the risk tier. It never adds two, and a tier you leave at `NONE` adds nobody.

An extra approver is a **bare id** set on the tier step: `$.defineVariable.manager`, `$.defineVariable.managersManager`, `$.configuration.defaultApprover`, or a literal. No type prefix anywhere. The workflow works out whether that id is an identity or a governance group on its own, so no step and no Configuration value has to agree with another about the kind.

Three ISC validator rules shape this workflow, and breaking any of them blocks saving it:

-   **No empty values.** `NONE` means no extra approver. Every variable starts at `NONE` rather than `""`, and a tier adds nobody by setting `variableA` to `NONE` with no transform.
-   **No JSONPath in `description` fields.** ISC parses those strings and reports them as invalid update targets.
-   **Update targets must use the generated step key.** A variable path comes from the step's JSON key, not its display name, and only ISC's own key is accepted as an update target — hence the step keyed `Define Variable` (shown as **Approver Variables**) and the `$.defineVariable.*` paths. `Configuration` keeps its key because it is only ever read.

The workflow runs in four phases:

1. **Resolve the manager levels as ids.** Both start at `NONE`. Reading the recipient and the manager fills them with the identity id. **No manager, use default approver** sets Manager to **Default Approver** and continues to **No manager's manager, use default approver**, which does the same for the second level.
2. **Score risk**, as in the other workflows.
3. **Set the approver** for the winning tier. There is one step per tier — **Set High approver**, **Set Medium approver**, **Set Low approver** — each copying an id as above. These three steps are the whole routing policy.
4. **Answer.** `NONE` sends the none callback. Any other `Approver` goes through **Approver is a governance group?**, which sets the callback `type` and picks the matching read — **Get Approver Identity** or **Get Approver Group** — to fill in the display name before **Callback** sends id, type, and name.

The invoke call stays on `/beta/platform-connectors`. The `/v2026` and `/v2025` equivalents reject requests that omit the `X-SailPoint-Experimental: true` header, so beta is the stable path for it today.

The only extra Configuration variable is **Default Approver**, an identity or governance group **id** on its own. Missing manager levels copy that id, and so does the error path, so a governance group works in every one of those places without any other edit.

Each tier step is yours to set: point `variableA` at whichever id should approve. As shipped, High is the manager's manager, Medium is the manager, and Low is `NONE`. Anything that stops the workflow from reaching a tier — a failed token, an invoke that returns `"status":"failed"` in an HTTP 200 body, a failed result read, and a missing or unknown tier — takes **Set Error approver**, which copies **Default Approver**. A request that was never scored is not treated as a High-risk one. **Invoke failed?** runs before **Read Risk Result**, so a leftover success account from an earlier run cannot look like a scored request.

**The callback `name` cannot be empty.** Sending an id and type with `name: ""` leaves the approval with no owner: the request dies at the approval phase with `Approval workflow error: … workflowType='generic-approvals:approval-workflow'`, `approvalDetails` shows `originalOwner.id` as `null`, and no work item is ever created. Nothing rejects the callback, so the only symptom is the failed request. The trigger still routes on `id`, but the name has to be there.

That is why **Approver is a governance group?** exists. Governance group ids are hyphenated UUIDs and identity ids are unhyphenated 32-character hex, so the hyphen decides the kind, which fixes both the callback `type` and which endpoint supplies the name — `/v2026/identities/{id}` or `/v2026/workgroups/{id}`. Note that this id format is an observed ISC convention rather than a documented guarantee; if it ever stopped holding, a misread id would send the wrong `type`, and ISC answers a wrong id by assigning a random org admin instead of failing. Either read falling over goes to **Name lookup failed, use the id**, which puts the id in `name` — still correct routing, just an uglier approver list — because any non-empty name beats the empty one that breaks the approval.

### Dynamic Approval Workflow - Risk analysis

Requires Adaptive Approvals. The declared trigger is `idn:access-request-trigger`, the Adaptive Approvals **Access Request Submitted** trigger. It is not the subscribable event trigger of the same display name (`idn:access-request-pre-approval`), and it does not appear in `/beta/triggers`. ISC rejects the workflow unless a trigger and an `sp:access-request-approval` action appear together, in either direction. After import, enable the workflow and set the role, access profile, or entitlement **Approval Type** to **Workflow**, then pick this workflow. It runs only for items attached to it.

The workflow scores the request, then opens one Approval Policy (`sp:access-request-approval`) for that tier: High, Medium, or Low. Each policy is **Manager of** the requested-for identity (`singleApproverCategory` `MANAGER_OF`), with a 7-day timeout that expires, reminders off, and timezone `Europe/Madrid`. It does not resolve a default approver. After import, change a policy's reviewer category if you need a fixed identity or governance group instead.

A fourth policy, **Approval Policy Evaluation Failed**, covers a failed token, an invoke that returns `"status":"failed"` in an HTTP 200 body (**Invoke failed?**), a failed result read, and a missing or unknown tier. It ships with the same settings as the High policy and its own `YOUR_EVALUATION_FAILED_REVIEWER_ID` placeholder, so an unscored request routes to a reviewer you choose for that case rather than silently looking like a High-risk one. Bind its reviewer along with the other three.

Do not also subscribe the dynamic-approver workflow for the same items unless you want both this policy and a later extra approver.

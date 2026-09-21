# custom:evaluate-access-request-risk

## Purpose

Scores an access request and persists the highest risk tier. It does not choose approvers, approve, or deny. Three bundled workflows apply that tier to different Identity Security Cloud contracts.

Dimensions are not read. Role risk uses the role, its access profiles, and entitlements returned by the role and access-profile APIs.

## Command

`custom:evaluate-access-request-risk`

## Risk rules

The highest tier wins.

| Object | High | Medium | Low |
|---|---|---|---|
| Role or access profile | Risk metadata `iscRisk` is `critical` or `high` | Risk metadata is `medium` | Anything else, including no Risk metadata |
| Entitlement (`considerPrivilege` true, default) | Effective privilege is `HIGH`, or Risk metadata is `critical` or `high` | Effective privilege is `MEDIUM`, or Risk metadata is `medium` | Anything else |
| Entitlement (`considerPrivilege` false) | Risk metadata is `critical` or `high` | Risk metadata is `medium` | Anything else |

A role or access profile is then scored again through its entitlements. Wrapped access profiles are scored with the same role/access-profile rule before their entitlements.

## Input

| Field | Required | Description |
|---|---|---|
| `requestedItems` | No* | `{ id, type, name? }` from the trigger. `type` is `ROLE`, `ACCESS_PROFILE`, or `ENTITLEMENT`. An array, a single object, or a JSON string of either — ISC collapses a one-element `$.trigger.requestedItems` to a bare object |
| `accessRequestId` | No* | Used only when `requestedItems` is omitted. Status rows must include the access-item id |
| `considerPrivilege` | No | Default `true`. When `false`, entitlement scoring ignores `privilegeLevel.effective` and uses Risk metadata only |

\* One of the two is required. When both are set, `requestedItems` is used.

`requestId` is the result-account identity. The bundled workflows set it to the access request id plus a suffix so the three wrappers do not overwrite each other.

## Output (persisted)

| Field | Description |
|---|---|
| `evaluate-access-request-risk:tier` | `High`, `Medium`, or `Low` |
| `evaluate-access-request-risk:situation-summary` | Winning tier and the objects that produced it. `Low` when nothing ranked higher |
| `evaluate-access-request-risk:contributing-ids` | Comma-separated ids of those objects, truncated to the account string limit |

Lookup failures throw. The result account is `failed`, not a silent `Low`.

## Invoke examples

| Payload | Use |
|---|---|
| [`payloads/evaluate-access-request-risk.json`](../../../payloads/evaluate-access-request-risk.json) | Offline local invoke |

```bash
npm run call:op -- payloads/evaluate-access-request-risk.json
```

Offline ids: `offline-ent-high`, `offline-ent-medium`, `offline-ent-low`, `offline-role-wrapped`, `offline-ap-low`. Any other id fails.

## PAT scope requirements

The workflow access token must allow:

- Get role, list role entitlements
- Get access profile, list access profile entitlements
- Get entitlement
- List access request status, only when `requestedItems` is omitted
- Result source account persist

## Bundled workflows

Import the workflow, set **Configuration**, then subscribe or attach it as described. All three are imported disabled.

| Workflow | Contract |
|---|---|
| [`workflows/Risk Approval - Auto Approve or Deny.json`](../../../workflows/Risk%20Approval%20-%20Auto%20Approve%20or%20Deny.json) | [Access Request Submitted](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-submitted) event trigger. Approves or denies |
| [`workflows/Risk Approval - Dynamic Approver.json`](../../../workflows/Risk%20Approval%20-%20Dynamic%20Approver.json) | [Access Request Dynamic Approval](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval). Adds the approver you pick per tier, or none where you pick nobody |
| [`workflows/Risk Approval - Dynamic approval workflow.json`](../../../workflows/Risk%20Approval%20-%20Dynamic%20approval%20workflow.json) | Native Access Request Submitted trigger plus one Approval Policy per risk tier. Set this workflow as the access item Approval Type |

Shared Configuration on every workflow:

| Variable | JSON path | Purpose |
|---|---|---|
| API URL | `$.configuration.aPIURL` | Tenant API base URL, no trailing slash |
| SaaS Custom Operations Source Name | `$.configuration.saaSCustomOperationsSourceName` | Result source name |
| SaaS Custom Operations Connector ID | `$.configuration.saaSCustomOperationsConnectorID` | Platform connector id |
| Consider Privilege | `$.configuration.considerPrivilege` | `true` (default) includes entitlement `privilegeLevel.effective`. `false` scores entitlements from Risk metadata only |

On **Get Access Token**, set HTTP basic authentication to the workflow OAuth client (`client_credentials`). Do not paste the client secret into the exported JSON.

### Auto approve or deny

Subscribe the Access Request Submitted event trigger to this workflow's external trigger URL. Response type **Async**. Set a response deadline long enough for the role and entitlement reads.

| Variable | Default | Meaning |
|---|---|---|
| Deny At Tier | `High` | `High` denies only High. `Medium` denies High and Medium. `Low` denies every tier |
| Approver Name | `Workflow` | Callback `approver`. Use an existing identity username if Access Request Decision is also subscribed |

This subscription is tenant-wide. A deny stops later dynamic approval, because [dynamic approval runs only after this callback approves](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval). A failed evaluation denies the request.

### Dynamic approver

Subscribe Access Request Dynamic Approval the same way (Async, external URL, deadline).

This workflow adds **at most one extra approver, or none**, depending on the risk tier. It never adds two, and a tier you leave at `NONE` adds nobody.

An extra approver is built on the tier steps as **type + id**. `variableA` is `IDENTITY|` or `GOVERNANCE_GROUP|`, and the concatenate transform supplies the id: `$.defineVariable.manager`, `$.defineVariable.managersManager`, `$.configuration.defaultApprover`, or a literal.

Three ISC validator rules shape this workflow, and breaking any of them blocks saving it:

- **No empty values.** `NONE` means no extra approver. Every variable starts at `NONE` rather than `""`, and a tier adds nobody by setting `variableA` to `NONE` with no transform.
- **No JSONPath in `description` fields.** ISC parses those strings and reports them as invalid update targets.
- **Update targets must use the generated step key.** A variable path comes from the step's JSON key, not its display name, and only ISC's own key is accepted as an update target — hence the step keyed `Define Variable` (shown as **Approver Variables**) and the `$.defineVariable.*` paths. `Configuration` keeps its key because it is only ever read.

The workflow runs in four phases:

1. **Resolve the manager levels as ids.** Both start at `NONE`. Reading the recipient and the manager fills them with the identity id. **No manager, use default approver** sets Manager to **Default Approver** and continues to **No manager's manager, use default approver**, which does the same for the second level.
2. **Score risk**, as in the other workflows.
3. **Set the approver** for the winning tier. There is one step per tier — **Set High approver**, **Set Medium approver**, **Set Low approver** — each concatenates type and id as above. These three steps are the whole routing policy.
4. **Answer.** An `Approver` other than `NONE` is split on the `|` into the callback's `type` and `id`; `NONE` sends the none callback.

The invoke call stays on `/beta/platform-connectors`. The `/v2026` and `/v2025` equivalents reject requests that omit the `X-SailPoint-Experimental: true` header, so beta is the stable path for it today.

The only extra Configuration variable is **Default Approver**, an identity or governance group **id** (no type prefix). Missing manager levels copy that id. Pair the type (`IDENTITY|` or `GOVERNANCE_GROUP|`) on the Set approver steps.

Each tier step is yours to set: change `variableA` for the type, and the concatenate input for the id. As shipped, High is `IDENTITY|` plus the manager's manager, Medium is `IDENTITY|` plus the manager, and Low is `NONE`. A failed Read Risk Result takes **Set Error approver**, which concatenates `IDENTITY|` with **Default Approver**. A failed token or invoke, and an unknown tier, take the High step.

The callback sends `name` empty. The trigger assigns the approval from `id` and `type`, so the workflow does not read the identity or the governance group just to fill it in.

### Dynamic approval workflow

Requires Adaptive Approvals. The declared trigger is `idn:access-request-trigger`, the Adaptive Approvals **Access Request Submitted** trigger. It is not the subscribable event trigger of the same display name (`idn:access-request-pre-approval`), and it does not appear in `/beta/triggers`. ISC rejects the workflow unless a trigger and an `sp:access-request-approval` action appear together, in either direction. After import, enable the workflow and set the role, access profile, or entitlement **Approval Type** to **Workflow**, then pick this workflow. It runs only for items attached to it.

The workflow scores the request, then opens one Approval Policy (`sp:access-request-approval`) for that tier: High, Medium, or Low. It does not resolve managers or a default approver. After import, open each Approval Policy step and bind the reviewer (identity or governance group). SailPoint does not publish that action's field names.

A failed evaluation, or a missing tier, uses the High policy.

Do not also subscribe the dynamic-approver workflow for the same items unless you want both this policy and a later extra approver.

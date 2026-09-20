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
| `requestedItems` | No* | `{ id, type, name? }` from the trigger. `type` is `ROLE`, `ACCESS_PROFILE`, or `ENTITLEMENT` |
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
| [`workflows/Risk Approval - Submitted Gate.json`](../../../workflows/Risk%20Approval%20-%20Submitted%20Gate.json) | [Access Request Submitted](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-submitted) event trigger. Approves or denies |
| [`workflows/Risk Approval - Extra Approver.json`](../../../workflows/Risk%20Approval%20-%20Extra%20Approver.json) | [Access Request Dynamic Approval](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval). Adds one approver, or none on Low |
| [`workflows/Risk Approval - Access Item.json`](../../../workflows/Risk%20Approval%20-%20Access%20Item.json) | Native Access Request Submitted trigger plus Approval Policy. Set this workflow as the access item Approval Type |

Shared Configuration on every workflow:

| Variable | JSON path | Purpose |
|---|---|---|
| API URL | `$.configuration.aPIURL` | Tenant API base URL, no trailing slash |
| SaaS Custom Operations Source Name | `$.configuration.saaSCustomOperationsSourceName` | Result source name |
| SaaS Custom Operations Connector ID | `$.configuration.saaSCustomOperationsConnectorID` | Platform connector id |
| Consider Privilege | `$.configuration.considerPrivilege` | `true` (default) includes entitlement `privilegeLevel.effective`. `false` scores entitlements from Risk metadata only |

On **Get Access Token**, set HTTP basic authentication to the workflow OAuth client (`client_credentials`). Do not paste the client secret into the exported JSON.

### Submitted gate

Subscribe the Access Request Submitted event trigger to this workflow's external trigger URL. Response type **Async**. Set a response deadline long enough for the role and entitlement reads.

| Variable | Default | Meaning |
|---|---|---|
| Deny At Tier | `High` | `High` denies only High. `Medium` denies High and Medium. `Low` denies every tier |
| Approver Name | `Workflow` | Callback `approver`. Use an existing identity username if Access Request Decision is also subscribed |

This subscription is tenant-wide. A deny stops later dynamic approval, because [dynamic approval runs only after this callback approves](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval). A failed evaluation denies the request.

### Extra approver

Subscribe Access Request Dynamic Approval the same way (Async, external URL, deadline).

The workflow loads the recipient, the manager, and the manager's manager before it scores risk. A missing manager level is not used. The configured default approver replaces it.

| Variable | Values |
|---|---|
| High Selector / Medium Selector | `manager`, `managersManager`, `defaultApprover`, `customIdentity`, `customGovernanceGroup` |
| Default Approver ID / Name | Identity used when the selected level is missing, the selector is `defaultApprover`, or evaluation fails |
| Custom High/Medium Identity ID / Name | Used when that tier's selector is `customIdentity` |
| Custom High/Medium Group ID / Name | Used when that tier's selector is `customGovernanceGroup` |

Low sends an empty approver (`id`, `name`, and `type` are empty strings). Defaults: High selector `managersManager`, Medium selector `manager`.

### Access item

Requires Adaptive Approvals. After import, enable the workflow and set the role, access profile, or entitlement **Approval Type** to **Workflow**, then pick this workflow. It runs only for items attached to it.

Selectors match the extra-approver workflow. Medium and High each open one Approval Policy (`sp:access-request-approval`) for the resolved reviewer. Low ends successfully and does not open a review. If a tenant leaves those Low requests stuck, point the **Check Tier** Low branch at **Approval Policy Default**.

After import, open each Approval Policy step and confirm the reviewer is still bound. SailPoint does not publish that action's field names; the branch targets are the manager, the manager's manager, the default identity, or the custom identity or governance group configured above.

Do not also subscribe the extra-approver workflow for the same items unless you want both this policy and a later extra approver.

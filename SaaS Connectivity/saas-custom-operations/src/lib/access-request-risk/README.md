# Access request risk scoring (library)

## Purpose

Scores an access request and produces the highest risk tier. This folder is the **risk scoring library** under `src/lib/` used by [`custom:evaluate-access-request`](../../operations/evaluate-access-request/README.md). It does not register a connector command.

Bundled Dynamic Approver workflows and the Access Request Pre-Check invoke `custom:evaluate-access-request`. Risk-only wrappers omit `evaluateSod` (default `false`). The pre-check sets `evaluateSod` to `true`.

Dimensions are not read. Role risk uses the role, its access profiles, and entitlements returned by the role and access-profile APIs. Independent catalog reads run with bounded concurrency and in-flight memoization. The shared Axios client also enforces an invocation-wide concurrency limit and retries HTTP 429 with `Retry-After` / backoff.

## Risk rules

The highest tier wins.

| Object                                          | High                                                                    | Medium                                                        | Low                                       |
| ----------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------- |
| Role or access profile                          | Risk metadata `iscRisk` is `critical` or `high`                         | Risk metadata is `medium`                                     | Anything else, including no Risk metadata |
| Entitlement (`considerPrivilege` true, default) | Effective privilege is `HIGH`, or Risk metadata is `critical` or `high` | Effective privilege is `MEDIUM`, or Risk metadata is `medium` | Anything else                             |
| Entitlement (`considerPrivilege` false)         | Risk metadata is `critical` or `high`                                   | Risk metadata is `medium`                                     | Anything else                             |

A role or access profile is then scored again through its entitlements. Wrapped access profiles are scored with the same role/access-profile rule before their entitlements.

## Persisted attributes

`custom:evaluate-access-request` writes these when risk runs. The result account uses the **risk persist identity**, which is the invoke `requestId`. Bundled Dynamic Approver workflows set it to `evaluate-access-request-risk:{accessRequestId}` plus a **wrapper discriminator**:
`:dynamic` or `:dynamic-approval`. The Access Request Pre-Check workflow persists under `access-request-precheck:{accessRequestId}:submitted`.

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

## Bundled workflows

Import the workflow, set **Configuration**, then subscribe or attach it as described. All three are imported disabled.

| Workflow                                                                                                                                                                          | Contract                                                                                                                                                                                                                                           |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`workflows/Access Request Pre-Check - Risk analysis and SOD.json`](../../../workflows/Access%20Request%20Pre-Check%20-%20Risk%20analysis%20and%20SOD.json) | [Access Request Submitted](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-submitted) event trigger. Invokes `custom:evaluate-access-request` with `evaluateSod` true and branches on the result account |
| [`workflows/Dynamic Approver - Risk analysis.json`](../../../workflows/Dynamic%20Approver%20-%20Risk%20analysis.json)                                                             | [Access Request Dynamic Approval](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval). Adds the approver you pick per tier, or none where you pick nobody                                  |
| [`workflows/Dynamic Approval Workflow - Risk analysis.json`](../../../workflows/Dynamic%20Approval%20Workflow%20-%20Risk%20analysis.json)                                         | Native Access Request Submitted trigger plus one Approval Policy per risk tier. Set this workflow as the access item Approval Type                                                                                                                 |

Shared Configuration on every workflow:

| Variable                            | JSON path                                         | Purpose                                                                                                               |
| ----------------------------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| API URL                             | `$.configuration.aPIURL`                          | Tenant API base URL, no trailing slash                                                                                |
| SaaS Custom Operations Source Name  | `$.configuration.saaSCustomOperationsSourceName`  | Result source name                                                                                                    |
| SaaS Custom Operations Connector ID | `$.configuration.saaSCustomOperationsConnectorID` | Platform connector id                                                                                                 |
| Consider Privilege                  | `$.configuration.considerPrivilege`               | `true` (default) includes entitlement `privilegeLevel.effective`. `false` scores entitlements from Risk metadata only |

The Access Request Pre-Check workflow also has **Inflight Only** (`$.configuration.inflightOnly`, default `true`).

Each Dynamic Approver workflow's **Read Risk Result** filter must match the `requestId` sent on **Call Evaluate Risk**:

-   Dynamic Approver - Risk analysis: `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic`
-   Dynamic Approval Workflow - Risk analysis: `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval`

The Access Request Pre-Check workflow uses `access-request-precheck:{{$.trigger.accessRequestId}}:submitted` and reads the result account after verified persist (see [`evaluate-access-request`](../evaluate-access-request/README.md)).

Deploy the connector and re-import the bundled Risk Approval workflows in one maintenance window.
After re-import, re-apply Configuration values and the **Get Access Token** basic-auth reference.

### Access Request Pre-Check - Risk analysis and SOD

Subscribe the Access Request Submitted event trigger to this workflow's external URL. Response type **Async**. Set a response deadline long enough for the combined risk and SoD evaluation plus result-account indexing.

This workflow runs one check and answers once. It invokes [`custom:evaluate-access-request`](../evaluate-access-request/README.md) with `evaluateSod` true, waits for the indexed result account, then branches on persisted attributes (`evaluate-access-request-risk:tier`, `preventive-sod-check:has-violation`, situation summaries). The invoke receives the trigger identity and requested items directly. **Inflight Only** defaults to `true`, so only violations _this request_ would introduce count.

**Decision Variables** holds the answer while the workflow builds it: `Approved` starts `true`, `Message` starts as a placeholder. Four Mutation steps are the entire policy, and each one can change both:

| Step                     | Ships as | Comment it writes                                                  |
| ------------------------ | -------- | ------------------------------------------------------------------ |
| Set Low risk decision    | approve  | Persisted risk situation summary                                   |
| Set Medium risk decision | approve  | Persisted risk situation summary                                   |
| Set High risk decision   | approve  | Persisted risk situation summary                                   |
| Set violation decision   | deny     | Replaces the risk comment with the persisted SoD situation summary |

The SoD policy step runs after the risk tier steps, so it has the last word. **Set evaluation failed decision** catches every failed token, an invoke that returns `"status":"failed"` in an HTTP 200 body, a failed account read, and an unknown risk tier — it denies, and setting `Approved` to `true` there is the one switch that makes the pre-check fail open.

**A boolean does not survive a workflow variable.** Define Variable stores `Approved` as a real boolean, but the moment an Update Variable step writes it, workflow state holds the string `"true"` or `"false"`. **Approved?** therefore compares with `StringEquals` against `"true"`.

This subscription is tenant-wide. A deny stops later dynamic approval, because [dynamic approval runs only after this callback approves](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-dynamic-approval).

### Dynamic Approver - Risk analysis

Subscribe Access Request Dynamic Approval the same way (Async, external URL, deadline).

This workflow adds **at most one extra approver, or none**, depending on the risk tier. It never adds two, and a tier you leave at `NONE` adds nobody. It invokes `custom:evaluate-access-request` (risk only) and reads the result account after verified persist.

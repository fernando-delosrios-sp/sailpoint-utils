# custom:preventive-sod-check

## Purpose

Evaluates SoD violations for an identity. Output semantics depend on whether `accessRequestId` is provided — use identity-only invoke for holistic state, request-scoped invoke to gate a specific approval.

## Command

`custom:preventive-sod-check`

## Input

| Field | Required | Description |
|---|---|---|
| `identityId` | No* | Target identity for holistic evaluation (identity mode) |
| `accessRequestId` | No* | When set, switches to **request mode** (predict delta for this request). Resolves target identity from the access request when `identityId` is omitted |
| `inflightOnly` | No | When `true`, skip existing/active violations and report only inflight (predict) violations. Defaults to `false`. Workflows may send the string `"true"` / `"false"` |

\* At least one of `identityId` or `accessRequestId` is required. When both are provided, `accessRequestId` takes precedence and `identityId` is **ignored** (a warning is logged).

## Output (persisted)

| Field | Type | Identity mode (no `accessRequestId`) | Request mode (`accessRequestId` set) |
|---|---|---|---|
| `preventive-sod-check:has-violation` | boolean | `true` if existing **or** inflight violations (`inflightOnly: true` → inflight only) | `true` if **this request** introduces a violation (`inflightOnly: false` also includes existing active violations) |
| `preventive-sod-check:violated-policy-names` | string[] | Mode-appropriate policy names (see `has-violation`) | Mode-appropriate policy names (see `has-violation`) |
| `preventive-sod-check:situation-summary` | string | See summary rules below | See summary rules below |

When the identity already violates SoD but the target request adds nothing new, request mode with default `inflightOnly` (`false`) still reports those existing policies. The bundled pre-check workflow sets `inflightOnly` to `true`, so that case returns `has-violation: false`, empty policy names, and `"No violations found"`.

## Summary rules

| Condition | `preventive-sod-check:situation-summary` |
|---|---|
| No violations | `No violations found` |
| Violations, no `accessRequestId` | Lists violating policy names with each policy's level, e.g. `Finance Control (High)` |
| Violations, with `accessRequestId` | Attributes those labeled policies to the access request |

A policy with no resolvable level is listed by name only. Levels are the SoD policy risk classification (`Critical`, `High`, `Medium`, `Low`).

`preventive-sod-check:violated-policy-names` contains the mode-appropriate policy list (see output table above).

## Invoke examples

| Payload | Use |
|---|---|
| [`payloads/preventive-sod-check.json`](../../../payloads/preventive-sod-check.json) | Offline local invoke (canned data) |

Offline example:

```json
{
    "type": "custom:preventive-sod-check",
    "input": {
        "requestId": "offline-preventive-001",
        "identityId": "offline-preventive-identity"
    }
}
```

Workflow-ready example:

```json
{
    "connectorRef": "{{$.defineVariable.saaSCustomOperationsConnectorID}}",
    "tag": "latest",
    "type": "custom:preventive-sod-check",
    "input": {
        "requestId": "req-preventive-001",
        "accessRequestId": "{{$.trigger.accessRequestId}}",
        "inflightOnly": "{{$.defineVariable.inflightOnly}}"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

## Bundled workflows

| Workflow | Contract |
|---|---|
| [`workflows/Access Request Pre-Check - Risk analysis and in-flight SOD.json`](../../../workflows/Access%20Request%20Pre-Check%20-%20Risk%20analysis%20and%20in-flight%20SOD.json) | [Access Request Submitted](https://developer.sailpoint.com/docs/extensibility/event-triggers/triggers/access-request-submitted) event trigger. Runs this operation in request mode alongside `custom:evaluate-access-request-risk`, and denies on a detected violation |

That workflow invokes with `requestId` `preventive-sod-check:{{$.trigger.accessRequestId}}:submitted` and filters **Read SoD Result** on the same value. The prefix keeps the result account clear of other operations writing on the same access request id. **Inflight Only** defaults to `true` in Configuration and is passed as `inflightOnly`. See the [risk operation README](../evaluate-access-request-risk/README.md#access-request-pre-check---risk-analysis-and-in-flight-sod) for its Configuration and decision steps.

The access token must also allow SoD policy read (`listSodPoliciesV1` / `getSodPolicyV1`) so the situation summary can include each policy's level.

## Workflow integration

1. Invoke `custom:preventive-sod-check` with `identityId` for holistic checks, or with `accessRequestId` alone (or plus ignored `identityId`) to gate a specific approval.
2. Read persisted output via **Get Accounts** filtered by `requestId`. The operation persists under the `requestId` you send, verbatim, so pick one that will not collide with another operation's result account.
3. Branch on `preventive-sod-check:has-violation` or policy names. It persists as a real boolean, so compare the account read itself with `sp:compare-boolean`. If you copy it into a workflow variable first, note that `sp:update-variable` stores it as the string `"true"` / `"false"` — read that variable back with `sp:compare-strings`, never `sp:compare-boolean`.

Example branch (request-scoped approval gate):

- If `preventive-sod-check:has-violation` is `false` → continue approval.
- If `true` → route to manual review using `preventive-sod-check:situation-summary` and `preventive-sod-check:violated-policy-names`.

## PAT scope requirements

The access token must allow:

- Access request status read (`listAccessRequestStatusV1`)
- Active violations read (`GET /violations/v1` with experimental header)
- Search/events read (`searchPostV1` on `events` index)
- SoD predict (`startPredictSodViolationsV1`)
- SoD policy read (`listSodPoliciesV1` / `getSodPolicyV1`)
- Result source account persist (standard custom operation scopes)

## Local development

```bash
npm run call:op -- payloads/preventive-sod-check.json
```

Use identity `offline-preventive-empty` in offline payloads to simulate no executing grants.

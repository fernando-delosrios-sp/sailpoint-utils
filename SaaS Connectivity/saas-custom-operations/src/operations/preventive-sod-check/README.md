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

\* At least one of `identityId` or `accessRequestId` is required. When both are provided, `accessRequestId` takes precedence and `identityId` is **ignored** (a warning is logged).

## Output (persisted)

| Field | Type | Identity mode (no `accessRequestId`) | Request mode (`accessRequestId` set) |
|---|---|---|---|
| `preventive-sod-check:has-violation` | boolean | `true` if existing **or** inflight violations | `true` only if **this request** introduces a violation |
| `preventive-sod-check:violated-policy-names` | string[] | All violated policies (existing ∪ inflight) | Policies attributed to **this request** only |
| `preventive-sod-check:situation-summary` | string | See summary rules below | See summary rules below |

When the identity already violates SoD but the target request adds nothing new, request mode returns `has-violation: false`, empty policy names, and `"No violations found"`.

## Summary rules

| Condition | `preventive-sod-check:situation-summary` |
|---|---|
| No violations | `No violations found` |
| Violations, no `accessRequestId` | Lists all violating policy names |
| Violations, with `accessRequestId` | Attributes violations to the access request |

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
        "accessRequestId": "{{$.trigger.accessRequestId}}"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

## Bundled workflows

No workflow exports are bundled for this operation. Wire it into approval or access-request workflows using the invoke contract below — typically as a gate before manager or SoD review.

## Workflow integration

1. Invoke `custom:preventive-sod-check` with `identityId` for holistic checks, or with `accessRequestId` alone (or plus ignored `identityId`) to gate a specific approval.
2. Read persisted output via **Get Accounts** filtered by `requestId`.
3. Branch on `preventive-sod-check:has-violation` or policy names.

Example branch (request-scoped approval gate):

- If `preventive-sod-check:has-violation` is `false` → continue approval.
- If `true` → route to manual review using `preventive-sod-check:situation-summary` and `preventive-sod-check:violated-policy-names`.

## PAT scope requirements

The access token must allow:

- Access request status read (`listAccessRequestStatusV1`)
- Active violations read (`GET /violations/v1` with experimental header)
- Search/events read (`searchPostV1` on `events` index)
- SoD predict (`startPredictSodViolationsV1`)
- Result source account persist (standard custom operation scopes)

## Local development

```bash
npm run call:op -- payloads/preventive-sod-check.json
```

Use identity `offline-preventive-empty` in offline payloads to simulate no executing grants.

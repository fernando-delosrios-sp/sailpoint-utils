# custom:access-request-threshold

## Purpose

Checks whether an identity would exceed an entitlement count threshold for a named source when combining granted, pending, and requested entitlements for an access request.

## Command

`custom:access-request-threshold`

## Input

| Field | Required | Description |
|---|---|---|
| `accessRequestId` | Yes | ISC access request id |
| `sourceName` | Yes | Source name to filter entitlements (case-insensitive) |
| `thresholdValue` | Yes | Maximum allowed entitlements before `thresholdHit` is true |

## Output (persisted)

| Field | Type | Description |
|---|---|---|
| `thresholdHit` | boolean | True when found count exceeds threshold |
| `foundCount` | number | Entitlements matching source across all buckets |
| `sourceName` | string | Source name evaluated |
| `thresholdValue` | number | Threshold used |
| `requestedCount` | number | Entitlements from this request |
| `pendingCount` | number | Entitlements from other executing requests |
| `grantedCount` | number | Currently granted entitlements |

## Invoke response

| Field | Type | Description |
|---|---|---|
| `thresholdHit` | boolean | Same as persisted |
| `details.identityId` | string | Requested-for identity |
| `details.source` | string | Source name evaluated |
| `details.threshold` | number | Threshold used |
| `details.foundCount` | number | Matching entitlement count |
| `details.breakdown` | object | `{ requested, pending, granted }` counts |

## Invoke example

```json
{
    "type": "custom:access-request-threshold",
    "input": {
        "requestId": "req-threshold-001",
        "accessRequestId": "{{$.trigger.accessRequestId}}",
        "sourceName": "Active Directory",
        "thresholdValue": 0
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

## PAT scope requirements

- Access request status read
- Identity entitlements read
- Entitlement / role / access profile read
- Result source account persist

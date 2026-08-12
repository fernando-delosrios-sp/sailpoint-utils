# custom:check-sod-pending

## Purpose

Evaluates whether an identity would violate SoD when combining currently granted entitlements with entitlements from other EXECUTING access requests. Uses local policy criteria matching (not the ISC predict API).

For predict-based preventive checks with persisted workflow outputs, use `custom:preventive-sod-check` instead.

## Command

`custom:check-sod-pending`

## Input

| Field | Required | Description |
|---|---|---|
| `identityId` | Yes | Target identity to evaluate |

## Output (invoke response only)

This operation does **not** persist to the result source. Read values from the invoke response:

| Field | Type | Description |
|---|---|---|
| `identityId` | string | Evaluated identity |
| `hasViolations` | boolean | True when local policy matching finds violations |
| `violatedPolicyNames` | string[] | Names of violated policies |
| `counts.pendingEntitlements` | number | Entitlements from other executing requests |
| `counts.grantedEntitlements` | number | Currently granted entitlements |
| `counts.combinedTotal` | number | Deduplicated combined entitlement count |

## Invoke example

```json
{
    "type": "custom:check-sod-pending",
    "input": {
        "requestId": "req-sod-pending-001",
        "identityId": "{{$.trigger.identityId}}"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

## PAT scope requirements

- Access request status read (executing requests)
- Identity entitlements read
- Entitlement / role / access profile read
- SoD policy read

## Comparison with preventive-sod-check

| Aspect | check-sod-pending | preventive-sod-check |
|---|---|---|
| Algorithm | Local policy criteria match | ISC predict API + violations search |
| Output | Invoke response | Persisted account attributes |
| Use case | Legacy/simple local check | Workflow branching via Get Accounts |

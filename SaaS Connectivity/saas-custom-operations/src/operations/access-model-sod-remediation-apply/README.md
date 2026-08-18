# custom:access-model-sod-remediation-apply

## Purpose

Applies a completed access-model SoD remediation form decision to the ISC catalog. Detaches nested access profiles from roles or removes direct role entitlements; removes entitlements from access profile definitions when the violated item is an AP. Appends an audit line to the corrected catalog item description.

Runs after `custom:access-model-sod-remediation` form submit in the access-model SoD workflow.

## Command

`custom:access-model-sod-remediation-apply`

## Input

| Field | Required | Description |
|---|---|---|
| `formInstanceId` | Yes | Completed form instance id from the form trigger or Get Form Instance step |
| `requestId` | Yes | Standard invoke id for logging; persist key is `formInstanceId`. In-flight dedupe also keys on `formInstanceId` for this command |

## Output

Persisted on result-source identity `{formInstanceId}` and returned on successful invoke:

| Field | Description |
|---|---|
| `access-model-sod-remediation-apply:status` | `applied`, `skipped-already-clean`, or `skipped-already-applied` |
| `access-model-sod-remediation-apply:access-item-id` | Corrected role or access profile id |
| `access-model-sod-remediation-apply:access-item-type` | `ROLE` or `ACCESS_PROFILE` |
| `access-model-sod-remediation-apply:removed-entitlement-ids` | Optional; direct entitlements removed from role or AP |
| `access-model-sod-remediation-apply:detached-access-profile-ids` | Optional; nested APs detached from role |
| `access-model-sod-remediation-apply:description-appended` | Optional audit snippet appended to catalog description |

## Remediation semantics

| Access item type | Selected-side entitlement source | Action |
|---|---|---|
| `ROLE` | Nested access profile bundle | Detach whole AP from role (`accessProfiles` PATCH) |
| `ROLE` | Direct role entitlement | Remove from role `entitlements` PATCH |
| `ACCESS_PROFILE` | AP under review | Remove entitlement ids from AP definition |

Never patches entitlement lists on nested access profiles when correcting a role.

## Idempotency

Before catalog PATCH, the handler checks the result-source account at `{formInstanceId}` for a prior terminal apply (`applied` or `skipped-already-applied`). When found, it skips PATCH and returns `skipped-already-applied`. Concurrent invokes for the same `formInstanceId` dedupe in-flight via a framework key that includes `formInstanceId` (not `requestId`).

| Status | Meaning |
|---|---|
| `applied` | Catalog correction PATCH executed |
| `skipped-already-clean` | Catalog already matched the form decision; no PATCH needed |
| `skipped-already-applied` | Prior successful apply persist found for this form instance; no duplicate PATCH |

## Invoke example

```json
{
    "type": "custom:access-model-sod-remediation-apply",
    "input": {
        "requestId": "access-model-sod-apply-001",
        "formInstanceId": "{{$.trigger.formInstanceId}}"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

Offline: [`payloads/access-model-sod-remediation-apply-offline.json`](../../../payloads/access-model-sod-remediation-apply-offline.json)

## Workflow integration

1. After access-model SoD form completion (Wait for Form / trigger), invoke this command with `formInstanceId` only.
2. Read `access-model-sod-remediation-apply:status` from the invoke response or Get Accounts on `{formInstanceId}`.
3. Branch on `applied`, `skipped-already-clean`, or `skipped-already-applied`. Retries and parallel workflow branches are safe — duplicate applies for the same form instance do not double-PATCH.

## Token scope requirements

- Custom Forms read (`getFormInstanceByKeyV1`)
- Roles read/update (`getRoleV1`, `getRoleEntitlementsV1`, `patchRoleV1`) when correcting roles
- Access profiles read/update (`getAccessProfileV1`, `getAccessProfileEntitlementsV1`, `patchAccessProfileV1`) when correcting APs or expanding role nested APs
- Result source account persist (standard custom operation scopes)

## Local development

```bash
npm run call:op payloads/access-model-sod-remediation-apply-offline.json
```

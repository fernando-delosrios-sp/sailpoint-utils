# custom:access-classification

## Purpose

Scheduled classification of entitlements, access profiles, roles, and identities that violate tagged SoD policies. Reconciles the `privileged` and `risk` tags on access items, and promotes each SoD policy's tags onto its entitlements, containing access profiles and roles, and violating identities. Persists one run summary account.

## Command

`custom:access-classification`

## Classification rules

| Tag | Entitlement | Access profile / role | Identity |
|---|---|---|---|
| `privileged` | Effective privilege `MEDIUM` or `HIGH` (`direct` when `effective` is absent) | Contains a privileged entitlement (AP) or privileged AP / direct entitlement (role); stop at first hit | Never |
| `risk` | Own Risk metadata (`iscRisk` / Risk) has any non-empty value | Own Risk metadata only; not inherited | Never |
| SoD policy tags | On either side of an enforced, tagged policy | Contains a tagged entitlement (or AP for roles); stop looking for a tag once acquired | Open/Mitigated/Reopened violators plus identities matching the policy query (Closed excluded) |

## Input

| Field | Required | Description |
|---|---|---|
| _(none)_ | — | Standard `requestId` / config only |

## Output (persisted)

| Field | Required | Description |
|---|---|---|
| `access-classification:entitlements-scanned` | Yes | Entitlements evaluated |
| `access-classification:access-profiles-scanned` | Yes | Access profiles evaluated |
| `access-classification:roles-scanned` | Yes | Roles evaluated |
| `access-classification:identities-scanned` | Yes | Distinct violating identities considered |
| `access-classification:tags-added` | Yes | Object×tag pairs added |
| `access-classification:tags-removed` | Yes | Object×tag pairs removed |
| `access-classification:objects-failed` | Yes | Failed add/remove batches |
| `access-classification:failure-details` | Yes | Failure messages |

## Response (invoke envelope)

| Summary field | Required | Description |
|---|---|---|
| `entitlementsScanned` | No | Same as persisted |
| `accessProfilesScanned` | No | Same as persisted |
| `rolesScanned` | No | Same as persisted |
| `identitiesScanned` | No | Same as persisted |
| `tagsAdded` | No | Same as persisted |
| `tagsRemoved` | No | Same as persisted |
| `objectsFailed` | No | Same as persisted |

## Invoke examples

| Payload | Use |
|---|---|
| `payloads/access-classification-offline.json` | Local `npm run call:op` |
| `payloads/access-classification-workflow.json` | ISC workflow HTTP invoke |

## Workflow integration

1. Scheduled trigger (default daily 02:00 Europe/Madrid).
2. Get OAuth token.
3. Invoke `custom:access-classification` with a per-run `requestId`.
4. Treat NDJSON body containing `"status":"failed"` as failure.

See `workflows/Access Classification.json`.

## Local development

```bash
npm run call:op -- payloads/access-classification-offline.json
```

Offline mode uses canned catalog, policies, current tags, and violators. Tag writes are counted without live HTTP.

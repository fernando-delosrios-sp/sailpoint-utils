# custom:machine-identity-entitlements

## Purpose

Lists machine accounts, follows each account's authoritative `machineIdentity` node, reads configured entitlement values from `connectorAttributes`, matches ISC entitlements by value across sources, and directly PATCHes each machine identity's `userEntitlements` union. Identity failures are isolated so remaining updates continue.

## Command

`custom:machine-identity-entitlements`

## Input

| Field        | Required | Description                                                                                                             |
| ------------ | -------- | ----------------------------------------------------------------------------------------------------------------------- |
| `identityId` | No       | Limits the scan to one machine identity (`id`, then `cisIdentityId`). Omit to scan all. Unknown values fail the invoke. |

## Output (persisted)

Every run persists one scan summary account. Its scan summary identity is `{requestId}`, including no-work runs.

| Field                                                    | Type         | Description                                      |
| -------------------------------------------------------- | ------------ | ------------------------------------------------ |
| `machine-identity-entitlements:identities-scanned`       | INT          | Machine identities evaluated                     |
| `machine-identity-entitlements:identities-updated`       | INT          | Identities successfully PATCHed                   |
| `machine-identity-entitlements:identities-skipped`       | INT          | Identities whose delta was empty                  |
| `machine-identity-entitlements:identities-failed`        | INT          | Identities that could not be read or PATCHed      |
| `machine-identity-entitlements:entitlements-added`       | INT          | Count of entitlements to add that were PATCHed    |
| `machine-identity-entitlements:failed-identity-ids`      | STRING multi | Failed machine identity ids                      |
| `machine-identity-entitlements:failure-details`          | STRING multi | Error detail aligned with failed identity ids     |

Core account `status` is `success`, `partial`, or `failed`. A mixed run returns invoke success with account status `partial`; if every attempted update fails, the failed summary is persisted and the invoke reports failure.

## Response (invoke envelope)

| Summary field       | Description                          |
| ------------------- | ------------------------------------ |
| `identitiesScanned` | Machine identities evaluated         |
| `identitiesUpdated` | Identities successfully PATCHed      |
| `identitiesSkipped` | Identities with no delta              |
| `identitiesFailed`  | Identities whose apply attempt failed |
| `entitlementsAdded` | Count of entitlements to add that were PATCHed |

## Inbound entitlements attribute

The operation reads the inbound entitlements attribute name from source `connectorAttributes.userEntitlements`, then reads that key from each linked underlying account's `connectorAttributes`. The value may be a single string or array. Missing/blank source configuration or an absent underlying-account value skips that account without failing the scan.

For example, `Microsoft Entra ID @emea-tes-team.cloud (NHI)` currently configures `userEntitlements` as `spn_app_groups`.

## Machine-account correlation

The scan pages `/v2026/machine-accounts`. Each machine account is the underlying account for its machine identity. The scan discards accounts whose source is not configured and groups the remainder using each response object's `machineIdentity.id`. A full scan lists machine identities once and batches distinct entitlement values with `value in (...)`; it does not issue one catalog request per identity or value. Entitlements to add are the matched refs not already on `userEntitlements`. Before each PATCH it re-reads current `userEntitlements`, preserving refs added concurrently, and skips the update when entitlements to add is empty. PATCHes run with bounded concurrency. Entitlement matching is by value alone: one Entra group value can map to separate Users, NHI, active-PIM, and eligible-PIM records, and every match is added.

## Token scopes

Connected invokes need PAT/OAuth scopes for:

-   Machine identities list/get/patch (experimental `X-SailPoint-Experimental`)
-   Machine accounts list and result-source account persist
-   Source read (including `connectorAttributes`)
-   Entitlements list by `value`

## Invoke examples

| Payload                                                                                                                 | Use                    |
| ----------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| [`payloads/machine-identity-entitlements-offline.json`](../../../payloads/machine-identity-entitlements-offline.json)   | Offline local invoke   |
| [`payloads/machine-identity-entitlements.json`](../../../payloads/machine-identity-entitlements.json)                   | Connected full scan    |
| [`payloads/machine-identity-entitlements-identity.json`](../../../payloads/machine-identity-entitlements-identity.json) | Connected one identity |

## Workflow integration

[`workflows/Machine Identity Entitlements.json`](../../../workflows/Machine%20Identity%20Entitlements.json) is an interactive presentation wrapper. It invokes this command and reports no-work, successful, partial, or failed outcomes from the response summary. There is no Account Created Apply workflow.

1. Import the workflow, then set its interactive trigger filter to that workflow's own id (`$[?(@.workflowId == '<workflow-id>')]`).
2. Re-bind **Get Access Token** basic auth and set the connector id and API URL variables.
3. The workflow uses `requestId` `mie:{{$.trigger.interactiveProcessId}}`, which becomes the scan summary identity on the scan summary account. Omit `identityId` for a full tenant run, or add it to the invoke input to limit the run.

## Local development

```bash
npm run call:op -- payloads/machine-identity-entitlements-offline.json
```

Offline fixtures cover linked machine accounts, source connector configuration, two machine identities, catalog matches, direct apply, and the summary. Persist is inhibited in test mode; the response still lists `requestId` as the summary identity.

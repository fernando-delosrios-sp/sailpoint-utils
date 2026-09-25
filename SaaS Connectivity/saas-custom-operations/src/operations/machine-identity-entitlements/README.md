# custom:machine-identity-entitlements

## Purpose

Lists machine accounts, follows each account's authoritative `machineIdentity` node, reads configured entitlement values from `connectorAttributes`, matches ISC entitlements by value and source, and persists **entitlements to add** on one **trigger account** per machine identity that has a non-empty add list. A bundled Account Created workflow PATCHes `userEntitlements`.

## Command

`custom:machine-identity-entitlements`

## Input

| Field        | Required | Description                                                                                                             |
| ------------ | -------- | ----------------------------------------------------------------------------------------------------------------------- |
| `identityId` | No       | Limits the scan to one machine identity (`id`, then `cisIdentityId`). Omit to scan all. Unknown values fail the invoke. |

## Output (persisted)

Native identity is the **machine identity persist identity** `{requestId}:{machineIdentityId}`. Persist runs only when entitlements to add is non-empty. Zip `entitlement-ids` with `entitlement-source-ids` by index.

| Field                                                  | Required | Description                                    |
| ------------------------------------------------------ | -------- | ---------------------------------------------- |
| `machine-identity-entitlements:machine-identity-id`    | Yes      | Machine identity id                            |
| `machine-identity-entitlements:entitlement-ids`        | Yes      | Entitlement ids to add (STRING multi)          |
| `machine-identity-entitlements:entitlement-source-ids` | Yes      | Matching source ids, same order (STRING multi) |

## Response (invoke envelope)

| Summary field            | Description                            |
| ------------------------ | -------------------------------------- |
| `identitiesScanned`      | Machine identities evaluated           |
| `triggerAccountsWritten` | Trigger accounts persisted this invoke |

## User-entitlements connector attribute

The operation reads the attribute name from source `connectorAttributes.userEntitlements`, then reads that key from each linked machine account's `connectorAttributes`. The value may be a single string or array. Missing/blank source configuration or an absent machine-account value skips that account without failing the scan.

For example, `Microsoft Entra ID @emea-tes-team.cloud (NHI)` currently configures `userEntitlements` as `spn_app_groups`.

## Machine-account correlation

The scan pages `/v2026/machine-accounts`, discards accounts whose source is not configured, and groups the remainder using each response object's `machineIdentity.id`. A full scan lists machine identities once and batches distinct entitlement values with `value in (...)`; it does not issue one API request per identity or value. It does not infer correlation through Accounts `identityId` or account names. Entitlement matching is by value alone: one Entra group value is aggregated as a separate entitlement record on each source that sees it (Users and NHI) and under each membership type (`groups`, `azureADActiveGroups`, `azureADEligibleGroups`), and every match is added.

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

| File                                                                                                                            | Trigger                            | Purpose                                                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [`workflows/Machine Identity Entitlements - Scan.json`](../../../workflows/Machine%20Identity%20Entitlements%20-%20Scan.json)   | `idn:interactive-process-launched` | Explain the scan, invoke this operation, then report 0 vs N trigger accounts                                                                   |
| [`workflows/Machine Identity Entitlements - Apply.json`](../../../workflows/Machine%20Identity%20Entitlements%20-%20Apply.json) | `idn:account-created`              | Invoke [`custom:machine-identity-entitlements-apply`](../machine-identity-entitlements-apply/README.md), optionally delete the trigger account |

1. Import Scan, then set its interactive trigger filter to that workflow's own id (`$[?(@.workflowId == '<scan-workflow-id>')]`).
2. Import Apply. Advanced filter: `$.account.attributes[?(@.operationName == "custom:machine-identity-entitlements")]`.
3. Re-bind the **Get Access Token** basic auth on both workflows after import, and set Apply's connector id variable. Both invoke the connector, and the invoke body carries `config.token`, so a saved OAuth credential on the step alone is not enough.
4. Scan uses `requestId` `mie:{{$.trigger.interactiveProcessId}}` so each launch writes new trigger accounts and Account Created can fire again. Omit `identityId` on the invoke for a full scan, or add it there to limit to one machine identity.
5. Set **Delete Trigger Account** on Apply (default `false`). When `true`, the workflow deletes the trigger account only after a successful `userEntitlements` patch.
6. Apply invokes `custom:machine-identity-entitlements-apply`, which reads the identity's current refs and PATCHes the union with the persisted add list. The union is computed in the connector because a workflow `sp:http` body cannot zip the two parallel string arrays into the `{sourceId, entitlementId}` objects the API requires.

## Local development

```bash
npm run call:op -- payloads/machine-identity-entitlements-offline.json
```

Offline fixtures cover linked machine accounts, source connector configuration, two machine identities, and catalog matches. Persist is inhibited in test mode; the response still lists trigger identities that would be written.

# custom:machine-identity-entitlements

## Purpose

Evaluates machine identities, reads entitlement values from processable **underlying accounts**, matches ISC entitlements by `value`, and persists **entitlements to add** on one **trigger account** per machine identity that has a non-empty add list. A bundled Account Created workflow PATCHes `userEntitlements`.

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

## Inbound entitlements attribute

Opt in per source on the **account** schema: `configuration.inboundEntitlements` is the attribute name (STRING, single or multi). Missing, blank, or an unknown attribute name skips that **underlying account** and does not fail the scan.

## Accounts `identityId` mapping

Underlying accounts are listed with `identityId eq "{cisIdentityId ?? machineIdentity.id}"`. Confirm this mapping on a live tenant if correlation looks empty.

## Token scopes

Connected invokes need PAT/OAuth scopes for:

-   Machine identities list/get/patch (experimental `X-SailPoint-Experimental`)
-   Accounts list (underlying accounts) and result-source persist
-   Source account schema read
-   Entitlements list by `value`

## Invoke examples

| Payload                                                                                                                 | Use                    |
| ----------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| [`payloads/machine-identity-entitlements-offline.json`](../../../payloads/machine-identity-entitlements-offline.json)   | Offline local invoke   |
| [`payloads/machine-identity-entitlements.json`](../../../payloads/machine-identity-entitlements.json)                   | Connected full scan    |
| [`payloads/machine-identity-entitlements-identity.json`](../../../payloads/machine-identity-entitlements-identity.json) | Connected one identity |

## Workflow integration

1. Import [`workflows/Machine Identity Entitlements - Apply.json`](../../../workflows/Machine%20Identity%20Entitlements%20-%20Apply.json).
2. Point the Account Created trigger at the result source. Advanced filter: `operationName == custom:machine-identity-entitlements`.
3. Set **Delete Trigger Account** (default `false`). When `true`, the workflow deletes the trigger account only after a successful `userEntitlements` patch.
4. The apply path GETs the machine identity, then PATCHes `userEntitlements` as the union of existing refs and the persisted add list — it must not replace with only the add list.

## Local development

```bash
npm run call:op -- payloads/machine-identity-entitlements-offline.json
```

Offline fixtures cover two machine identities (id and `cisIdentityId` shapes), opted-in and skipped schemas, and catalog matches. Persist is inhibited in test mode; the response still lists trigger identities that would be written.

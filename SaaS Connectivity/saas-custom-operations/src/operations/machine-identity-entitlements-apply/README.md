# custom:machine-identity-entitlements-apply

## Purpose

Unions scanned entitlements onto a machine identity's `userEntitlements`. Reads the identity's current refs, merges the supplied additions, and PATCHes the result. The union is built in the connector because a workflow `sp:http` body cannot zip two parallel string arrays into the array of `{sourceId, entitlementId}` objects the API requires.

## Command

`custom:machine-identity-entitlements-apply`

## Input

| Field                  | Required | Description                                                    |
| ---------------------- | -------- | -------------------------------------------------------------- |
| `machineIdentityId`    | Yes      | Machine identity to patch                                      |
| `entitlementIds`       | Yes      | Entitlement ids to add                                         |
| `entitlementSourceIds` | Yes      | Matching source ids, same order and length as `entitlementIds` |

Mismatched array lengths fail the invoke, because the two arrays are zipped by index.

## Output (persisted)

Native identity is `{requestId}:{machineIdentityId}`.

| Attribute                                                   | Required | Description                                |
| ----------------------------------------------------------- | -------- | ------------------------------------------ |
| `machine-identity-entitlements-apply:machine-identity-id`   | Yes      | Machine identity that was patched          |
| `machine-identity-entitlements-apply:status`                | Yes      | `applied` or `skipped-already-present`     |
| `machine-identity-entitlements-apply:added-entitlement-ids` | Yes      | Entitlement ids newly added (STRING multi) |

| Summary field | Description                          |
| ------------- | ------------------------------------ |
| `addedCount`  | Refs added by this invoke            |
| `totalCount`  | Refs on the identity after the patch |

## Union semantics

Existing refs are preserved in order and duplicates are dropped, so the patch never replaces `userEntitlements` with only the add list. When every supplied ref is already present the operation skips the PATCH and reports `skipped-already-present`.

## Token scopes

Machine identity get and update, with the experimental `X-SailPoint-Experimental` header.

## Workflow

| File                                                                                                                            | Trigger               | Role                                                                    |
| ------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ----------------------------------------------------------------------- |
| [`workflows/Machine Identity Entitlements - Apply.json`](../../../workflows/Machine%20Identity%20Entitlements%20-%20Apply.json) | `idn:account-created` | Invoke this command for each trigger account, then optionally delete it |

## Offline invoke

Offline fixtures cover an identity with no existing refs and one that already holds the supplied ref. Test mode inhibits both the PATCH and the persist.

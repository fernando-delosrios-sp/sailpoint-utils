# Accounts

Use this API to implement and customize account functionality.

16 endpoints. Paths are relative to the environment API host.

## Accounts list

`GET /accounts/v1`

Success: 200.

List accounts.

Query:

- standard: `limit`, `offset`, `count`
- `detailLevel`: This value determines whether the API provides `SLIM` or increased level of detail (`FULL`) for each account in the returned list. `FULL` is the default behavior. (This can only be one of SLIM,FULL)
- filters: id (eq, in, sw); identityId (eq, in, sw); name (eq, in, sw); nativeIdentity (eq, in, sw); hasEntitlements (eq); sourceId (eq, in, sw); uncorrelated (eq); entitlements (eq); origin (eq, in); manuallyCorrelated (eq); identity.name (eq, in, sw); identity.correlated (eq); identity.identityState (eq, in); source.displayableName (eq, in); source.authoritative (eq); source.connectionType (eq, in); recommendation.method (eq, in, isnull); created (eq, ge, gt, le, lt); modified (eq, ge, gt, le, lt)
- sorters: id, name, created, modified, sourceId, identityId, nativeIdentity, uuid, manuallyCorrelated, entitlements, origin, identity.name, identity.identityState, identity.correlated, source.displayableName, source.authoritative, source.connectionType

## Create account

`POST /accounts/v1`

Success: 202.

Submit an account creation task - the API then returns the task ID.

You must include the `sourceId` where the account will be created in the `attributes` object.

This endpoint creates an account on the source record in your ISC tenant.
This is useful for Flat File (`DelimitedFile`) type sources because it allows you to aggregate new accounts without needing to import a new CSV file every time.

However, if you use this endpoint to create an account for a Direct Connection type source, you must ensure that the account also exists on the target source.
The endpoint doesn't actually provision the account on the target source, which means that if the account doesn't also exist on the target source, an aggregation between the source and your tenant will remove it from your tenant.

By providing the account ID of an existing account in the request body, this API will function as a PATCH operation and update the account.

Body:

```json
{
  "attributes": {
    "sourceId": "34bfcbe116c9407464af37acbaf7a4dc",
    "city": "Austin",
    "displayName": "John Doe",
    "userName": "jdoe",
    "sAMAccountName": "jDoe",
    "mail": "john.doe@sailpoint.com"
  }
}
```

## Account details

`GET /accounts/v1/:id`

Success: 200.

Use this API to return the details for a single account by its ID.

## Update account (PATCH /accounts/v1/:id)

`PATCH /accounts/v1/:id`

Success: 202.

Use this API to update account details.

This API supports updating an account's correlation by modifying the `identityId` and `manuallyCorrelated` fields.
To reassign an account from one identity to another, replace the current `identityId` with a new value.
If the account you're assigning was provisioned by Identity Security Cloud (ISC), it's possible for ISC to create a new account
for the previous identity as soon as the account is moved. If the account you're assigning is authoritative,
this causes the previous identity to become uncorrelated and can even result in its deletion.
All accounts that are reassigned will be set to `manuallyCorrelated: true` unless you specify otherwise.

>**Note:** The `attributes` field can only be modified for flat file accounts.

Body:

```json
[
  {
    "op": "remove",
    "path": "/identityId"
  }
]
```

## Update account (PUT /accounts/v1/:id)

`PUT /accounts/v1/:id`

Success: 202.

Use this API to update an account with a PUT request.

This endpoint submits an account update task and returns the task ID.

>**Note: You can only use this PUT endpoint to update accounts from flat file sources.**

Body:

```json
{
  "attributes": {
    "city": "Austin",
    "displayName": "John Doe",
    "userName": "jdoe",
    "sAMAccountName": "jDoe",
    "mail": "john.doe@sailpoint.com"
  }
}
```

## Delete account

`DELETE /accounts/v1/:id`

Success: 202.

Use this API to delete an account.
This endpoint submits an account delete task and returns the task ID.
This endpoint only deletes the account from IdentityNow, not the source itself, which can result in the account's returning with the next aggregation between the source and IdentityNow.  To avoid this scenario, it is recommended that you disable accounts rather than delete them. This will also allow you to reenable the accounts in the future.
>**NOTE: You can only delete accounts from sources of the "DelimitedFile" type.**

## Account entitlements

`GET /accounts/v1/:id/entitlements`

Success: 200.

This API returns entitlements of the account.

Query:

- standard: `limit`, `offset`, `count`

## Reload account

`POST /accounts/v1/:id/reload`

Success: 202.

This API asynchronously reloads the account directly from the connector and performs a one-time aggregation process.

## Enable account

`POST /accounts/v1/:id/enable`

Success: 202.

This API submits a task to enable account and returns the task ID.

Body:

```json
{
  "externalVerificationId": "3f9180835d2e5168015d32f890ca1581",
  "forceProvisioning": false
}
```

## Disable account

`POST /accounts/v1/:id/disable`

Success: 202.

This API submits a task to disable the account and returns the task ID.

Body:

```json
{
  "externalVerificationId": "3f9180835d2e5168015d32f890ca1581",
  "forceProvisioning": false
}
```

## Unlock account

`POST /accounts/v1/:id/unlock`

Success: 202.

This API submits a task to unlock an account and returns the task ID.
To use this endpoint to unlock an account that has the `forceProvisioning` option set to true, the `idn:accounts-provisioning:manage` scope is required.

Body:

```json
{
  "externalVerificationId": "3f9180835d2e5168015d32f890ca1581",
  "unlockIDNAccount": false,
  "forceProvisioning": false
}
```

## Remove account

`POST /accounts/v1/:id/remove`

Success: 202.

Use this endpoint to remove accounts from the system without provisioning changes to the source. Accounts that are removed could be re-created during the next aggregation.

This endpoint is good for:
* Removing accounts that no longer exist on the source.
* Removing accounts that won't be aggregated following updates to the source configuration.
* Forcing accounts to be re-created following the next aggregation to re-run account processing, support testing, etc.

## Enable idn account for identity

`POST /identities-accounts/v1/:id/enable`

Success: 202.

This API submits a task to enable IDN account for a single identity.

## Disable idn account for identity

`POST /identities-accounts/v1/:id/disable`

Success: 202.

This API submits a task to disable IDN account for a single identity.

## Enable idn accounts for identities

`POST /identities-accounts/v1/enable`

Success: 207.

This API submits tasks to enable IDN account for each identity provided in the request body.

Body:

```json
{
  "identityIds": [
    "2c91808384203c2d018437e631158308",
    "2c9180858082150f0180893dbaf553fe"
  ]
}
```

## Disable idn accounts for identities

`POST /identities-accounts/v1/disable`

Success: 207.

This API submits tasks to disable IDN account for each identity provided in the request body.

Body:

```json
{
  "identityIds": [
    "2c91808384203c2d018437e631158308",
    "2c9180858082150f0180893dbaf553fe"
  ]
}
```

# Machine Accounts

14 endpoints. Paths are relative to the environment API host.

## List machine accounts

`GET /machine-accounts/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This returns a list of machine accounts.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, in, sw); nativeIdentity (eq, in, sw); uuid (eq, in); description (eq, in, sw); machineIdentity.id (eq, in); machineIdentity.name (eq, in, sw); subtype.technicalName (eq, in, sw); subtype.displayName (eq, in, sw); accessType (eq, in, sw); environment (eq, in, sw); ownerIdentity (eq, in); ownerIdentity.id (eq, in); ownerIdentity.name (eq, in, sw); manuallyCorrelated (eq); enabled (eq); locked (eq); hasEntitlements (eq); attributes (eq); source.id (eq, in); source.name (eq, in, sw); created (eq, gt, lt, ge, le); modified (eq, gt, lt, ge, le); risk.severity (eq, in); permissionLevel (eq, in); lastUsedAt (gt, lt, ge, le)
- sorters: id, name, nativeIdentity, ownerIdentity, uuid, description, machineIdentity.id, machineIdentity.name, subtype.technicalName, subtype.displayName, accessType, environment, manuallyCorrelated, enabled, locked, hasEntitlements, ownerIdentity.id, ownerIdentity.name, attributes, source.id, source.name, created, modified, risk.severity, permissionLevel, lastUsedAt

## Get machine account details

`GET /machine-accounts/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to return the details for a single machine account by its ID.

## Update machine account details

`PATCH /machine-accounts/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to update machine accounts details.

Body:

```json
[
  {
    "op": "add",
    "path": "/environment",
    "value": "test"
  }
]
```

## Enable machine account

`POST /machine-accounts/v1/:id/enable`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This API submits a task to enable a machine account and returns the task ID.

A caller who owns the machine account can enable it. Other callers need the **idn:mis-account:enable** right.

## Disable machine account

`POST /machine-accounts/v1/:id/disable`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This API submits a task to disable a machine account and returns the task ID.

A caller who owns the machine account can disable it. Other callers need the **idn:mis-account:disable** right.

## Reload machine account

`POST /machine-accounts/v1/:id/reload`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This API asynchronously reloads the machine account directly from the connector and performs a one-time aggregation. It returns the task ID.

A caller who owns the machine account can reload it. Other callers need the **idn:mis-account:reload** right.

## Remove machine account

`POST /machine-accounts/v1/:id/remove`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Use this API to remove a machine account from Identity Security Cloud. The source account is left unchanged, and a removed machine account can be re-created during the next aggregation. The response returns the task ID.

This endpoint is intended for:

* Removing machine accounts that no longer exist on the source.

* Removing machine accounts that will not be aggregated after a source configuration change.

* Forcing machine accounts to be re-created on the next aggregation so account processing can run again.

A caller who owns the machine account can remove it. Other callers need the **idn:mis-account:remove** right.

## Unlock machine account

`POST /machine-accounts/v1/:id/unlock`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This API submits a task to unlock a machine account and returns the task ID.

A caller who owns the machine account can unlock it. Other callers need the **idn:mis-account:unlock** right.

## Retrieve all subtypes by source

`GET /sources/v1/:sourceId/subtypes`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get all machine account subtypes for a given source.

Query:

- standard: `limit`, `offset`, `count`
- filters: displayName (eq, sw); technicalName (eq, sw)
- sorters: displayName, technicalName

## Create subtype

`POST /sources/v1/:sourceId/subtypes`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Create a new machine account subtype for a source.

Body:

```json
{
  "technicalName": "foo",
  "displayName": "Mr Foo",
  "description": "fighters",
  "type": "MACHINE"
}
```

## Retrieve subtype by source and technicalName

`GET /sources/v1/:sourceId/subtypes/:technicalName`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get a machine account subtype by source ID and technical name.

## Patch subtype

`PATCH /sources/v1/:sourceId/subtypes/:technicalName`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Update fields of a machine account subtype by source ID and technical name.
Patchable fields include: `displayName`, `description`.

Body:

```json
[
  {
    "op": "replace",
    "path": "/displayName",
    "value": "Test New DisplayName"
  }
]
```

## Delete subtype

`DELETE /sources/v1/:sourceId/subtypes/:technicalName`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Delete a machine account subtype by source ID and technical name.

## Retrieve subtype by subtype id

`GET /sources/v1/subtypes/:subtypeId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get a machine account subtype by its unique ID.

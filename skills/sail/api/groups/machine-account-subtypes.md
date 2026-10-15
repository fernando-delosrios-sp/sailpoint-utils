# Machine Account Subtypes

Use this API to get, update, and delete machine account subtype for sources.

8 endpoints. Paths are relative to the environment API host.

## Bulk Retrieve of Source Subtypes

`POST /source-subtypes/v1/bulk-retrieve`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint retrieves the subtypes for given subtypeIds.

Body:

```json
[
  "38453251-6be2-5f8f-df93-5ce19e295838"
]
```

## Retrieve all subtypes

`GET /source-subtypes/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get all machine account subtypes.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in, sw); displayName (eq, sw); technicalName (eq, sw); source.id (eq, in)
- sorters: displayName, technicalName

## Create subtype

`POST /source-subtypes/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Create a new machine account subtype.

Body:

```json
{
  "sourceId": "6d0458373bec4b4b80460992b76016da",
  "technicalName": "foo",
  "displayName": "Mr Foo",
  "description": "fighters",
  "type": "MACHINE"
}
```

## Get subtype by ID

`GET /source-subtypes/v1/:subtypeId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get a machine account subtype by subtype ID.

## Patch subtype by ID

`PATCH /source-subtypes/v1/:subtypeId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Update fields of a machine account subtype by subtype ID.
Patchable fields only include: `displayName`, `description`.

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

## Delete subtype by ID

`DELETE /source-subtypes/v1/:subtypeId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Delete a machine account subtype by subtype ID.

Note: If subtype has approval settings or entitlement for machine account creation enablement then it'll be also deleted.

## Machine Subtype Approval Config (GET /source-subtypes/v1/:subtypeId/machine-config)

`GET /source-subtypes/v1/:subtypeId/machine-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint retrieves the approval configuration for machine account creation and deletion at the machine subtype level. By providing a specific subtypeId in the path, clients can fetch the approval rules and settings (such as required approvers and comments policy) that govern account creation and deletion for that particular machine subtype. The response includes a MachineAccountSubtypeConfigDto object detailing these configurations, enabling clients to understand or display the approval workflow required for creating and deleting machine accounts of the given subtype. Use this endpoint to get machine subtype level approval config for account creation and deletion.

## Machine Subtype Approval Config (PATCH /source-subtypes/v1/:subtypeId/machine-config)

`PATCH /source-subtypes/v1/:subtypeId/machine-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Updates the approval configuration for machine account deletion at the specified machine subtype level. This endpoint allows clients to modify approval rules and settings (such as required approvers and comments policy) for account creation and deletion workflows associated with a given subtypeId. Use this to customize or enforce approval requirements for creating and deleting machine accounts of a particular subtype.

Body:

```json
[
  {
    "op": "replace",
    "path": "/machineAccountDelete/approvalConfig/approvers",
    "value": "sourceOwner"
  }
]
```

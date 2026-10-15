# Dimensions

Use this API to implement and customize dynamic role functionality.

8 endpoints. Paths are relative to the environment API host.

## List dimensions

`GET /roles/v1/:roleId/dimensions`

Success: 200.

This API returns a list of dimensions under a specified role.

A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API.

Query:

- standard: `limit`, `offset`, `count`
- `for-subadmin`: If provided, filters the returned list according to what is visible to the indicated ROLE_SUBADMIN Identity. The value of the parameter is either an Identity ID, or the special value **me**, which is shorthand for the calling Identity's…
- filters: id (eq, in); name (eq, sw); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in)
- sorters: name, created, modified

## Create a dimension

`POST /roles/v1/:roleId/dimensions`

Success: 201.

This API creates a dimension.
You must have a token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority to call this API.
Additionally, a ROLE_SUBADMIN cannot create a dimension that includes an access profile or entitlement if that access profile or entitlement is linked to a source that the ROLE_SUBADMIN is not associated with.
The maximum supported length for the description field is 2000 characters.

Body:

```json
{
  "name": "Dimension 2567",
  "owner": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "support"
  },
  "id": "2c918086749d78830174a1a40e121518",
  "description": "Urna amet cursus pellentesque nisl orci maximus lorem nisl euismod fusce morbi placerat adipiscing maecenas nisi tristique et metus et lacus sed morbi nunc nisl maximus magna arcu varius sollicitudin elementum enim maecenas nisi id ipsum tempus fusce diam ipsum tortor.",
  "accessProfiles": [
    {
      "id": "ff808081751e6e129f1518161919ecca",
      "type": "ACCESS_PROFILE",
      "name": "Access Profile 2567"
    },
    {
      "id": "ff808081751e6e129f1518161919ecca",
      "type": "ACCESS_PROFILE",
      "name": "Access Profile 2567"
    }
  ],
  "entitlements": [
    {
      "type": "ENTITLEMENT",
      "id": "2c91809773dee32014e13e122092014e",
      "name": "CN=entitlement.490efde5,OU=OrgCo,OU=ServiceDept,DC=HQAD,DC=local"
    },
    {
      "type": "ENTITLEMENT",
      "id": "2c91809773dee32014e13e122092014e",
      "name": "CN=entitlement.490efde5,OU=OrgCo,OU=ServiceDept,DC=HQAD,DC=local"
    }
  ],
  "membership": {
    "type": "STANDARD",
    "criteria": {
```

Body example truncated.

## Get a dimension under role.

`GET /roles/v1/:roleId/dimensions/:dimensionId`

Success: 200.

This API returns a Dimension by its ID.

A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API. In addition, a token with ROLE_SUBADMIN authority may only call this API if all Access Profiles or Entitlements included in the Dimension or Parent Role are associated to Sources with management workgroups of which the ROLE_SUBADMIN is a member.

## Patch a specified dimension

`PATCH /roles/v1/:roleId/dimensions/:dimensionId`

Success: 200.

This API updates an existing dimension using JSON Patch syntax.
The following fields are patchable: **name** **description** **owner** **accessProfiles** **entitlements** **membership**
A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API. In addition, a token with ROLE_SUBADMIN authority may only call this API if all access profiles/entitlements included in the dimension are associated to Sources with management workgroups of which the ROLE_SUBADMIN is a member.
The maximum supported length for the description field is 2000 characters.
When you use this API to modify a dimension's membership identities, you can only modify up to a limit of 500 membership identities at a time.

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "Test Description"
  },
  {
    "op": "replace",
    "path": "/name",
    "value": "new name"
  }
]
```

## Delete a dimension

`DELETE /roles/v1/:roleId/dimensions/:dimensionId`

Success: 204.

This API deletes a Dimension by its ID.
A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API. In addition, a token with ROLE_SUBADMIN authority may only call this API if all Access Profiles/Entitlements included in the Dimension are associated to Sources with management workgroups of which the ROLE_SUBADMIN is a member.

## Delete dimension(s)

`POST /roles/v1/:roleId/dimensions/bulk-delete`

Success: 202.

This endpoint initiates a bulk deletion of one or more dimensions.
When the request is successful, the endpoint returns the bulk delete's task result ID.  To follow the task, you can use Get Task Status by ID, which will return the task result's status and information.
This endpoint can only bulk delete up to a limit of 50 roles per request.
A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this endpoint. In addition, a token with ROLE_SUBADMIN authority can only call this endpoint if all dimensions included in the request are associated with sources with management workgroups the ROLE_SUBADMIN is a member of.

Body:

```json
{
  "dimensionIds": [
    "2c91808876438bb2017668b91919ecca",
    "2c91808876438ba801766e129f151816"
  ]
}
```

## List dimension's access profiles

`GET /roles/v1/:roleId/dimensions/:dimensionId/access-profiles`

Success: 200.

This API lists the Access Profiles associated with a given Dimension

A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API. In addition, a token with ROLE_SUBADMIN authority may only call this API if all Access Profiles included in the Role are associated to Sources with management workgroups of which the ROLE_SUBADMIN is a member.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, sw); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); source.id (eq, in)
- sorters: name, created, modified

## List dimension's entitlements

`GET /roles/v1/:roleId/dimensions/:dimensionId/entitlements`

Success: 200.

This API lists the Entitlements associated with a given dimension.

A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, sw); attribute (eq, sw); value (eq, sw); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); source.id (eq, in)
- sorters: name, attribute, value, created, modified

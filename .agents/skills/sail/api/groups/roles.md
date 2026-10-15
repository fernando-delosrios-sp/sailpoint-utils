# Roles

Use this API to implement and customize role functionality.

16 endpoints. Paths are relative to the environment API host.

## List roles

`GET /roles/v1`

Success: 200.

This API returns a list of Roles.

A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API.

Query:

- standard: `limit`, `offset`, `count`
- `for-subadmin`: If provided, filters the returned list according to what is visible to the indicated ROLE_SUBADMIN Identity. The value of the parameter is either an Identity ID, or the special value **me**, which is shorthand for the calling Identity's…
- filters: id (eq, in); name (eq, sw); created (gt, ge, le); modified (lt, ge, le); owner.id (eq, in); requestable (eq); dimensional (eq)
- sorters: name, created, modified
- `for-segment-ids`: If present and not empty, additionally filters Roles to those which are assigned to the Segment(s) with the specified IDs. If segmentation is currently unavailable, specifying this parameter results in an error.
- `include-unsegmented`: Whether or not the response list should contain unsegmented Roles. If *for-segment-ids* is absent or empty, specifying *include-unsegmented* as false results in an error.

## Create a role

`POST /roles/v1`

Success: 201.

This API creates a role.

You must have a token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority to call this API.

In addition, a ROLE_SUBADMIN may not create a role including an access profile if that access profile is associated with a source the ROLE_SUBADMIN is not associated with themselves.

The maximum supported length for the description field is 2000 characters. Longer descriptions will be preserved for existing roles. However, any new roles as well as any updates to existing descriptions will be limited to 2000 characters.

Body:

```json
{
  "name": "Role 2567",
  "owner": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "support"
  },
  "id": "2c918086749d78830174a1a40e121518",
  "description": "Urna amet cursus pellentesque nisl orci maximus lorem nisl euismod fusce morbi placerat adipiscing maecenas nisi tristique et metus et lacus sed morbi nunc nisl maximus magna arcu varius sollicitudin elementum enim maecenas nisi id ipsum tempus fusce diam ipsum tortor.",
  "additionalOwners": [
    {
      "type": "IDENTITY",
      "id": "2c9180a46faadee4016fb4e018c20639",
      "name": "support"
    },
    {
      "type": "IDENTITY",
      "id": "2c9180a46faadee4016fb4e018c20639",
      "name": "support"
    }
  ],
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
```

Body example truncated.

## Get a role

`GET /roles/v1/:id`

Success: 200.

This API returns a Role by its ID.
A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API. In addition, a token with ROLE_SUBADMIN authority may only call this API if all Access Profiles included in the Role are associated to Sources with management workgroups of which the ROLE_SUBADMIN is a member.

## Patch a specified role

`PATCH /roles/v1/:id`

Success: 200.

This API updates an existing role using JSON Patch syntax.

The following fields are patchable:

* name
* description
* enabled
* owner
* additionalOwners
* accessProfiles
* entitlements
* membership
* requestable
* accessRequestConfig
* revokeRequestConfig
* segments
* accessModelMetadata
A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API. In addition, a token with ROLE_SUBADMIN authority may only call this API if all access profiles included in the role are associated to Sources with management workgroups of which the ROLE_SUBADMIN is a member.

The maximum supported length for the description field is 2000 characters. Longer descriptions will be preserved for existing roles, however, any new roles as well as any updates to existing descriptions will be limited to 2000 characters.

When you use this API to modify a role's membership identities, you can only modify up to a limit of 500 membership identities at a time.

Body:

```json
[
  {
    "op": "replace",
    "path": "/requestable",
    "value": true
  },
  {
    "op": "replace",
    "path": "/enabled",
    "value": true
  }
]
```

## Delete a role

`DELETE /roles/v1/:id`

Success: 204.

This API deletes a Role by its ID.

A token with API, ORG_ADMIN, ROLE_ADMIN, or ROLE_SUBADMIN authority is required to call this API. In addition, a token with ROLE_SUBADMIN authority may only call this API if all Access Profiles included in the Role are associated to Sources with management workgroups of which the ROLE_SUBADMIN is a member.

## Delete role(s)

`POST /roles/v1/bulk-delete`

Success: 202.

This endpoint initiates a bulk deletion of one or more roles.
When the request is successful, the endpoint returns the bulk delete's task result ID.  To follow the task, you can use Get Task Status by ID, which will return the task result's status and information.
This endpoint can only bulk delete up to a limit of 50 roles per request.
A user with ROLE_SUBADMIN authority can only call this endpoint if all roles included in the request are associated with sources with management workgroups the ROLE_SUBADMIN is a member of.

Body:

```json
{
  "roleIds": [
    "2c91808876438bb2017668b91919ecca",
    "2c91808876438ba801766e129f151816"
  ]
}
```

## List identities assigned a role

`GET /roles/v1/:id/assigned-identities`

Success: 200.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); aliasName (eq, sw); email (eq, sw); name (eq, sw, co)
- sorters: id, name, aliasName, email

## List role's entitlements

`GET /roles/v1/:id/entitlements`

Success: 200.

Get a list of entitlements associated with a specified role.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, sw); attribute (eq, sw); value (eq, sw); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); source.id (eq, in)
- sorters: name, attribute, value, created, modified

## Add a metadata to role.

`POST /roles/v1/:id/access-model-metadata/:attributeKey/values/:attributeValue`

Success: 200.

This API initialize a request to add a single Access Model Metadata to a role by attribute key and attribute value. A token with ORG_ADMIN, ROLE_ADMIN ROLE_SUBADMIN authority is required to call this API. The maximum number of attributes in one role is 25. Custom metadata update, including ADD and REPLACE need suit licensed.

## Remove a metadata from role.

`DELETE /roles/v1/:id/access-model-metadata/:attributeKey/values/:attributeValue`

Success: 202.

This API initialize a request to remove a single Access Model Metadata from a role by attribute key and value. A token with ORG_ADMIN, ROLE_ADMIN ROLE_SUBADMIN authority is required to call this API.

## Bulk-update roles' metadata by id

`POST /roles/v1/access-model-metadata/bulk-update/ids`

Success: 202.

This API initiates a bulk update of metadata for one or more Roles by a list of Role Ids.
A token with ORG_ADMIN, ROLE_ADMIN ROLE_SUBADMIN authority is required to call this API.
The maximum role count in a single update request is 3000. The maximum metadata value count for a single role is 25.
Custom metadata update, including add, replace need suit licensed.

Body:

```json
{
  "roles": [
    "b1db89554cfa431cb8b9921ea38d9367"
  ],
  "operation": "REPLACE",
  "values": [
    {
      "attribute": "iscFederalClassifications",
      "values": [
        "topSecret"
      ]
    }
  ],
  "replaceScope": "ALL"
}
```

## Bulk-update roles' metadata by filters

`POST /roles/v1/access-model-metadata/bulk-update/filter`

Success: 202.

This API initiates a bulk update of metadata for one or more Roles by filter.
A token with ORG_ADMIN, ROLE_ADMIN ROLE_SUBADMIN authority is required to call this API.
The maximum metadata value count for a single role is 25.
Custom metadata update, including add, replace need suit licensed.

Body:

```json
{
  "operation": "ADD",
  "replaceScope": "ALL",
  "filters": "requestable eq false",
  "values": [
    {
      "attribute": "iscFederalClassifications",
      "values": [
        "topSecret"
      ]
    }
  ]
}
```

## Bulk-update roles' metadata by query

`POST /roles/v1/access-model-metadata/bulk-update/query`

Success: 202.

This API initiates a bulk update of metadata for one or more Roles by query.
A token with ORG_ADMIN, ROLE_ADMIN ROLE_SUBADMIN authority is required to call this API.
The maximum metadata value count for a single role is 25.
Custom metadata update, including add, replace need suit licensed.

Body:

```json
{
  "example of a success update": {
    "query": {
      "indices": [
        "roles"
      ],
      "queryType": "TEXT",
      "textQuery": {
        "terms": [
          "test123"
        ],
        "fields": [
          "id"
        ],
        "matchAny": false,
        "contains": true
      },
      "includeNested": false
    },
    "operation": "REPLACE",
    "replaceScope": "ALL",
    "values": [
      {
        "attribute": "iscFederalClassifications",
        "values": [
          "secret"
        ]
      }
    ]
  }
}
```

## Get bulk-update status by id

`GET /roles/v1/access-model-metadata/bulk-update/id`

Success: 202.

This API initial a request for one bulk update's status by bulk update Id returns the status of the bulk update process.
A token with ORG_ADMIN, ROLE_ADMIN ROLE_SUBADMIN authority is required to call this API.

## Get bulk-update statuses

`GET /roles/v1/access-model-metadata/bulk-update`

Success: 200.

This API returns a list of all unfinished bulk update process status of the tenant.

## Filter roles by metadata

`POST /roles/v1/filter`

Success: 200.

This API returns a list of Role that filter by metadata and filter, it support filter by  both path parameter and attribute key and values.
A token with API, ORG_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, HELPDESK, CERT_ADMIN, REPORT_ADMIN or SOURCE_ADMIN  authority is required to call this API.

Query:

- standard: `limit`, `offset`, `count`
- `for-subadmin`: If provided, filters the returned list according to what is visible to the indicated ROLE_SUBADMIN Identity. The value of the parameter is either an Identity ID, or the special value **me**, which is shorthand for the calling Identity's…
- sorters: name, created, modified
- `for-segment-ids`: If present and not empty, additionally filters Roles to those which are assigned to the Segment(s) with the specified IDs. If segmentation is currently unavailable, specifying this parameter results in an error.
- `include-unsegmented`: Whether or not the response list should contain unsegmented Roles. If *for-segment-ids* is absent or empty, specifying *include-unsegmented* as false results in an error.

Body:

```json
{
  "filters": "dimensional eq false",
  "ammKeyValues": [
    {
      "attribute": "iscFederalClassifications",
      "values": [
        "secret"
      ]
    }
  ]
}
```

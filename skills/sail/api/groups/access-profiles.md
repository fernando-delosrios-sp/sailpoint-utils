# Access Profiles

Use this API to implement and customize access profile functionality.

14 endpoints. Paths are relative to the environment API host.

## List access profiles

`GET /access-profiles/v1`

Success: 200.

Get a list of access profiles.
>**Note:** When you filter for access profiles that have the '+' symbol in their names, the response is blank.

Query:

- standard: `limit`, `offset`, `count`
- `for-subadmin`: Filters the returned list according to what is visible to the indicated ROLE_SUBADMIN or SOURCE_SUBADMIN identity. The value of the parameter is either an identity ID or the special value **me**, which is shorthand for the calling…
- filters: id (eq, in); name (eq, sw); created (gt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); requestable (eq); source.id (eq, in)
- sorters: name, created, modified
- `for-segment-ids`: Filters access profiles to only those assigned to the segment(s) with the specified IDs. If segmentation is currently unavailable, specifying this parameter results in an error.
- `include-unsegmented`: Indicates whether the response list should contain unsegmented access profiles. If `for-segment-ids` is absent or empty, specifying *include-unsegmented* as `false` results in an error.

## Create access profile

`POST /access-profiles/v1`

Success: 201.

Create an access profile.
Set `accessRequestConfig.formDefinitionId` to associate an optional custom form with access profile access requests.
A user with `ROLE_SUBADMIN` or `SOURCE_SUBADMIN` authority must be associated with the access profile's source.
The maximum supported length for the description field is 2000 characters. Longer descriptions will be preserved for existing access profiles. However, any new access profiles as well as any updates to existing descriptions are limited to 2000 characters.
>**Note:** To use this endpoint, you need all the listed scopes.

Body:

```json
{
  "owner": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "support"
  },
  "name": "Employee-database-read-write",
  "source": {
    "id": "2c91809773dee3610173fdb0b6061ef4",
    "type": "SOURCE",
    "name": "ODS-AD-SOURCE"
  },
  "description": "Collection of entitlements to read/write the employee database",
  "enabled": true,
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
  "requestable": true,
  "accessRequestConfig": {
    "commentsRequired": true,
    "denialCommentsRequired": true,
    "reauthorizationRequired": true,
    "requireEndDate": true,
    "maxPermittedAccessDuration": {
      "value": 6,
      "timeUnit": "MONTHS"
    },
    "approvalSchemes": [
      {
        "approverType": "GOVERNANCE_GROUP",
        "approverId": "46c79819-a69f-49a2-becb-12c971ae66c6"
      },
      {
```

Body example truncated.

## Get an access profile

`GET /access-profiles/v1/:id`

Success: 200.

This API returns an Access Profile by its ID.
The `accessRequestConfig.formDefinitionId` field associates an optional custom form with access profile access requests.

## Patch a specified access profile

`PATCH /access-profiles/v1/:id`

Success: 200.

This API updates an existing Access Profile. The following fields are patchable:

**name**

**description**

**enabled**

**owner**

**additionalOwners**

**requestable**

**accessRequestConfig**

**revokeRequestConfig**

**segments**

**entitlements**

**provisioningCriteria**

**source** (must be updated with entitlements belonging to new source in the same API call)

If you need to change the `source` of the access profile, you can do so only if you update the `entitlements` in the same API call.  The new entitlements can only come from the target source that you want to change to.  Look for the example "Replace Source" in the examples dropdown.

Set `accessRequestConfig.formDefinitionId` to associate an optional custom form with access profile access requests.

A user with SOURCE_SUBADMIN may only use this API to patch Access Profiles which are associated with Sources they are able to administer.
>  The maximum supported length for the description field is 2000 characters. Longer descriptions will be preserved for existing access profiles, however, any new access profiles as well as any updates to existing descriptions will be limited to 2000 characters.

> You can only add or replace **entitlements** that exist on the source that the access profile is attached to. You can use the **list entitlements** endpoint with the **filters** query parameter to get a list of available entitlements on the access profile's source.

Body:

```json
[
  {
    "op": "add",
    "path": "/entitlements",
    "value": [
      {
        "id": "2c9180857725c14301772a93bb77242d",
        "type": "ENTITLEMENT",
        "name": "AD User Group"
      }
    ]
  }
]
```

## Delete the specified access profile

`DELETE /access-profiles/v1/:id`

Success: 204.

This API deletes an existing Access Profile.

The Access Profile must not be in use, for example, Access Profile can not be deleted if they belong to an Application, Life Cycle State or a Role. If it is, a 400 error is returned.

A user with SOURCE_SUBADMIN must be able to administer the Source associated with the Access Profile.

## Delete access profile(s)

`POST /access-profiles/v1/bulk-delete`

Success: 200, 202.

This endpoint initiates a bulk deletion of one or more access profiles.
When the request is successful, the endpoint returns the bulk delete's task result ID.  To follow the task, you can use Get Task Status by ID, which will return the task result's status and information.
This endpoint can only bulk delete up to a limit of 50 access profiles per request.
By default, if any of the indicated access profiles are in use, no deletions will be performed and the **inUse** field of the response indicates the usages that must be removed first. If the request field **bestEffortOnly** is **true**, however, usages are reported in the **inUse** response field but all other indicated access profiles will be deleted.
A SOURCE_SUBADMIN user can only use this endpoint to delete access profiles associated with sources they're able to administer.

Body:

```json
{
  "bestEffortOnly": true,
  "accessProfileIds": [
    "2c91808876438bb2017668b91919ecca",
    "2c91808876438ba801766e129f151816"
  ]
}
```

## List access profile's entitlements

`GET /access-profiles/v1/:id/entitlements`

Success: 200.

Use this API to get a list of an access profile's entitlements.
A SOURCE_SUBADMIN user must have access to the source associated with the specified access profile.
>**Note:** When you filter for access profiles that have the '+' symbol in their names, the response is blank.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, sw); attribute (eq, sw); value (eq, sw); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); source.id (eq, in)
- sorters: name, attribute, value, created, modified

## Update access profile(s) requestable field.

`POST /access-profiles/v1/bulk-update-requestable`

Success: 207.

This API initiates a bulk update of field requestable for one or more Access Profiles.

>  If any of the indicated Access Profiles is exists in Organization,then those Access Profiles will be added in **updated**
    list of the response.Requestable field of these Access Profiles marked as **true** or **false**.

>  If any of the indicated Access Profiles is not does not exists in Organization,then those Access Profiles will be added in **notFound** list of the response. Access Profiles marked as **notFound** will not be updated.
 A SOURCE_SUBADMIN may only use this API to update Access Profiles which are associated with Sources they are able to administer.

Body:

```json
[
  {
    "id": "464ae7bf-791e-49fd-b746-06a2e4a89635",
    "requestable": false
  }
]
```

## Add metadata to access profile

`POST /access-profiles/v1/:id/access-model-metadata/:attributeKey/values/:attributeValue`

Success: 200.

This API adds a single Access Model Metadata value to an access profile by attribute key and attribute value. A single access profile cannot be assigned more than 25 metadata values. Adding custom metadata requires a suite license.

## Remove metadata from access profile

`DELETE /access-profiles/v1/:id/access-model-metadata/:attributeKey/values/:attributeValue`

Success: 202.

This API removes a single Access Model Metadata value from an access profile by attribute key and attribute value.

## Bulk-update metadata by ids

`POST /access-profiles/v1/access-model-metadata/bulk-update/ids`

Success: 202.

This API initiates a bulk update of Access Model Metadata for one or more access profiles by a list of access profile IDs.

The update is processed asynchronously. The response returns the ID of the task performing the update.

The maximum access profile count in a single request is 3000. A single access profile cannot be assigned more than 25 metadata values. Adding or replacing custom metadata requires a suite license.

Body:

```json
{
  "accessProfiles": [
    "b1db89554cfa431cb8b9921ea38d9367"
  ],
  "operation": "REPLACE",
  "replaceScope": "ATTRIBUTE",
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

## Bulk-update metadata by filter

`POST /access-profiles/v1/access-model-metadata/bulk-update/filter`

Success: 202.

This API initiates a bulk update of Access Model Metadata for every access profile matching the supplied filter expression.

The update is processed asynchronously. The response returns the ID of the task performing the update.

A single access profile cannot be assigned more than 25 metadata values. Adding or replacing custom metadata requires a suite license.

Body:

```json
{
  "filters": "requestable eq false",
  "operation": "REPLACE",
  "replaceScope": "ATTRIBUTE",
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

## Bulk-update metadata by query

`POST /access-profiles/v1/access-model-metadata/bulk-update/query`

Success: 202.

This API initiates a bulk update of Access Model Metadata for every access profile matching the supplied search query.

The update is processed asynchronously. The response returns the ID of the task performing the update.

A single access profile cannot be assigned more than 25 metadata values. Adding or replacing custom metadata requires a suite license.

Body:

```json
{
  "query": {
    "indices": [
      "accessprofiles"
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
  "replaceScope": "ATTRIBUTE",
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

## Filter access profiles by metadata

`POST /access-profiles/v1/filter`

Success: 200.

Get a list of access profiles filtered by Access Model Metadata and by filter expression. Filtering is supported by filter expression, by metadata attribute key and values, or by both together.

Query:

- standard: `limit`, `offset`, `count`
- `for-subadmin`: Filters the returned list according to what is visible to the indicated ROLE_SUBADMIN or SOURCE_SUBADMIN identity. The value of the parameter is either an identity ID or the special value **me**, which is shorthand for the calling…
- sorters: name, created, modified
- `for-segment-ids`: Filters the returned list to those access profiles assigned to the specified segment IDs.
- `include-unsegmented`: Whether the returned list includes unsegmented access profiles.

Body:

```json
{
  "filters": "requestable eq false",
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

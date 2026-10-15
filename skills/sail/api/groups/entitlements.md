# Entitlements

16 endpoints. Paths are relative to the environment API host.

## Gets a list of entitlements.

`GET /entitlements/v1`

Success: 200.

This API returns a list of entitlements. Any authenticated token can call this API.

Query:

- standard: `limit`, `offset`, `count`
- `segmented-for-identity`: If present and not empty, additionally filters Entitlements to those which are assigned to the Segment(s) which are visible to the Identity with the specified ID.
- `for-segment-ids`: If present and not empty, additionally filters Access Profiles to those which are assigned to the Segment(s) with the specified IDs.
- `include-unsegmented`: Whether or not the response list should contain unsegmented Entitlements. If **for-segment-ids** and **segmented-for-identity** are both absent or empty, specifying **include-unsegmented=false** results in an error.
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. This is used to expand the…
- sorters: id, name, created, modified, type, attribute, value, source.id, requestable
- filters: id (eq, in); name (eq, in, sw); type (eq, in); attribute (eq, in); value (eq, in, sw); source.id (eq, in); requestable (eq); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); tags (eq); privilegeLevel.direct (eq)

## Get entitlements for an account

`GET /entitlements/v1/account/:accountId/entitlements`

Success: 200.

This API returns a list of all entitlements associated with the given account ID. The account must exist; if not found, the API returns 404.

Query:

- standard: `limit`, `offset`, `count`
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. This is used to expand the…
- sorters: id, name, created, modified, type, attribute, value, source.id, requestable

## Bulk update an entitlement list

`POST /entitlements/v1/bulk-update`

Success: 204.

This API applies an update to every entitlement of the list.

The number of entitlements to update is limited to 50 items maximum.

The JsonPatch update follows the JSON Patch standard.
examples of allowed operations :
`**{ "op": "replace", "path": "/requestable","value": boolean }**`
`**{ "op": "replace", "path": "/privilegeOverride/level","value": string }**`

A token with ORG_ADMIN or API authority is required to call this API.

Body:

```json
{
  "entitlementIds": [
    "2c91808a7624751a01762f19d665220d",
    "2c91808a7624751a01762f19d67c220e",
    "2c91808a7624751a01762f19d692220f"
  ],
  "jsonPatch": [
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    },
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    }
  ]
}
```

## Get an entitlement

`GET /entitlements/v1/:id`

Success: 200.

This API returns an entitlement by its ID.

## Patch an entitlement

`PATCH /entitlements/v1/:id`

Success: 200.

This API updates an existing entitlement using JSON Patch syntax.

The following fields are patchable: **requestable**, **segments**, **privilegeOverride/level**, **owner**, **name**, **description**, **manuallyUpdatedFields**, and **accessModelMetadata**

When you're patching owner, only owner type and owner id must be provided. Owner name is optional, and it won't be modified. If the owner name is provided, it should correspond to the real name. The only owner type currently supported is IDENTITY.

When you're patching **accessModelMetadata**, each attribute's **key** must match the key of an existing access model metadata attribute, and each **value** must be one of the values configured for that key. Use List access model metadata attributes to look up the available keys and values.

Body:

```json
[
  {
    "op": "replace",
    "path": "/requestable",
    "value": true
  }
]
```

## List of entitlements parents

`GET /entitlements/v1/:id/parents`

Success: 200.

This API returns a list of all parent entitlements of a given entitlement.

Query:

- standard: `limit`, `offset`, `count`
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. This is used to expand the…
- sorters: id, name, created, modified, type, attribute, value, source.id, requestable
- filters: id (eq, in); name (eq, in, sw); type (eq, in); attribute (eq, in); value (eq, in, sw); source.id (eq, in); requestable (eq); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); tags (eq); privilegeLevel.direct (eq)

## List of entitlements children

`GET /entitlements/v1/:id/children`

Success: 200.

This API returns a list of all child entitlements of a given entitlement.

Query:

- standard: `limit`, `offset`, `count`
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. This is used to expand the…
- sorters: id, name, created, modified, type, attribute, value, source.id, requestable
- filters: id (eq, in); name (eq, in, sw); type (eq, in); attribute (eq, in); value (eq, in, sw); source.id (eq, in); requestable (eq); created (gt, lt, ge, le); modified (gt, lt, ge, le); owner.id (eq, in); tags (eq); privilegeLevel.direct (eq)

## Get entitlement request config

`GET /entitlements/v1/:id/entitlement-request-config`

Success: 200.

This API returns the entitlement request config for a specified entitlement.
The `accessRequestConfig.formDefinitionId` field associates an optional custom form with entitlement access requests.

## Replace entitlement request config

`PUT /entitlements/v1/:id/entitlement-request-config`

Success: 200.

This API replaces the entitlement request config for a specified entitlement.
Set `accessRequestConfig.formDefinitionId` to associate an optional custom form with entitlement access requests.

Body:

```json
{
  "accessRequestConfig": {
    "requestCommentRequired": true,
    "denialCommentRequired": true,
    "approvalSchemes": [
      {
        "approverType": "ENTITLEMENT_OWNER"
      },
      {
        "approverType": "GOVERNANCE_GROUP",
        "approverId": "46c79819-a69f-49a2-becb-12c971ae66c6"
      }
    ]
  },
  "revocationRequestConfig": {
    "approvalSchemes": []
  }
}
```

## Reset source entitlements

`POST /entitlements/v1/reset/sources/:id`

Success: 202.

Remove all entitlements from a specific source.
To reload the accounts along with the entitlements you removed, you must run an unoptimized aggregation.  To do so, use Account Aggregation with `disableOptimization` = `true`.

## Add metadata to an entitlement.

`POST /entitlements/v1/:id/access-model-metadata/:attributeKey/values/:attributeValue`

Success: 201.

Add single Access Model Metadata to an entitlement.

## Remove metadata from an entitlement.

`DELETE /entitlements/v1/:id/access-model-metadata/:attributeKey/values/:attributeValue`

Success: 200.

Remove single Access Model Metadata from an entitlement.

## Bulk-update metadata by ids

`POST /entitlements/v1/access-model-metadata/bulk-update/ids`

Success: 202.

This API initiates a bulk update of Access Model Metadata for one or more entitlements by a list of entitlement IDs.

The update is processed asynchronously. The response returns the ID of the task performing the update.

The maximum entitlement count in a single request is 3000. Adding or replacing custom metadata requires a suite license.

This API replaces the deprecated `updateAccessModelMetadataByIdsV1` operation.

Body:

```json
{
  "entitlements": [
    "2c9180867817ac4d017817c491119a20"
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

`POST /entitlements/v1/access-model-metadata/bulk-update/filter`

Success: 202.

This API initiates a bulk update of Access Model Metadata for every entitlement matching the supplied filter expression.

The update is processed asynchronously. The response returns the ID of the task performing the update.

Adding or replacing custom metadata requires a suite license.

This API replaces the deprecated `updateAccessModelMetadataByFilterV1` operation.

Body:

```json
{
  "filters": "id eq 2c9180867817ac4d017817c491119a20",
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

`POST /entitlements/v1/access-model-metadata/bulk-update/query`

Success: 202.

This API initiates a bulk update of Access Model Metadata for every entitlement matching the supplied search query.

The update is processed asynchronously. The response returns the ID of the task performing the update.

Adding or replacing custom metadata requires a suite license.

This API replaces the deprecated `updateAccessModelMetadataByQueryV1` operation.

Body:

```json
{
  "query": {
    "indices": [
      "entitlements"
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

## Aggregate entitlements

`POST /entitlements/v1/aggregate/sources/:id`

Success: 202.

Starts an entitlement aggregation on the specified source. Though this endpoint has been deprecated, you can find its Beta equivalent here.

If the target source is a direct connection, then the request body must be empty. You will also need to make sure the Content-Type header is not set. If you set the Content-Type header without specifying a body, then you will receive a 500 error.

If the target source is a delimited file source, then the CSV file needs to be included in the request body. You will also need to set the Content-Type header to `multipart/form-data`.

# Access Model Metadata

Use this API to create and manage metadata attributes for your Access Model.

13 endpoints. Paths are relative to the environment API host.

## List access model metadata attributes

`GET /access-model-metadata/v1/attributes`

Success: 200.

Get a list of Access Model Metadata Attributes. Supports pagination through limit and offset parameters.

Query:

- standard: `limit`, `offset`, `count`
- filters: key (eq, co); name (eq, co); type (eq); status (eq); objectTypes (eq)
- sorters: key, name, type, status

## Create access model metadata attribute

`POST /access-model-metadata/v1/attributes`

Success: 201.

Create a new Access Model Metadata Attribute.

The **isAdhoc** field can be set on creation to indicate whether the Attribute supports ad-hoc
(dynamically created) values in addition to static values; if omitted, it defaults to *false*.

Any **values** provided at creation time must each have a *type* of *static* (or omit/leave *type*
blank); *adhoc* is not an allowed value on this public API and results in a *400* error. Ad-hoc
values are created dynamically through an internal service-to-service flow, not through this API.

Body:

```json
{
  "key": "iscPrivacy",
  "name": "Privacy",
  "multiselect": false,
  "isAdhoc": true,
  "type": "custom",
  "objectTypes": [
    "all"
  ],
  "description": "Specifies the level of privacy associated with an access item.",
  "values": [
    {
      "value": "public",
      "name": "Public",
      "status": "active",
      "type": "static"
    }
  ]
}
```

## Get access model metadata attribute

`GET /access-model-metadata/v1/attributes/:key`

Success: 200.

Get single Access Model Metadata Attribute

## Update access model metadata attribute

`PATCH /access-model-metadata/v1/attributes/:key`

Success: 200.

Update an existing Access Model Metadata Attribute.
The following fields are patchable: **name**, **description**, **multiselect**, **isAdhoc**, **values**

Body:

```json
[
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
```

## Delete access model metadata attribute

`DELETE /access-model-metadata/v1/attributes/:key`

Success: 200.

Delete an existing Access Model Metadata Attribute and all of its values.

## List access model metadata values

`GET /access-model-metadata/v1/attributes/:key/values`

Success: 200.

Get a list of Access Model Metadata Attribute Values. Supports pagination through limit and offset parameters.

Query:

- standard: `limit`, `offset`, `count`
- filters: value (eq, co); name (eq, co); status (eq); type (eq)
- sorters: value, name, status, type

## Create access model metadata value

`POST /access-model-metadata/v1/attributes/:key/values`

Success: 201.

Create a new value for an existing Access Model Metadata Attribute.

The **type** field must be omitted, blank, or *static* (case-insensitive); *adhoc* is not an
allowed value on this public API and results in a *400* error. Ad-hoc values are created
dynamically through an internal service-to-service flow when the parent Attribute has *isAdhoc*
set to *true*, not through this API.

Body:

```json
{
  "value": "public",
  "name": "Public",
  "status": "active",
  "type": "static"
}
```

## Get access model metadata value

`GET /access-model-metadata/v1/attributes/:key/values/:value`

Success: 200.

Get single Access Model Metadata Attribute Value

## Update access model metadata value

`PATCH /access-model-metadata/v1/attributes/:key/values/:value`

Success: 200.

Update an existing Access Model Metadata Attribute Value.
The following fields are patchable: **name**

Body:

```json
[
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
```

## Delete access model metadata value

`DELETE /access-model-metadata/v1/attributes/:key/values/:value`

Success: 200.

Delete an existing Access Model Metadata Attribute Value.

## Metadata Attribute update by filter

`POST /access-model-metadata/v1/bulk-update/filter`

Success: 200.

Bulk update Access Model Metadata Attribute Values using a filter

Body:

```json
{
  "filters": "id eq 2c9180867817ac4d017817c491119a20",
  "operation": "REMOVE",
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

## Metadata Attribute update by query

`POST /access-model-metadata/v1/bulk-update/query`

Success: 200.

Bulk update Access Model Metadata Attribute Values using a query

Body:

```json
{
  "query": {
    "indices": [
      "identities"
    ],
    "queryType": "SAILPOINT",
    "queryVersion": "5.2",
    "query": {
      "query": "name:a*",
      "fields": "string",
      "timeZone": "America/Chicago",
      "innerHit": {
        "query": "source.name:\\\"Active Directory\\\"",
        "type": "access"
      }
    },
    "queryDsl": {
      "match": {
        "name": "john.doe"
      }
    },
    "textQuery": {
      "terms": [
        "The quick brown fox",
        "3141592",
        "7"
      ],
      "fields": [
        "displayName",
        "employeeNumber",
        "roleCount"
      ],
      "matchAny": false,
      "contains": true
    },
    "typeAheadQuery": {
      "query": "Work",
      "field": "source.name",
      "nestedType": "access",
      "maxExpansions": 10,
      "size": 100,
      "sort": "asc",
      "sortByValue": true
    },
    "includeNested": true,
    "queryResultFilter": {
      "includes": [
        "name",
        "displayName"
      ],
      "excludes": [
        "stacktrace"
      ]
    },
    "aggregationType": "DSL",
    "aggregationsVersion": "5.2",
    "aggregationsDsl": {},
    "aggregations": {
      "nested": {
```

Body example truncated.

## Metadata Attribute update by ids

`POST /access-model-metadata/v1/bulk-update/ids`

Success: 200.

Bulk update Access Model Metadata Attribute Values using ids.

Body:

```json
{
  "entitlements": [
    "2c9180867817ac4d017817c491119a20",
    "2c9180867817ac4d017817c491119a21"
  ],
  "operation": "ADD",
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

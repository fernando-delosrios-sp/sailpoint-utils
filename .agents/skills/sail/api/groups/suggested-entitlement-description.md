# Suggested Entitlement Description

Use this API to implement Suggested Entitlement Description (SED) functionality.

15 endpoints. Paths are relative to the environment API host.

## Get auto-write settings for SED

`GET /suggested-entitlement-descriptions/v1/auto-write-settings`

Success: 200.

Get the current auto-write configuration for the tenant, including the enabled state and source include/exclude lists.

## Create auto-write settings for SED

`POST /suggested-entitlement-descriptions/v1/auto-write-settings`

Success: 201.

Create the initial auto-write settings for a tenant. Returns 409 Conflict if settings already exist. Use PATCH to update existing settings.

Body:

```json
{
  "enabled": true,
  "includedSourceIds": [
    "2c91808a7813090a017814552e526349",
    "2c91808a7813090a017814552e52634a"
  ],
  "excludedSourceIds": [
    "2c91808a7813090a017814552e526350"
  ]
}
```

## Update auto-write settings for SED

`PATCH /suggested-entitlement-descriptions/v1/auto-write-settings`

Success: 200.

Partially update the auto-write settings for a tenant using JSON Patch operations. Only the "replace" operation is supported. Returns 404 if no settings exist yet - use POST to create them first.

Body:

```json
[
  {
    "op": "replace",
    "path": "/enabled",
    "value": true
  },
  {
    "op": "replace",
    "path": "/enabled",
    "value": true
  }
]
```

## List pending entitlement recommendation approvals

`GET /entitlement-recommendations/v1/pending-approvals`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a list of entitlement recommendations (SED and/or privilege) that are currently awaiting review or approval. Each record includes the recommendation type, entitlement details, and any AI-generated suggestions.

Query:

- standard: `limit`, `offset`

## List privileged entitlement recommendations

`GET /privileged-recommendations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a list of privileged entitlement recommendation groups. Each group aggregates individual entitlement instances that share the same entitlement name and connector type, along with a recommendation score and instance count.

Query:

- standard: `limit`, `offset`

## Bulk approve entitlement recommendations

`POST /entitlement-recommendations/v1/bulk-approve`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Approve multiple entitlement recommendations in a single request. Each item in the request must include the recommendation ID and, depending on the record type, either an approved description (SED items) or an approved privilege level (privilege items). Returns a per-item result indicating success or failure.

Body:

```json
{
  "items": [
    {
      "id": "79db50d4-723c-4aa0-a824-83c2205d82d1",
      "recordType": "SED",
      "description": "Provides access and permissions related to the Delinea Secret Server Cloud system.",
      "privilegeLevel": "high"
    },
    {
      "id": "79db50d4-723c-4aa0-a824-83c2205d82d1",
      "recordType": "SED",
      "description": "Provides access and permissions related to the Delinea Secret Server Cloud system.",
      "privilegeLevel": "high"
    }
  ]
}
```

## Assign entitlement recommendations for review

`POST /entitlement-recommendations/v1/assign`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Assign a set of entitlement recommendation records to a reviewer. The assignee can be a specific identity, a governance group, or a role-based assignee such as source owner or entitlement owner. Returns a batch ID that can be used to track the assignment.

Body:

```json
{
  "items": [
    "79db50d4-723c-4aa0-a824-83c2205d82d1",
    "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  ],
  "assignee": {
    "type": "IDENTITY",
    "value": "2c91808a7f3b2e8a017f3c3e5f6d0099"
  }
}
```

## Update an entitlement recommendation

`PATCH /entitlement-recommendations/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Partially update a single entitlement recommendation record by its ID. Use this endpoint to update the status, description, or privilege level of a specific SED or privilege recommendation.

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

## Submit sed batch stats request

`GET /suggested-entitlement-description-batches/v1/:batchId/stats`

Success: 200.

'Submit Sed Batch Stats Request.

 Submits batchId in the path param `(e.g. {batchId}/stats)`. API responses with stats
 of the batchId.'

## List Sed Batch Record

`GET /suggested-entitlement-description-batches/v1`

Success: 200.

List Sed Batches.
API responses with Sed Batch Records

Query:

- standard: `limit`, `offset`, `count`
- `count-only`: If `true` it will populate the `X-Total-Count` response header with the number of results that would be returned if `limit` and `offset` were ignored. This parameter differs from the count parameter in that this one skips executing the…
- `status`: Batch Status

## Submit sed batch request

`POST /suggested-entitlement-description-batches/v1`

Success: 200.

Submit Sed Batch Request.
Request body has one of the following: - a list of entitlement Ids - a list of SED Ids that user wants to have description generated by LLM.  API responses with batchId that groups Ids together

Body:

```json
{
  "entitlements": [
    "016629d1-1d25-463f-97f3-c6686846650"
  ],
  "seds": [
    "016629d1-1d25-463f-97f3-c6686846650"
  ],
  "searchCriteria": {
    "key_0": {
      "indices": [
        "entitlements"
      ],
      "filters": {
        "status": {
          "type": "TERMS",
          "terms": [
            "active",
            "inactive"
          ]
        }
      },
      "query": {
        "query": "status:active"
      },
      "queryType": "TEXT",
      "textQuery": {
        "terms": [
          "admin",
          "user"
        ],
        "fields": [
          "role",
          "name"
        ],
        "matchAny": true
      },
      "includeNested": true,
      "sort": [
        "name:asc",
        "createdAt:desc"
      ],
      "searchAfter": [
        "12345",
        "67890"
      ]
    },
    "key_1": {
      "indices": [
        "entitlements"
      ],
      "filters": {
        "status": {
          "type": "TERMS",
          "terms": [
            "active",
            "inactive"
          ]
        }
      },
      "query": {
        "query": "status:active"
      },
      "queryType": "TEXT",
      "textQuery": {
        "terms": [
          "admin",
```

Body example truncated.

## Submit bulk approval request

`POST /suggested-entitlement-description-approvals/v1`

Success: 200.

Submit Bulk Approval Request for SED.
Request body takes list of SED Ids. API responses with list of SED Approval Status

Body:

```json
[
  {
    "items": [
      "0f631764-850d-2d43-70c2-451a6af06d16",
      "559ad27c-a91f-c246-ddd7-408841f48a49"
    ]
  },
  {
    "items": [
      "84ffad6a-9b38-5ef5-c6e9-d4cc57fb0891",
      "44c6430b-c69b-cfd4-dfcb-099223884c6b"
    ]
  }
]
```

## Submit sed assignment request

`POST /suggested-entitlement-description-assignments/v1`

Success: 202.

Submit Assignment Request.
Request body has an assignee, and list of SED Ids that are assigned to that assignee API responses with batchId that groups all approval requests together

Body:

```json
{
  "assignee": {
    "type": "SOURCE_OWNER",
    "value": "016629d1-1d25-463f-97f3-c6686846650"
  },
  "items": [
    "f935a388-75a4-b6b4-92d8-5b9d7f5aafb3",
    "3045216b-0e57-ede1-091d-188e4a702a05"
  ]
}
```

## List suggested entitlement descriptions

`GET /suggested-entitlement-descriptions/v1`

Success: 200.

List of Suggested Entitlement Descriptions (SED)

SED field descriptions:

**batchId**: the ID of the batch of entitlements that are submitted for description generation

**displayName**: the display name of the entitlement that we are generating a description for

**sourceName**: the name of the source associated with the entitlement that we are generating the description for

**sourceId**: the ID of the source associated with the entitlement that we are generating the description for

**status**: the status of the suggested entitlement description, valid status options: "requested", "suggested", "not_suggested", "failed", "assigned", "approved", "denied"

**fullText**: will filter suggested entitlement description records by text found in any of the following fields: entitlement name, entitlement display name, suggested description, source name

Query:

- standard: `limit`, `offset`, `count`
- filters: batchId (eq, ne); displayName (eq, ne, co); sourceName (eq, ne, co); sourceId (eq, ne); status (eq, ne); fullText (co)
- sorters: displayName, sourceName, status
- `count-only`: If `true` it will populate the `X-Total-Count` response header with the number of results that would be returned if `limit` and `offset` were ignored. This parameter differs from the count parameter in that this one skips executing the…
- `requested-by-anyone`: By default, the ListSeds API will only return items that you have requested to be generated. This option will allow you to see all items that have been requested
- `show-pending-status-only`: Will limit records to items that are in "suggested" or "approved" status

## Patch suggested entitlement description

`PATCH /suggested-entitlement-descriptions/v1`

Success: 200.

Patch Suggested Entitlement Description

Body:

```json
[
  {
    "op": "replace",
    "path": "status",
    "value": "approved"
  },
  {
    "op": "replace",
    "path": "status",
    "value": "approved"
  }
]
```

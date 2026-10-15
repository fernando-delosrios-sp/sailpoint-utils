# Data Segmentation

This service is responsible for creating segments that will determine how access is delegated to identities withing the organization.

8 endpoints. Paths are relative to the environment API host.

## Get segmentmembership by identity id

`GET /data-segments/v1/membership/:identityId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the segment membership specified by the given identity ID.

## Is segmentation enabled by identity

`GET /data-segments/v1/user-enabled/:identityId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns whether or not segmentation is enabled for the identity.

## Get segment by id

`GET /data-segments/v1/:segmentId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the segment specified by the given ID.

## Publish segment by id

`POST /data-segments/v1/:segmentId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This will publish the segment so that it starts applying the segmentation to the desired users if enabled

Query:

- `publishAll`: This flag decides whether you want to publish all unpublished or a list of specific segment ids

Body:

```json
[
  "string",
  "string"
]
```

## Update segment

`PATCH /data-segments/v1/:segmentId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to update segment fields by using the JSON Patch standard.

Body:

```json
[
  {
    "op": "replace",
    "path": "/memberFilter",
    "value": {
      "expression": {
        "operator": "AND",
        "children": [
          {
            "operator": "EQUALS",
            "attribute": "location",
            "value": {
              "type": "STRING",
              "value": "Philadelphia"
            }
          },
          {
            "operator": "EQUALS",
            "attribute": "department",
            "value": {
              "type": "STRING",
              "value": "HR"
            }
          }
        ]
      }
    }
  }
]
```

## Delete segment by id

`DELETE /data-segments/v1/:segmentId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This API deletes the segment specified by the given ID.

Query:

- `published`: This determines which version of the segment to delete

## Get segments

`GET /data-segments/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the segment specified by the given ID.

Query:

- standard: `limit`, `offset`, `count`
- `enabled`: This boolean indicates whether the segment is currently active. Inactive segments have no effect.
- `unique`: This returns only one record if set to true and that would be the published record if exists.
- `published`: This boolean indicates whether the segment is being applied to the accounts. If unpublished its being actively modified until published
- filters: id (eq, in, sw); name (eq, in, sw)

## Create segment

`POST /data-segments/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This API creates a segment.
>**Note:** Segment definitions may take time to propagate to all identities.

Body:

```json
{
  "id": "0f11f2a4-7c94-4bf3-a2bd-742580fe3bde",
  "name": "segment-xyz",
  "created": "2020-01-01T00:00:00.000000Z",
  "modified": "2020-01-01T00:00:00.000000Z",
  "description": "This segment represents xyz",
  "scopes": [
    {
      "scope": "ENTITLEMENT",
      "visibility": "ALL",
      "scopeFilter": {
        "expression": {
          "operator": "EQUALS",
          "attribute": "location",
          "value": {
            "type": "STRING",
            "value": "Austin"
          }
        }
      },
      "scopeSelection": [
        {
          "type": "IDENTITY"
        },
        {
          "type": "IDENTITY"
        }
      ]
    },
    {
      "scope": "IDENTITY",
      "visibility": "ALL",
      "scopeFilter": {
        "expression": {
          "operator": "EQUALS",
          "attribute": "location",
          "value": {
            "type": "STRING",
            "value": "Austin"
          }
        }
      },
      "scopeSelection": [
        {
          "type": "IDENTITY"
        },
        {
          "type": "IDENTITY"
        }
      ]
    }
  ],
  "memberSelection": [
    {
      "type": "IDENTITY"
    },
    {
      "type": "IDENTITY"
    }
  ],
```

Body example truncated.

# Segments

Use this API to implement and customize access request segment functionality.

5 endpoints. Paths are relative to the environment API host.

## Create segment

`POST /segments/v1`

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
  "owner": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "support"
  },
  "visibilityCriteria": {
    "expression": {
      "operator": "EQUALS",
      "attribute": "location",
      "value": {
        "type": "STRING",
        "value": "Austin"
      }
    }
  },
  "active": true
}
```

## List segments

`GET /segments/v1`

Success: 200.

This API returns a list of all segments.

Query:

- standard: `limit`, `offset`, `count`

## Get segment by id

`GET /segments/v1/:id`

Success: 200.

This API returns the segment specified by the given ID.

## Delete segment by id

`DELETE /segments/v1/:id`

Success: 204.

This API deletes the segment specified by the given ID.
>**Note:** that segment deletion may take some time to become effective.

## Update segment

`PATCH /segments/v1/:id`

Success: 200.

Use this API to update segment fields by using the JSON Patch standard.
>**Note:** Changes to a segment may take some time to propagate to all identities.

Body:

```json
[
  {
    "op": "replace",
    "path": "/visibilityCriteria",
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

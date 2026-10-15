# Scheduled Search

Use this API to implement scheduled search functionality.

6 endpoints. Paths are relative to the environment API host.

## Create a new scheduled search

`POST /scheduled-searches/v1`

Success: 201.

Creates a new scheduled search.

Body:

```json
{
  "savedSearchId": "9c620e13-cd33-4804-a13d-403bd7bcdbad",
  "schedule": {
    "type": "DAILY",
    "hours": {
      "type": "LIST",
      "values": [
        "9"
      ]
    }
  },
  "recipients": [
    {
      "type": "IDENTITY",
      "id": "2c9180867624cbd7017642d8c8c81f67"
    }
  ]
}
```

## List scheduled searches

`GET /scheduled-searches/v1`

Success: 200.

Returns a list of scheduled searches.

Query:

- standard: `limit`, `offset`, `count`
- filters: owner.id (eq); savedSearchId (eq)

## Update an existing scheduled search

`PUT /scheduled-searches/v1/:id`

Success: 200.

Updates an existing scheduled search.

Body:

```json
{
  "recipients": [
    {
      "type": "IDENTITY",
      "id": "2c9180867624cbd7017642d8c8c81f67"
    },
    {
      "type": "IDENTITY",
      "id": "2c9180867624cbd7017642d8c8c81f67"
    }
  ],
  "savedSearchId": "554f1511-f0a1-4744-ab14-599514d3e57c",
  "schedule": {
    "type": "WEEKLY",
    "hours": {
      "type": "RANGE",
      "values": [
        "9",
        "18"
      ],
      "interval": 3
    },
    "months": {
      "type": "LIST",
      "values": [
        "3",
        "6",
        "9",
        "12"
      ]
    },
    "days": {
      "type": "LIST",
      "values": [
        "MON",
        "WED",
        "FRI"
      ]
    },
    "expiration": "2018-06-25T20:22:28.104Z",
    "timeZoneId": "America/Chicago"
  },
  "name": "Daily disabled accounts",
  "description": "Daily disabled accounts",
  "created": "2018-06-25T20:22:28.104Z",
  "modified": "2018-06-25T20:22:28.104Z",
  "enabled": false,
  "emailEmptyResults": false,
  "displayQueryDetails": false
}
```

## Get a scheduled search

`GET /scheduled-searches/v1/:id`

Success: 200.

Returns the specified scheduled search.

## Delete a scheduled search

`DELETE /scheduled-searches/v1/:id`

Success: 204.

Deletes the specified scheduled search.

## Unsubscribe a recipient from scheduled search

`POST /scheduled-searches/v1/:id/unsubscribe`

Success: 204.

Unsubscribes a recipient from the specified scheduled search.

Body:

```json
{
  "type": "IDENTITY",
  "id": "2c91808568c529c60168cca6f90c1313"
}
```

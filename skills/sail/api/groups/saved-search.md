# Saved Search

Use this API to implement saved search functionality.

6 endpoints. Paths are relative to the environment API host.

## Create a saved search

`POST /saved-searches/v1`

Success: 201.

Creates a new saved search.

Body:

```json
{
  "indices": [
    "identities"
  ],
  "query": "@accounts(disabled:true)",
  "name": "Disabled accounts",
  "description": "Disabled accounts",
  "created": "2018-06-25T20:22:28.104Z",
  "modified": "2018-06-25T20:22:28.104Z",
  "columns": {
    "identity": [
      {
        "field": "displayName",
        "header": "Display Name"
      },
      {
        "field": "e-mail",
        "header": "Work Email"
      }
    ]
  },
  "fields": [
    "disabled"
  ],
  "orderBy": {
    "identity": [
      "lastName",
      "firstName"
    ],
    "role": [
      "name"
    ]
  },
  "sort": [
    "displayName"
  ],
  "filters": {
    "attributes.cloudAuthoritativeSource": {
      "type": "EXISTS",
      "exclude": true
    },
    "accessCount": {
      "type": "RANGE",
      "range": {
        "lower": {
          "value": "3"
        }
      }
    },
    "created": {
      "type": "RANGE",
      "range": {
        "lower": {
          "value": "2019-12-01",
          "inclusive": true
        },
        "upper": {
          "value": "2020-01-01"
        }
      }
    },
    "source.name": {
      "type": "TERMS",
      "terms": [
        "HR Employees",
        "Corporate Active Directory"
```

Body example truncated.

## A list of saved searches

`GET /saved-searches/v1`

Success: 200.

Returns a list of saved searches.

Query:

- standard: `limit`, `offset`, `count`
- filters: owner.id (eq)

## Updates an existing saved search


`PUT /saved-searches/v1/:id`

Success: 200.

Updates an existing saved search.

>**NOTE: You cannot update the `owner` of the saved search.**

Body:

```json
{
  "indices": [
    "identities"
  ],
  "query": "@accounts(disabled:true)",
  "id": "0de46054-fe90-434a-b84e-c6b3359d0c64",
  "owner": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313"
  },
  "ownerId": "2c91808568c529c60168cca6f90c1313",
  "public": false,
  "name": "Disabled accounts",
  "description": "Disabled accounts",
  "created": "2018-06-25T20:22:28.104Z",
  "modified": "2018-06-25T20:22:28.104Z",
  "columns": {
    "identity": [
      {
        "field": "displayName",
        "header": "Display Name"
      },
      {
        "field": "e-mail",
        "header": "Work Email"
      }
    ]
  },
  "fields": [
    "disabled"
  ],
  "orderBy": {
    "identity": [
      "lastName",
      "firstName"
    ],
    "role": [
      "name"
    ]
  },
  "sort": [
    "displayName"
  ],
  "filters": {
    "attributes.cloudAuthoritativeSource": {
      "type": "EXISTS",
      "exclude": true
    },
    "accessCount": {
      "type": "RANGE",
      "range": {
        "lower": {
          "value": "3"
        }
      }
    },
    "created": {
      "type": "RANGE",
      "range": {
        "lower": {
          "value": "2019-12-01",
          "inclusive": true
```

Body example truncated.

## Return saved search by id

`GET /saved-searches/v1/:id`

Success: 200.

Returns the specified saved search.

## Delete document by id

`DELETE /saved-searches/v1/:id`

Success: 204.

Deletes the specified saved search.

## Execute a saved search by id

`POST /saved-searches/v1/:id/execute`

Success: 202.

Executes the specified saved search.

Body:

```json
{
  "scheduleId": "7a724640-0c17-4ce9-a8c3-4a89738459c8"
}
```

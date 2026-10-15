# Connector Rule Management

Use this API to implement connector rule management functionality.

6 endpoints. Paths are relative to the environment API host.

## List connector rules

`GET /connector-rules/v1`

Success: 200.

List existing connector rules.

Query:

- standard: `limit`, `offset`, `count`

## Create connector rule

`POST /connector-rules/v1`

Success: 201.

Create a connector rule from the available types.

Body:

```json
{
  "name": "WebServiceBeforeOperationRule",
  "type": "BuildMap",
  "sourceCode": {
    "version": "1.0",
    "script": "return \"Mr. \" + firstName;"
  },
  "description": "This rule does that",
  "signature": {
    "input": [
      {
        "name": "firstName",
        "description": "the first name of the identity",
        "type": "String"
      },
      {
        "name": "firstName",
        "description": "the first name of the identity",
        "type": "String"
      }
    ],
    "output": {
      "name": "firstName",
      "description": "the first name of the identity",
      "type": "String"
    }
  },
  "attributes": {}
}
```

## Get connector rule

`GET /connector-rules/v1/:id`

Success: 200.

Get a connector rule by ID.

## Update connector rule

`PUT /connector-rules/v1/:id`

Success: 200.

Update an existing connector rule with the one provided in the request body. These fields are immutable: `id`, `name`, `type`

Body:

```json
{
  "id": "8113d48c0b914f17b4c6072d4dcb9dfe",
  "name": "WebServiceBeforeOperationRule",
  "sourceCode": {
    "version": "1.0",
    "script": "return \"Mr. \" + firstName;"
  },
  "type": "BuildMap",
  "description": "This rule does that",
  "signature": {
    "input": [
      {
        "name": "firstName",
        "description": "the first name of the identity",
        "type": "String"
      },
      {
        "name": "firstName",
        "description": "the first name of the identity",
        "type": "String"
      }
    ],
    "output": {
      "name": "firstName",
      "description": "the first name of the identity",
      "type": "String"
    }
  },
  "attributes": {}
}
```

## Delete connector rule

`DELETE /connector-rules/v1/:id`

Success: 204.

Delete the connector rule for the given ID.

## Validate connector rule

`POST /connector-rules/v1/validate`

Success: 200.

Detect issues within the connector rule's code to fix and list them.

Body:

```json
{
  "version": "1.0",
  "script": "return \"Mr. \" + firstName;"
}
```

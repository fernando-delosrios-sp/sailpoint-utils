# SOD Controls

Use this API to create, list, retrieve, update, and delete compensating controls associated with separation-of-duties policies.

5 endpoints. Paths are relative to the environment API host.

## List Compensating Controls

`GET /controls/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a list of compensating controls associated with separation-of-duties policies.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, in, sw, co); type (eq); owner (eq, in); description (eq, in, sw, co); action (eq, in)
- `sort`: Sort results using the standard syntax described in V3 API Standard Collection Parameters Sorting is supported for the following fields: **name** Prefix a field with - for descending order, for example -name. If no sort is provided,…

## Create Compensating Control

`POST /controls/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Creates a compensating control associated with separation-of-duties policies.

Body:

```json
{
  "name": "a name",
  "description": "a description",
  "owner": {
    "id": "3e07886555ed43cfb83c85c58d2016e6",
    "type": "IDENTITY"
  },
  "secondaryOwners": [
    {
      "id": "943a7c57da334d07ba2454bf7fcf144f",
      "type": "GOVERNANCE_GROUP"
    }
  ],
  "type": "Mitigation",
  "action": "Workflow",
  "expiration": "20d",
  "justificationRequired": true,
  "workflowID": "3e07886555ed43cfb83c85c58d2016e6"
}
```

## Get compensating control by ID

`GET /controls/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a single compensating control by ID.

## Put Compensating Control

`PUT /controls/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Updates the specified compensating control.

Body:

```json
{
  "name": "a name",
  "description": "a description",
  "owner": {
    "id": "3e07886555ed43cfb83c85c58d2016e6",
    "type": "IDENTITY"
  },
  "secondaryOwners": [
    {
      "id": "943a7c57da334d07ba2454bf7fcf144f",
      "type": "GOVERNANCE_GROUP"
    }
  ],
  "type": "Mitigation",
  "action": "Workflow",
  "expiration": "20d",
  "justificationRequired": true,
  "workflowID": "3e07886555ed43cfb83c85c58d2016e6"
}
```

## Delete compensating control by ID

`DELETE /controls/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Deletes the specified compensating control from the data store.

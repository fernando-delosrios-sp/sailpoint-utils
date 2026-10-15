# Password Sync Groups

Use this API to implement password sync group functionality.

5 endpoints. Paths are relative to the environment API host.

## Get password sync group list

`GET /password-sync-groups/v1`

Success: 200.

This API returns a list of password sync groups.

Query:

- standard: `limit`, `offset`, `count`

## Create password sync group

`POST /password-sync-groups/v1`

Success: 200.

This API creates a password sync group based on the specifications provided.

Body:

```json
{
  "name": "Password Sync Group 2",
  "passwordPolicyId": "2c91808d744ba0ce01746f93b6204501",
  "sourceIds": [
    "2c918084660f45d6016617daa9210584",
    "2c918084660f45d6016617daa9210500"
  ]
}
```

## Get password sync group by id

`GET /password-sync-groups/v1/:id`

Success: 200.

This API returns the sync group for the specified ID.

## Update password sync group by id

`PUT /password-sync-groups/v1/:id`

Success: 200.

This API updates the specified password sync group.

Body:

```json
{
  "id": "6881f631-3bd5-4213-9c75-8e05cc3e35dd",
  "name": "Password Sync Group 2",
  "passwordPolicyId": "2c91808d744ba0ce01746f93b6204501",
  "sourceIds": [
    "2c918084660f45d6016617daa9210584",
    "2c918084660f45d6016617daa9210500"
  ]
}
```

## Delete password sync group by id

`DELETE /password-sync-groups/v1/:id`

Success: 204.

This API deletes the specified password sync group.

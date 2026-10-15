# Auth Users

Use this API to implement user authentication system functionality.

2 endpoints. Paths are relative to the environment API host.

## Auth user details

`GET /auth-users/v1/:id`

Success: 200.

Return the specified user's authentication system details.

## Auth user update

`PATCH /auth-users/v1/:id`

Success: 200.

Use a PATCH request to update an existing user in the authentication system.
Use this endpoint to modify these fields:
  * `capabilities`

A '400.1.1 Illegal update attempt' detail code indicates that you attempted to PATCH a field that is not allowed.

Body:

```json
[
  {
    "op": "replace",
    "path": "/capabilities",
    "value": [
      "ORG_ADMIN"
    ]
  }
]
```

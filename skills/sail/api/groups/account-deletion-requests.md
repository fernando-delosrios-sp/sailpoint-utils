# Account Deletion Requests

2 endpoints. Paths are relative to the environment API host.

## List of Account Deletion Requests

`GET /account-requests/v1/deletion`

Success: 200.

Retrieves a paginated list of account deletion requests filtered by the provided query parameters. When the "mine" parameter is set to true, the response includes only those deletion requests that were initiated by the currently authenticated user. If "mine" is false or not specified, the endpoint returns all account deletion requests associated with the current tenant, regardless of the initiator. This allows both users and administrators to view relevant deletion requests based on their access level and intent.

Query:

- standard: `limit`, `offset`, `count`
- `mine`: Determines whether to return only the account deletion requests initiated by the currently authenticated user. If set to true, the response includes only deletion requests created by the logged-in user. If set to false or not provided, the…

## Delete account

`POST /account-requests/v1/account/:accountId/delete`

Success: 202.

Initiates an account deletion request for the specified account.
This method validates the input data, processes the deletion request,
and generates an asynchronous result containing a tracking ID.
>**NOTE: You can only delete accounts from sources of the "Connected" type. which supports account deletion**

Body:

```json
{
  "comments": "I requested this account deletion."
}
```

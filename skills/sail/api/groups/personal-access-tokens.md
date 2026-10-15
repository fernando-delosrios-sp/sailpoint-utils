# Personal Access Tokens

Use this API to implement personal access token (PAT) functionality.

5 endpoints. Paths are relative to the environment API host.

## List personal access tokens

`GET /personal-access-tokens/v1`

Success: 200.

This gets a collection of personal access tokens associated with the optional `owner-id`.  query parameter. If the `owner-id` query parameter is omitted, all personal access tokens  for a tenant will be retrieved, but the caller must have the 'idn:all-personal-access-tokens:read' right.

Query:

- `owner-id`: The identity ID of the owner whose personal access tokens should be listed. If "me", the caller should have the following right: 'idn:my-personal-access-tokens:read' If an actual owner ID or if the `owner-id` parameter is omitted in the…
- filters: lastUsed (le, isnull)

## Create personal access token

`POST /personal-access-tokens/v1`

Success: 200.

This creates a personal access token.
**expirationDate and userAwareTokenNeverExpires Relationship:**
**Important:** When `expirationDate` is `null` or empty (not included in the request body), the token will never expire.
**Required Validation:** If `expirationDate` is `null` or empty, `userAwareTokenNeverExpires` must be set to `true`. This is a required validation rule.
The valid values for `expirationDate` depend on the value provided for `userAwareTokenNeverExpires`:
* **When `userAwareTokenNeverExpires` is `true` (or required to be `true`):** `expirationDate` can be `null` or omitted from the request body. When `expirationDate` is `null` or empty, the token will never expire. This creates a PAT that never expires and serves as an explicit acknowledgment that the user is aware of the security implications of creating a non-expiring token. * **When `userAwareTokenNeverExpires` is `false` or omitted:** `expirationDate` must be provided and must be a valid date-time string representing a future date (there is no upper limit). `expirationDate` cannot be `null` in this case. In this scenario, `userAwareTokenNeverExpires` can be omitted.
**Validation Rules:** * **If `expirationDate` is `null` or not included in the request body:** `userAwareTokenNeverExpires` must be set to `true` (required). The token will never expire. * **If `expirationDate` is provided and is not `null`:** `userAwareTokenNeverExpires` can be omitted.
**Security Considerations:** The `userAwareTokenNeverExpires` field is designed to ensure that users explicitly acknowledge the security implications of creating tokens that never expire. Setting this field to `true` indicates that the user understands the increased security risks and has made an informed decision to proceed.
**Note:** The `userAwareTokenNeverExpires` field indicates that the user acknowledges they are creating a token that will never expire. It does not affect token behavior beyond indicating this acknowledgment.

Body:

```json
{
  "name": "NodeJS Integration",
  "scope": [
    "demo:personal-access-token-scope:first",
    "demo:personal-access-token-scope:second"
  ],
  "accessTokenValiditySeconds": 36900,
  "expirationDate": "2026-12-31T23:59:59.999Z",
  "userAwareTokenNeverExpires": false
}
```

## Patch personal access token

`PATCH /personal-access-tokens/v1/:id`

Success: 200.

This performs a targeted update to the field(s) of a Personal Access Token.
Changing scopes for a Personal Access Token does not impact existing bearer tokens. You will need to create a new bearer token to have the new scopes. Please note that it can take up to 20 minutes for scope changes to be seen on new bearer tokens.
**expirationDate and userAwareTokenNeverExpires Relationship:**
**Important:** When `expirationDate` is `null` or empty (replaced to `null` or omitted from the patch request), the token will never expire.
**Required Validation:** If `expirationDate` is being replaced to `null` or is empty, `userAwareTokenNeverExpires` must be set to `true` in the patch request. This is a required validation rule.
When patching `expirationDate` and `userAwareTokenNeverExpires`, the valid values for `expirationDate` depend on the value provided for `userAwareTokenNeverExpires`:
* **When `userAwareTokenNeverExpires` is being set to `true` (or required to be `true`):** `expirationDate` can be replaced to `null` or omitted from the patch request. When `expirationDate` is `null` or empty, the token will never expire. This sets the PAT to never expire and serves as an explicit acknowledgment that the user is aware of the security implications of creating a non-expiring token. * **When `userAwareTokenNeverExpires` is `false` or omitted:** `expirationDate` must be provided and must be a valid date-time string representing a future date (there is no upper limit). `expirationDate` cannot be `null` in this case. In this scenario, `userAwareTokenNeverExpires` can be omitted.
**Validation Rules:** * **If `expirationDate` is being replaced to `null`:** `userAwareTokenNeverExpires` must also be present in the patch request with a value of `true` (required). The token will never expire. * **If `expirationDate` is not being replaced to `null` (i.e., set to a future date):** `userAwareTokenNeverExpires` can be omitted.
**Security Considerations:** The `userAwareTokenNeverExpires` field is designed to ensure that users explicitly acknowledge the security implications of creating tokens that never expire. Setting this field to `true` indicates that the user understands the increased security risks and has made an informed decision to proceed.
**Note:** The `userAwareTokenNeverExpires` field indicates that the user acknowledges they are creating a token that will never expire. It does not affect token behavior beyond indicating this acknowledgment.

Body:

```json
[
  {
    "op": "replace",
    "path": "/name",
    "value": "New name"
  },
  {
    "op": "replace",
    "path": "/scope",
    "value": [
      "sp:scopes:all"
    ]
  },
  {
    "op": "replace",
    "path": "/expirationDate",
    "value": "2027-12-31T23:59:59.999Z"
  }
]
```

## Delete personal access token

`DELETE /personal-access-tokens/v1/:id`

Success: 204.

This deletes a personal access token.

## Bulk update personal access tokens

`PATCH /personal-access-tokens/v1/bulk-update`

Success: 200.

This applies a single JSON Patch document to multiple personal access tokens (PATs) in the current tenant in one request.
The same `patch` is applied to every token referenced in `ids`. Up to **25** tokens can be updated per request.
This is an administrative operation intended for org admins managing PATs across their tenant. The caller must have the `idn:all-personal-access-tokens:update` right. API OAuth client credentials are not permitted to call this endpoint.
Note: This operation is also accessible via `POST` to the same path; both methods behave identically. Unlike the single-token patch endpoint, the request body uses `Content-Type: application/json` (not `application/json-patch+json`).
**Allowed patch paths**
Only expiration-related paths may be modified in bulk:
* `/expirationDate` - Set or clear the token's expiration date. Any other path (for example `/name` or `/scope`) results in a `400` response.
* `/userAwareTokenNeverExpires` - Explicit acknowledgment that the token will never expire.
**expirationDate and userAwareTokenNeverExpires Relationship:**
When clearing `expirationDate` (either by removing it or replacing it with `null`), `userAwareTokenNeverExpires` must also be set to `true` in the same patch. This serves as an explicit acknowledgment that the caller is aware of the security implications of creating a token that will never expire. When `expirationDate` is set to a valid future date-time, `userAwareTokenNeverExpires` can be omitted.
**Note:** `userAwareTokenNeverExpires` is stored internally and is not returned in the response.

Body:

```json
{
  "ids": [
    "695dab70d33d466b81d958dc9fb392db",
    "abc123def456abc123def456abc12345"
  ],
  "patch": [
    {
      "op": "replace",
      "path": "/expirationDate",
      "value": "2026-12-31T23:59:59.999Z"
    }
  ]
}
```

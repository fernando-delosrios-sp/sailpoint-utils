# OAuth Clients

Use this API to implement OAuth client functionality.

5 endpoints. Paths are relative to the environment API host.

## List oauth clients

`GET /oauth-clients/v1`

Success: 200.

This gets a list of OAuth clients.

Query:

- filters: lastUsed (le, isnull)

## Create oauth client

`POST /oauth-clients/v1`

Success: 200.

This creates an OAuth client.

Body:

```json
{
  "name": "Demo API Client",
  "description": "An API client used for the authorization_code, refresh_token, and client_credentials flows",
  "accessTokenValiditySeconds": 750,
  "grantTypes": [
    "AUTHORIZATION_CODE",
    "CLIENT_CREDENTIALS",
    "REFRESH_TOKEN"
  ],
  "accessType": "OFFLINE",
  "enabled": true,
  "businessName": "Acme-Solar",
  "homepageUrl": "http://localhost:12345",
  "refreshTokenValiditySeconds": 86400,
  "redirectUris": [
    "http://localhost:12345"
  ],
  "type": "CONFIDENTIAL",
  "internal": false,
  "strongAuthSupported": false,
  "claimsSupported": false,
  "scope": [
    "demo:api-client-scope:first",
    "demo:api-client-scope:second"
  ]
}
```

## Get oauth client

`GET /oauth-clients/v1/:id`

Success: 200.

This gets details of an OAuth client.

## Delete oauth client

`DELETE /oauth-clients/v1/:id`

Success: 204.

This deletes an OAuth client.

## Patch oauth client

`PATCH /oauth-clients/v1/:id`

Success: 200.

This performs a targeted update to the field(s) of an OAuth client.

Body:

```json
[
  {
    "op": "replace",
    "path": "/strongAuthSupported",
    "value": true
  },
  {
    "op": "replace",
    "path": "/businessName",
    "value": "acme-solar"
  }
]
```

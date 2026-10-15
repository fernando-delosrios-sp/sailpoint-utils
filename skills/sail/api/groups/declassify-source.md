# Declassify Source

1 endpoints. Paths are relative to the environment API host.

## Declassify source's all accounts

`POST /sources/v1/:sourceId/declassify`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Use this API to declassify all the accounts from a source.
A token with API, ORG_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

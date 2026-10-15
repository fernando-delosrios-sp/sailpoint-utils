# Classify Source

3 endpoints. Paths are relative to the environment API host.

## Classify source's all accounts

`POST /sources/v1/:sourceId/classify`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to classify all the accounts from a source.
A token with API, ORG_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

## Cancel classify source's accounts process

`DELETE /sources/v1/:sourceId/classify`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Use this API to cancel account classification process on a source.
A token with API, ORG_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

## Source accounts classification status

`GET /sources/v1/:sourceId/classify`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to get the status of Machine Account Classification process for a source.
A token with API, ORG_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

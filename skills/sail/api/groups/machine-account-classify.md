# Machine Account Classify

1 endpoints. Paths are relative to the environment API host.

## Classify single machine account

`POST /accounts/v1/:id/classify`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to classify a single machine account.
A token with API, ORG_ADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

Query:

- `classificationMode`: Specifies how the accounts should be classified. default - uses criteria to classify account as machine or human, excludes accounts that were manually classified. ignoreManual - like default, but includes accounts that were manually…

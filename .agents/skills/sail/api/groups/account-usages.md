# Account Usages

Use this API to implement account usage insight functionality.

1 endpoints. Paths are relative to the environment API host.

## Returns account usage insights

`GET /account-usages/v1/:accountId/summaries`

Success: 200.

This API returns a summary of account usage insights for past 12 months.

Query:

- standard: `limit`, `offset`, `count`
- sorters: date

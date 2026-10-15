# Source Usages

Use this API to implement source usage insight functionality.

2 endpoints. Paths are relative to the environment API host.

## Finds status of source usage

`GET /source-usages/v1/:sourceId/status`

Success: 200.

This API returns the status of the source usage insights setup by IDN source ID.

## Returns source usage insights

`GET /source-usages/v1/:sourceId/summaries`

Success: 200.

This API returns a summary of source usage insights for past 12 months.

Query:

- standard: `limit`, `offset`, `count`
- sorters: date

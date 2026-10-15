# Api Usage

Use this API to retrieve metrics about an org's API usage.

2 endpoints. Paths are relative to the environment API host.

## Total number of API requests

`GET /api-usage/v1/count`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API gets an aggregated number of all API calls from an org in a specific timespan. Unless specified, the results are aggregated between the first day of the current month and today.

Query:

- filters: method (eq); startDate (gt, eq); endDate (lt, eq)

## Get Api Summary

`GET /api-usage/v1/summary`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API gets a list of APIs called by the org in a specific timespan, sorted by number of calls. Unless specified,  the results are aggregated between the first day of the current month and today.

Query:

- standard: `limit`, `offset`
- filters: method (eq); startDate (gt, eq); endDate (lt, eq)

# Certification Summaries

Use this API to implement certification summary functionality.

4 endpoints. Paths are relative to the environment API host.

## Summary of certification decisions

`GET /certifications/v1/:id/decision-summary`

Success: 200.

This API returns a summary of the decisions made on an identity campaign certification. The decisions are summarized by type. Reviewers for this certification can also call this API.

Query:

- filters: identitySummary.id (eq, in)

## Identity summaries for campaign certification

`GET /certifications/v1/:id/identity-summaries`

Success: 200.

This API returns a list of the identity summaries for a specific identity campaign certification. Reviewers for this certification can also call this API.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); completed (eq, ne); name (eq, sw)
- sorters: name

## Access summaries

`GET /certifications/v1/:id/access-summaries/:type`

Success: 200.

This API returns a list of access summaries for the specified identity campaign certification and type. Reviewers for this certification can also call this API.

Query:

- standard: `limit`, `offset`, `count`
- filters: completed (eq, ne); access.id (eq, in); access.name (eq, sw); entitlement.sourceName (eq, sw); accessProfile.sourceName (eq, sw)
- sorters: access.name

## Summary for identity

`GET /certifications/v1/:id/identity-summaries/:identitySummaryId`

Success: 200.

This API returns the summary for an identity on a specified identity campaign certification. Reviewers for this certification can also call this API.

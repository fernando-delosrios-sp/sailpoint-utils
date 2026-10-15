# Intelligence

HTTP API that returns the Intelligence (identity context) for SecOps enrichment use cases (SIEM/SOAR connectors, MCP, browser extension), and accepts asynchronous response actions for remediation.

8 endpoints. Paths are relative to the environment API host.

## Get identity by filter

`GET /intelligence/v1/identities`

Success: 200.

Requires tenant license idn:response-and-remediation.

**Caution:** When Data Segmentation is enabled, generic API Management API keys are not tied to
a user identity and may fail or return incomplete data. Use a personal access token
or other user-scoped OAuth token. See API keys
and Data Segmentation.

Resolves exactly one identity using a single SCIM-style filters expression. Returns an enriched
Human or non-human identity (NHI) envelope. Single-clause filters only; unsupported fields or
operators return HTTP 400.

Query:

- filters: id (eq); email (eq); opaqueIdentifier (eq)

## List identity accounts

`GET /intelligence/v1/identities/:id/accounts`

Success: 200.

Continuation endpoint for `accounts.next`. Pass `count=true` for `X-Total-Count`.

- Human (default): omit `isNHI` or set it to `false`. Slice object (`items`).
- Non-human identity (NHI): set `isNHI=true` (required for NHI aggregate `accounts.next` links). Bare JSON array.

Query:

- standard: `limit`, `offset`, `count`
- `isNHI`: NHI accounts when `true` (bare array). Human accounts when omitted or `false` (slice object).

## List identity rare access

`GET /intelligence/v1/identities/:id/outliers/rare-access`

Success: 200.

Continuation endpoint for the parent response's `outliers.rareAccess.next` link.
Resolves the identity's first outlier, then returns one page of rare access
items for the supplied limit and offset values. Pass `count=true` to receive
`X-Total-Count` (including `0` on empty pages). An identity with no outlier
returns an empty array with `X-Total-Count: 0` when `count=true`. Requires
tenant license idn:response-and-remediation and the IDA-outliers license.

Not applicable to non-human identities (no outliers slice on the NHI envelope).

Query:

- standard: `limit`, `offset`, `count`

## List identity access item history

`GET /intelligence/v1/identities/:id/access-history/access-items`

Success: 200.

Continuation endpoint for the parent response's `accessHistory.accessItems.next` link.
Returns one page of access-item history events for the supplied limit and offset values.
Pass `count=true` to receive `X-Total-Count` (including `0` on empty pages).
Unsupported event types and per-record decode failures are dropped server-side.
Requires tenant license idn:response-and-remediation.

Not applicable to non-human identities.

Query:

- standard: `limit`, `offset`, `count`

## List identity certification history

`GET /intelligence/v1/identities/:id/access-history/certifications`

Success: 200.

Continuation endpoint for the parent response's `accessHistory.certifications.next` link.
Returns one page of certification history events for the supplied limit and offset values.
Pass `count=true` to receive `X-Total-Count` (including `0` on empty pages).
Per-record decode failures are dropped server-side.
Requires tenant license idn:response-and-remediation.

Not applicable to non-human identities.

Query:

- standard: `limit`, `offset`, `count`

## List owned NHI identities

`GET /intelligence/v1/identities/:id/non-human-identity-ownership/:category`

Success: 200.

Continuation endpoint for a human parent's
`nonHumanIdentityOwnership.{category}.primaryOwned.next` or
`nonHumanIdentityOwnership.{category}.secondaryOwned.next` link. Returns a bare JSON array of
owned non-human identity summary rows for the given `category`, optional `ownershipRole`,
`limit`, and `offset`. Wire items match the aggregate ownership item shape
(`{ id, displayName, source? }`).

When `ownershipRole` is omitted, the request defaults to `primary`. Pass `count=true` to
receive `X-Total-Count` (including `0` on empty pages). The `filters` query parameter is not
supported on this route (HTTP 400).

Requires tenant licenses `idn:response-and-remediation` and `idn:machine-identity-security`.
Tenants without `idn:machine-identity-security` receive HTTP 403.

Not applicable to non-human identities (no ownership slice on the NHI envelope).

Query:

- standard: `limit`, `offset`, `count`
- `ownershipRole`: Optional ownership role discriminator. When set to `primary` or `secondary`, returns one paged role bucket. When omitted, defaults to `primary`. (This can only be one of primary,secondary)

## Create a response action

`POST /intelligence/v1/response-actions`

Success: 202.

Requires tenant license idn:response-and-remediation.

Creates a response action: the request is validated, a requestId (the correlation id) is
minted, the action is recorded as SUBMITTED, and an event is published that triggers the
correlated workflow(s).

Returns HTTP 202 with the requestId, an initial SUBMITTED status, and a statusUrl. Poll
GET /intelligence/v1/response-actions/{requestId}/status for progress.

Body:

```json
{
  "actionType": "DISABLE_IDENTITY",
  "identityType": "HUMAN",
  "identityId": "2c918085842e69ae018428c919680149",
  "context": {
    "source": "CROWDSTRIKE",
    "externalAlertId": "CS-FALCON-12345",
    "reason": "Malware detected on endpoint DESKTOP-A1B2C3",
    "operator": "soc-analyst@customer.com"
  }
}
```

## Get response action status

`GET /intelligence/v1/response-actions/:id/status`

Success: 200.

Requires tenant license idn:response-and-remediation.

Returns the current aggregate status of a previously submitted response action, identified by
the requestId returned from POST /intelligence/v1/response-actions.

Supported actionType values: DISABLE_IDENTITY, DISABLE_ACCOUNT.

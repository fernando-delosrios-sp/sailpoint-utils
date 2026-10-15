# JIT Activations

Use this API to start and manage Just-In-Time (JIT) Privileged activation workflows for entitlement connections, to read and submit activation frictions, and to search activation history.

7 endpoints. Paths are relative to the environment API host.

## Start JIT activation workflow

`POST /jit-activations/v1/activate`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Starts a JIT Privileged (JIT P) activation workflow for the given entitlement connection and duration.
The service performs quick validation; the workflow performs additional validation.

The response is returned with HTTP 202 Accepted while the workflow initializes.

Body:

```json
{
  "connectionId": "757fb803-9024-5861-e510-83a56e4c5bd3",
  "activationPeriodMins": 120,
  "requestOrigin": "slack",
  "metaData": {
    "type": "slack",
    "slackUserId": "U123",
    "commandText": "/jit activate",
    "channelId": "C456",
    "threadId": "1699887766.123456",
    "messageId": "1699887770.654321",
    "workspaceId": "T789"
  }
}
```

## Deactivate JIT activation workflow

`POST /jit-activations/v1/deactivate`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Sends a signal to a running JIT Privileged (JIT P) activation workflow to deactivate.

This request cannot be applied to a workflow that does not exist or whose execution has already completed.
The client receives an error response in those cases.

The response is returned with HTTP 202 Accepted after the signal is sent.

Body:

```json
{
  "connectionId": "757fb803-9024-5861-e510-83a56e4c5bd3",
  "requestOrigin": "slack",
  "metaData": {
    "type": "slack",
    "slackUserId": "U123",
    "commandText": "/jit activate",
    "channelId": "C456",
    "threadId": "1699887766.123456",
    "messageId": "1699887770.654321",
    "workspaceId": "T789"
  }
}
```

## Extend JIT activation workflow

`POST /jit-activations/v1/extend`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Sends a signal to a running JIT Privileged (JIT P) activation workflow to extend the activation period
by the requested number of minutes.

This request cannot be applied to a workflow that does not exist or whose execution has already completed.
The client receives an error response in those cases.

The response is returned with HTTP 202 Accepted after the signal is sent.

Body:

```json
{
  "connectionId": "757fb803-9024-5861-e510-83a56e4c5bd3",
  "activationPeriodExtensionMins": 120,
  "requestOrigin": "slack",
  "metaData": {
    "type": "slack",
    "slackUserId": "U123",
    "commandText": "/jit activate",
    "channelId": "C456",
    "threadId": "1699887766.123456",
    "messageId": "1699887770.654321",
    "workspaceId": "T789"
  }
}
```

## Get JIT activation frictions

`GET /jit-activations/v1/:activationId/frictions`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns evaluated frictions for a JIT Privileged (JIT P) activation.

Requires OAuth scope **idn:jit-activation-workflow:activate** or
**idn:jit-activation-workflow:manage**. The JWT identity id must match the
activation identity.

Returns HTTP 403 when **PSPM_JIT_ACCESS_ACTIVATION** or
**PSPM_JIT_ACCESS_ACTIVATION_15** is disabled.

Returns HTTP 404 when the activation does not exist.

## Submit JIT activation friction

`PATCH /jit-activations/v1/:activationId/frictions`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Submits the current friction step for a JIT Privileged (JIT P) activation.

Requires OAuth scope **idn:jit-activation-workflow:activate** or
**idn:jit-activation-workflow:manage**. The JWT identity id must match the
activation identity.

Returns HTTP 403 when **PSPM_JIT_ACCESS_ACTIVATION** or
**PSPM_JIT_ACCESS_ACTIVATION_15** is disabled.

Request bodies larger than 16 KB return HTTP 413.

Body:

```json
{
  "type": "JUSTIFICATION",
  "submittedData": {
    "justification": "Current P1 requires activation to mitigate"
  },
  "bypass": false
}
```

## List JIT activation history (admin)

`GET /jit-activation-history/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns JIT activation history records for the tenant.

This is the admin/operator view - it returns activations across all identities in the tenant.
Requires `idn:jit-activation-history:read`.

Returns HTTP 403 when the `PSPM_858_JIT_ACCESS_ACTIVATION_HISTORY_SEARCH` feature flag is disabled.

Query:

- standard: `limit`, `offset`, `count`
- sorters: activationInitiated, provisionCompleted, status
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. Used to paginate beyond the offset…
- filters: identityId (eq, in); entitlementId (eq, in); sourceId (eq); connectionId (eq); status (eq, in); activationInitiated (gt, lt, ge, le); policyFrictionOutcome (eq, in)

## List JIT activation history (self)

`GET /jit-activation-history/v1/current-identity`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns JIT activation history records for the authenticated identity only.

This is the self-service view - results are automatically scoped to the calling identity.
Requires `idn:jit-activation-history-self:read`.

Returns HTTP 403 when the `PSPM_858_JIT_ACCESS_ACTIVATION_HISTORY_SEARCH` feature flag is disabled.

Query:

- standard: `limit`, `offset`, `count`
- sorters: activationInitiated, provisionCompleted, status
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. Used to paginate beyond the offset…
- filters: entitlementId (eq, in); sourceId (eq); connectionId (eq); status (eq, in); activationInitiated (gt, lt, ge, le); policyFrictionOutcome (eq, in)

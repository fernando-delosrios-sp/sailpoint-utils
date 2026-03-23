# Postman Remote Source Evaluation

Pre-request script for Postman that:

- Authenticates to SailPoint ISC using OAuth client credentials.
- Resolves the target source by exact `sourceName`.
- Loads `connectorAttributes` from that source.
- Merges request `config` values using predictable precedence.
- Optionally rewrites the request for remote connector invoke mode.

## Prerequisites

- Postman desktop app (latest recommended).
- A SailPoint ISC tenant.
- An OAuth API client with permissions to:
  - Obtain tokens from `/oauth/token`.
  - Read sources from `/v2025/sources`.
  - Invoke platform connectors in `/beta/platform-connectors/{id}/invoke` (if using remote mode).

## Installation / Setup

1. Open Postman and import your collection that uses this script.
2. Open or create a Postman environment for your tenant.
3. Add the required environment variables listed below.
4. Add collection variable `remoteMode` as needed.
5. Attach this script as the collection pre-request script.

## Required Environment Variables

- `tenant`: ISC tenant short name. Example: `acme`
- `domain`: ISC domain. Example: `identitynow`
- `clientId`: OAuth client ID
- `clientSecret`: OAuth client secret
- `sourceName`: Exact source name to resolve

## Optional Variables

- `sp_access_token`: Token cache set automatically by script.
- `sp_access_token_expires_at`: Token expiry cache set automatically by script.
- Any variable matching a config key in your request body or connector attributes (used for override behavior).

## Collection Variables

- `remoteMode`: `true` or `false`
  - `false` (default behavior): Request URL stays as configured in your request.
  - `true`: Script rewrites URL to:
    - `https://{tenant}.api.{domain}.com/beta/platform-connectors/{resolvedConnectorId}/invoke`
    - Adds `Authorization`, `Content-Type`, and `Accept` headers.
    - Sets request body `tag` to `"latest"`.

## How Runtime Resolution Works

1. Script gets (or reuses) OAuth token from `/oauth/token`.
2. Script fetches sources from `/v2025/sources?limit=250`.
3. Script performs exact match by `source.name === sourceName`.
4. Behavior for match count:
   - 0 matches: fail with clear "No source found" error.
   - >1 matches: fail with clear duplicate-name error.
   - 1 match: continue.
5. Script reads `connectorAttributes` from resolved source.
6. Script resolves connector ID from common source fields when `remoteMode=true`.

## Request Body Behavior

The script expects a raw JSON request body and manages `config` at the root:

```json
{
  "config": {
    "timeout": 30,
    "host": "example.org"
  }
}
```

Config merge precedence is:

1. `body.config` (already in the request body)
2. environment variable with same key name
3. `source.connectorAttributes` value

If an env override value is valid JSON, it is parsed as JSON; otherwise treated as string.

## Typical Run Checklist

1. Set environment vars (`tenant`, `domain`, `clientId`, `clientSecret`, `sourceName`).
2. Set collection var `remoteMode` to `true` or `false`.
3. Ensure request body is valid raw JSON.
4. Send request.

## Troubleshooting

- `Missing required environment variable: sourceName`
  - Set `sourceName` in the active Postman environment.
- `No source found with exact name`
  - Check spelling/case and ensure source exists in tenant.
- `Multiple sources found with exact name`
  - Rename one source in ISC or use a uniquely named source.
- `remoteMode is enabled but the source does not expose a connector identifier`
  - Validate source payload has connector/platform connector metadata and that your source type supports remote invoke.
- `No access_token in OAuth response`
  - Verify client credentials and OAuth client permissions.
- `Request body is not valid JSON`
  - Switch body mode to raw JSON and fix syntax errors.

## Security Notes

- Store `clientSecret` in Postman environment variables marked secret/sensitive.
- Do not commit secrets to source control.
- Rotate OAuth credentials periodically per your security policy.


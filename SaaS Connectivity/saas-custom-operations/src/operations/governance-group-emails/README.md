# custom:governance-group-emails

## Purpose

Resolves a governance group (workgroup) by display name and persists member email addresses for workflow BCC lines, distribution lists, or escalation paths.

## Command

`custom:governance-group-emails`

## Input

| Field | Required | Description |
|---|---|---|
| `groupName` | Yes | Exact governance group display name (`GET /workgroups/v1` with `name eq` filter) |

## Output (persisted)

| Field | Description |
|---|---|
| `governance-group-emails:emails` | Non-empty member email addresses (string array) |

## Token scopes

The invocation bearer token must allow governance group read access:

- List workgroups (`listWorkgroupsV1`)
- List workgroup members (`listWorkgroupMembersV1`)

Use a workflow OAuth token or PAT with governance group read permissions. HTTP 403 responses surface as `ConnectorError` with status details.

## Invoke examples

| Payload | Use |
|---|---|
| [`payloads/governance-group-emails-offline.json`](../../../payloads/governance-group-emails-offline.json) | Offline local invoke (canned group emails) |
| [`payloads/governance-group-emails.json`](../../../payloads/governance-group-emails.json) | Connected local dry-run |

Offline example:

```json
{
    "type": "custom:governance-group-emails",
    "input": {
        "requestId": "offline-gg-001",
        "groupName": "Offline Approvers"
    }
}
```

Connected workflow example:

```json
{
    "connectorRef": "{{$.defineVariable.saaSCustomOperationsConnectorID}}",
    "tag": "latest",
    "type": "custom:governance-group-emails",
    "input": {
        "requestId": "req-gg-001",
        "groupName": "Access Review Approvers"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

## Bundled workflows

No workflow exports are bundled for this operation. Use it as a lookup step before Send Email — invoke, then read `governance-group-emails:emails` from Get Accounts for BCC or distribution lists.

## Workflow integration

1. Invoke `custom:governance-group-emails` with the target governance group display name.
2. Read persisted output via **Get Accounts** filtered by `requestId`.
3. Use `governance-group-emails:emails` for BCC recipients, distribution lists, or escalation routing in downstream email/notification steps.

When duplicate group names exist in a tenant, the connector returns the first exact name match from the ISC API response.

## Local development

```bash
npm run call:op -- payloads/governance-group-emails-offline.json
```

Register the handler in `scripts/call-op.ts` `OPERATION_HANDLERS` when adding new operations.

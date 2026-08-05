# Workflow migration guide

This folder contains migrated workflow templates that replace calls to `isc-custom-endpoint` with SaaS custom connector operations.

## Prerequisites

1. Deploy the updated `saas-custom-operations` connector (`npm run pack-zip`).
2. Import or configure the dummy result source (`SaaS Custom Operations`).
3. Set workflow configuration variables:
   - **API URL** — tenant ISC API base URL
   - **SaaS Custom Operations Source ID** — dummy result source ID
   - **SaaS Custom Operations Connector ID** — deployed connector ID

## Step mapping

### Approval workflow (`38d42800-approval-migrated.json`)

| Removed steps | Replacement |
|---|---|
| HTTP getAccessRequestStatus | Absorbed into `custom:access-request-status` |
| HTTP getXdrData (outliers) | Absorbed into `custom:access-request-status` |
| HTTP requestedItems (item owner) | Absorbed into `custom:access-request-status` |
| HTTP POST `/api/access-request-status` | Invoke `custom:access-request-status` |
| HTTP POST `/api/govgroup-emails` | Absorbed when `emailRoute` = `manager-owner-bcc` |
| Compare Strings 1–4 | Compare `param1` (`emailRoute`) after Get Accounts |

**New flow**

1. Get Identity (manager recipient — unchanged)
2. Configuration + Get Access Token
3. Invoke `custom:access-request-status` with `outputProfile: approval-email`
4. Get Accounts where `nativeIdentity eq "{requestId}"`
5. Route on `attributes.param1`:
   - `manager` → Send Email (body = `param2`)
   - `manager-owner` → Send Email with CC = `param4` (body = `param2`)
   - `manager-owner-bcc` → Send Email with CC = `param4`, BCC = `param3` (body = `param2`)

### Threshold workflow (`418355cf-threshold-migrated.json`)

| Removed steps | Replacement |
|---|---|
| HTTP getAccessRequestStatus | Absorbed into `custom:access-request-threshold` |
| HTTP POST `/api/access-request-threshold` | Invoke `custom:access-request-threshold` |
| Compare Boolean on `thresholdHit` | Compare Strings on `param1` (`"true"` / `"false"`) |

**New flow**

1. Manager approval → if APPROVED
2. Configuration (API URL, connector ID, source ID, `sourceName`, `thresholdValue`)
3. Get Identity + Get Access Token
4. Invoke `custom:access-request-threshold`
5. Get Accounts filtered by `accessRequestId`
6. Fetch requested item owner (HTTP GET — still needed for threshold-hit path)
7. Compare `param1`:
   - `"true"` → email item owner + escalated approval
   - default → informational email to manager

### ETS workflow (`0785b8f4-ets-migrated.json`)

| Removed steps | Replacement |
|---|---|
| HTTP getAccessRequestStatus | Absorbed |
| HTTP getXdrData | Absorbed |
| HTTP requestedItems | Absorbed |
| HTTP POST `/api/access-request-status` | Invoke with `outputProfile: ets-comment` |
| Comment assembly in callback step | Read `param1` from Get Accounts |

**New flow**

1. Configuration + Get Access Token
2. Invoke `custom:access-request-status` with `outputProfile: ets-comment`
3. Get Accounts → `param1` = preApproval comment
4. HTTP callback uses `param1` in approval comment

## Invoke payload examples

### access-request-status

```json
{
  "connectorRef": "{{$.configuration.saaSCustomOperationsConnectorID}}",
  "tag": "latest",
  "type": "custom:access-request-status",
  "input": {
    "requestId": "{{$.trigger.accessRequestId}}",
    "accessRequestId": "{{$.trigger.accessRequestId}}",
    "outputProfile": "approval-email",
    "govGroupName": "SOD Governance Group"
  },
  "config": {
    "apiUrl": "{{$.configuration.aPIURL}}",
    "token": "{{$.getAccessToken.body.access_token}}",
    "sourceId": "{{$.configuration.saaSCustomOperationsSourceID}}"
  }
}
```

### access-request-threshold

```json
{
  "connectorRef": "{{$.configuration.saaSCustomOperationsConnectorID}}",
  "tag": "latest",
  "type": "custom:access-request-threshold",
  "input": {
    "requestId": "{{$.trigger.accessRequestId}}",
    "accessRequestId": "{{$.trigger.accessRequestId}}",
    "sourceName": "SAP GRC",
    "thresholdValue": 2
  },
  "config": {
    "apiUrl": "{{$.configuration.aPIURL}}",
    "token": "{{$.getAccessToken.body.access_token}}",
    "sourceId": "{{$.configuration.saaSCustomOperationsSourceID}}"
  }
}
```

## Persist param contracts

### `custom:access-request-status` — `approval-email`

| Param | Content |
|---|---|
| param1 | `manager` \| `manager-owner` \| `manager-owner-bcc` |
| param2 | HTML email body |
| param3 | BCC emails (comma-separated) or `N/A` |
| param4 | Access item owner ID |

### `custom:access-request-status` — `ets-comment`

| Param | Content |
|---|---|
| param1 | Full preApproval comment text |

### `custom:govgroup-emails`

| Param | Content |
|---|---|
| param1 | Comma-separated member emails |

### `custom:access-request-threshold`

| Param | Content |
|---|---|
| param1 | `thresholdHit` (`"true"` \| `"false"`) |
| param2 | `foundCount` |
| param3 | `sourceName` |
| param4 | `thresholdValue` |
| param5 | `requestedCount` |
| param6 | `pendingCount` |
| param7 | `grantedCount` |

## Deferred operations (invoke response only)

`custom:check-sod-pending` returns JSON via invoke for manual testing. No calling workflow exists in the `abb-poc` backup yet.

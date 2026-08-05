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
| Compare Strings 1–4 | Compare `emailRoute` after Get Accounts |

**New flow**

1. Get Identity (manager recipient — unchanged)
2. Configuration + Get Access Token
3. Invoke `custom:access-request-status` with `outputProfile: approval-email`
4. Get Accounts where `nativeIdentity eq "{requestId}"`
5. Route on `attributes.emailRoute`:
   - `manager` → Send Email (body = `emailBodyHtml`)
   - `manager-owner` → Send Email with CC = `accessOwnerId` (body = `emailBodyHtml`)
   - `manager-owner-bcc` → Send Email with CC = `accessOwnerId`, BCC = `bccEmails` (body = `emailBodyHtml`)

### Threshold workflow (`418355cf-threshold-migrated.json`)

| Removed steps | Replacement |
|---|---|
| HTTP getAccessRequestStatus | Absorbed into `custom:access-request-threshold` |
| HTTP POST `/api/access-request-threshold` | Invoke `custom:access-request-threshold` |
| Compare Boolean on `thresholdHit` | Compare Strings on `thresholdHit` (`"true"` / `"false"`) |

**New flow**

1. Manager approval → if APPROVED
2. Configuration (API URL, connector ID, source ID, `sourceName`, `thresholdValue`)
3. Get Identity + Get Access Token
4. Invoke `custom:access-request-threshold`
5. Get Accounts filtered by `accessRequestId`
6. Fetch requested item owner (HTTP GET — still needed for threshold-hit path)
7. Compare `thresholdHit`:
   - `"true"` → email item owner + escalated approval
   - default → informational email to manager

### ETS workflow (`0785b8f4-ets-migrated.json`)

| Removed steps | Replacement |
|---|---|
| HTTP getAccessRequestStatus | Absorbed |
| HTTP getXdrData | Absorbed |
| HTTP requestedItems | Absorbed |
| HTTP POST `/api/access-request-status` | Invoke with `outputProfile: ets-comment` |
| Comment assembly in callback step | Read `preApprovalComment` from Get Accounts |

**New flow**

1. Configuration + Get Access Token
2. Invoke `custom:access-request-status` with `outputProfile: ets-comment`
3. Get Accounts → `preApprovalComment` = preApproval comment
4. HTTP callback uses `preApprovalComment` in approval comment

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

## Persist output contracts

### `custom:access-request-status` — `approval-email`

| Attribute | Content |
|---|---|
| emailRoute | `manager` \| `manager-owner` \| `manager-owner-bcc` |
| emailBodyHtml | HTML email body |
| bccEmails | BCC email list (`string[]`; empty when route is not `manager-owner-bcc`) |
| accessOwnerId | Access item owner ID |

### `custom:access-request-status` — `ets-comment`

| Attribute | Content |
|---|---|
| preApprovalComment | Full preApproval comment text |

### `custom:govgroup-emails`

| Attribute | Content |
|---|---|
| emails | Member email list (`string[]`) |

### `custom:access-request-threshold`

| Attribute | Content |
|---|---|
| thresholdHit | `true` \| `false` |
| foundCount | Entitlement count for source |
| sourceName | Source name filter |
| thresholdValue | Configured threshold |
| requestedCount | Requested entitlement count |
| pendingCount | Pending entitlement count |
| grantedCount | Granted entitlement count |

## Deferred operations (invoke response only)

`custom:check-sod-pending` returns JSON via invoke for manual testing. No calling workflow exists in the `abb-poc` backup yet.


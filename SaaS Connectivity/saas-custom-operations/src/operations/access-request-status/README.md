# custom:access-request-status

## Purpose

Builds approval email content or ETS pre-approval comments for access request workflows based on risk analytics, SoD signals, and recommendations.

## Command

`custom:access-request-status`

## Input

| Field | Required | Description |
|---|---|---|
| `outputProfile` | Yes | `approval-email` or `ets-comment` |
| `accessRequestId` | Yes | ISC access request id |
| `govGroupName` | No | Governance group for BCC when route is `manager-owner-bcc` (default: `SOD Governance Group`) |

## Output (persisted)

| Field | Type | Profile |
|---|---|---|
| `preApprovalComment` | string | `ets-comment` |
| `emailRoute` | string | `approval-email` |
| `emailBodyHtml` | string | `approval-email` |
| `bccEmails` | string[] | `approval-email` (Critical risk route only) |
| `accessOwnerId` | string | `approval-email` |

`emailBodyHtml` is a compact one-paragraph body built to fit ISC STRING storage (256 characters) — requester, requested item, ISC risk, and an Approval Center link. Long names are shortened with `…` so the value is never cut mid-tag. Full risk analytics belong in the `ets-comment` profile's `preApprovalComment`. The Approval Center link uses the tenant UI origin derived from `config.apiUrl` (`resolveUiOrigin`); when no origin resolves (offline invoke), the body renders plain text instead of an anchor.

## Invoke response

| Profile | Response fields |
|---|---|
| `ets-comment` | `outputProfile`, `preApprovalComment` |
| `approval-email` | `outputProfile`, `emailRoute`, `accessOwnerId` |

## Email routes

| Route | Condition |
|---|---|
| `manager` | ISC risk is N/A or Low |
| `manager-owner` | Medium pre-approval comment prefix or High risk |
| `manager-owner-bcc` | Critical risk (BCC from governance group) |

## Invoke example

```json
{
    "type": "custom:access-request-status",
    "input": {
        "requestId": "req-status-001",
        "outputProfile": "approval-email",
        "accessRequestId": "{{$.trigger.accessRequestId}}"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

## PAT scope requirements

- Access request status read
- Identity read
- Entitlement / role / access profile read
- SoD policy read and predict
- IAI outliers and recommendations (experimental)
- Governance group read (Critical risk BCC route)
- Result source account persist

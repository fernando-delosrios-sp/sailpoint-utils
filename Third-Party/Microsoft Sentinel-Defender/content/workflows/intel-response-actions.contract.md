# ISC Intel Response Actions workflow contract

This contract describes the SailPoint ISC side of Sentinel containment. The Azure Logic App
submits `POST /intelligence/v1/response-actions`; ISC publishes an Intel Response Actions
trigger that starts the **SecOps Identity Intelligence Response Action** workflow template
(or an equivalent custom workflow).

## Prerequisites

- Tenant license: `idn:response-and-remediation`
- PAT (or OAuth client) with scopes:
  - `sp:identity-sec-intel:read`
  - `sp:identity-sec-intel:write`
- Do **not** reuse the ingestion PAT (`sp:search:read` only)
- Connected identity sources so `DISABLE_ACCOUNT` / `DISABLE_IDENTITY` can provision

## Request body (from Sentinel playbook)

```json
{
  "actionType": "DISABLE_ACCOUNT",
  "identityType": "HUMAN",
  "identityId": "<sailpoint-identity-id>",
  "accountIds": ["<optional-account-id>"],
  "context": {
    "source": "SENTINEL",
    "externalAlertId": "<sentinel-incident-or-alert-id>",
    "reason": "Microsoft Sentinel containment request",
    "operator": "<analyst-upn-or-object-id>"
  }
}
```

Defaults for this project:

| Field | Value |
| --- | --- |
| Preferred action | `DISABLE_ACCOUNT` (lower blast radius) |
| Escalation action | `DISABLE_IDENTITY` (confirmed compromise only) |
| `context.source` | `SENTINEL` |
| Approval | Required in the ISC workflow before disable |

## Workflow template setup (ISC UI)

1. Admin → Workflows → Create Workflow → Start with a Template
2. Select **SecOps Identity Intelligence Response Action**
3. Configure:
   - Approval step for human identities (required for this project)
   - Pre-checks (VIP / break-glass exclusions if available)
   - Notifications to SOC + identity ops
   - Confirm lifecycle / provisioning behavior for disable branches
4. Test with a non-production identity
5. Enable the workflow

## Trigger payload fields to surface in approvals

Keep these visible in the approval form / email so reviewers can decide safely:

- `identityId`, display name, email
- `actionType` (`DISABLE_ACCOUNT` vs `DISABLE_IDENTITY`)
- `accountIds` (when present)
- `context.source` (must be `SENTINEL`)
- `context.externalAlertId` (Sentinel incident / alert id)
- `context.reason`
- `context.operator`

## Shared Signals vs Response Actions

| Path | Role in this project |
| --- | --- |
| Shared Signals Framework (SSF) receiver | Prefer when a Microsoft CAEP/SSF transmitter discovery URL is available and the tenant has SSF entitlement. Useful for risk-level / session signals into ISC. |
| Response Actions API | Documented Sentinel containment path. Always the fallback and the default for this repo. Triggers the Intel Response Actions workflow above. |

`just response` runs a capability check for SSF; if unavailable it deploys the Response Actions playbook only.

## Safety defaults

- Manual Sentinel incident action (no automatic automation rule on every alert)
- ISC workflow approval required before disable
- Prefer `DISABLE_ACCOUNT` in the playbook default parameter
- Deduplicate by Sentinel incident id + action type inside the Logic App

# custom:sod-remediation

## Purpose

Launch-only operation that fetches an SOD violation, ensures a named form definition exists (owned by the access-token identity on first create), creates a standalone remediation form for the violation owner (or override recipient), and persists form URL and situation summary fields for downstream workflow steps.

## Command

`custom:sod-remediation`

## Input

| Field | Required | Description |
|---|---|---|
| `violationId` | Yes | SOD violation ID (`GET /violations/v1/:id`, experimental API) |
| `formName` | Yes | Tenant form definition name — created from bundled seed on first use; **owner on create** is the access-token identity (not the violation owner) |
| `owner` | No | Form instance recipient override; defaults to violation owner |

## Output (persisted)

| Field | Description |
|---|---|
| `sod-remediation:form-url` | Standalone form URL (`standAloneFormUrl`) for email deep links |
| `sod-remediation:situation-summary` | HTML summary for workflow email bodies |
| `sod-remediation:situation-header` | Plain-text email subject |
| `sod-remediation:owner-email` | Recipient email for notifications |

## Invoke examples

| Payload | Use |
|---|---|
| [`payloads/sod-remediation-workflow.json`](../../../payloads/sod-remediation-workflow.json) | Workflow-ready invoke aligned with [`workflows/SOD Remediation - Violation Response.json`](../../../workflows/SOD%20Remediation%20-%20Violation%20Response.json) |
| [`payloads/sod-remediation-offline.json`](../../../payloads/sod-remediation-offline.json) | Offline local invoke (canned violation data) |
| [`payloads/sod-remediation.json`](../../../payloads/sod-remediation.json) | Connected local dry-run |
| [`payloads/sod-remediation-live.json`](../../../payloads/sod-remediation-live.json) | Connected invoke with persist enabled |

Workflow-ready example:

```json
{
    "connectorRef": "{{$.defineVariable.saaSCustomOperationsConnectorID}}",
    "tag": "latest",
    "type": "custom:sod-remediation",
    "input": {
        "requestId": "req-sod-001",
        "violationId": "00000000-0000-0000-0000-000000000001",
        "formName": "SOD Violation Remediation",
        "owner": "optional-recipient-identity-id"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

Related workflow exports:

- [`workflows/SOD Remediation - Violation Response.json`](../../../workflows/SOD%20Remediation%20-%20Violation%20Response.json) — launch, email, wait for form
- [`workflows/SOD Remediation - Action.json`](../../../workflows/SOD%20Remediation%20-%20Action.json) — post-submit revoke / compensating control

## Workflow integration

1. Invoke `custom:sod-remediation` with violation ID and form name.
2. Read persisted output via **Get Accounts** filtered by `requestId` (`form-url`, email fields).
3. Send email to recipient with `situation-summary` as the HTML body and link to `form-url`.
4. Wait for form submission; read **user decisions** from submitted `formData`: `action`, `remediationSide`, `control`, `comments`.
5. Read **launch-time workflow keys** from the completed form instance **`formInput`** (not `formData`):
   - `violationId`, `targetIdentityId`, `groupAAccessSearch`, `groupBAccessSearch`
   - Access search strings include **revocable** access path ids only (`id:x OR id:y`); non-revocable entitlements granted via role or access profile on the same side are omitted from the filter
   - Workflow JSONPath example after a Wait for Form / Get Form Instance step: `{{$.form.formInput.groupAAccessSearch}}`
6. Select the access-search string for the chosen side using `formData.remediationSide`.
7. Execute corrective revoke or apply compensating control in separate workflow HTTP actions (not handled by the connector).

Workflow keys are declared in the form definition `formInput` schema and populated at instance create. They do **not** need hidden form elements and do **not** round-trip through `formData`.

After upgrading the connector, re-invoke `custom:sod-remediation` so the form-definition watermark patches the tenant form definition before creating a new instance. Each invoke creates a **new** form instance; re-opening a URL from an already-submitted instance shows "already submitted".

## Local development

```bash
npm run call:op -- payloads/sod-remediation-offline.json
npm run call:op -- payloads/sod-remediation.json
```

Experimental APIs require header `X-SailPoint-Experimental: true` (handled internally). Offline payload runs use canned violation data when no `config` is provided.

See the root [README](../../../README.md) for generic invoke envelope, persist inhibition (`testMode`), and result source setup.

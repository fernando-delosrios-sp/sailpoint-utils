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
| `sod-remediation:form-email-body` | HTML summary for workflow email bodies |
| `sod-remediation:form-email-header` | Plain-text email subject |
| `sod-remediation:form-email-recipients` | Recipient emails for notifications (`string[]`) |

## Invoke examples

| Payload | Use |
|---|---|
| [`payloads/sod-remediation-workflow.json`](../../../payloads/sod-remediation-workflow.json) | Workflow-ready invoke aligned with [`workflows/SOD Violation - Notification.json`](../../../workflows/SOD%20Violation%20-%20Notification.json) |
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

## Bundled workflows

Two ISC workflow exports under [`workflows/`](../../../workflows/) implement the violation remediation lifecycle. Import both and re-point **Configuration** variables (API URL, connector ID, source name, OAuth client) to your tenant.

| Export | Trigger | Role |
|---|---|---|
| [`workflows/SOD Violation - Notification.json`](../../../workflows/SOD%20Violation%20-%20Notification.json) | `idn:sod-violation-created` | Invoke this operation, read persist output, email the violation owner |
| [`workflows/SOD Violation - Remediation.json`](../../../workflows/SOD%20Violation%20-%20Remediation.json) | `sp:form-submitted` (filtered by remediation form definition ID) | Post-submit revoke or compensating-control apply |

End-to-end flow:

```
SoD violation created (ISC event)
        │
        ▼
SOD Violation - Notification
  OAuth → invoke custom:sod-remediation
  Get Accounts (requestId) → Send Email (form-email-*)
        │
        ▼
Owner opens form-url, submits remediationSide + action
        │
        ▼
SOD Violation - Remediation
  action == Correct → revoke via groupAAccessSearch / groupBAccessSearch
  action != Correct  → POST /violations/v1/{id}/controls (Mitigate)
```

**Notification workflow integration**

1. **Configuration** sets `requestID` to `sod-remediation:` concatenated with the violation id from `$.trigger.id`, `violationID` from the same trigger, `formName` (default `SOD Violation Remediation`), and optional `overrideOwnerID`.
2. **Get Access Token** → **Call SaaS Custom Operation** posts to `/beta/platform-connectors/{connectorId}/invoke` with `type: custom:sod-remediation` (see [`payloads/sod-remediation-workflow.json`](../../../payloads/sod-remediation-workflow.json)).
3. **Read SaaS Custom Operation Result** (**Get Accounts**, `nativeIdentity eq requestID`) loads persisted `sod-remediation:form-email-header`, `form-email-body`, and `form-email-recipients`.
4. **Send Email** binds those attributes to `subject`, `body`, and `recipientEmailList`. The HTML body already contains the standalone form link (`form-url` is not duplicated in the email step).

**Remediation workflow integration**

Runs on form submit — no connector invoke. Reads the bundled seed form definition by ID (re-point `formDefinitionId` in the trigger filter after import).

1. Branch on `formData.action`: **Correct** vs **Mitigate** (compensating control).
2. **Correct** path: branch on `formData.remediationSide`, set access search from launch-time keys on the form instance:
   - `$.trigger.formInstanceInputs[0].groupAAccessSearch.value` or `groupBAccessSearch.value`
   - These mirror `formInput` values set at instance create by this operation
3. **Get Access** (search query) → **Manage Access** (`REVOKE_ACCESS`) removes revocable items from `targetIdentityId`.
4. **Mitigate** path: **HTTP Request** POSTs to `/violations/v1/{violationId}/controls` with `control` and `comments` from `formData`.

> **Import note:** Export snapshots embed tenant-specific connector IDs, OAuth parameter refs, form definition UUIDs, and owner identity IDs. Treat bundled JSON as templates — update Configuration and the form-submitted trigger filter to match your deployed form definition after the first `custom:sod-remediation` invoke creates or patches it.

## Workflow integration

Manual or custom orchestration follows the same contract as the bundled exports:

1. Invoke `custom:sod-remediation` with violation ID and form name.
2. Read persisted output via **Get Accounts** filtered by `requestId` (`form-url`, email fields).
3. Send email to `form-email-recipients` (bind to Send Email `recipientEmailList`) with `form-email-body` as the HTML body, `form-email-header` as the subject, and a link to `form-url`.
4. Wait for form submission; read **user decisions** from submitted `formData`: `action`, `remediationSide`, `control`, `comments`.
5. Read **launch-time workflow keys** from the completed form instance **`formInput`** (not `formData`):
   - `violationId`, `targetIdentityId`, `groupAAccessSearch`, `groupBAccessSearch`
   - Access search strings include **revocable** access path ids only (`id:x OR id:y`); non-revocable entitlements granted via role or access profile on the same side are omitted from the filter
   - On a **form-submitted** event trigger, ISC exposes the same values under `formInstanceInputs` (see Remediation export above). After a **Wait for Form** / **Get Form Instance** step, use `{{$.form.formInput.groupAAccessSearch}}`.
6. Select the access-search string for the chosen side using `formData.remediationSide`.
7. Execute corrective revoke or apply compensating control in separate workflow HTTP actions (not handled by the connector).

Workflow keys are declared in the form definition `formInput` schema and populated at instance create. They do **not** need hidden form elements and do **not** round-trip through `formData`.

After upgrading the connector, re-invoke `custom:sod-remediation` so the form-definition watermark patches the tenant form definition before creating a new instance. Each invoke creates a **new** form instance; re-opening a URL from an already-submitted instance shows "already submitted".

## Form HTML (group columns and situation summary)

Launch-time `formInput` carries **six** STRING HTML fields for the Correct section columns:

| Field | When shown |
|---|---|
| `groupAContentsHtml`, `groupBContentsHtml` | Plain flat access-path lists with type tags and icon suffixes — before `remediationSide` is selected |
| `groupAContentsHtmlAsKept`, `groupBContentsHtmlAsKept` | Green keep outcome panel — after the opposite side is selected for removal |
| `groupAContentsHtmlAsRemoved`, `groupBContentsHtmlAsRemoved` | Red remove outcome panel — after that side is selected for removal |

Bundled seed `formConditions` swap DESCRIPTION elements on `remediationSide` selection (live visual update).

`situationSummaryHtml` reuses the same access-path rendering (flat lists, icon-only suffixes) and appends a single **emoji legend** footer decoding privileged, keep, and revocability icons. Group column variants do not include the legend. Persisted `form-email-body` remains the compact summary without legend or full path lists.

**Form definition migration:** Updated seeds change the form fingerprint. Tenants only receive the new six-field layout and outcome-panel conditions when they use a **new** `formName`. Reusing an existing definition name keeps the prior two-field layout until you adopt a new form name.

## Local development

```bash
npm run call:op -- payloads/sod-remediation-offline.json
npm run call:op -- payloads/sod-remediation.json
```

Experimental APIs require header `X-SailPoint-Experimental: true` (handled internally). Offline payload runs use canned violation data when no `config` is provided.

See the root [README](../../../README.md) for generic invoke envelope, persist inhibition (`testMode`), and result source setup.

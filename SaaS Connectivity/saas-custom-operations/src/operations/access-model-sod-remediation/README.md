# custom:access-model-sod-remediation

## Purpose

Proactive catalog hygiene: scan enabled roles and/or access profiles in scope, detect intrinsic SoD policy violations by entitlement intersection (via `policyQuery` parsing), and create standalone remediation forms for each **(access item, policy)** pair targeted to the **access item owner**.

Distinct from `custom:sod-remediation`, which remediates existing **identity violations**.

## Command

`custom:access-model-sod-remediation`

## Input

| Field | Required | Default | Description |
|---|---|---|---|
| `formName` | Yes | — | Shared tenant form definition name (ensure-from-seed on first use) |
| `scope` | No | `"*"` | ISC search filter; `"*"` lists all enabled items in each selected index |
| `searchIndices` | No | `["accessprofiles","roles"]` | Catalogs to scan; only `accessprofiles` and `roles` allowed |
| `policyScope` | No | `state eq "ENFORCED"` | Filter for SoD policies to evaluate |
| `disableLinks` | No | `false` (links enabled when `apiUrl` resolves) | When `true`, omits ISC admin UI deep links in form HTML (`situationSummaryHtml` and group columns). Does **not** remove `form-url` or the email remediation CTA |

## Output

### Invoke response (scan summary)

On success, `ctx.respond(summary)` returns an **operation response** envelope:

| Envelope field | Meaning |
|---|---|
| `name` | `custom:access-model-sod-remediation` |
| `status` | `success` |
| `responses` | Native identities persisted this invoke |
| `summary` | Scan rollup counters (below) |

| Summary field | Description |
|---|---|
| `access-model-sod-remediation:access-items-scanned` | Count of roles/APs evaluated |
| `access-model-sod-remediation:violations-found` | Count of (access item × policy) hits |
| `access-model-sod-remediation:forms-skipped` | Optional; violations skipped because the child persist account at `{requestId}:{accessItemId}:{policyId}` already exists |
| `access-model-sod-remediation:forms-skipped-instances` | Optional; global invoke-only list of skipped violations (child identity plus access item and policy context). Form URLs and email fields are **not** on the envelope — read them from the existing child account at `{requestId}:{accessItemId}:{policyId}` |
| `access-model-sod-remediation:forms-launch-failed` | Optional; form instance creation failures during the scan |
| `access-model-sod-remediation:forms-persist-failed` | Optional; child persist failures after a form was created |

These summary fields are declared under `OperationSignature.response`, **not** persisted on result-source identity `{requestId}`, and **not** account schema attributes.

### Scan idempotency and performance

Before launching a form for each violation, the scan checks whether a child result-source account already exists at `{requestId}:{accessItemId}:{policyId}`. When found, the handler skips form creation and child persist (no overwrite), increments `forms-skipped`, and appends an entry to `forms-skipped-instances` on **`ctx.res.send` only** (never persisted). Per-form outputs (`form-url`, email fields) for created or prior forms remain on child accounts via `ctx.persist` only — the invoke response carries rollup counters plus this skipped list, not individual form payloads. Form instance state is not queried for idempotency. Access-item owner resolution (and email) and access-item entitlement expansion are **memoized within the scan** to avoid repeated ISC calls on large catalogs.

### Child account (persisted) — `{requestId}:{accessItemId}:{policyId}` (one per form)

| Field | Description |
|---|---|
| `access-model-sod-remediation:form-url` | Standalone form URL |
| `access-model-sod-remediation:form-email-header` | Plain-text email subject for workflow Send Email |
| `access-model-sod-remediation:form-email-body` | HTML email body with remediation link |
| `access-model-sod-remediation:form-email-recipients` | Access item owner email addresses (`string[]`) |

Child form notification fields are built via the shared form notification envelope (`src/lib/form-notification/`).

## Invoke example

Use a stable `requestId` prefix (for example `access-model-sod`) — only **child** accounts are persisted at `{requestId}:{accessItemId}:{policyId}`. No account is written on bare `requestId`, including on terminal failure.

```json
{
    "type": "custom:access-model-sod-remediation",
    "input": {
        "requestId": "access-model-sod-001",
        "formName": "Access Model SOD Remediation",
        "scope": "*",
        "searchIndices": ["roles", "accessprofiles"]
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

Offline: [`payloads/access-model-sod-remediation-offline.json`](../../../payloads/access-model-sod-remediation-offline.json)

## Bundled workflows

Three ISC workflow exports under [`workflows/`](../../../workflows/) implement proactive access-model SoD remediation. Import all three and re-point **Configuration** variables to your tenant. Pair with [`custom:access-model-sod-remediation-apply`](../access-model-sod-remediation-apply/README.md) for the post-submit catalog correction step.

| Export | Trigger | Role |
|---|---|---|
| [`workflows/Access Model SOD - Analysis.json`](../../../workflows/Access%20Model%20SOD%20-%20Analysis.json) | Scheduled (daily) | Invoke this scan operation |
| [`workflows/Access Model SOD - Notification.json`](../../../workflows/Access%20Model%20SOD%20-%20Notification.json) | `idn:account-created` (filtered by `operationName`) | Email access item owner when a child persist account is created |
| [`workflows/Access Model SOD - Remediation.json`](../../../workflows/Access%20Model%20SOD%20-%20Remediation.json) | `sp:form-submitted` (filtered by remediation form definition ID) | Invoke `custom:access-model-sod-remediation-apply` |

End-to-end flow:

```
Scheduled / manual trigger
        │
        ▼
Access Model SOD - Analysis
  OAuth → invoke custom:access-model-sod-remediation
  (rollup counters on invoke response only)
        │
        ▼
Per violation: child account persisted at
  {requestId}:{accessItemId}:{policyId}
        │
        ▼
Access Model SOD - Notification (account-created event)
  Send Email from trigger.account.attributes (form-email-*)
        │
        ▼
Access item owner submits form (remediationSide)
        │
        ▼
Access Model SOD - Remediation
  OAuth → invoke custom:access-model-sod-remediation-apply
```

**Analysis workflow integration**

1. **Configuration** sets API URL, connector ID, and result source name.
2. **Call SaaS Custom Operation** invokes `custom:access-model-sod-remediation` with a stable scan `requestId` (export uses `access-model-sod-remediation`), `formName` `Access Model SOD Remediation`, and scan scope (`searchIndices`, `scope`).
3. Read rollup fields from the **invoke HTTP response body** — not from Get Accounts on `requestId` (no parent account is persisted).

**Notification workflow integration**

Event-driven — no connector invoke in this workflow.

1. Trigger: **Account Created** on the result source, advanced filter `operationName == custom:access-model-sod-remediation`.
2. **Send Email** reads email fields directly from the created child account on the event payload:
   - `access-model-sod-remediation:form-email-header` → subject
   - `access-model-sod-remediation:form-email-body` → body
   - `access-model-sod-remediation:form-email-recipients` → `recipientEmailList`

Each child account creation fires one notification. Skipped violations (existing child persist) do not emit a new account and therefore do not re-trigger email.

**Remediation workflow integration**

Handled by [`custom:access-model-sod-remediation-apply`](../access-model-sod-remediation-apply/README.md) — see that README for apply semantics. The export invokes apply with `formInstanceId` from `$.trigger.formInstanceId` on form submit.

> **Import note:** Re-point form-submitted trigger `formDefinitionId` to your tenant's **Access Model SOD Remediation** form definition (created or patched on first scan invoke). Connector IDs and OAuth refs are tenant-specific.

## Workflow integration

Manual or custom orchestration follows the same contract as the bundled exports:

1. Invoke scan; read rollup counts from the operation response **`summary`**: `summary['access-model-sod-remediation:access-items-scanned']`, `summary['access-model-sod-remediation:violations-found']`, and optional `summary['access-model-sod-remediation:forms-skipped']`, `summary['access-model-sod-remediation:forms-skipped-instances']`, `summary['access-model-sod-remediation:forms-launch-failed']`, and `summary['access-model-sod-remediation:forms-persist-failed']`.
2. For each violation, read **child** account at native identity `{requestId}:{accessItemId}:{policyId}` for `form-url` and `form-email-*` fields — or rely on an account-created event as the Notification export does.
3. Notify access item owner via Send Email using `form-email-header`, `form-email-body`, and `form-email-recipients` (bind to `recipientEmailList`).
4. On form submit, read `formData.remediationSide` (`groupA` | `groupB`) and entitlement id lists from **`formInput`** (`groupAIds`, `groupBIds` — JSON-stringified arrays, e.g. `JSON.parse(formInput.groupAIds)`).
5. Invoke `custom:access-model-sod-remediation-apply` with `formInstanceId` from the form trigger to apply the catalog correction (detach nested APs from roles or remove direct entitlements; remove entitlements from AP definitions when the access item is an AP). Re-invokes for the same form instance are idempotent — expect `skipped-already-applied` when a prior apply persist exists, or `skipped-already-clean` when the catalog already matches the decision.

## Form submit contract

| Layer | Fields |
|---|---|
| `formInput` (launch) | `parentRequestId` (scan invoke `requestId`), `accessItemId`, `accessItemType`, `accessItemName`, `policyId`, `policyName`, `situationSummaryHtml`, `groupAIds`, `groupBIds` (JSON arrays), three HTML column fields (see below) |
| `formData` (submit) | `remediationSide`, optional `comments` |

No action selector or Mitigate path.

## Form HTML (context panel and group columns)

The upper **context panel** is a single `situationSummaryHtml` DESCRIPTION with **What we found** / **What we need from you** blocks and ⚠️/ℹ️ signposting. When `config.apiUrl` is present, access item and policy display names link to ISC admin UI routes; offline invoke uses plain escaped text. See `src/lib/sod-form-html/README.md` for admin path templates.

Launch-time `formInput` carries **three** composite side-by-side column HTML fields (each embeds plain or outcome variants for both groups):

| Field | When shown |
|---|---|
| `groupColumnsHtmlPlain` | Plain lists with type tags — before `remediationSide` is selected |
| `groupColumnsHtmlWhenGroupARemoved` | Group A red / Group B green outcome panels — when Group A is selected for removal |
| `groupColumnsHtmlWhenGroupBRemoved` | Group B red / Group A green outcome panels — when Group B is selected for removal |

Bundled seed `formConditions` SHOW/HIDE the matching DESCRIPTION element when the recipient changes `remediationSide`. Direct role entitlements render as single flat lines. Nested access profiles render as **flat access profile lines** with an **offending entitlement mention** (for example `— offending: payment_issue`) so access item owners see the whole AP as the removable unit on roles. When online, entitlement and access profile display names in columns link to ISC admin UI routes. **No** revocability emojis or legend.

**Form definition migration:** Updated seeds change the form fingerprint. After deploying this connector version, re-invoke the scan with the **same** `formName` — `ensureFormDefinitionByName` detects a stale watermark and patches the existing definition in place. New form instances then get the unified context panel, admin links, and column layout. Already-assigned instances keep their launch-time HTML until recreated. Use a **new** `formName` only when you want to keep the prior definition unchanged alongside the updated one. Scan retries with the same `requestId` skip violations that already have a child persist account regardless of form instance state.

## Token scope requirements

- SoD policies list/read
- Roles and access profiles list/read (including entitlements and role AP membership)
- Custom Forms create/search
- Result source account persist (standard custom operation scopes)

## Local development

```bash
npm run call:op payloads/access-model-sod-remediation-offline.json
```

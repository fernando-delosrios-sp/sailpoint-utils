# custom:access-model-sod-remediation

## Purpose

Proactive catalog hygiene: scan enabled roles and/or access profiles in scope, detect intrinsic SoD policy violations by entitlement intersection (via `policyQuery` parsing), and create standalone remediation forms for each **(access item, policy)** pair targeted to the **policy owner**.

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

## Output

### Invoke response (scan summary)

On success, `ctx.res.send` returns rollup counters alongside `status: 'success'`:

| Field | Description |
|---|---|
| `access-model-sod-remediation:access-items-scanned` | Count of roles/APs evaluated |
| `access-model-sod-remediation:violations-found` | Count of (access item × policy) hits |
| `access-model-sod-remediation:forms-skipped` | Optional; ASSIGNED duplicate forms skipped |
| `access-model-sod-remediation:forms-persist-failed` | Optional; child persist failures during the scan |

These fields are **not** persisted on result-source identity `{requestId}`.

### Child account (persisted) — `{requestId}:{accessItemId}:{policyId}` (one per form)

| Field | Description |
|---|---|
| `access-model-sod-remediation:form-url` | Standalone form URL |
| `access-model-sod-remediation:form-email-header` | Plain-text email subject for workflow Send Email |
| `access-model-sod-remediation:form-email-body` | HTML email body with remediation link |
| `access-model-sod-remediation:form-email-recipients` | Policy owner email addresses (`string[]`) |

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

## Workflow integration

1. Invoke scan; read rollup counts from the **invoke response** (`access-model-sod-remediation:access-items-scanned`, `violations-found`, optional `forms-skipped` / `forms-persist-failed`).
2. For each violation, read **child** account at native identity `{requestId}:{accessItemId}:{policyId}` for `form-url` and `form-email-*` fields.
3. Notify policy owner via Send Email using `form-email-header`, `form-email-body`, and `form-email-recipients` (bind to `recipientEmailList`).
4. On form submit, read `formData.remediationSide` (`groupA` | `groupB`) and entitlement id lists from **`formInput`** (`groupAIds`, `groupBIds` — JSON-stringified arrays, e.g. `JSON.parse(formInput.groupAIds)`).
5. Downstream workflow removes entitlements on the chosen side from the role or access profile definition.

## Form submit contract

| Layer | Fields |
|---|---|
| `formInput` (launch) | `accessItemId`, `accessItemType`, `accessItemName`, `policyId`, `policyName`, `groupAIds`, `groupBIds` (JSON arrays), six HTML column fields (see below) |
| `formData` (submit) | `remediationSide`, optional `comments` |

No action selector or Mitigate path.

## Form HTML (group columns)

Launch-time `formInput` carries **three** composite side-by-side column HTML fields (each embeds plain or outcome variants for both groups):

| Field | When shown |
|---|---|
| `groupColumnsHtmlPlain` | Plain lists with type tags — before `remediationSide` is selected |
| `groupColumnsHtmlWhenGroupARemoved` | Group A red / Group B green outcome panels — when Group A is selected for removal |
| `groupColumnsHtmlWhenGroupBRemoved` | Group B red / Group A green outcome panels — when Group B is selected for removal |

Bundled seed `formConditions` SHOW/HIDE the matching DESCRIPTION element when the recipient changes `remediationSide`. Direct role entitlements render as single flat lines. Nested access profiles render as **flat access profile lines** with an **offending entitlement mention** (for example `— offending: payment_issue`) so policy owners see the whole AP as the removable unit on roles. **No** revocability emojis or legend.

**Form definition migration:** Updated seeds change the form fingerprint. Tenants only receive the new six-field layout when they use a **new** `formName` (ensure-by-name does not patch existing definitions). Reuse an existing name to keep the prior two-field layout until you adopt a new form name.

## Token scope requirements

- SoD policies list/read
- Roles and access profiles list/read (including entitlements and role AP membership)
- Custom Forms create/search
- Result source account persist (standard custom operation scopes)

## Local development

```bash
npm run call:op payloads/access-model-sod-remediation-offline.json
```

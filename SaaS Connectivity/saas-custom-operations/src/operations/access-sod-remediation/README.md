# custom:access-sod-remediation

## Purpose

Proactive catalog hygiene: scan enabled roles and/or access profiles in scope, detect intrinsic SoD policy violations by entitlement intersection (via `policyQuery` parsing), and create standalone remediation forms for each **(access item, policy)** pair targeted to the **policy owner**.

Distinct from `custom:sod-remediation`, which remediates existing **identity violations**.

## Command

`custom:access-sod-remediation`

## Input

| Field | Required | Default | Description |
|---|---|---|---|
| `formName` | Yes | — | Shared tenant form definition name (ensure-from-seed on first use) |
| `scope` | No | `"*"` | ISC search filter; `"*"` lists all enabled items in each selected index |
| `searchIndices` | No | `["accessprofiles","roles"]` | Catalogs to scan; only `accessprofiles` and `roles` allowed |
| `policyScope` | No | `state eq "ENFORCED"` | Filter for SoD policies to evaluate |

## Output (persisted)

### Parent account — `{requestId}`

| Field | Description |
|---|---|
| `access-sod-remediation:access-items-scanned` | Count of roles/APs evaluated |
| `access-sod-remediation:violations-found` | Count of (access item × policy) hits |
| `access-sod-remediation:forms-skipped` | Optional; ASSIGNED duplicate forms skipped |

### Child account — `{requestId}:{accessItemId}:{policyId}` (one per form)

| Field | Description |
|---|---|
| `access-sod-remediation:form-url` | Standalone form URL |
| `access-sod-remediation:form-email-header` | Plain-text email subject for workflow Send Email |
| `access-sod-remediation:form-email-body` | HTML email body with remediation link |
| `access-sod-remediation:form-email-recipients` | Policy owner email addresses (`string[]`) |

## Invoke example

```json
{
    "type": "custom:access-sod-remediation",
    "input": {
        "requestId": "req-access-sod-001",
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

Offline: [`payloads/access-sod-remediation-offline.json`](../../../payloads/access-sod-remediation-offline.json)

## Workflow integration

1. Invoke scan; read **parent** account by `requestId` for rollup counts.
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

Launch-time `formInput` carries **six** STRING HTML fields per side column set:

| Field | When shown |
|---|---|
| `groupAContentsHtml`, `groupBContentsHtml` | Plain lists with type tags — before `remediationSide` is selected |
| `groupAContentsHtmlAsKept`, `groupBContentsHtmlAsKept` | Green keep outcome panel — after the opposite side is selected for removal |
| `groupAContentsHtmlAsRemoved`, `groupBContentsHtmlAsRemoved` | Red remove outcome panel — after that side is selected for removal |

Bundled seed `formConditions` SHOW/HIDE the matching DESCRIPTION element when the recipient changes `remediationSide`. Entitlements render in a nested access-profile tree with type tags; **no** revocability emojis or legend.

**Form definition migration:** Updated seeds change the form fingerprint. Tenants only receive the new six-field layout when they use a **new** `formName` (ensure-by-name does not patch existing definitions). Reuse an existing name to keep the prior two-field layout until you adopt a new form name.

## Token scope requirements

- SoD policies list/read
- Roles and access profiles list/read (including entitlements and role AP membership)
- Custom Forms create/search
- Result source account persist (standard custom operation scopes)

## Local development

```bash
npm run call:op payloads/access-sod-remediation-offline.json
```

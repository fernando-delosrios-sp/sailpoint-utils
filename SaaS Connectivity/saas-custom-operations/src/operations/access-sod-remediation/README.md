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
| `access-sod-remediation:form-email-recipient` | Policy owner email address |

## Invoke example

```json
{
    "type": "custom:access-sod-remediation",
    "input": {
        "requestId": "req-access-sod-001",
        "formName": "Access Catalog SOD Remediation",
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
3. Notify policy owner via Send Email using `form-email-header`, `form-email-body`, and `form-email-recipient`.
4. On form submit, read `formData.remediationSide` (`groupA` | `groupB`) and entitlement id lists from **`formInput`** (`groupAIds`, `groupBIds` — JSON-stringified arrays, e.g. `JSON.parse(formInput.groupAIds)`).
5. Downstream workflow removes entitlements on the chosen side from the role or access profile definition.

## Form submit contract

| Layer | Fields |
|---|---|
| `formInput` (launch) | `accessItemId`, `accessItemType`, `accessItemName`, `policyId`, `policyName`, `groupAIds`, `groupBIds` (JSON arrays), HTML columns |
| `formData` (submit) | `remediationSide`, optional `comments` |

No action selector or Mitigate path.

## Token scope requirements

- SoD policies list/read
- Roles and access profiles list/read (including entitlements and role AP membership)
- Custom Forms create/search
- Result source account persist (standard custom operation scopes)

## Local development

```bash
npm run call:op payloads/access-sod-remediation-offline.json
```

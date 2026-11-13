# Microsoft 365 Access Profiles Guide

Guide for creating and synchronizing requestable SailPoint Identity Security Cloud (ISC) access profiles from Microsoft Entra `servicePlan` entitlements using `New-SailPointM365AccessProfile` (`Microsoft 365 Access Profiles.ps1`).

---

## 1. Overview & Capabilities

Microsoft 365 license bundles (such as E5 or Business Premium) contain dozens of individual service plans (e.g., Teams, Exchange Online, SharePoint). Managing these directly in ISC requires mapping GUIDs to friendly names.

`New-SailPointM365AccessProfile`:
- Discovers `servicePlan` entitlements from your Entra ID connector source.
- Downloads Microsoft's official licensing reference table to map GUIDs to friendly names (e.g., `FLOW_O365_P3` → `Power Automate for Office 365`).
- Creates requestable, enabled ISC Access Profiles with standardized naming conventions.
- Optionally creates a Source Application and attaches all generated access profiles to it.
- Generates JSON and CSV audit manifests to allow replayable, version-controlled synchronization.

---

## 2. Prerequisites

- PowerShell 7+ (`pwsh`)
- `PSSailpoint` module installed from PowerShell Gallery
- SailPoint Personal Access Token (PAT) or Client Credentials with permissions to manage access profiles and source apps
- Authentication provided via:
  - Environment variables: `SAIL_BASE_URL`, `SAIL_CLIENT_ID`, `SAIL_CLIENT_SECRET`
  - Or a local `config.json`
  - Or interactive prompt

---

## 3. Interactive Usage

```powershell
New-SailPointM365AccessProfile
# Or directly via script:
.\Microsoft 365 Access Profiles.ps1
```

Guided prompts:
1. Select the ISC tenant environment (from `~/.sailpoint/config.yaml`).
2. Smoke-test authentication.
3. Select an aggregated Entra source.
4. Multi-select service plans (shows both Microsoft friendly name and internal SKU GUID).
5. Specify naming prefix (default: `M365 - `).
6. Optionally specify a Source Application name.
7. Choose handling for existing items (`Ask`, `Skip`, or `Update`).

---

## 4. Parameterized CLI Usage

```powershell
$env:SAIL_BASE_URL = 'https://tenant.api.identitynow.com'
$env:SAIL_CLIENT_ID = 'pat-client-id'
$env:SAIL_CLIENT_SECRET = 'pat-client-secret'

# Create access profiles for Teams, Exchange, and Power Automate
New-SailPointM365AccessProfile `
  -SourceId 'fd753b8266b64d09805d101b77bc35df' `
  -PlanValues 'FLOW_O365_P3,TEAMS1,EXCHANGE_S_ENTERPRISE' `
  -AccessProfilePrefix 'M365 - ' `
  -ApplicationName 'Microsoft 365 Users' `
  -NonInteractive

# Replay an earlier run from a saved manifest
New-SailPointM365AccessProfile `
  -PreviousManifestPath '~/.sailpoint-connect/m365/m365-access-profiles-manifest.json' `
  -ExistingItemAction Update
```

---

## 5. Troubleshooting

| Symptom | Cause and Fix |
| :--- | :--- |
| `ClientId, ClientSecret or TokenUrl Missing` | Set `SAIL_*` environment variables or supply credentials interactively. |
| No Entra sources listed | Ensure your Entra ID / Azure AD source has completed aggregation and aggregated `servicePlan` entitlements. |
| Friendly names display as internal IDs | Outbound HTTPS access to Microsoft's licensing CSV URL failed. Check connectivity. |
| Source app API error | Experimental APIs require the `X-SailPoint-Experimental` header (handled automatically) and appropriate PAT scopes. |

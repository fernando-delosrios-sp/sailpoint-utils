# `Connect-SailPointAzure`

Configures SailPoint ISC Microsoft Entra ID connectors and Entro onboarding.

## Synopsis

```powershell
Connect-SailPointAzure [-Wizard] [-Connector] [-Entro]
    [-Access <String>] [-Action <String>] [-TenantId <String>]
    [-ApplicationName <String>] [-EnvironmentNickname <String>]
    [-RotateSecret] [-Project <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointAzure` automates Microsoft Entra ID (formerly Azure AD) integration setup:
1. **Microsoft Entra ID connector**: Creates or updates Microsoft Entra app registration, assigns Microsoft Graph permissions (`ReadOnly` or `ReadWrite`), grants admin consent, generates client credentials, and outputs connection settings for ISC.
2. **Entro Microsoft integration**: Registers the tenant with Entro.
3. **Combined Entra + Entro**: Configures both in one session.

## Parameters

### `-Wizard`
Runs the guided interactive setup questionnaire. You can type every value. A signed-in Azure CLI can offer existing names. It does not create the application. The default action is a checklist.

### `-Action`
`BuildRequirements`, `Check` (read an existing app registration's granted permissions), `BuildScript`, or `Run`. Only `Run` changes the tenant, after you confirm.

### `-Connector`
Targets the Microsoft Entra ID connector application registration.

### `-Entro`
Targets the Entro Microsoft integration.

### `-TenantId`
Microsoft Entra tenant ID (GUID). Discovered automatically if signed in to `az` or Microsoft Graph.

### `-ApplicationName`
Display name of the app registration. `Check` reads the registration that already has this name. `Run` creates or updates it. Default: `SailPoint-ISC-EntraID`.

### `-Access`
Permission level: `ReadOnly` or `ReadWrite`.

### `-RotateSecret`
Generates a new client secret even if the application registration already exists.

## Examples

### Example 1: Interactive wizard
```powershell
Connect-SailPointAzure -Wizard
```

### Example 2: Read an existing app registration
```powershell
Connect-SailPointAzure -Connector -ApplicationName "SailPoint-ISC" -Access ReadOnly -Action Check
```
Compares admin-consented application permissions with the ReadOnly requirements. Nothing is created.

### Example 3: Non-interactive run
```powershell
Connect-SailPointAzure -Connector -TenantId "16131240-2ba6-4627-ad0a-275f8450303c" -ApplicationName "SailPoint-ISC" -Access ReadOnly -Action Run
```
This is the action that changes the tenant.

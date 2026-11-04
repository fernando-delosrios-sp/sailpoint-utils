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
Runs the guided interactive setup questionnaire.

### `-Connector`
Targets the Microsoft Entra ID connector application registration.

### `-Entro`
Targets the Entro Microsoft integration.

### `-TenantId`
Microsoft Entra tenant ID (GUID). Discovered automatically if signed in to `az` or Microsoft Graph.

### `-ApplicationName`
Name for the application registration. Default: `SailPoint-ISC-EntraID`.

### `-Access`
Permission level: `ReadOnly` or `ReadWrite`.

### `-RotateSecret`
Generates a new client secret even if the application registration already exists.

## Examples

### Example 1: Interactive wizard
```powershell
Connect-SailPointAzure -Wizard
```

### Example 2: Non-interactive run
```powershell
Connect-SailPointAzure -Connector -TenantId "16131240-2ba6-4627-ad0a-275f8450303c" -Access ReadOnly -Action Run
```

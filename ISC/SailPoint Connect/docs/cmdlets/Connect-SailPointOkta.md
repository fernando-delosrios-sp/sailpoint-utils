# `Connect-SailPointOkta`

Configures SailPoint ISC Okta SaaS connector (SailPoint Fabric) and Entro onboarding.

## Synopsis

```powershell
Connect-SailPointOkta [-Wizard] [-Connector] [-Entro]
    [-Action <String>] [-OktaDomain <String>] [-ClientId <String>]
    [-TokenUrl <String>] [-Scope <String>] [-JwtHeader <String>]
    [-PrivateKey <String>] [-PrivateKeyPassword <String>]
    [-Project <String>] [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointOkta` configures:
1. **SailPoint Fabric (Okta SaaS Connector)**: OAuth 2.0 Service App authentication using private key JWT assertions.
2. **Entro Okta**: Configures Okta API Services integration with public key authentication.

## Parameters

### `-Wizard`
Launches the interactive wizard.

### `-Connector`
Selects the SailPoint Fabric Okta connector.

### `-Entro`
Selects Entro Okta onboarding.

### `-OktaDomain`
Okta tenant domain (e.g., `company.okta.com`).

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Interactive Wizard
```powershell
Connect-SailPointOkta -Wizard
```

### Example 2: Audit Okta Service App
```powershell
Connect-SailPointOkta -Connector -OktaDomain "mycompany.okta.com" -ClientId "0oa123456789" -Action Check
```

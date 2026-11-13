# `Connect-SailPointServiceNow`

Configures Entro ServiceNow integration onboarding.

## Synopsis

```powershell
Connect-SailPointServiceNow [-Wizard] [-Entro] [-Action <String>]
    [-InstanceUrl <String>] [-Project <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointServiceNow` sets up REST API credentials and read-only roles for Entro non-human identity governance across ServiceNow instances.

## Parameters

### `-Wizard`
Launches the interactive questionnaire.

### `-InstanceUrl`
ServiceNow instance URL (e.g., `https://mycompany.service-now.com`).

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Interactive Wizard
```powershell
Connect-SailPointServiceNow -Wizard
```

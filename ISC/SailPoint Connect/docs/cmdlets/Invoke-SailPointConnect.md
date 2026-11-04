# `Invoke-SailPointConnect`

Unified entry point for SailPoint Connect.

## Synopsis

```powershell
Invoke-SailPointConnect [[-Platform] <String>] [-Wizard] [-Project <String>]
    [-Action <String>] [-OutputDirectory <String>] [-NonInteractive]
    [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

`Invoke-SailPointConnect` (aliased as `sailpoint-connect`) is the top-level driver for the SailPoint Connect module. It provides a single command to configure SailPoint ISC connectors, Entro cloud integrations, Microsoft 365 access profiles, and IQService infrastructure.

- When invoked with **no arguments**, it opens an interactive platform picker.
- When invoked with `-Platform <Platform> -Wizard`, it launches the progressive-disclosure questionnaire for that specific platform.
- Output artifacts and logs are automatically organized under `~/.sailpoint-connect/<Project>/`.

## Parameters

### `-Platform`
Target platform or integration:
- `AWS`: Amazon Web Services (SaaS Connector, CIEM, Entro)
- `Azure`: Microsoft Azure & Entra ID (Connector, Entro)
- `GoogleCloud` (or `GCP`): Google Workspace & Cloud (Connector, CIEM, Entro)
- `Databricks`: Databricks Account & Metastore connector
- `IQService`: IQService Host Lifecycle & LDAPS
- `M365AccessProfiles`: Microsoft 365 Entra Service Plan Access Profiles

### `-Wizard`
Launches the interactive questionnaire for the selected platform.

### `-Project`
Name of the project workspace under `~/.sailpoint-connect/`. If omitted in interactive mode, prompts to select an existing workspace or create a new one.

### `-Action`
Specifies what to do:
- `Run`: Applies changes directly against cloud and tenant APIs.
- `BuildScript`: Renders a standalone PowerShell automation script.
- `BuildRequirements`: Generates a customer-facing Markdown requirements document.

### `-OutputDirectory`
Overrides the directory where generated scripts or requirements files are saved (logs remain under `~/.sailpoint-connect/`).

### `-NonInteractive`
Executes headlessly. Required parameters must be provided; any missing required parameter results in a terminating error.

## Examples

### Example 1: Interactive platform menu
```powershell
Invoke-SailPointConnect
```

### Example 2: Launch guided AWS wizard
```powershell
Invoke-SailPointConnect -Platform AWS -Wizard
```

### Example 3: Non-interactive requirements build
```powershell
Invoke-SailPointConnect -Platform Azure -Action BuildRequirements -Project "demo-customer"
```

## See Also
- [`Connect-SailPointAWS`](Connect-SailPointAWS.md)
- [`Connect-SailPointAzure`](Connect-SailPointAzure.md)
- [`Connect-SailPointGoogleCloud`](Connect-SailPointGoogleCloud.md)
- [`Get-SailPointConnectProject`](Get-SailPointConnectProject.md)

# SailPoint Connect Documentation

Welcome to the documentation for **SailPoint Connect** — a progressive-disclosure PowerShell module for configuring SailPoint Identity Security Cloud (ISC) connectors, Entro cloud integrations, Microsoft 365 access profiles, and IQService host infrastructure.

---

## Quick Navigation

- [Installation & Quick Start](#installation--quick-start)
- [Command Reference (Cmdlets)](#command-reference)
- [Architecture & Workspace Directory (`~/.sailpoint-connect`)](#architecture--workspaces)
- [Progressive Disclosure Guide](#progressive-disclosure)
- [Prerequisites & Toolchain](#prerequisites--toolchain)

---

## Installation & Quick Start

### Installation

Install directly from the PowerShell Gallery (PowerShell 7+ required):

```powershell
Install-Module -Name SailPoint.Connect -Scope CurrentUser
```

Or update an existing installation:

```powershell
Update-Module -Name SailPoint.Connect
```

### Quick Start

Launch the interactive menu to select your platform:

```powershell
Invoke-SailPointConnect
# Or using the alias:
sailpoint-connect
```

Or jump straight to your target platform with guided questionnaires:

```powershell
# AWS (SaaS connector, CIEM, or Entro)
Connect-SailPointAWS -Wizard

# Azure / Microsoft Entra ID
Connect-SailPointAzure -Wizard

# Google Cloud & Google Workspace
Connect-SailPointGoogleCloud -Wizard

# Databricks Account & Metastore
Connect-SailPointDatabricks -Wizard
```

---

## Command Reference

| Cmdlet | Alias | Description |
| :--- | :--- | :--- |
| [`Invoke-SailPointConnect`](cmdlets/Invoke-SailPointConnect.md) | `sailpoint-connect` | Unified entry point with interactive platform picker |
| [`Connect-SailPointAWS`](cmdlets/Connect-SailPointAWS.md) | — | Configures AWS SaaS connector, CIEM, and Entro |
| [`Connect-SailPointAzure`](cmdlets/Connect-SailPointAzure.md) | — | Configures Microsoft Entra ID connector and Entro |
| [`Connect-SailPointGoogleCloud`](cmdlets/Connect-SailPointGoogleCloud.md) | `Connect-SailPointGCP` | Configures Google Workspace connector, GCP CIEM, and Entro |
| [`Connect-SailPointDatabricks`](cmdlets/Connect-SailPointDatabricks.md) | — | Configures Databricks service principal and OAuth M2M |
| [`Start-SailPointIQServiceControl`](cmdlets/Start-SailPointIQServiceControl.md) | — | Installs, upgrades, and streams IQService logs on Windows |
| [`New-SailPointM365AccessProfile`](cmdlets/New-SailPointM365AccessProfile.md) | — | Discovers Entra service plans and creates ISC access profiles |
| [`Get-SailPointConnectProject`](cmdlets/Get-SailPointConnectProject.md) | — | Lists all project workspaces under `~/.sailpoint-connect/` |
| [`Set-SailPointConnectProject`](cmdlets/Set-SailPointConnectProject.md) | — | Sets the default active project workspace |

---

## Architecture & Workspaces

All project workspaces, activity logs, runbooks, and saved selections are preserved centrally under the user's home folder:

```
~/.sailpoint-connect/
├── current.json                       # Active project pointer
└── <ProjectName>/
    ├── selection.json                 # Last chosen target & parameters
    ├── selections.jsonl               # Historical run audit log
    ├── operator-actions.md            # Action items for manual steps
    └── <Platform>/
        └── <Integration>/
            ├── activity.log           # Full step-by-step execution log
            ├── <target>.ps1           # Generated standalone script (-Action BuildScript)
            └── <target>-requirements.md # Generated checklist (-Action BuildRequirements)
```

Read more in the [Architecture & Workspaces Guide](guides/architecture-and-workspaces.md).

---

## Progressive Disclosure

Every platform wizard supports 3 execution layers:

1. **Interactive Guided Mode (`-Wizard`)**: Step-by-step questionnaire with dynamic auto-discovery of cloud resources (IAM roles, CloudTrail buckets, tenants, projects).
2. **Action Selection (`-Action`)**:
   - `Run`: Applies changes directly to cloud / tenant.
   - `BuildScript`: Generates an offline `.ps1` script for approval and change management.
   - `BuildRequirements`: Produces a complete Markdown requirements checklist for customer admins.
3. **Headless Automation (`-NonInteractive`)**: Designed for CI/CD pipelines and automated deployments.

Read more in the [Progressive Disclosure Guide](guides/progressive-disclosure.md).

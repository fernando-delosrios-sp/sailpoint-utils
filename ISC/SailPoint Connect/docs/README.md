# SailPoint Connect Documentation

Welcome to the documentation for **SailPoint Connect** — a progressive-disclosure PowerShell module for configuring SailPoint Identity Security Cloud (ISC) connectors, Entro cloud integrations, Microsoft 365 access profiles, and IQService host infrastructure.

Nothing in your tenant is created or updated unless you choose `Run` and confirm. Start with [What SailPoint Connect changes](guides/what-it-changes.md).

---

## Quick Navigation

- [Installation & Quick Start](#installation--quick-start)
- [Command Reference (Cmdlets)](#command-reference)
- [Architecture & Workspace Directory (`~/.sailpoint-connect`)](#architecture--workspaces)
- [What SailPoint Connect changes](guides/what-it-changes.md)
- [Progressive Disclosure Guide](#progressive-disclosure)
- [Connector & Platform Permissions Breakdown](guides/connector-permissions-breakdown.md)
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
| [`Connect-SailPointGoogleCloud`](cmdlets/Connect-SailPointGoogleCloud.md) | — | Configures Google Workspace connector, GCP CIEM, and Entro |
| [`Connect-SailPointDatabricks`](cmdlets/Connect-SailPointDatabricks.md) | — | Configures Databricks service principal and OAuth M2M |
| [`Invoke-SailPointIQServiceControl`](cmdlets/Start-SailPointIQServiceControl.md) | `Start-SailPointIQServiceControl` | Installs, upgrades, and streams IQService logs on Windows |
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
            ├── <target>-requirements.md # Generated checklist (-Action BuildRequirements)
            └── <target>-check.md     # Read-only gap report (-Action Check)
```

Read more in the [Architecture & Workspaces Guide](guides/architecture-and-workspaces.md).

---

## Progressive Disclosure

Every platform wizard supports the same choices. Discovery is optional, and only `Run` writes to the tenant.

1. **Interactive Guided Mode (`-Wizard`)**: The first question is what you want back: a checklist, a read-only check, a script, or an apply. Later questions only collect what that choice needs. You can type every value. If you are signed in, some questions also offer names that already exist. The default is `BuildRequirements`.
2. **Action Selection (`-Action`)**:
   - `BuildRequirements`: Markdown checklist for the team that owns the tenant. Nothing is created.
   - `Check`: Reads an existing role, app registration, or service account and reports gaps. Nothing is created.
   - `BuildScript`: Offline `.ps1` for review and change management. Nothing is created until that script is run.
   - `Run`: The only action that applies changes, and only after you confirm.
3. **Headless Automation (`-NonInteractive`)**: Pass the parameters explicitly, including `-Action`. `Check` fails the command when the existing identity does not meet the requirements, and still does not change it.

Read more in the [Progressive Disclosure Guide](guides/progressive-disclosure.md).

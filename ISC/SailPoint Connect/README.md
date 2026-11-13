# SailPoint Connect

**SailPoint Connect** is an interactive, progressive-disclosure PowerShell tool and module for configuring, verifying, and deploying cloud and SaaS integrations across **SailPoint Fabric** (ISC SaaS connectors), **SailPoint CIEM**, and **Entro**. It also manages **IQService Windows hosts** and generates requestable **Microsoft 365 access profiles**.

---

## 🛡️ The Safe-by-Default Philosophy

> [!IMPORTANT]
> **Nothing in your tenant or cloud provider is created or changed unless you explicitly choose `Run` and answer `yes`.**

Connecting enterprise identity governance to production clouds should never require blind trust. SailPoint Connect is structured around four safe-by-default paths:

| Action | What It Does | Changes to Cloud / Tenant? |
| :--- | :--- | :---: |
| **`BuildRequirements`** *(Default)* | Generates a clean Markdown requirements checklist specifying the exact role, permissions, and settings required. | **Zero changes** |
| **`Check`** | Audits an **already existing** IAM role, app registration, or service account in your cloud and reports gaps. | **Zero changes (Read-only)** |
| **`BuildScript`** | Generates an offline `.ps1` deployment script for peer review and change-management approval. | **Zero changes until run** |
| **`Run`** | Directly applies the required identity configuration via the official cloud CLI. | **Prompts for confirmation first** |

---

## 🚀 Installation & Quick Start

### 1. Requirements

SailPoint Connect runs on **PowerShell 7+** (`pwsh`) on macOS, Windows, and Linux. On Windows, use the PowerShell 7 app, which sits beside the built-in Windows PowerShell 5.1 (`powershell.exe`). Install PowerShell 7 or later, then run the module from a `pwsh` session.

Confirm the version:

```powershell
pwsh -NoLogo -Command '$PSVersionTable.PSVersion'
```

Major version 7 or higher is the expected result.

#### macOS

With [Homebrew](https://brew.sh/):

```bash
brew install --cask powershell
```

Microsoft's supported installer is the signed package on the [PowerShell releases](https://github.com/PowerShell/PowerShell/releases) page (`powershell-*-osx-arm64.pkg` on Apple silicon, `powershell-*-osx-x64.pkg` on Intel). Details: [Install PowerShell on macOS](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-macos).

#### Windows

PowerShell 7 installs beside Windows PowerShell 5.1. On Windows 11 or Windows Server 2025:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

Start **PowerShell 7** from the Start menu, or run `pwsh`. The **Windows PowerShell** shortcut is version 5.1. On Windows Server without `winget`, install the MSI from the [releases](https://github.com/PowerShell/PowerShell/releases) page. Details: [Install PowerShell on Windows](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows).

#### Linux

**Ubuntu** 22.04, 24.04, or 26.04. This registers the Microsoft package repository, then installs PowerShell:

```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
source /etc/os-release
wget -q "https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
```

**Red Hat Enterprise Linux** 8, 9, or 10:

```bash
source /etc/os-release
majorver=${VERSION_ID%.*}
curl -sSL -O "https://packages.microsoft.com/config/rhel/$majorver/packages-microsoft-prod.rpm"
sudo rpm -i packages-microsoft-prod.rpm
rm packages-microsoft-prod.rpm
sudo dnf install powershell -y
```

Debian and other distributions: [Install PowerShell on Linux](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux). Then run `pwsh`.

Cloud CLIs used by `Run` are listed in [Prerequisites & Toolchain](docs/guides/prerequisites-and-toolchain.md).

### 2. Install from PowerShell Gallery

```powershell
Install-Module -Name SailPoint.Connect -Scope CurrentUser
```

To update to the latest release:

```powershell
Update-SailPointConnect
# Or via alias
sailpoint-connect -Update
```

### 3. Launch the Unified Wizard

```powershell
# Open interactive menu (keyboard-driven navigation)
sailpoint-connect
# Or cmdlet
Invoke-SailPointConnect
```

### 4. Direct Platform Commands

You can jump straight into any platform's interactive questionnaire:

```powershell
Connect-SailPointAWS -Wizard
Connect-SailPointAzure -Wizard
Connect-SailPointGoogleCloud -Wizard
Connect-SailPointGitHub -Wizard
Connect-SailPointSalesforce -Wizard
Connect-SailPointOkta -Wizard
Connect-SailPointCrowdStrike -Wizard
Connect-SailPointDatabricks -Wizard
```

### 5. Running Locally from Repository

If you are working directly in this repository without installing the module:

```powershell
./AWS.ps1 -Wizard
./Azure.ps1 -Wizard
./GitHub.ps1 -Wizard
```

---

## 🌐 Supported Platforms & Integrations

SailPoint Connect supports **13 platforms and cloud targets** across **SailPoint Fabric**, **CIEM**, and **Entro**, plus dedicated host and governance utilities:

| Platform / Target | SailPoint Fabric | CIEM | Entro | Authentication / Credential Model | Primary Cmdlet / Launcher |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Amazon Web Services (AWS)** | ✅ | ✅ | ✅ | IAM Role (`sts:AssumeRole` + `ExternalId`) | `Connect-SailPointAWS`<br>`./AWS.ps1` |
| **Microsoft Azure & Entra ID** | ✅ | ✅ | ✅ | Entra App Registration (`ClientSecret`) | `Connect-SailPointAzure`<br>`./Azure.ps1` |
| **Google Cloud & Workspace** | ✅ | ✅ | ✅ | Service Account Key (JSON), OAuth2, WIF | `Connect-SailPointGoogleCloud`<br>`./Google Cloud.ps1` |
| **GitHub** | ✅ | ❌ | ✅ | GitHub App (PEM Key) or Organization PAT | `Connect-SailPointGitHub`<br>`./GitHub.ps1` |
| **Okta** | ✅ | ❌ | ✅ | OAuth Service App (JWT + PEM), API Services | `Connect-SailPointOkta`<br>`./Okta.ps1` |
| **CrowdStrike Falcon** | ✅ | ❌ | ✅ | OAuth2 API Client (`ClientId` + `ClientSecret`) | `Connect-SailPointCrowdStrike`<br>`./CrowdStrike.ps1` |
| **Slack Enterprise Grid** | ✅ | ❌ | ✅ | Bot, User, and App-Level Tokens | `Connect-SailPointSlack`<br>`./Slack.ps1` |
| **GitLab** | ✅ | ❌ | ✅ | Personal / Group Access Token | `Connect-SailPointGitLab`<br>`./GitLab.ps1` |
| **Salesforce** | ✅ | ❌ | ✅ | Connected App (OAuth Client Secret / Token) | `Connect-SailPointSalesforce`<br>`./Salesforce.ps1` |
| **Databricks** | ✅ | ❌ | ❌ | Service Principal (`ClientId` + `ClientSecret`) | `Connect-SailPointDatabricks`<br>`./Databricks.ps1` |
| **Snowflake** | ❌ | ❌ | ✅ | Key-Pair Authenticated User | `Connect-SailPointSnowflake`<br>`./Snowflake.ps1` |
| **ServiceNow** | ❌ | ❌ | ✅ | REST API Key / Credentials | `Connect-SailPointServiceNow`<br>`./ServiceNow.ps1` |
| **HashiCorp Vault** | ❌ | ❌ | ✅ | Vault Policy Token | `Connect-SailPointHashiCorpVault`<br>`./HashiCorp Vault.ps1` |

### Specialized Host & Governance Utilities

- **Windows IQService Host Control (`Invoke-SailPointIQServiceControl` / `./IQService Control.ps1`):** Complete lifecycle management for Windows IQService hosts (download, register, upgrade, trace levels, log streaming, and **Active Directory LDAPS TLS** certificate setup).
- **Microsoft 365 Access Profiles (`New-SailPointM365AccessProfile` / `./Microsoft 365 Access Profiles.ps1`):** Discovers Entra service plans, maps GUIDs to human-friendly licensing names, and creates requestable ISC access profiles.

---

## 🎯 How to Use SailPoint Connect

### 1. Interactive Mode (Default for Operators)

Launch `sailpoint-connect` to open the interactive operator console:
- **Up/Down** (or `j`/`k`) moves between items.
- **Space** toggles multi-select options.
- **Enter** confirms your selection.
- **Esc** goes back to the previous question.
- **Ctrl+C** exits safely at any time.

The wizard guides you through:
1. **Workspace Project:** Selects or creates an isolated workspace under `~/.sailpoint-connect/`.
2. **Action:** Pick `BuildRequirements`, `Check`, `BuildScript`, or `Run`.
3. **Platform & Integration:** Select target platform and product (**SailPoint Fabric**, **CIEM**, or **Entro**).
4. **Access Level:** Choose between `ReadOnly` (aggregation only) and `ReadWrite` (provisioning enabled).
5. **Optional Feature Packs:** Select optional add-ons (such as AI Agent Governance, Activity Insights, or Delta Aggregation).

### 2. Auditing Existing Cloud Identities (`-Action Check`)

When an identity was created by another team, use `Check` to verify compliance without changing anything:

```powershell
# AWS: Inspect an existing IAM role
Connect-SailPointAWS -Access ReadOnly -RoleName 'SailPointAWSRole' -Action Check

# Azure: Audit granted Graph permissions and directory roles on an Entra app
Connect-SailPointAzure -ApplicationName 'SailPoint-ISC' -Access ReadOnly -Action Check

# Google Cloud: Verify IAM permissions on a service account
Connect-SailPointGoogleCloud -ProjectId 'corp-sec' -OrganizationId '123456789' -Action Check
```

The output generates a clear Markdown gap report (`*-check.md`) indicating whether the identity:
- ✅ **Meets all requirements**.
- ⚠️ **Lacks specific permissions** (with the exact missing actions listed).
- ℹ️ **Requires manual portal steps** (such as Google domain-wide delegation or Salesforce Connected App policies).

### 3. Generating a Requirements Checklist (`-Action BuildRequirements`)

To hand off requirements to your cloud platform or security operations team:

```powershell
Connect-SailPointAWS `
  -Access ReadOnly `
  -Feature ActivityInsights,AgentDiscovery `
  -Action BuildRequirements
```

This generates `*-requirements.md` specifying the exact minimum IAM statements and trust relationships needed.

### 4. Headless Automation & Scripting (`-NonInteractive`)

For CI/CD pipelines and repeatable change deployments, run commands non-interactively:

```powershell
Connect-SailPointAzure `
  -TenantId 'contoso.onmicrosoft.com' `
  -ApplicationName 'SailPoint-ISC' `
  -Feature AccessPackages `
  -DirectoryRole UserAdministrator `
  -Action Run `
  -NonInteractive
```

---

## 🤖 AI Agent Governance (SailPoint Agentic Fabric)

SailPoint Connect includes native discovery for Non-Human Identities (NHI) and AI agents across major enterprise ecosystems:

- **AWS Bedrock & AgentCore:** Discovers Bedrock agents, knowledge bases, agent runtimes, and Amazon Lex bots (`-Feature AgentDiscovery`).
- **Microsoft Azure AI Foundry:** Governs AI Foundry project agents across Azure subscriptions (`-Feature CopilotDiscovery`).
- **Microsoft Copilot Studio & Agent 365:** Automates Dataverse security roles (`SailPoint BotReader` with Global read depth) and generates delegated refresh tokens (`-Feature CopilotDiscovery,Agent365`).
- **Google Vertex AI:** Discovers Vertex AI Reasoning Engines and deployed agents across GCP regions (`-Feature AgentDiscovery`).
- **Salesforce Agentforce:** Governs `BotDefinition` and `BotVersion` sObjects for Salesforce AI bots (`-Feature AgentDiscovery`).
- **GitHub Copilot:** Governs organization Copilot seat assignments and installed GitHub Apps.

---

## 📁 Workspaces & Audit History (`~/.sailpoint-connect/`)

All integration outputs, checklists, gap reports, and execution logs are organized centrally under your user profile:

```
~/.sailpoint-connect/
├── current.json                       # Currently active project pointer
└── <ProjectName>/
    ├── selection.json                 # Last chosen target & parameters (with masked secrets)
    ├── selections.jsonl               # Historical audit trail of all runs
    ├── operator-actions.md            # Pending manual actions required in provider consoles
    └── <Platform>/
        └── <Integration>/
            ├── activity.log           # Full timestamped execution log
            ├── <target>.ps1           # Generated offline script (-Action BuildScript)
            ├── <target>-requirements.md # Requirements checklist (-Action BuildRequirements)
            └── <target>-check.md      # Read-only audit report (-Action Check)
```

- **List Workspaces:** `Get-SailPointConnectProject`
- **Switch Workspace:** `Set-SailPointConnectProject -Name "<ProjectName>"`
- **Secret Masking:** Sensitive values (client secrets, private keys, refresh tokens) are masked (`***`) in logs and history files.

---

## 📚 Technical Documentation & Deep-Dives

Detailed technical reference guides, permission schemas, CloudFormation templates, and troubleshooting tables are available in the [`docs/`](docs/) directory:

- [**What SailPoint Connect Changes**](docs/guides/what-it-changes.md) — Comprehensive guide to the safe-by-default execution model.
- [**Connector & Permissions Breakdown**](docs/guides/connector-permissions-breakdown.md) — The 3-tier permissions model (Base Target, Access Level, Feature Packs).
- [**AWS Technical Reference**](docs/guides/aws-technical-reference.md) — IAM policies, Organizations trust, CloudFormation StackSets, and CIEM setup.
- [**Microsoft Azure & Entra ID Technical Reference**](docs/guides/azure-entra-technical-reference.md) — Microsoft Graph permissions, Agent 365 delegated auth, and Dataverse Copilot Studio setup.
- [**Google Cloud & Workspace Technical Reference**](docs/guides/google-cloud-technical-reference.md) — Domain-wide delegation, RSA PEM keys, and GCP custom org roles.
- [**IQService Control Guide**](docs/guides/iqservice-control-guide.md) — Windows IQService host lifecycle, log streaming, and Active Directory LDAPS TLS setup.
- [**Microsoft 365 Access Profiles Guide**](docs/guides/microsoft-365-access-profiles.md) — Entra service plan mapping and access profile generation.
- [**Architecture & Workspaces Guide**](docs/guides/architecture-and-workspaces.md) — Directory layout, audit logs, and project management.
- [**Command Reference Index**](docs/README.md) — Complete cmdlet reference and syntax.

---

## 📄 License

(c) 2026 SailPoint Technologies. All rights reserved. Licensed under the [Apache License, Version 2.0](https://github.com/sailpoint-oss/sailpoint-connect/blob/main/LICENSE).

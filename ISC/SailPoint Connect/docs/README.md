# SailPoint Connect Documentation

Welcome to the documentation for **SailPoint Connect** — a progressive-disclosure PowerShell module for configuring, verifying, and auditing cloud and SaaS integrations across **SailPoint Fabric** (ISC SaaS connectors), **SailPoint CIEM**, and **Entro**, as well as managing **IQService Windows hosts** and generating **Microsoft 365 access profiles**.

Nothing in your tenant or cloud provider is created or changed unless you explicitly choose `Run` and confirm. See [What SailPoint Connect changes](guides/what-it-changes.md).

---

## Quick Navigation

- [Supported Platforms & Integration Guides](#supported-platforms--integration-guides)
- [Complete Command Reference (All Cmdlets)](#complete-command-reference)
- [Architecture & Workspaces (`~/.sailpoint-connect`)](guides/architecture-and-workspaces.md)
- [Connector & Platform Permissions Breakdown](guides/connector-permissions-breakdown.md)
- [Progressive Disclosure Guide](guides/progressive-disclosure.md)
- [Prerequisites & Toolchain](guides/prerequisites-and-toolchain.md)

---

## Supported Platforms & Integration Guides

Detailed technical reference guides for each supported platform:

- [**Amazon Web Services (AWS)**](guides/aws-technical-reference.md) — IAM role trust, Organization scope, CloudFormation StackSets, and CIEM setup.
- [**Microsoft Azure & Entra ID**](guides/azure-entra-technical-reference.md) — Microsoft Graph application permissions, directory roles, Microsoft Agent 365, and Power Platform Copilot Studio.
- [**Google Cloud & Workspace**](guides/google-cloud-technical-reference.md) — Service accounts, RSA PEM keys, domain-wide delegation, and GCP CIEM.
- [**IQService Host Control**](guides/iqservice-control-guide.md) — Windows service lifecycle, binary unblocking, log streaming, and Active Directory LDAPS (TCP 636) TLS certificate generation.
- [**Microsoft 365 Access Profiles**](guides/microsoft-365-access-profiles.md) — Entra service plan mapping and requestable access profile generation.

---

## Complete Command Reference

### 1. Unified Entry Point & Workspaces

| Cmdlet | Alias | Description |
| :--- | :--- | :--- |
| [`Invoke-SailPointConnect`](cmdlets/Invoke-SailPointConnect.md) | `sailpoint-connect` | Unified entry point with interactive keyboard-driven platform questionnaire |
| [`Get-SailPointConnectProject`](cmdlets/Get-SailPointConnectProject.md) | — | Lists all project workspaces stored under `~/.sailpoint-connect/` |
| [`Set-SailPointConnectProject`](cmdlets/Set-SailPointConnectProject.md) | — | Sets or switches the default active project workspace |
| [`Update-SailPointConnect`](cmdlets/Update-SailPointConnect.md) | `update-sailpoint-connect` | Updates the SailPoint.Connect module from PowerShell Gallery |
| [`Get-SailPointConnectUpdate`](cmdlets/Get-SailPointConnectUpdate.md) | — | Checks PowerShell Gallery for newer module versions |

### 2. Platform Connectors (SailPoint Fabric, CIEM & Entro)

| Cmdlet | Primary Launcher | Supported Products | Description |
| :--- | :--- | :--- | :--- |
| [`Connect-SailPointAWS`](cmdlets/Connect-SailPointAWS.md) | `./AWS.ps1` | Fabric, CIEM, Entro | Configures AWS SaaS connector IAM role, CIEM CloudFormation, or Entro |
| [`Connect-SailPointAzure`](cmdlets/Connect-SailPointAzure.md) | `./Azure.ps1` | Fabric, CIEM, Entro | Configures Microsoft Entra ID connector, CIEM, and Entro integrations |
| [`Connect-SailPointGoogleCloud`](cmdlets/Connect-SailPointGoogleCloud.md) | `./Google Cloud.ps1` | Fabric, CIEM, Entro | Configures Google Workspace connector, GCP CIEM, and Entro |
| [`Connect-SailPointGitHub`](cmdlets/Connect-SailPointGitHub.md) | `./GitHub.ps1` | Fabric, Entro | Configures GitHub organization App or PAT for SaaS and Entro |
| [`Connect-SailPointOkta`](cmdlets/Connect-SailPointOkta.md) | `./Okta.ps1` | Fabric, Entro | Configures Okta OAuth service app (JWT) and Entro API Services |
| [`Connect-SailPointCrowdStrike`](cmdlets/Connect-SailPointCrowdStrike.md) | `./CrowdStrike.ps1` | Fabric, Entro | Configures CrowdStrike Falcon OAuth API client for SaaS and Entro |
| [`Connect-SailPointSalesforce`](cmdlets/Connect-SailPointSalesforce.md) | `./Salesforce.ps1` | Fabric, Entro | Configures Salesforce Connected App and Agentforce bot discovery |
| [`Connect-SailPointSlack`](cmdlets/Connect-SailPointSlack.md) | `./Slack.ps1` | Fabric, Entro | Configures Slack Enterprise Grid bot and user tokens |
| [`Connect-SailPointGitLab`](cmdlets/Connect-SailPointGitLab.md) | `./GitLab.ps1` | Fabric, Entro | Configures GitLab personal or group access token credentials |
| [`Connect-SailPointDatabricks`](cmdlets/Connect-SailPointDatabricks.md) | `./Databricks.ps1` | Fabric | Configures Databricks account service principal and OAuth M2M |
| [`Connect-SailPointSnowflake`](cmdlets/Connect-SailPointSnowflake.md) | `./Snowflake.ps1` | Entro | Configures Snowflake key-pair authenticated user for Entro |
| [`Connect-SailPointServiceNow`](cmdlets/Connect-SailPointServiceNow.md) | `./ServiceNow.ps1` | Entro | Configures ServiceNow REST API credentials for Entro |
| [`Connect-SailPointHashiCorpVault`](cmdlets/Connect-SailPointHashiCorpVault.md) | `./HashiCorp Vault.ps1` | Entro | Configures HashiCorp Vault policy and token for Entro |

### 3. Specialized Windows Host & Identity Tools

| Cmdlet | Alias / Script | Description |
| :--- | :--- | :--- |
| [`Invoke-SailPointIQServiceControl`](cmdlets/Start-SailPointIQServiceControl.md) | `Start-SailPointIQServiceControl`<br>`./IQService Control.ps1` | Manages Windows IQService host lifecycle, log streaming, and AD LDAPS certificates |
| [`New-SailPointM365AccessProfile`](cmdlets/New-SailPointM365AccessProfile.md) | `./Microsoft 365 Access Profiles.ps1` | Discovers Entra service plans and creates requestable ISC access profiles |

---

## The Four Progressive Disclosure Actions

Every platform connector cmdlet supports the same standard `-Action` parameter:

1. **`BuildRequirements`**: Generates a Markdown checklist (`*-requirements.md`) for your cloud security or operations team. Does not touch the cloud tenant.
2. **`Check`**: Reads an existing cloud identity (IAM role, Entra app, GCP service account) and reports gaps in `*-check.md`. Completely read-only.
3. **`BuildScript`**: Generates an executable `.ps1` script for change-management ticket review before running.
4. **`Run`**: Applies the changes directly to your cloud provider using the official CLI after an interactive confirmation prompt.

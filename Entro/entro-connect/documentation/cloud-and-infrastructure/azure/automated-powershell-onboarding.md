Automated PowerShell Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/automated-powershell-onboarding.md).

The **Automated PowerShell Onboarding** method enables a fast, secure, and fully automated setup of the Entro Security Azure Integration. This script configures all required Azure components, roles, and permissions directly within your environment - no credentials are transmitted externally.
GitBook Assistant[Entro-Azure-Onboarding.ps1](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F7pmnww8A099dTyQLXKT0%2FEntro-Azure-Onboarding.ps1?alt=media&token=d54484e5-cb08-4dbf-a126-30454e0f9267)143KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F7pmnww8A099dTyQLXKT0%2FEntro-Azure-Onboarding.ps1?alt=media&token=d54484e5-cb08-4dbf-a126-30454e0f9267)Aug 19, 2026
## Overview[#overview](#overview)

The onboarding script (`Entro-Azure-Onboarding.ps1`) automates the connection process by:
GitBook Assistant

- 

Creating a dedicated **App Registration** for Entro Security and applying **Microsoft Graph API permissions** for discovery and monitoring (see detailed list below)
GitBook Assistant
- 

Generating the **Client ID**, **Tenant ID**, and **Client Secret** used in Entro
GitBook Assistant
- 

Assigning the required **Entro Custom Role** (`EntroSecurityRole`) across selected subscriptions and/or management groups
GitBook Assistant
- 

Assigning the built-in **Key Vault Reader** and **Application Configuration Data Reader** roles to the Entro App Registration across selected subscriptions and/or management groups
GitBook Assistant
- 

Creating a **Log Analytics Workspace** to store NHI, service account, and key vault activity logs for activity analysis
GitBook Assistant
- 

Configure **Sign-in Logs** to be sent to Entro Log Analytics Workspace for service principals and service accounts
GitBook Assistant
- 

Configure **Key Vault Access Policies** for Entro App Registration to inventory selected Key Vaults
GitBook Assistant
- 

Configure **Key Vault** **Diagnostic Logging** to be sent to Entro Log Analytics Workspace for selected Key Vaults
GitBook Assistant

All operations occur locally through MS Graph and Azure APIs.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

In the Entro Dashboard, navigate to:
GitBook Assistant

**Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem**
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

Ensure the following before running the script:
GitBook Assistant

- 

**PowerShell 7.x** or later
GitBook Assistant
- 

**MS Graph** and **AzureAD** modules installed
GitBook Assistant

- 

Azure Entra ID role: **Global Administrator** or **Application Administrator**
GitBook Assistant
- 

Network access to:
GitBook Assistant

- 

`https://api.entro.security`
GitBook Assistant
- 

`https://graph.microsoft.com`
GitBook Assistant
- 

`https://management.azure.com`
GitBook Assistant

- 

Permission to create **App Registrations** and **custom roles**
GitBook Assistant
- 

Access to at least one active **Azure subscription**
GitBook Assistant

## Running the Script[#running-the-script](#running-the-script)
1
#### Prepare PowerShell[#prepare-powershell](#prepare-powershell)

Open **PowerShell as Administrator** on local machine and navigate to the directory containing `Entro-Azure-Onboarding.ps1`.
GitBook Assistant

*Or*
GitBook Assistant

In the **Azure Portal** (portal.azure.com), open the Azure **Cloud Shell**. Once Cloud Shell has loaded, click **Manage files** then **Upload** in the Cloud Shell menu to upload the `Entro-Azure-Onboarding.ps1` script to the Shell.
GitBook Assistant2
#### Execute the Script[#execute-the-script](#execute-the-script)

Run:
GitBook Assistant3
#### Follow Menu Sequence[#follow-menu-sequence](#follow-menu-sequence)

During execution you will:
GitBook Assistant

- 

Authenticate to MS Graph and Azure (interactive or device login)
GitBook Assistant
- 

Follow menu steps 1 - 7 to complete all necessary steps to fully onboard Entro into Azure
GitBook Assistant

## Expected Output[#expected-output](#expected-output)

On completion, the script displays:
GitBook Assistant

- 

**Azure Client ID**
GitBook Assistant
- 

**Azure Tenant ID**
GitBook Assistant
- 

**Azure Client Secret**
GitBook Assistant

Copy these values - they are required in the Entro onboarding form.
GitBook Assistant
## Connecting to Entro[#connecting-to-entro](#connecting-to-entro)

1. 

Return to the Entro Dashboard.
GitBook Assistant
1. 

Navigate to **Management → Accounts & Integrations → Add New Account → Microsoft Ecosystem**.
GitBook Assistant
1. 

Paste the following values:
GitBook Assistant

- 

Azure Client ID
GitBook Assistant
- 

Azure Tenant ID
GitBook Assistant
- 

Azure Client Secret
GitBook Assistant

1. 

Click **Create Account**.
GitBook Assistant

- 

Status: **Verified** upon successful validation.
GitBook Assistant

#### Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Script actions are limited to read-only and configuration changes through Azure APIs.
GitBook Assistant
- 

No credentials or data are sent to Entro during script execution.
GitBook Assistant
- 

Credentials are stored encrypted (**AES-256**) in Entro’s vault.
GitBook Assistant
[PreviousAzure Pre Onboarding Check](/integrations/cloud-and-infrastructure/azure/azure-pre-onboarding-check)[NextAzure Manual Onboarding](/integrations/cloud-and-infrastructure/azure/azure-manual-onboarding)

Last updated 3 days ago

- [Overview](#overview)
- [Navigation Path](#navigation-path)
- [Prerequisites](#prerequisites)
- [Running the Script](#running-the-script)
- [Expected Output](#expected-output)
- [Connecting to Entro](#connecting-to-entro)
Install modulesGitBook AssistantAskCopy
```
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Az.Accounts -Scope CurrentUser
Install-Module Az.Resources -Scope CurrentUser
Install-Module Az.OperationalInsights -Scope CurrentUser
Install-Module Az.Monitor -Scope CurrentUser
Install-Module Az.KeyVault -Scope CurrentUser
```
Run onboarding scriptGitBook AssistantAskCopy
```
.\Entro-Azure-Onboarding.ps1
```

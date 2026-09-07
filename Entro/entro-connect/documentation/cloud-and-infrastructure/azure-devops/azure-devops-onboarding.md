Azure DevOps Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure-devops/azure-devops-onboarding.md).

The Azure DevOps Integration securely connects your Azure DevOps organization with Entro Security to enable continuous scanning of repositories, pipelines, and configurations for exposed secrets. This section describes the setup process, prerequisites, and connection steps.
GitBook Assistant
## Integration Prerequisites[#integration-prerequisites](#integration-prerequisites)

Before onboarding, ensure the following:
GitBook Assistant

- 

An **App Registration** created in Entra ID (e.g., "Entro Security App").
GitBook Assistant
- 

The **Client ID**, **Client Secret**, and **Tenant ID** for the application.
GitBook Assistant
- 

Organization Administrator rights in Azure DevOps.
GitBook Assistant
1
#### Azure DevOps Configuration[#azure-devops-configuration](#azure-devops-configuration)

To allow Entro to scan your projects, you must add the App Registration as a user within your Azure DevOps organization:
GitBook Assistant

1. 

Navigate to **Organization Settings** → **Users**.
GitBook Assistant
1. 

Click **Add users**.
GitBook Assistant
1. 

In the **Users or Service Principals** field, search for and select your **Entro Security App**.
GitBook Assistant
1. 

Set **Access level** to `Basic`.
GitBook Assistant
1. 

In the **Add to projects** field, select all relevant projects you wish Entro to monitor.
GitBook Assistant
1. 

Set **Azure DevOps Groups** to `Project Readers`.
GitBook Assistant
1. 

Ensure **Send email invites** is unchecked (service principals do not require email invites).
GitBook Assistant
1. 

Click **Add**.
GitBook Assistant
2
#### Connect to Entro Security[#connect-to-entro-security](#connect-to-entro-security)

1. 

Navigate: **Management → Accounts & Integrations → Add New Account (top right) → Azure DevOps**.
GitBook Assistant
1. 

Fill in the following fields:
GitBook Assistant

- 

**Environment Nickname**: A descriptive name (e.g., `ADO-PROD`).
GitBook Assistant
- 

**Tenant ID**: Your Microsoft Entra Tenant ID.
GitBook Assistant
- 

**Client ID**: The Application ID of the Entro Security App.
GitBook Assistant
- 

**Client Secret**: A valid secret generated for the App Registration.
GitBook Assistant

1. 

**Worker Group (Connector)**: Choose the appropriate group to run the scans.
GitBook Assistant
1. 

Click **Create Account**.
GitBook Assistant
3
#### Validation and Scanning[#validation-and-scanning](#validation-and-scanning)

Once connected:
GitBook Assistant

- 

Entro validates the client secret via Entra ID (Application Registration) API
GitBook Assistant
- 

Access is confirmed as **read-only**
GitBook Assistant
- 

Scanning begins automatically across repositories and pipelines
GitBook Assistant
- 

Findings appear in your Entro Console with metadata and severity context
GitBook Assistant

Security Notes
GitBook Assistant

- 

All operations occur over **HTTPS/TLS 1.2+**
GitBook Assistant
- 

Entro performs **read-only** operations; no data is modified
GitBook Assistant
- 

Client secret can be revoked anytime via the Entro application in Entra ID
GitBook Assistant
[PreviousAzure DevOps](/integrations/cloud-and-infrastructure/azure-devops)[NextAzure DevOps Troubleshooting And Validation](/integrations/cloud-and-infrastructure/azure-devops/azure-devops-troubleshooting-and-validation)

Last updated 4 months ago

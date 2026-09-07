Azure Pre Onboarding Check | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/azure-pre-onboarding-check.md).

Before connecting Microsoft Azure to Entro Security, perform the following verification steps. These checks ensure your Azure environment is correctly configured for secure and successful integration.
GitBook Assistant1
#### Verify Azure Administrator Access[#verify-azure-administrator-access](#verify-azure-administrator-access)

Confirm that the user performing onboarding holds at least one of the following roles:
GitBook Assistant

- 

Global Administrator
GitBook Assistant
- 

Application Administrator
GitBook Assistant
- 

Privileged Role Administrator
GitBook Assistant

1. 

Go to [https://portal.azure.com](https://portal.azure.com).
GitBook Assistant
1. 

Click the **Cloud Shell (>_)** icon at the top-right of the portal header.
GitBook Assistant
1. 

Choose **Bash** (not PowerShell).
GitBook Assistant

Run the following command in Azure CLI:
GitBook AssistantGitBook AssistantAskCopy
```
az role assignment list --assignee <your_user_principal_name> --output table
```

Expected: one of the above roles appears in the results.
GitBook Assistant2
#### Confirm API and Portal Availability[#confirm-api-and-portal-availability](#confirm-api-and-portal-availability)

- 

Verify access to https://portal.azure.com.
GitBook Assistant
- 

Ensure outbound network connectivity to these endpoints:
GitBook Assistant

- 

https://api.entro.security
GitBook Assistant
- 

https://graph.microsoft.com
GitBook Assistant
- 

https://management.azure.com
GitBook Assistant

If outbound HTTPS is restricted, onboarding will fail.
GitBook Assistant3
#### Validate Azure CLI Installation (Optional)[#validate-azure-cli-installation-optional](#validate-azure-cli-installation-optional)

Run the following commands to confirm that Azure CLI is installed and authenticated:
GitBook AssistantGitBook AssistantAskCopy
```
az version
az login
az account show
```
4
#### Confirm Tenant and Subscription Context[#confirm-tenant-and-subscription-context](#confirm-tenant-and-subscription-context)

Record these values for the onboarding process:
GitBook Assistant

- 

Tenant ID
GitBook Assistant
- 

Subscription ID
GitBook Assistant
- 

Azure Client ID (once App Registration is created)
GitBook Assistant

These will be required during the connection step in Entro.
GitBook Assistant5
#### Check for Existing Entro App Registration[#check-for-existing-entro-app-registration](#check-for-existing-entro-app-registration)

If onboarding has been attempted previously, check for an existing Entro app registration:
GitBook AssistantFind Entro app registrationGitBook AssistantAskCopy
```
az ad app list --display-name "EntroSecurityIntegration"
```

If found, either delete it or reuse it after secret rotation.
GitBook Assistant6
#### Verify Key Vault Access Control Mode[#verify-key-vault-access-control-mode](#verify-key-vault-access-control-mode)

For environments using Azure Key Vault:
GitBook Assistant

1. 

Navigate to a Key Vault in the Azure Portal.
GitBook Assistant
1. 

Under Access configuration, verify whether it uses:
GitBook Assistant

- 

Vault access policy, or
GitBook Assistant
- 

Azure RBAC
GitBook Assistant

Entro supports both access models. Ensure that at least read metadata access is available — Entro never reads secret content.
GitBook Assistant7
#### Optional Connectivity Test to Entro[#optional-connectivity-test-to-entro](#optional-connectivity-test-to-entro)

To confirm connectivity from a connector or VM host, run:
GitBook AssistantConnectivity testGitBook AssistantAskCopy
```
curl -I https://api.entro.security/health
```

Expected response: `200 OK`
GitBook Assistant
## Pre-Onboarding Checklist[#pre-onboarding-checklist](#pre-onboarding-checklist)
CheckDescription

Azure Administrator
GitBook Assistant

Confirm user has Global or Application Administrator Role
GitBook Assistant

Network Connectivity
GitBook Assistant

Outbound HTTPS to Entro and Microsoft Graph
GitBook Assistant

Azure CLI Installed
GitBook Assistant

Azure CLI authenticated and working
GitBook Assistant

Tenant & Subscription Recorded
GitBook Assistant

Tenant ID and Subscription ID noted
GitBook Assistant

Existing App Registration
GitBook Assistant

None found or ready for reuse
GitBook Assistant

Key Vault Access Control
GitBook Assistant

Read metadata access confirmed
GitBook Assistant[PreviousAzure / Entra / M365](/integrations/cloud-and-infrastructure/azure)[NextAutomated PowerShell Onboarding](/integrations/cloud-and-infrastructure/azure/automated-powershell-onboarding)

Last updated 2 months ago

Azure Continuous Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/azure-continuous-onboarding.md).

This section explains how to enable continuous onboarding of Azure Subscriptions and Key Vaults using an Azure Function App and Management Groups. This configuration allows Entro Security to automatically detect and onboard new resources without manual intervention.
GitBook Assistant

The setup leverages Microsoft Azure Functions (serverless runtime) to periodically invoke Entro's onboarding API through a managed identity.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem**
GitBook Assistant
## Requirements[#requirements](#requirements)

Before proceeding, ensure that:
GitBook Assistant

- 

You have Global Administrator or Owner permissions in your Azure tenant.
GitBook Assistant
- 

Azure Function App, Storage Account, and Management Group creation is permitted.
GitBook Assistant
- 

Ability to set roles in desired Management Groups or Subscriptions
GitBook Assistant
1
#### Verify Access to the Tenant Root Group[#verify-access-to-the-tenant-root-group](#verify-access-to-the-tenant-root-group)

- 

In the Azure Portal, go to Management Groups.
GitBook Assistant
- 

Locate and open Tenant Root Group.
GitBook Assistant
- 

Select Access control (IAM).
GitBook Assistant
- 

Ensure your account has permissions to add role assignments at this level.
GitBook Assistant
2
#### Azure Function App Creation[#azure-function-app-creation](#azure-function-app-creation)

- 

Navigate to [Function App](https://portal.azure.com/#browse/Microsoft.Web%2Fsites/kind/functionapp) → Create.
GitBook Assistant
- 

Under Hosting, choose the Flex Consumption Plan (or other desired plan suitable for your environment).
GitBook Assistant
BasicStorageNetworkingMonitoringDeploymentUntitled

Create a new Storage Account
GitBook Assistant

- 

Basics tab
GitBook Assistant

- 

Set Subscription and Resource Group where this Function App will live
GitBook Assistant
- 

Give App a name such as "EntroContinuousOnboarding"
GitBook Assistant
- 

Select desired Azure region
GitBook Assistant
- 

Runtime stack set to PowerShell
GitBook Assistant
- 

Version is set most current version available
GitBook Assistant
- 

Rest of settings are left as default
GitBook Assistant

- 

Storage tab
GitBook Assistant

- 

Select appropriate storage account
GitBook Assistant

- 

Networking tab
GitBook Assistant

- 

Disable "Enable public access" setting
GitBook Assistant

- 

Authentication tab
GitBook Assistant

- 

Change Resource authentication to "Managed identity" for all resource types
GitBook Assistant
- 

Note Managed Identity that is assigned (we will need this later)
GitBook Assistant

- 

Click Review + Create button to finalize the creation and wait for Function App to be deployed
GitBook Assistant
- 

Head over to the Function App created and **Create in Azure Portal **
GitBook Assistant
3
### Add Environment Variables[#add-environment-variables](#add-environment-variables)

- 

Under Settings > Environment variables, add the following ***required*** environment variables
GitBook Assistant
NameExample ValuePurpose

`ENTRO_APP_REG_ID`
GitBook Assistant

e05ddb08-838f-46d3-ad0e-e2c52b6074ae
GitBook Assistant

Application (client) ID of the Entro Security App Registration
GitBook Assistant

`ENTRO_LAW_RESOURCE_ID`
GitBook Assistant

/subscriptions/c7a3020e-9a40-33be-9014-9dbd1c35d241/resourceGroups/EntroSecurityRG/providers/Microsoft.OperationalInsights/workspaces/EntroSecurityLogAnalytics
GitBook Assistant

Resource ID of the Log Analytics Workspace where Key Vault activity logs will be stored. Found in Settings > Properties page of the chosen 
GitBook Assistant

workspace's details page.
GitBook Assistant

- 

The following are ***optional*** environment variables to help tune the Function App for the environment
GitBook Assistant
NameExample ValuePurpose

`SUBSCRIPTIONS_TO_EXCLUDE`
GitBook Assistant

Default Value: *Empty*
GitBook Assistant

List of comma separated Subscription IDs. Example: `"fa6448db-ey49-4118-8231-13aac72c3f89", etc.`
GitBook Assistant

Subscriptions that will be excluded from processing. 
GitBook Assistant

`SUBSCRIPTIONS_EXACT_LIST`
GitBook Assistant

Default Value: *Empty*
GitBook Assistant

List of comma separated Subscription IDs. Example: `"fa6448db-ey49-4118-8231-13aac72c3f89", etc.`
GitBook Assistant

`DRY_RUN`
GitBook Assistant

Default Value: *false *To enable, set value to *true.*
GitBook Assistant

When set to *true* the script will not perform any actions on Key Vaults, but will log all actions that would have happened.
GitBook Assistant

`SUBS_PARALLEL_PROCESSING_COUNT`
GitBook Assistant

Default Value: *5*
GitBook Assistant

Number of concurrent Key Vault settings processing routines to run. This features speeds up script speed and can be tuned up to 10 parallel processing threads when evaluating and setting Key Vault properties.
GitBook Assistant

`VAULT_CONFIG_SKIP_INTERVAL_HOURS`
GitBook Assistant

Default Value: *23*
GitBook Assistant

Number of hours to wait before evaluating the same Key Vaults by the script again. 
GitBook Assistant

4
#### Add the Function Code[#add-the-function-code](#add-the-function-code)

- 

In the Function App, open Development > Deployment Center.
GitBook Assistant
- 

Select Source as Manual Deployment (Push) > Publish files (new) in the dropdown box
GitBook Assistant
- 

Download the following zip file and select it for upload into the Function App
GitBook Assistant
[EntroAzureContinuous.zip](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FRefLLXswnBsdyJGarXju%2FEntroAzureContinuous.zip?alt=media&token=4de1f6cc-e75a-40ec-a6a1-eb071cf237d8)archive · 22MBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FRefLLXswnBsdyJGarXju%2FEntroAzureContinuous.zip?alt=media&token=4de1f6cc-e75a-40ec-a6a1-eb071cf237d8)Version: May 29, 20265
#### Grant Func App Identity Permissions [#grant-func-app-identity-permissions](#grant-func-app-identity-permissions)

It is recommended to perform the following Role Assignment steps at the highest management group level as possible (Tenant Root Group or high level Management Group)
GitBook Assistant

**Management Group Assignment**
GitBook Assistant

- 

Go to Management Groups
GitBook Assistant
- 

Choose the appropriate Management Group or Subscription 
GitBook Assistant
- 

Go to Access Control (IAM) and click +Add > Add role assignment.
GitBook Assistant
- 

Search for and select the role **Key Vault Contributor**
GitBook Assistant
- 

Click Members tab, assign access to: **Managed Identity**
GitBook Assistant
- 

Click +Select Members, then find the Managed identity we noted in Step 2 (User-assigned managed identity), then click Select button at the bottom
GitBook Assistant
- 

Click Review + Assign button
GitBook Assistant
- 

Repeat the adding of Role Assignment steps and this time chose the role **User Access Administrator** to assign to our Function App's managed identity
GitBook Assistant
6
#### Validate Continuous Onboarding[#validate-continuous-onboarding](#validate-continuous-onboarding)

- 

In Entro, navigate to Management → Accounts & Integrations → Microsoft Ecosystem (Azure).
GitBook Assistant
- 

Confirm that:
GitBook Assistant

- 

New subscriptions are auto-detected.
GitBook Assistant
- 

Key Vaults are continuously discovered and onboarded.
GitBook Assistant

- 

Review logs in Azure Monitor or Log Analytics for confirmation of scheduled executions.
GitBook Assistant

CLI Verification Example:
GitBook AssistantCLI verificationGitBook AssistantAskCopy
```
az monitor diagnostic-settings list --resource <resource-id> --output table
```

Expected result: Includes `EntroContinuousOnboarder` or equivalent diagnostic entry.
GitBook Assistant[PreviousHybrid Entra AD](/integrations/cloud-and-infrastructure/azure/hybrid-entra-ad)[NextTroubleshooting And Validation](/integrations/cloud-and-infrastructure/azure/troubleshooting-and-validation)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Requirements](#requirements)
- [Add Environment Variables](#add-environment-variables)

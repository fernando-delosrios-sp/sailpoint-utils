Onboarding Microsoft Copilot Studio | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/microsoft-copilot-studio/onboarding-microsoft-copilot-studio.md).

**Prerequisites:** Microsoft Entra **Global Administrator** role, a local machine with PowerShell 7 and terminal access.
GitBook Assistant
## Phase A: Create the Entra App Registration[#phase-a-create-the-entra-app-registration](#phase-a-create-the-entra-app-registration)
1
## App Creation[#app-creation](#app-creation)

1. 

Navigate to [https://entra.microsoft.com](https://entra.microsoft.com/).
GitBook Assistant
1. 

Go to **Applications** -> **App registrations** -> **+ New registration**.
GitBook Assistant
1. 

Set the Name to `Entro Copilot Studio Connector`.
GitBook Assistant
1. 

Select **Supported account types** as **Single tenant**.
GitBook Assistant
1. 

Leave the Redirect URI blank and click **Register**.
GitBook Assistant
2
## Record Credentials[#record-credentials](#record-credentials)

From the application **Overview** page, copy the following values to a secure temporary location:
GitBook Assistant

- 

**Application (client) ID** (Azure Client ID)
GitBook Assistant
- 

**Directory (tenant) ID** (Azure Tenant ID)
GitBook Assistant
3
## Generate a Client Secret[#generate-a-client-secret](#generate-a-client-secret)

1. 

Navigate to **Certificates & secrets** -> **Client secrets** -> **+ New client secret**.
GitBook Assistant
1. 

Provide a description (e.g., `Entro Connector`) and set an expiration interval conforming to your security policy.
GitBook Assistant
1. 

Click **Add**.
GitBook Assistant
1. 

**Immediately copy the string in the "Value" column.** This value is your **Azure Client Secret** and will be masked permanently once you leave the screen.
GitBook Assistant
4
## Configure API Permissions[#configure-api-permissions](#configure-api-permissions)

1. 

Navigate to **API permissions** -> **+ Add a permission**.
GitBook Assistant
1. 

Add the required scopes outlined in the **Microsoft Copilot Studio Permissions Reference** guide.
GitBook Assistant
1. 

After adding all required scopes, click **✓ Grant admin consent for [tenant]** at the top of the workspace and confirm.
GitBook Assistant

## Phase B: Provision the App into Dataverse Environments[#phase-b-provision-the-app-into-dataverse-environments](#phase-b-provision-the-app-into-dataverse-environments)

Because Copilot Studio agents run inside Power Platform environments, the Entra application must be provisioned into each environment's Dataverse database.
GitBook Assistant1
## Prepare PowerShell[#prepare-powershell](#prepare-powershell)

Ensure you have PowerShell 7 installed (`pwsh --version` should return 7.x.x).
GitBook Assistant2
## Script Execution[#script-execution](#script-execution)

1. 

Save the execution script `Entro-Onboard.ps1` to a local folder (replace with your actual internal script location).
GitBook Assistant
1. 

Execute a dry run to verify accessible environments without making modifications:
GitBook AssistantGitBook AssistantAskCopy
```
pwsh ./Entro-Onboard.ps1 \
    -ClientId "<your Azure Client ID>"        -TenantId "<your Azure tenant ID>" \
    -DryRun
```

1. 

Authenticate in the browser window using your **Global Administrator** credentials when prompted.
GitBook Assistant
1. 

Target a single non-production environment to test deployment:
GitBook AssistantGitBook AssistantAskCopy
```
pwsh ./Entro-Onboard.ps1 \
    -ClientId "<your Azure Client ID>" \
    -TenantId "<your Azure tenant ID>" \
    -OnlyEnvironment "<test env name>"
```

1. 

Verify deployment by checking [https://admin.powerplatform.microsoft.com](https://admin.powerplatform.microsoft.com/) -> Select Environment -> **Settings** -> **Users + permissions** -> **Application users**. Ensure the app user is present with the assigned security role.
GitBook Assistant
1. 

Run the script across all tenant environments:
GitBook AssistantGitBook AssistantAskCopy
```
pwsh ./Entro-Onboard.ps1 \
    -ClientId "<your Azure Client ID>" \
    -TenantId "<your Azure tenant ID>"
```

## Phase C: Connect in Entro Console[#phase-c-connect-in-entro-console](#phase-c-connect-in-entro-console)
1
## Log into the Entro Console[#log-into-the-entro-console](#log-into-the-entro-console)

Log into the Entro Console.
GitBook Assistant2
## Navigate to the integration[#navigate-to-the-integration](#navigate-to-the-integration)

Navigate to: **Management** → **Accounts & Integrations** → **Add New Account (top right)** → **Microsoft Copilot Studio**.
GitBook Assistant3
## Fill out the integration fields[#fill-out-the-integration-fields](#fill-out-the-integration-fields)

- 

**Environment Type:** Production / Staging / Dev
GitBook Assistant
- 

**Display Name / Nickname:** Provide a unique identifying label
GitBook Assistant
- 

**Azure Tenant ID:** Pasted from Phase A.2
GitBook Assistant
- 

**Azure Client ID:** Pasted from Phase A.2
GitBook Assistant
- 

**Azure Client Secret:** Pasted from Phase A.3
GitBook Assistant
4
## Test and create the account[#test-and-create-the-account](#test-and-create-the-account)

Click **Test connection**. Once verified successfully, click **Create Account**.
GitBook Assistant

Last updated 3 months ago

- [Phase A: Create the Entra App Registration](#phase-a-create-the-entra-app-registration)
- [App Creation](#app-creation)
- [Record Credentials](#record-credentials)
- [Generate a Client Secret](#generate-a-client-secret)
- [Configure API Permissions](#configure-api-permissions)
- [Phase B: Provision the App into Dataverse Environments](#phase-b-provision-the-app-into-dataverse-environments)
- [Prepare PowerShell](#prepare-powershell)
- [Script Execution](#script-execution)
- [Phase C: Connect in Entro Console](#phase-c-connect-in-entro-console)
- [Log into the Entro Console](#log-into-the-entro-console)
- [Navigate to the integration](#navigate-to-the-integration)
- [Fill out the integration fields](#fill-out-the-integration-fields)
- [Test and create the account](#test-and-create-the-account)

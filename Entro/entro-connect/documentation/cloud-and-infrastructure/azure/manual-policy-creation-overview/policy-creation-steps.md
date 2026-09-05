Policy Creation Steps | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/policy-creation-steps.md).

This page outlines the manual policy setup process for connecting **Microsoft Azure** to **Entro Security** using the Azure Portal. Follow these steps to create the required App Registration and grant the appropriate Microsoft Graph API permissions.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

In the Entro Dashboard, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem**
GitBook Assistant1
#### Step 1 - Create App Registration[#step-1-create-app-registration](#step-1-create-app-registration)

1. 

Open the [Azure Portal](https://portal.azure.com/).
GitBook Assistant
1. 

Go to **Azure Active Directory → App registrations → + New registration**.
GitBook Assistant
1. 

Enter a descriptive name such as **EntroSecurityIntegration**.
GitBook Assistant
1. 

Under **Supported account types**, select **Accounts in this organizational directory only**.
GitBook Assistant
1. 

Leave the Redirect URI field empty and click **Register**.
GitBook Assistant

After registration, record the following values (displayed in the Overview section):
GitBook Assistant

- 

**Application (client) ID**
GitBook Assistant
- 

**Directory (tenant) ID**
GitBook Assistant

These values will be used later in the Entro connection form.
GitBook Assistant2
#### Generate Client Secret[#generate-client-secret](#generate-client-secret)

1. 

In the App Registration, open **Certificates & Secrets**.
GitBook Assistant
1. 

Under **Client secrets**, click **+ New client secret**.
GitBook Assistant
1. 

Add a description such as *Entro Security Integration Token* and select **12 months** for expiration.
GitBook Assistant
1. 

Click **Add**.
GitBook Assistant
1. 

Copy the secret **Value** immediately - it cannot be retrieved later.
GitBook Assistant
3
#### Assign API Permissions[#assign-api-permissions](#assign-api-permissions)

1. 

In the App Registration, open the **API permissions** tab.
GitBook Assistant
1. 

Click **+ Add a permission → Microsoft Graph → Application permissions**.
GitBook Assistant
1. 

Add the required permission sets (listed below) based on your environment.
GitBook Assistant
1. 

Click **Grant admin consent** to apply the permissions.
GitBook Assistant
4
#### Grant Consent[#grant-consent](#grant-consent)

1. 

From the **API Permissions** tab, click **Grant admin consent for [Your Organization]**.
GitBook Assistant
1. 

Wait until all permissions show a **Granted for [Org Name]** status.
GitBook Assistant
1. 

Verify that no permissions display a "Pending admin consent" message.
GitBook Assistant

### Core Microsoft Graph Permissions[#core-microsoft-graph-permissions](#core-microsoft-graph-permissions)

*(Required for all integrations)*
GitBook AssistantPermissionDescription

`User.Read.All`
GitBook Assistant

Read user profiles
GitBook Assistant

`Directory.Read.All`
GitBook Assistant

Read directory data
GitBook Assistant

`Application.Read.All`
GitBook Assistant

Read application registrations
GitBook Assistant

`Device.Read.All`
GitBook Assistant

Read device details
GitBook Assistant

`AuditLog.Read.All`
GitBook Assistant

Read audit logs
GitBook Assistant
### Microsoft Teams (if applicable)[#microsoft-teams-if-applicable](#microsoft-teams-if-applicable)
PermissionDescription

`TeamsActivity.Read.All`
GitBook Assistant

Read Teams activity data
GitBook Assistant

`TeamSettings.Read.All`
GitBook Assistant

Read team settings
GitBook Assistant

`TeamsTab.Read.All`
GitBook Assistant

Read Teams tabs
GitBook Assistant

`TeamsAppInstallation.ReadForChat.All`
GitBook Assistant

Read Teams apps in chat
GitBook Assistant

`TeamsAppInstallation.ReadForTeam.All`
GitBook Assistant

Read Teams apps in team
GitBook Assistant

`TeamsAppInstallation.ReadForUser.All`
GitBook Assistant

Read Teams apps for users
GitBook Assistant

`Channel.ReadBasic.All`
GitBook Assistant

Read channel metadata
GitBook Assistant

`ChannelMember.Read.All`
GitBook Assistant

Read channel members
GitBook Assistant

`ChannelMessage.Read.All`
GitBook Assistant

Read channel messages
GitBook Assistant

`ChannelSettings.Read.All`
GitBook Assistant

Read channel settings
GitBook Assistant

`Chat.Read.All`
GitBook Assistant

Read chat messages
GitBook Assistant
### SharePoint / OneDrive (if applicable)[#sharepoint-onedrive-if-applicable](#sharepoint-onedrive-if-applicable)
PermissionDescription

`Sites.Read.All`
GitBook Assistant

Read all site collections
GitBook Assistant

`Files.Read.All`
GitBook Assistant

Read user files
GitBook Assistant
### Azure Service Management (ARM)[#azure-service-management-arm](#azure-service-management-arm)

*(Automatically handled by the Azure Resource Manager connection)*
GitBook AssistantPermissionDescription

`*/read`
GitBook Assistant

Read-only access to Azure resources
GitBook Assistant

These permissions provide Entro read-only visibility into Azure resources. No `.Write` or `.Delete` permissions are ever required or used.
GitBook Assistant
## Validation[#validation](#validation)

After completing these steps, confirm:
GitBook Assistant

- 

The App Registration appears under **Enterprise Applications**.
GitBook Assistant
- 

The **API Permissions** tab lists all scopes as "Granted".
GitBook Assistant
- 

The **Client ID**, **Tenant ID**, and **Secret Value** are safely stored for use in Entro.
GitBook Assistant

Make sure you copy the Client Secret value immediately after creation - it cannot be retrieved later.
GitBook Assistant
## Security Notes[#security-notes](#security-notes)

- 

Entro never requests or uses write-level permissions.
GitBook Assistant
- 

All API scopes are limited to metadata and configuration retrieval.
GitBook Assistant
- 

Access tokens are encrypted (AES‑256) and transmitted over HTTPS/TLS 1.2+.
GitBook Assistant
- 

Permissions can be revoked anytime via Azure Portal → App Registrations.
GitBook Assistant

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Core Microsoft Graph Permissions](#core-microsoft-graph-permissions)
- [Microsoft Teams (if applicable)](#microsoft-teams-if-applicable)
- [SharePoint / OneDrive (if applicable)](#sharepoint-onedrive-if-applicable)
- [Azure Service Management (ARM)](#azure-service-management-arm)
- [Validation](#validation)
- [Security Notes](#security-notes)

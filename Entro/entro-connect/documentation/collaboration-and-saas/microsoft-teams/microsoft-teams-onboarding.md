Microsoft Teams Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/microsoft-teams/microsoft-teams-onboarding.md).

This page explains how to integrate Microsoft Teams with Entro Security using either the automated onboarding process or manual configuration via Azure. It leverages the existing Microsoft Ecosystem Azure App Registration method.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

- 

Azure administrator privileges
GitBook Assistant
- 

Existing Entro Azure App Registration
GitBook Assistant
- 

Temporary Contributor role 
GitBook Assistant

## Mandatory - Graph Permissions[#mandatory-graph-permissions](#mandatory-graph-permissions)
1
#### Add Graph API Permissions [#add-graph-api-permissions](#add-graph-api-permissions)

In Azure Portal, navigate to App registrations → Entro App → API Permissions and add the following:
GitBook Assistant

- 

Choose: + Add a permission → Microsoft Graph → Application permissions
GitBook Assistant
- 

Mandatory:
GitBook Assistant

- 

User.Read.All
GitBook Assistant
- 

Directory.Read.All
GitBook Assistant
- 

AuditLogs.Read.All
GitBook Assistant

- 

For Secret Detection:
GitBook Assistant

- 

TeamsActivity.Read.All
GitBook Assistant
- 

TeamSettings.Read.All
GitBook Assistant
- 

TeamsTab.Read.All
GitBook Assistant
- 

TeamsAppInstallation.ReadForChat.All
GitBook Assistant
- 

TeamsAppInstallation.ReadForTeam.All
GitBook Assistant
- 

TeamsAppInstallation.ReadForUser.All
GitBook Assistant
- 

Channel.ReadBasic.All
GitBook Assistant
- 

ChannelMember.Read.All
GitBook Assistant
- 

ChannelMessage.Read.All
GitBook Assistant
- 

ChannelSettings.Read.All
GitBook Assistant
- 

Chat.Read.All
GitBook Assistant

- 

For Messaging and Alerts (optional):
GitBook Assistant

- 

TeamsAppInstallation.ReadWriteForTeam.All
GitBook Assistant
- 

TeamsAppInstallation.ReadWriteForUser.All
GitBook Assistant
- 

TeamsAppInstallation.ReadWriteSelfForUser.All
GitBook Assistant

After adding permissions, click "Grant admin consent" for all permissions.
GitBook Assistant

If you'd like Entro to solely scan for secrets in Teams, no need to continue to other steps.
GitBook Assistant
## Optional - Microsoft Teams alerts and messaging setup[#optional-microsoft-teams-alerts-and-messaging-setup](#optional-microsoft-teams-alerts-and-messaging-setup)
1
#### Add contributer role temporarily [#add-contributer-role-temporarily](#add-contributer-role-temporarily)

To activate the messaging and alerting functionalities, an Entro bot (application) must be downloaded and added to the Teams App Catalog.
GitBook Assistant

For steps 1-5, assigning the contributor role to the Entro service principal is temporary only for the downoading and installation of the Entro Bot, once it is installed you can remove the permission.
GitBook Assistant

1. 

Go to the subscription related to the Entro integration.
GitBook Assistant
1. 

Click on "Access control (IAM)" > "+Add" > "Add role assignment".
GitBook Assistant
1. 

In the "Role" tab, search for the "Contributor" role and click "Next".
GitBook Assistant
1. 

In the "Members" tab, choose the "User, group or service principal" option and search for the created Entro app registration. Select the Entro app registration and click on "Next".
GitBook Assistant
1. 

In the "Review + assign" tab, make sure you granted the contributor role to the Entro app registration and click on "Review + assign".
GitBook Assistant
2
### Download the bot app from Entro [#download-the-bot-app-from-entro](#download-the-bot-app-from-entro)

- 

On Entro application, go to "Management" > "Accounts & Integrations", click on "+ Add new account".
GitBook Assistant
- 

Click on the "Microsoft Teams" icon.
GitBook Assistant
- 

Choose the Azure account where the application with the Teams permissions is found and click on "Download App".
GitBook Assistant

- 

Wait a few seconds until the application will be ready and downloaded.
GitBook Assistant

3
### Setup in Teams[#setup-in-teams](#setup-in-teams)

- 

Head over to the Teams admin portal: [https://admin.teams.microsoft.com/](https://admin.teams.microsoft.com/)
GitBook Assistant
- 

On the side menu, click on "Teams apps" > "Manage apps". 
GitBook Assistant
- 

On the right side of the screen click on "Actions" > "Upload new app". 
GitBook Assistant
- 

Once uploaded, you will see the following screen. Click on “this link” in the prompt. 
GitBook Assistant
- 

It will redirect you to this screen, copy the App ID and go back to the Teams onboarding form in Entro. 
GitBook Assistant
- 

Now head over to “Setup policies” as seen below and click on “Global (Org-wide default)”. 
GitBook Assistant
- 

Click on "Add apps". 
GitBook Assistant
- 

Select “Entro Security” and save the changes. 
GitBook Assistant
- 

You should see the following screen. 
GitBook Assistant
- 

Copy the App ID and paste it in Entro's onboarding form. Click on "Connect Bot".
GitBook Assistant

Security & Compliance:
GitBook Assistant

- 

TLS 1.2+ encryption
GitBook Assistant
- 

AES-256 token protection
GitBook Assistant
- 

Read-only access, no data persistence
GitBook Assistant
- 

SOC 2 Type II, ISO 27001, GDPR compliant
GitBook Assistant
[PreviousMicrosoft Teams](/integrations/collaboration-and-saas/microsoft-teams)[NextMicrosoft Teams Permissions Reference](/integrations/collaboration-and-saas/microsoft-teams/microsoft-teams-permissions-reference)

Last updated 2 months ago

- [Prerequisites](#prerequisites)
- [Mandatory - Graph Permissions](#mandatory-graph-permissions)
- [Optional - Microsoft Teams alerts and messaging setup](#optional-microsoft-teams-alerts-and-messaging-setup)
- [Download the bot app from Entro](#download-the-bot-app-from-entro)
- [Setup in Teams](#setup-in-teams)

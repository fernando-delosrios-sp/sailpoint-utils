Microsoft Teams Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/microsoft-teams/microsoft-teams-permissions-reference.md).

This section lists the required Microsoft Graph API permissions for Entro’s Microsoft Teams integration and their justification.
GitBook Assistant
## Permission Categories[#permission-categories](#permission-categories)
CategoryPermissionsPurpose

**Mandatory**
GitBook Assistant

User.Read.All, Directory.Read.All
GitBook Assistant

Basic user and directory visibility
GitBook Assistant

**Secret Detection**
GitBook Assistant

TeamsActivity.Read.All, TeamSettings.Read.All, TeamsTab.Read.All, TeamsAppInstallation.ReadForChat.All, TeamsAppInstallation.ReadForTeam.All, TeamsAppInstallation.ReadForUser.All, Channel.ReadBasic.All, ChannelMember.Read.All, ChannelMessage.Read.All, ChannelSettings.Read.All, Chat.Read.All
GitBook Assistant

Enables secure read-only detection of exposed secrets within Teams resources
GitBook Assistant

**Messaging & Alerts**
GitBook Assistant

TeamsAppInstallation.ReadWriteForTeam.All, TeamsAppInstallation.ReadWriteForUser.All, TeamsAppInstallation.ReadWriteSelfForUser.All
GitBook Assistant

Allows Entro Bot to send and manage alert messages securely
GitBook Assistant
#### Access Behavior[#access-behavior](#access-behavior)

- 

Entro uses read-only Graph API calls where possible.
GitBook Assistant
- 

Tokens are AES-256 encrypted and stored within Entro’s secure worker environment.
GitBook Assistant
- 

All actions are logged and traceable within Entro’s audit logs.
GitBook Assistant

#### Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

SOC 2 Type II
GitBook Assistant
- 

ISO 27001
GitBook Assistant
- 

GDPR compliance
GitBook Assistant
- 

TLS 1.2+ for all connections
GitBook Assistant
- 

No modification or message content persistence
GitBook Assistant
[PreviousMicrosoft Teams Onboarding](/integrations/collaboration-and-saas/microsoft-teams/microsoft-teams-onboarding)[NextSharePoint / OneDrive](/integrations/collaboration-and-saas/sharepoint)

Last updated 4 months ago

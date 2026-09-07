Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/permissions-reference.md).

This page lists the required permissions that **Entro Security** uses for continuous **Secrets Scanning, AI Agents Governance** and **Non-Human Identity (NHI)** monitoring across Microsoft Entra, Azure, 365 environments. All permissions are **read-only** and adhere to **least-privilege principles**.
GitBook Assistant
## Microsoft Graph API[#microsoft-graph-api](#microsoft-graph-api)

The following Microsoft Graph permissions allow Entro to enumerate identities, applications, and configuration metadata:
GitBook AssistantPermissionPurpose

**Directory.Read.All**
GitBook Assistant

Enumerate Entra ID directory structure and metadata
GitBook Assistant

**Application.Read.All**
GitBook Assistant

Retrieve application and service principal metadata
GitBook Assistant

**User.Read.All**
GitBook Assistant

Discover user objects for identity correlation
GitBook Assistant
### NHI, AI Usage (optional)[#nhi-ai-usage-optional](#nhi-ai-usage-optional)

The following optional permissions improve visibility and correlation between secrets and related identity activity (NHI or AI):
GitBook AssistantPermissionPurpose

**AuditLog.Read.All**
GitBook Assistant

Access Azure AD audit logs for activity tracking
GitBook Assistant

**SignInLogs.Read.All**
GitBook Assistant

Retrieve sign-in activity for identity correlation
GitBook Assistant
### 365 Apps Secrets Scanning (optional)[#id-365-apps-secrets-scanning-optional](#id-365-apps-secrets-scanning-optional)

Microsoft Teams (Chats, Channels), Sharepoint / OneDrive (Pages, Documents, Sites)
GitBook Assistant
#### Microsoft Teams[#microsoft-teams](#microsoft-teams)
PermissionPurpose

**TeamsActivity.Read.All**
GitBook Assistant

Read Teams activity metadata for discovery and correlation
GitBook Assistant

**TeamSettings.Read.All**
GitBook Assistant

Read team settings and configuration metadata
GitBook Assistant

**TeamsTab.Read.All**
GitBook Assistant

Read installed Teams tabs and related configuration
GitBook Assistant

**TeamsAppInstallation.ReadForChat.All**
GitBook Assistant

Read app installations in chats
GitBook Assistant

**TeamsAppInstallation.ReadForTeam.All**
GitBook Assistant

Read app installations in teams
GitBook Assistant

**TeamsAppInstallation.ReadForUser.All**
GitBook Assistant

Read app installations for users
GitBook Assistant

**Channel.ReadBasic.All**
GitBook Assistant

Enumerate channels and basic channel metadata
GitBook Assistant

**ChannelMember.Read.All**
GitBook Assistant

Read channel membership for access correlation
GitBook Assistant

**ChannelMessage.Read.All**
GitBook Assistant

Read channel messages for secrets scanning
GitBook Assistant

**ChannelSettings.Read.All**
GitBook Assistant

Read channel settings and moderation configuration
GitBook Assistant

**Chat.Read.All**
GitBook Assistant

Read chat messages and metadata for secrets scanning
GitBook Assistant

**AuditLog.Read.All**
GitBook Assistant

Prioritization for secrets scanning by individuals (MS Teams), by recent activity timestamp.
GitBook Assistant
### Graph permissions for sending risks in Teams messages natively from Entro[#graph-permissions-for-sending-risks-in-teams-messages-natively-from-entro](#graph-permissions-for-sending-risks-in-teams-messages-natively-from-entro)

These permissions are required only when you enable native Teams risk messaging from Entro.
GitBook AssistantPermissionPurpose

**TeamsAppInstallation.ReadWriteForTeam.All**
GitBook Assistant

Install and manage the Entro Teams app in teams for native risk delivery
GitBook Assistant

**TeamsAppInstallation.ReadWriteForUser.All**
GitBook Assistant

Install and manage the Entro Teams app for users receiving risk messages
GitBook Assistant

**TeamsAppInstallation.ReadWriteSelfForUser.All**
GitBook Assistant

Allow the Entro Teams app to manage its own user-level installation state
GitBook Assistant
#### Sharepoint / OneDrive[#sharepoint-onedrive](#sharepoint-onedrive)
PermissionPurpose

**Sites.Read.All**
GitBook Assistant

Read SharePoint site collections and site metadata
GitBook Assistant

**Files.Read.All**
GitBook Assistant

Read file metadata and document structure across SharePoint and OneDrive
GitBook Assistant
### Additional Graph permissions for AI discovery[#additional-graph-permissions-for-ai-discovery](#additional-graph-permissions-for-ai-discovery)

The following permissions are required only when you enable AI discovery flows for Microsoft Copilot or Microsoft Defender.
GitBook Assistant
#### Microsoft Copilot - Discover and analyze Copilot Endpoint and Chat Agents[#microsoft-copilot-discover-and-analyze-copilot-endpoint-and-chat-agents](#microsoft-copilot-discover-and-analyze-copilot-endpoint-and-chat-agents)
PermissionPurpose

**AiEnterpriseInteraction.Read.All**
GitBook Assistant

Read Microsoft Copilot enterprise AI interaction metadata
GitBook Assistant

**Reports.Read.All**
GitBook Assistant

Access usage and activity reports for discovery and analysis
GitBook Assistant

**ExternalConnection.Read.All**
GitBook Assistant

Read external connection metadata used by Copilot
GitBook Assistant

**AppCatalog.Read.All**
GitBook Assistant

Enumerate app catalog entries and related app metadata
GitBook Assistant
#### Microsoft Defender - Endpoint Agentic AI discovery[#microsoft-defender-endpoint-agentic-ai-discovery](#microsoft-defender-endpoint-agentic-ai-discovery)
PermissionPurpose

**Machine.Read.All**
GitBook Assistant

Read device inventory and related machine metadata - WindowsDefenderATP API
GitBook Assistant

**ThreatHunting.Read.All**
GitBook Assistant

Query advanced hunting data for AI agent discovery visibility
GitBook Assistant

Most Graph permissions requested are read-only. The native Teams risk messaging permissions above require limited write access to install and manage the Entro Teams app.
GitBook Assistant
## Azure Resource Access[#azure-resource-access](#azure-resource-access)

Entro Application requires these read-access assigned roles scopes to access `subscription` / `management group` metadata from Azure.
GitBook AssistantRoleDescription

**Reader**
GitBook Assistant

Grants read-only access to resource metadata and configurations
GitBook Assistant

**Key Vault Reader**
GitBook Assistant

Allows enumeration of Key Vaults and secret metadata
GitBook Assistant
## Key Vault Access Policy[#key-vault-access-policy](#key-vault-access-policy)

When Key Vault **Access Policy** mode (non-RBAC) is enabled, Entro's service principal app must have the following permissions to manage it's secrets. `Get` permission is optional for Vault <-> NHI Token / Exposed Secret correlation.
GitBook AssistantObjectRequired Permissions

**Keys**
GitBook Assistant

Get, List
GitBook Assistant

**Secrets**
GitBook Assistant

Get, List
GitBook Assistant

With List permission only, Entro reads only metadata such as key names, versions, and expiration dates. Secret values are never retrieved or transmitted.
GitBook Assistant[PreviousTroubleshooting And Validation](/integrations/cloud-and-infrastructure/azure/troubleshooting-and-validation)[NextAzure DevOps](/integrations/cloud-and-infrastructure/azure-devops)

Last updated 2 months ago

- [Microsoft Graph API](#microsoft-graph-api)
- [NHI, AI Usage (optional)](#nhi-ai-usage-optional)
- [365 Apps Secrets Scanning (optional)](#id-365-apps-secrets-scanning-optional)
- [Graph permissions for sending risks in Teams messages natively from Entro](#graph-permissions-for-sending-risks-in-teams-messages-natively-from-entro)
- [Additional Graph permissions for AI discovery](#additional-graph-permissions-for-ai-discovery)
- [Azure Resource Access](#azure-resource-access)
- [Key Vault Access Policy](#key-vault-access-policy)

Microsoft Copilot Studio Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/microsoft-copilot-studio/microsoft-copilot-studio-permissions-reference.md).
### Microsoft Graph API Permissions (Application Scopes)[#microsoft-graph-api-permissions-application-scopes](#microsoft-graph-api-permissions-application-scopes)
PermissionTypePurpose / Justification

`Application.Read.All`
GitBook Assistant

Application
GitBook Assistant

Scans app registrations and service principals for Non-Human Identity (NHI) discovery.
GitBook Assistant

`Directory.Read.All`
GitBook Assistant

Application
GitBook Assistant

Reads directory metadata including basic tenant structural configuration.
GitBook Assistant

`Group.Read.All`
GitBook Assistant

Application
GitBook Assistant

Analyzes group memberships linked to resource authorization.
GitBook Assistant

`User.Read.All`
GitBook Assistant

Application
GitBook Assistant

Resolves user accounts to correlate identity owners with specific AI agents.
GitBook Assistant

`RoleManagement.Read.Directory`
GitBook Assistant

Application
GitBook Assistant

Inventories admin directory role assignments.
GitBook Assistant

`Policy.Read.All`
GitBook Assistant

Application
GitBook Assistant

Inventories active conditional access and consent policies.
GitBook Assistant

`AuditLog.Read.All` 
GitBook Assistant

Application
GitBook Assistant

Monitors sign-in behavior and usage patterns for anomalous NHI activity.
GitBook Assistant
### Dynamics CRM API Permissions (Delegated Scopes)[#dynamics-crm-api-permissions-delegated-scopes](#dynamics-crm-api-permissions-delegated-scopes)
PermissionTypePurpose / Justification

`user_impersonation`
GitBook Assistant

Delegated
GitBook Assistant

Enables backend Web API communication with individual Dataverse environment instances.
GitBook Assistant
### Power Platform API Permissions (Application Scopes)[#power-platform-api-permissions-application-scopes](#power-platform-api-permissions-application-scopes)
PermissionTypePurpose / Justification

`AppManagement.ApplicationPackages.Read` 
GitBook Assistant

Application
GitBook Assistant

Inventories installed packages and extensions within monitored environments.
GitBook Assistant

`Analytics.Analytics.Read` 
GitBook Assistant

Application
GitBook Assistant

Reads platform metrics and environment analytics records.
GitBook Assistant
### Dataverse Environment Access[#dataverse-environment-access](#dataverse-environment-access)

- 

**Assigned Security Role:** `System Administrator` 
GitBook Assistant
- 

**Justification:** Required by the application user within each targeted environment to thoroughly examine connection references, structural workflows, metadata configurations, and hidden credentials attached to Copilot Studio agent implementations.
GitBook Assistant

Last updated 3 months ago

- [Microsoft Graph API Permissions (Application Scopes)](#microsoft-graph-api-permissions-application-scopes)
- [Dynamics CRM API Permissions (Delegated Scopes)](#dynamics-crm-api-permissions-delegated-scopes)
- [Power Platform API Permissions (Application Scopes)](#power-platform-api-permissions-application-scopes)
- [Dataverse Environment Access](#dataverse-environment-access)

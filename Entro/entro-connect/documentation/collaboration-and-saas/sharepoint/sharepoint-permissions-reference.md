SharePoint Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/sharepoint/sharepoint-permissions-reference.md).

This section outlines the permissions required for Entro to integrate with Microsoft SharePoint and explains their purpose.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Azure
GitBook Assistant
## Required Permissions[#required-permissions](#required-permissions)

### Microsoft Graph (Application Permissions)[#microsoft-graph-application-permissions](#microsoft-graph-application-permissions)
PermissionDescription

`User.Read.All`
GitBook Assistant

Allows Entro to retrieve basic user and NHI information across the tenant
GitBook Assistant

`Directory.Read.All`
GitBook Assistant

Grants read access to directory objects such as users, groups, and roles
GitBook Assistant

`Sites.Read.All`
GitBook Assistant

Enables Entro to read all site collections and associated metadata
GitBook Assistant

`Files.Read.All`
GitBook Assistant

Allows Entro to read files’ metadata, structure, and access permissions
GitBook Assistant

`AuditLog.Read.All`
GitBook Assistant

Prioritizes scanning or active users by their last logon timestamp.
GitBook Assistant[PreviousSharePoint Troubleshooting And Validation](/integrations/collaboration-and-saas/sharepoint/sharepoint-troubleshooting-and-validation)[NextServiceNow](/integrations/collaboration-and-saas/servicenow)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Required Permissions](#required-permissions)
- [Microsoft Graph (Application Permissions)](#microsoft-graph-application-permissions)

User Management | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/user-management.md).

The **User Management** section provides centralized oversight of all users within the Entro platform, helping teams manage access, assign roles, and monitor user activity. It ensures that permissions are properly aligned with organizational responsibilities while maintaining transparency and accountability through detailed audit tracking.
GitBook Assistant
### **Role Management**[#role-management](#role-management)

The **Role Management** tab lists all users in the organization, including their login IDs, names, email addresses, current status, and assigned roles. Administrators can edit user details and adjust access levels as needed.
GitBook Assistant
#### **Roles Defined**[#roles-defined](#roles-defined)

Entro provides several predefined roles that determine each user’s level of access and control within the platform:
GitBook Assistant

- 

**Admin** — Full, unrestricted access across all modules and settings, including user and role management.
GitBook Assistant
- 

**Operator** — Manages inventories and risks and uses all operational features except platform configuration.
GitBook Assistant
- 

**Viewer** — Read-only access to inventories, risks, and dashboards for monitoring without modification privileges.
GitBook Assistant
- 

**Integrator** — Focused solely on managing account integrations; can onboard new accounts but cannot view or act on risks or inventories.
GitBook Assistant
- 

**API Key Manager** — Grants access to Entro’s APIs and API Keys Management, and view access to the Prevention Logs inventory.
GitBook Assistant
- 

**Engineer** — Developer-focused role limited to CLI Scanner usage and visibility into their own exposures.
GitBook Assistant

For more information of the different roles and permissions, see [Management](/knowledge-base/management/rbac)
GitBook Assistant
### **User Audit Logs**[#user-audit-logs](#user-audit-logs)

The **User Audit Logs** tab captures a detailed history of user activity within Entro, offering visibility into logins, configuration changes, and other key actions. Each record includes the time of the event, the user and actor involved, the originating IP address, and the specific action performed. Logs can be filtered by time period (for example, *Last 2 Weeks*) to help administrators quickly review recent activities or investigate unusual events.
GitBook Assistant

[PreviousSlack Configurations](/administration/settings/slack-configurations)[NextWebhooks](/administration/settings/webhooks)

Last updated 10 months ago

- [Role Management](#role-management)
- [User Audit Logs](#user-audit-logs)

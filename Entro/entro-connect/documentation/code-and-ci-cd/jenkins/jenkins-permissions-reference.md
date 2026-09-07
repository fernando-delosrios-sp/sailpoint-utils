Jenkins Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/jenkins/jenkins-permissions-reference.md).

This section details the permissions required for Entro to operate with Jenkins in a secure, read-only mode.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Jenkins → Permissions Reference
GitBook Assistant
## Required Roles and Permissions[#required-roles-and-permissions](#required-roles-and-permissions)

To ensure secure read-only access, configure a Jenkins service account with the following permissions:
GitBook AssistantPermissionLevelDescription

Overall/Read
GitBook Assistant

Global
GitBook Assistant

Grants visibility into Jenkins configuration and metadata
GitBook Assistant

Job/Read
GitBook Assistant

Job
GitBook Assistant

Allows Entro to retrieve job configurations, logs, and metadata
GitBook Assistant

Build/Read
GitBook Assistant

Build
GitBook Assistant

Allows Entro to retrieve build configurations, logs, and metadata
GitBook Assistant

These permissions can be configured through Jenkins’ Role-Based Authorization Strategy plugin.
GitBook Assistant

Access Summary
GitBook Assistant

- 

Authentication is performed via **User ID** and **API Token**
GitBook Assistant
- 

Entro uses only **GET** requests to retrieve metadata
GitBook Assistant
- 

No write, modify, or execute operations occur.
GitBook Assistant
- 

Tokens are encrypted and stored securely in the Entro Worker
GitBook Assistant
- 

All communication occurs over **TLS 1.2+**
GitBook Assistant

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Required Roles and Permissions](#required-roles-and-permissions)

Dedicated Atlassian User Creation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/dedicated-atlassian-user-creation.md).

This guide explains how to create a **dedicated service user** in your Atlassian environment for use with Entro Security. Using a separate integration account helps enforce the **principle of least privilege**, improves auditability, and prevents cross-contamination between production and monitoring activities.
GitBook Assistant
## Why Use a Dedicated User?[#why-use-a-dedicated-user](#why-use-a-dedicated-user)

Entro Security connects to Jira and Confluence using API calls or an on-prem Worker. A dedicated integration user ensures:
GitBook Assistant

- 

Clear audit trails in Atlassian logs
GitBook Assistant
- 

Isolation from personal user credentials
GitBook Assistant
- 

Easier permission management (read-only access)
GitBook Assistant
- 

Safe token rotation without disrupting other services
GitBook Assistant
- 

Compliance with SOC 2, ISO 27001, and least-privilege requirements
GitBook Assistant

## Choosing the Right Account Type[#choosing-the-right-account-type](#choosing-the-right-account-type)
EnvironmentUser TypeWhere to CreateNotes

**Atlassian Cloud**
GitBook Assistant

Atlassian Account
GitBook Assistant

[admin.atlassian.com](https://admin.atlassian.com/)
GitBook Assistant

Create a new user and assign product access.
GitBook Assistant

**Atlassian Server / Data Center**
GitBook Assistant

Local Application User
GitBook Assistant

Admin Console → User Management
GitBook Assistant

Create within each self-hosted product.
GitBook Assistant
## Atlassian Cloud[#atlassian-cloud](#atlassian-cloud)
1
#### Access the Admin Console[#access-the-admin-console](#access-the-admin-console)

- 

Go to [admin.atlassian.com](https://admin.atlassian.com/).
GitBook Assistant
- 

Select your organization and choose **Directory → Users**.
GitBook Assistant
- 

Click **Invite Users**.
GitBook Assistant
2
#### Create the Integration User[#create-the-integration-user](#create-the-integration-user)

- 

Enter the email address for your integration account (e.g., `entro.integration@yourcompany.com`).
GitBook Assistant
- 

Under **Product Access**, grant access to:
GitBook Assistant

- 

**Jira Software**
GitBook Assistant
- 

**Confluence**
GitBook Assistant

- 

Assign the **Basic** or **Viewer** role where applicable.
GitBook Assistant
- 

Click **Invite Users**.
GitBook Assistant
3
#### Configure Permissions[#configure-permissions](#configure-permissions)

In each Atlassian product (Jira, Confluence, Bitbucket), ensure the integration user has read-only access required for scanning:
GitBook AssistantProductPermissionsPurpose

**Jira**
GitBook Assistant

`Browse Projects`, `View Issues`, `View Attachments`
GitBook Assistant

Allows Entro to scan issues and attachments.
GitBook Assistant

**Confluence**
GitBook Assistant

`View Pages`, `View Comments`, `View Attachments`
GitBook Assistant

Allows scanning of page and comment content.
GitBook Assistant
## Atlassian Server / Data Center[#atlassian-server-data-center](#atlassian-server-data-center)
1
#### Open the Administration Panel[#open-the-administration-panel](#open-the-administration-panel)

- 

Log in to your Jira or Confluence Server as an administrator.
GitBook Assistant
- 

Navigate to **User Management → Create User**.
GitBook Assistant
2
#### Create the Integration Account[#create-the-integration-account](#create-the-integration-account)

- 

**Username:** `entro.integration`
GitBook Assistant
- 

**Full Name:** `Entro Security Integration`
GitBook Assistant
- 

**Email:** `entro.integration@yourcompany.com`
GitBook Assistant
- 

**Password:** Generate a secure password (or use SSO if supported).
GitBook Assistant

Click **Create User**.
GitBook Assistant3
#### Assign Permissions[#assign-permissions](#assign-permissions)

Grant **read-only access** to relevant projects, spaces, or repositories. Avoid granting global admin roles.
GitBook AssistantProductAccess TypePermissions

**Jira Server**
GitBook Assistant

Project Access
GitBook Assistant

`Browse Projects`, `View Issues`, `View Attachments`
GitBook Assistant

**Confluence Server**
GitBook Assistant

Space Access
GitBook Assistant

`View`, `View Attachments`, `View Comments`
GitBook Assistant
## Token Association[#token-association](#token-association)

Once the user is created, generate a corresponding API or Personal Access Token under that account. Follow [Atlassian Token Creation](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/classic-token-creation) for instructions on how to generate and associate tokens with this new integration user.
GitBook Assistant

Security Recommendations
GitBook Assistant

- 

Rotate the integration user’s token regularly (90 days recommended).
GitBook Assistant
- 

Disable all write/admin permissions.
GitBook Assistant
- 

Restrict login access to specific IPs or VPN (if possible).
GitBook Assistant
- 

Document and audit all access under this account.
GitBook Assistant
[PreviousAdditional Guides and Reference](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference)[NextClassic Token Creation](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/classic-token-creation)

Last updated 4 months ago

- [Why Use a Dedicated User?](#why-use-a-dedicated-user)
- [Choosing the Right Account Type](#choosing-the-right-account-type)
- [Atlassian Cloud](#atlassian-cloud)
- [Atlassian Server / Data Center](#atlassian-server-data-center)
- [Token Association](#token-association)

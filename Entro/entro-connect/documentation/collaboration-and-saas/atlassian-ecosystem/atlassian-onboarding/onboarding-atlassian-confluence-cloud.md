Confluence - Cloud | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/onboarding-atlassian-confluence-cloud.md).
### Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → Atlassian → Scoped API Token - Confluence**
GitBook Assistant
## Overview[#overview](#overview)

Connect Entro to Confluence Cloud with an scoped API token to enable least-privilege, read-only scanning of pages, comments, and attachments, plus space and user context. All access strictly follows the scopes you grant and your existing Confluence permissions.
GitBook Assistant
## Installation & Configuration[#installation-and-configuration](#installation-and-configuration)
1
#### **Get Company's Confluence Domain**[#get-companys-confluence-domain](#get-companys-confluence-domain)

1. 

Login to your company's Atlassian Confluence.
GitBook Assistant
1. 

Get the domain with the format: `https://<yourCompany>.atlassian.net`
GitBook Assistant
1. 

Copy the domain and save for later.
GitBook Assistant
2
#### **Get Your Confluence Cloud ID**[#get-your-confluence-cloud-id](#get-your-confluence-cloud-id)

1. 

While logged in to Confluence, go to this URL: `https://<yourCompany>.atlassian.net/_edge/tenant_info`
GitBook Assistant
1. 

The JSON presented includes the Cloud ID.
GitBook Assistant
1. 

Copy the Cloud ID and save for later.
GitBook Assistant
3
#### **Get Your Atlassian User Email Address**[#get-your-atlassian-user-email-address](#get-your-atlassian-user-email-address)

1. 

While logged in to Confluence, go to this URL: [https://id.atlassian.com/manage-profile/profile-and-visibility](https://id.atlassian.com/manage-profile/profile-and-visibility)
GitBook Assistant
1. 

Under the Contact section, see the user email address.
GitBook Assistant
1. 

Copy the email address and save for later.
GitBook Assistant
Optional: Create Dedicated Entro Integration User[#optional-create-dedicated-entro-integration-user](#optional-create-dedicated-entro-integration-user)

Create an Entro Security user with its own email account, it can be used for all future Atlassian integrations as well if necessary.
GitBook Assistant

1. 

Go to [Atlassian Admin Portal](https://admin.atlassian.com/) - Admin user is required.
GitBook Assistant
1. 

Click on "Directory" tab.
GitBook Assistant
1. 

Click on "Invite user" and follow the prompts.
GitBook Assistant
1. 

Use the created user email address in the Atlassian username on the Entro onboarding form.
GitBook Assistant
4
#### **Create Confluence Scoped API Token**[#create-confluence-scoped-api-token](#create-confluence-scoped-api-token)

1. 

Go to [Atlassian API Token page](https://id.atlassian.com/manage-profile/security/api-tokens) and click on **Create API token with scopes**.
GitBook Assistant
1. 

Give the token a name (for example: `Entro Security Confluence Integration`).
GitBook Assistant
1. 

Set expiration date for the token (maximum time is 365 days).
GitBook Assistant
1. 

Click on **Next**.
GitBook Assistant
1. 

Choose **Confluence** and click on **Next**.
GitBook Assistant
1. 

Select the scopes you wish to grant the token. The below scopes are what Entro requires in order to scan and give the best context on an exposure detected.
GitBook Assistant
GitBook AssistantAskCopy
```
read:confluence-content.all
read:confluence-content.permission
read:confluence-content.summary
read:confluence-groups
read:confluence-props
read:confluence-space.summary
read:confluence-user
read:account
readonly:content.attachment:confluence
search:confluence
```

Or just copy the below in the searchbox for easy selection:
GitBook AssistantGitBook AssistantAskCopy
```
read:confluence-content.all,read:confluence-content.permission,read:confluence-content.summary,read:confluence-groups,read:confluence-props,read:confluence-space.summary,read:confluence-user,read:account,readonly:content.attachment:confluence,search:confluence
```

1. 

Click on **Next**.
GitBook Assistant
1. 

Review the details and scopes, once you confirm click on **Create token**.
GitBook Assistant
1. 

Copy the token and save for later.
GitBook Assistant
5
#### **Connect Atlassian Confluence to Entro Security**[#connect-atlassian-confluence-to-entro-security](#connect-atlassian-confluence-to-entro-security)

In the **Entro Console**, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → Atlassian → Scoped API Token - Confluence**
GitBook Assistant

Complete the onboarding form as follows:
GitBook Assistant

**Field**
GitBook Assistant

**Description**
GitBook Assistant

**Environment**
GitBook Assistant

Enter the relevant environment type (e.g., Production / Staging)
GitBook Assistant

**Atlassian URL**
GitBook Assistant

Paste the URL with the company domain from Step 1
GitBook Assistant

**Confluence Cloud ID**
GitBook Assistant

Paste the Confluence cloud ID from Step 2
GitBook Assistant

**Atlassian Username**
GitBook Assistant

Paste the user email address from Step 3
GitBook Assistant

**Atlassian API Token**
GitBook Assistant

Paste the API token from Step 4
GitBook Assistant

**Worker Group (Connector)**
GitBook Assistant

Select the Entro Connector handling Atlassian scans
GitBook Assistant

Then click **Create Account**.
GitBook Assistant

Entro will validate your credentials and start the initial scanning.
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

All Entro actions are **read-only**; no changes are made to your pages, comments or attachments.
GitBook Assistant
- 

Tokens are encrypted in memory and transmitted only via **TLS 1.2+**.
GitBook Assistant
- 

Access scopes are restricted to pages, comments and attachments metadata and its history.
GitBook Assistant
- 

Entro is certified for **SOC 2 Type II**, **ISO 27001**, and **GDPR** compliance.
GitBook Assistant
[PreviousJira - Cloud](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/onboarding-atlassian-jira-cloud)[NextJira Server - On-premise](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/jira-server-on-premise)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Overview](#overview)
- [Installation & Configuration](#installation-and-configuration)
- [Security & Compliance](#security-and-compliance)

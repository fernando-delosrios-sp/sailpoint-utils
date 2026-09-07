Jira - Cloud | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/onboarding-atlassian-jira-cloud.md).
### Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → Atlassian → Scoped API Token - Jira**
GitBook Assistant
## Overview[#overview](#overview)

Connect Entro to Jira Cloud using an Atlassian scoped API token so you grant only the access you choose. We use those scopes to scan issues, comments, and attachments (and optionally create issues), while Jira project permissions continue to control what we can read/write. The connection uses your Cloud ID and can be paired with [webhooks for near real-time detection](/integrations/collaboration-and-saas/atlassian-ecosystem/setting-up-jira-real-time-scanning).
GitBook Assistant
## Installation & Configuration[#installation-and-configuration](#installation-and-configuration)
1
#### **Get Company's Jira Domain**[#get-companys-jira-domain](#get-companys-jira-domain)

1. 

Login to your company's Atlassian Jira.
GitBook Assistant
1. 

Get the domain with the format: `https://<yourCompany>.atlassian.net`
GitBook Assistant
1. 

Copy the domain and save for later.
GitBook Assistant
2
#### **Get Your Jira Cloud ID**[#get-your-jira-cloud-id](#get-your-jira-cloud-id)

1. 

While logged in to Jira, go to this URL: `https://<yourCompany>.atlassian.net/_edge/tenant_info`
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

While logged in to Jira, go to this URL: [https://id.atlassian.com/manage-profile/profile-and-visibility](https://id.atlassian.com/manage-profile/profile-and-visibility)
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
#### **Create Jira Scoped API Token**[#create-jira-scoped-api-token](#create-jira-scoped-api-token)

1. 

Go to [Atlassian API Token page](https://id.atlassian.com/manage-profile/security/api-tokens) and click on **Create API token with scopes**.
GitBook Assistant
1. 

Give the token a name (for example: `Entro Security Jira Integration`).
GitBook Assistant
1. 

Set expiration date for the token (maximum time is 365 days).
GitBook Assistant
1. 

Click on **Next**.
GitBook Assistant
1. 

Choose **Jira** and click on **Next**.
GitBook Assistant
1. 

Select the scopes you wish to grant the token.
GitBook Assistant

**Note: the write scope is optional and it enables the capability to create Jira tickets for risks straight from the Entro application.**
GitBook AssistantClassic scopes with additional granular scopes (6 scopes)[#classic-scopes-with-additional-granular-scopes-6-scopes](#classic-scopes-with-additional-granular-scopes-6-scopes)

Classic scopes:
GitBook AssistantGitBook AssistantAskCopy
```
read:jira-work 
read:jira-user
write:jira-work
```

Granular scopes:
GitBook AssistantGitBook AssistantAskCopy
```
read:email-address:jira
read:epic:jira-software
validate:jql:jira
```

Or just copy the below in the searchbox for easy selection:
GitBook AssistantGitBook AssistantAskCopy
```
read:jira-work,read:jira-user,write:jira-work,read:email-address:jira,read:epic:jira-software,validate:jql:jira
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
#### **Connect Atlassian Jira to Entro Security**[#connect-atlassian-jira-to-entro-security](#connect-atlassian-jira-to-entro-security)

In the **Entro Console**, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → Atlassian → Scoped API Token - Jira**
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

**Jira Cloud ID**
GitBook Assistant

Paste the Jira cloud ID from Step 2
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

All Entro actions are **read-only**; no changes are made to your issues, comments or attachments.
GitBook Assistant

- 

Except for one write action (optional) to create Jira issue from Entro application.
GitBook Assistant

- 

Tokens are encrypted in memory and transmitted only via **TLS 1.2+**.
GitBook Assistant
- 

Access scopes are restricted to issues, comments and attachments metadata and its history.
GitBook Assistant
- 

Entro is certified for **SOC 2 Type II**, **ISO 27001**, and **GDPR** compliance.
GitBook Assistant
[PreviousAtlassian Onboarding](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding)[NextConfluence - Cloud](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/onboarding-atlassian-confluence-cloud)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Overview](#overview)
- [Installation & Configuration](#installation-and-configuration)
- [Security & Compliance](#security-and-compliance)

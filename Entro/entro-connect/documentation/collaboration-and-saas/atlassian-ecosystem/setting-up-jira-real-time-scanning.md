Setting Up Jira Real-Time Scanning | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/setting-up-jira-real-time-scanning.md).
### Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Jira Application (⋮ menu) → Real Time Scanning**
GitBook Assistant
### Overview[#overview](#overview)

Jira Real-Time Scanning uses a tenant-specific webhook to notify Entro whenever issues, comments, or attachments are created, changed or deleted. Each event triggers an immediate, read-only scan within your granted scopes and Jira permissions, surfacing exposures in near real time.
GitBook Assistant

Note: Jira administrator is needed to setup the webhook
GitBook Assistant
## Enabling Real-Time Scanning[#enabling-real-time-scanning](#enabling-real-time-scanning)
1
#### **Get Entro Webhook**[#get-entro-webhook](#get-entro-webhook)

In Entro follow the below navigation path to get the webhook you need to setup in Jira: Management → Accounts & Integrations → Jira Application (⋮ menu) → Real Time Scanning
GitBook Assistant

Copy the webhook and save for later.
GitBook Assistant2
#### **Configure Entro Webhook in Jira**[#configure-entro-webhook-in-jira](#configure-entro-webhook-in-jira)

With the Jira administrator do the following:
GitBook Assistant

1. 

Sign in to your Jira.
GitBook Assistant
1. 

Go to **Settings → System → Webhooks → Create a Webhook**
GitBook Assistant
1. 

Give it a name (for example : `Entro Security Real Time Scanning`)
GitBook Assistant
1. 

In the URL enter the webhook from Step 1.
GitBook Assistant
1. 

Under Issue related events you can add JQL to allow Entro to scan specific locations (recommended to leave it empty for overall scanning)
GitBook Assistant
1. 

Check all the checkboxes under: **Issue, Comment, Attachment**
GitBook Assistant

1. 

Issue:created , Issue:updated , Issue:deleted
GitBook Assistant
1. 

Comment:created , Comment:updated , Comment:deleted
GitBook Assistant
1. 

Attachment:created , Attachment:deleted
GitBook Assistant

1. 

Click on **Create**
GitBook Assistant

**Note: Make sure NOT to check the Exclude Body checkbox.**
GitBook Assistant[Previous[Legacy] Atlassian (Jira & Confluence) - Cloud](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/legacy-atlassian-jira-and-confluence-cloud)[NextAdditional Guides and Reference](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Overview](#overview)
- [Enabling Real-Time Scanning](#enabling-real-time-scanning)

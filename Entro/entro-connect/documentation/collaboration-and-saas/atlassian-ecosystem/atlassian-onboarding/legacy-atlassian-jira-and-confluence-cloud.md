[Legacy] Atlassian (Jira & Confluence) - Cloud | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/legacy-atlassian-jira-and-confluence-cloud.md).
## Installation & Configuration[#installation-and-configuration](#installation-and-configuration)

### Prerequisites[#prerequisites](#prerequisites)

- 

Atlassian Cloud admin privileges
GitBook Assistant
- 

A **Dedicated Integration User** with read-only access (see [Dedicated Atlassian User](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/dedicated-atlassian-user-creation#create-the-integration-user))
GitBook Assistant
- 

A valid **API Token** (see [Atlassian Token Creation](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/classic-token-creation))
GitBook Assistant
- 

Outbound HTTPS (TCP 443) access from Entro Security to Atlassian Cloud
GitBook Assistant

### Connect to Entro Security[#connect-to-entro-security](#connect-to-entro-security)
1
#### Select Integration[#select-integration](#select-integration)

In the **Entro Security Dashboard**, go to **Management → Accounts & Integrations → Add New Account (top right) → Atlassian**
GitBook Assistant2
#### Enter Connection Details[#enter-connection-details](#enter-connection-details)

Provide the following details:
GitBook Assistant

- 

**Environment (eg. Production)**
GitBook Assistant
- 

**Base URL:** e.g., `https://yourcompany.atlassian.net`
GitBook Assistant
- 

**Atlassian Username: user@entrosecurity.com**
GitBook Assistant
- 

**Integration User Email**
GitBook Assistant
- 

**Atlassian Token**
GitBook Assistant
- 

**Choose your connector**
GitBook Assistant
3
#### Create Account[#create-account](#create-account)

Click **Create Account** to validate access.
GitBook Assistant
## System Requirements[#system-requirements](#system-requirements)
ComponentRequirement

**Platform**
GitBook Assistant

Atlassian Cloud (Jira/Confluence)
GitBook Assistant

**Authentication**
GitBook Assistant

Atlassian API Token
GitBook Assistant

**Network**
GitBook Assistant

Outbound HTTPS (443) to Entro Security endpoints
GitBook Assistant

**Permissions**
GitBook Assistant

Read-only access for the integration user
GitBook Assistant

**File Size Limit**
GitBook Assistant

≤ 10 MB per file
GitBook Assistant
## Managing Findings[#managing-findings](#managing-findings)

After the initial synchronization, detected secrets appear in the **Findings Dashboard**.
GitBook Assistant

Each finding displays:
GitBook Assistant

- 

Product (Jira/Confluence)
GitBook Assistant
- 

Resource name (issue, page, repository)
GitBook Assistant
- 

Secret type and exposure severity
GitBook Assistant
- 

Direct URL to the affected resource
GitBook Assistant

You can:
GitBook Assistant

- 

Assign remediation to team members
GitBook Assistant
- 

Sync or create Jira tickets for follow-up
GitBook Assistant
- 

Mark verified false positives as **Resolved**
GitBook Assistant

## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

All operations are **read-only** via Atlassian’s official APIs.
GitBook Assistant
- 

Raw Atlassian data is never stored - only metadata and detected findings are retained.
GitBook Assistant
- 

All traffic between Entro and Atlassian is encrypted with HTTPS/TLS 1.2+.
GitBook Assistant
- 

Tokens are securely encrypted and stored in Entro’s infrastructure.
GitBook Assistant

🔒 **Compliance Alignment**
GitBook Assistant

- 

SOC 2 Type II
GitBook Assistant
- 

ISO 27001
GitBook Assistant
- 

GDPR Compliant
GitBook Assistant
- 

Principle of Least Privilege enforced (read-only access)
GitBook Assistant
[PreviousConfluence Server - On-premise](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/confluence-server-on-premise)[NextSetting Up Jira Real-Time Scanning](/integrations/collaboration-and-saas/atlassian-ecosystem/setting-up-jira-real-time-scanning)

Last updated 4 months ago

- [Installation & Configuration](#installation-and-configuration)
- [Prerequisites](#prerequisites)
- [Connect to Entro Security](#connect-to-entro-security)
- [System Requirements](#system-requirements)
- [Managing Findings](#managing-findings)
- [Security & Compliance](#security-and-compliance)

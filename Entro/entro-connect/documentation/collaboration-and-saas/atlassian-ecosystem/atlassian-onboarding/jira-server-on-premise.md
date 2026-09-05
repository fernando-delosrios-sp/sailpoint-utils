Jira Server - On-premise | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/jira-server-on-premise.md).

The **Jira Server (On-Prem)** integration enables Entro Security to detect and monitor exposed secrets within your Jira environment — including issues, comments, and attachments — without altering or storing project data.
GitBook Assistant
## Overview[#overview](#overview)

Entro connects to your on-prem Jira Server through a **local Worker** running within your environment. All communication between the Worker and Entro Security occurs securely over HTTPS/TLS, ensuring your Jira data never leaves your network.
GitBook Assistant

**Architecture Diagram**
GitBook AssistantGitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (Secure connection via On-Prem Worker)
Jira Server (On-Prem)
```

## Installation & Configuration[#installation-and-configuration](#installation-and-configuration)
1
#### **Prerequisites**[#prerequisites](#prerequisites)

Before integrating Jira Server with Entro:
GitBook Assistant

- 

Jira Server **v8.0 or later**
GitBook Assistant
- 

REST API access enabled (`/rest/api/2/`)
GitBook Assistant
- 

A **dedicated integration user** (see [Dedicated Atlassian User](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/dedicated-atlassian-user-creation))
GitBook Assistant
- 

A **Personal Access Token (PAT)** for that user (see [Atlassian Token Creation](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/classic-token-creation))
GitBook Assistant
2
#### **Configure the Integration in Entro**[#configure-the-integration-in-entro](#configure-the-integration-in-entro)

1. 

In the **Entro Security Dashboard**, go to **Management → Accounts & Integrations → Add New Account (top right) → Atlassian**
GitBook Assistant
1. 

Enter:
GitBook Assistant

- 

**Base URL:** e.g., `https://jira.internal.company.com`
GitBook Assistant
- 

**Access Token:** the PAT for your integration user
GitBook Assistant
- 

**Worker Group:** select a connector that is active
GitBook Assistant
- 

**Make sure to select Self Managed**
GitBook Assistant

1. 

Click **Create Account** to verify connectivity.
GitBook Assistant
3
#### **Initial Scan**[#initial-scan](#initial-scan)

After setup, initiate the first scan manually or allow the default scheduler to begin automatically.
GitBook Assistant

- 

Scans use Jira’s REST API to collect metadata and content.
GitBook Assistant
- 

Only text‑based data is processed locally by your Worker.
GitBook Assistant
- 

Findings metadata is sent securely to Entro Cloud for classification.
GitBook Assistant

## System Requirements[#system-requirements](#system-requirements)
ComponentRequirement

**Jira Version**
GitBook Assistant

8.0+
GitBook Assistant

**API Access**
GitBook Assistant

`/rest/api/2/` enabled
GitBook Assistant

**Network**
GitBook Assistant

Outbound HTTPS (443) from Worker to Entro
GitBook Assistant

**Authentication**
GitBook Assistant

Personal Access Token (PAT)
GitBook Assistant

**Permissions**
GitBook Assistant

`Browse Projects`, `View Issues`, `View Attachments`
GitBook Assistant
## Managing Findings[#managing-findings](#managing-findings)

Detected secrets appear in the **Findings Dashboard** within Entro Security. Each finding includes:
GitBook Assistant

- 

Project name and issue key
GitBook Assistant
- 

Secret type (e.g., AWS key, database password)
GitBook Assistant
- 

Exposure level (generic or confirmed)
GitBook Assistant
- 

Direct Jira link for remediation
GitBook Assistant

From the dashboard, you can:
GitBook Assistant

- 

Assign or comment on findings
GitBook Assistant
- 

Sync with Jira tickets for tracking
GitBook Assistant
- 

Mark false positives as resolved
GitBook Assistant

## Generic vs Exposed Secrets[#generic-vs-exposed-secrets](#generic-vs-exposed-secrets)
TypeDefinitionExample

**Generic Secret**
GitBook Assistant

Pattern‑matched value that may represent a secret.
GitBook Assistant

`password=abcd1234`
GitBook Assistant

**Exposed Secret**
GitBook Assistant

Verified secret exposed in accessible content.
GitBook Assistant

`AWS_SECRET_ACCESS_KEY=ABCD12345XYZ`
GitBook Assistant

Entro classifies secrets to reduce noise and surface only actionable exposures.
GitBook Assistant
## Data Privacy & Security[#data-privacy-and-security](#data-privacy-and-security)

Entro Security never stores raw Jira issue content or attachments. All scanning occurs within your environment via the local Worker. Only metadata and findings are securely transmitted to Entro Cloud.
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

Read‑only access enforced by token scope
GitBook Assistant

All communication between the on‑prem Worker and Entro Cloud is encrypted (HTTPS/TLS). The Worker processes text-based content locally - raw content and attachments are not stored in Entro Cloud.
GitBook Assistant[PreviousConfluence - Cloud](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/onboarding-atlassian-confluence-cloud)[NextConfluence Server - On-premise](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/confluence-server-on-premise)

Last updated 4 months ago

- [Overview](#overview)
- [Installation & Configuration](#installation-and-configuration)
- [System Requirements](#system-requirements)
- [Managing Findings](#managing-findings)
- [Generic vs Exposed Secrets](#generic-vs-exposed-secrets)
- [Data Privacy & Security](#data-privacy-and-security)

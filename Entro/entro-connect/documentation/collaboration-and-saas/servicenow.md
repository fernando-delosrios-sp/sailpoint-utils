ServiceNow | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/servicenow.md).

The ServiceNow Integration allows Entro Security to securely scan your ServiceNow environment for exposed secrets and sensitive data across tickets, knowledge articles, attachments, and configuration records (including CMDB items where accessible). This enables continuous discovery and monitoring of secret exposure within ITSM workflows and automation content.
GitBook Assistant
## Overview[#overview](#overview)

Entro connects to your **ServiceNow instance** using an **Admin API Access Token** generated within ServiceNow. The integration operates in **read-only mode** and interacts with ServiceNow's REST APIs to fetch metadata and content for secret detection.
GitBook Assistant

All connections and data retrieval are performed through secure HTTPS/TLS communication, following least-privilege access and strict data handling policies.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

In the Entro Dashboard, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → ServiceNow**
GitBook Assistant
## Architecture Diagram[#architecture-diagram](#architecture-diagram)
GitBook AssistantAskCopy
```
+-------------------+           +-----------------------------+
| Entro Security    |  <------> |  ServiceNow Instance        |
| Cloud Platform    |   HTTPS   |  (Table & Attachment APIs)  |
+-------------------+           +-----------------------------+
```

## What Entro Scans[#what-entro-scans](#what-entro-scans)

Once connected, Entro analyzes:
GitBook Assistant

- 

**Tickets:** Incident, Change Request, and Problem records
GitBook Assistant
- 

**Knowledge Base Articles, Comments and Attachments**
GitBook Assistant
- 

**Configuration Items (CIs) and CMDB records**
GitBook Assistant
- 

**Custom tables & Fields** where accessible through the same token scope
GitBook Assistant

Detection includes API keys, tokens, passwords, SSH keys, and other sensitive data within text or attached files.
GitBook Assistant
## Supported Authentication[#supported-authentication](#supported-authentication)

- 

**ServiceNow Admin API Token** (generated in your instance)
GitBook Assistant
- 

Authenticated via ServiceNow REST APIs:
GitBook Assistant

- 

**Table API** (for ticket and record content)
GitBook Assistant
- 

**Attachment API** (for attached files and documents)
GitBook Assistant

- 

Entro validates API connectivity during onboarding and confirms scope before scanning begins.
GitBook Assistant

#### Data Access Mode[#data-access-mode](#data-access-mode)

- 

**Read-only:** Entro never modifies, deletes, or writes data in ServiceNow.
GitBook Assistant
- 

**Scoped Access:** Integration scopes include only the APIs required for metadata and content retrieval.
GitBook Assistant
- 

**Encrypted Transport:** All data is transmitted over HTTPS/TLS 1.2+.
GitBook Assistant
- 

**Token Security:** All API tokens are encrypted and stored in Entro's vault. No secrets or credentials are persisted beyond analysis.
GitBook Assistant
- 

**Worker Group:** The ServiceNow connector can operate through any active **Worker Group (Connector)** in your environment.
GitBook Assistant

## Security & Compliance[#security-and-compliance](#security-and-compliance)

Entro follows least-privilege and zero-modification principles consistent with:
GitBook Assistant

- 

SOC 2 Type II
GitBook Assistant
- 

ISO 27001
GitBook Assistant
- 

GDPR data protection requirements
GitBook Assistant

All integration actions and validations are logged for auditing within the Entro Console.
GitBook Assistant[PreviousSharePoint Permissions Reference](/integrations/collaboration-and-saas/sharepoint/sharepoint-permissions-reference)[NextServiceNow Onboarding](/integrations/collaboration-and-saas/servicenow/servicenow-onboarding)

Last updated 2 months ago

- [Overview](#overview)
- [Navigation Path](#navigation-path)
- [Architecture Diagram](#architecture-diagram)
- [What Entro Scans](#what-entro-scans)
- [Supported Authentication](#supported-authentication)
- [Security & Compliance](#security-and-compliance)

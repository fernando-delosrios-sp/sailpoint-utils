Confluence Server - On-premise | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/confluence-server-on-premise.md).

The **Confluence Server (On-Prem)** integration allows Entro Security to automatically detect exposed secrets in your Confluence instance - including page content, comments, and attachments — while ensuring that no raw data ever leaves your environment.
GitBook Assistant
## Overview[#overview](#overview)

Entro connects securely to your on-prem Confluence instance through a **local Worker (connector)**. All API interactions and scans occur locally, and only metadata and findings are sent securely to Entro’s cloud dashboard.
GitBook Assistant

**Architecture Diagram**
GitBook AssistantGitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (Secure connection via On-Prem Worker)
Confluence Server (On-Prem)
```

## What Is Scanned[#what-is-scanned](#what-is-scanned)

Entro Security scans for secrets across the following Confluence components:
GitBook Assistant

- 

**Pages**
GitBook Assistant

- 

Full page body (plain text and wiki storage formats)
GitBook Assistant
- 

Titles and metadata
GitBook Assistant

- 

**Comments**
GitBook Assistant

- 

Page-level and inline comments
GitBook Assistant

- 

**Attachments**
GitBook Assistant

- 

Supported text-based file formats:
GitBook Assistant

- 

`.txt`, `.log`, `.json`, `.yaml`, `.yml`, `.xml`, `.ini`, `.csv`, `.config`, `.properties`
GitBook Assistant

- 

Maximum file size: **10 MB**
GitBook Assistant

- 

**Metadata**
GitBook Assistant

- 

Page ID, space key, creator, and modification timestamps
GitBook Assistant

Detection Engine: Entro uses contextual scanning and entropy-based algorithms to detect API keys, credentials, tokens, and misconfigured secrets.
GitBook Assistant
## What Is Not Scanned[#what-is-not-scanned](#what-is-not-scanned)

For performance and privacy reasons, the following are **excluded** from scanning:
GitBook Assistant

- 

Deleted or archived spaces and pages
GitBook Assistant
- 

Historical page versions (only latest version is scanned)
GitBook Assistant
- 

Encrypted or binary attachments (e.g., `.zip`, `.jpg`, `.pdf`)
GitBook Assistant
- 

Audit logs, templates, or macros
GitBook Assistant
- 

Marketplace app data and third-party plugin storage
GitBook Assistant

These exclusions are intentional to maintain data integrity and minimize API load.
GitBook Assistant
## Installation & Configuration[#installation-and-configuration](#installation-and-configuration)

Follow these steps to connect your Confluence Server to Entro Security.
GitBook Assistant
### Prerequisites[#prerequisites](#prerequisites)

- 

Confluence Server **v7.0 or later**
GitBook Assistant
- 

REST API enabled (`/wiki/rest/api/`)
GitBook Assistant
- 

Access to your **on-prem Worker Group(Connector)**
GitBook Assistant
- 

A **dedicated integration user** with the following permissions:
GitBook Assistant

- 

*View Pages*
GitBook Assistant
- 

*View Comments*
GitBook Assistant
- 

*View Attachments*
GitBook Assistant

- 

A **Personal Access Token (PAT)** generated for the integration user
GitBook Assistant

### Configure the Integration in Entro[#configure-the-integration-in-entro](#configure-the-integration-in-entro)
1
#### **Connect integration**[#connect-integration](#connect-integration)

In Entro Security → Integrations → Atlassian → Confluence Server, click **Connect**.
GitBook Assistant2
#### **Enter configuration details**[#enter-configuration-details](#enter-configuration-details)

Provide the following:
GitBook Assistant

- 

**Base URL:** e.g.,
GitBook Assistant

- 

**Access Token:** The token created for the integration user
GitBook Assistant
- 

**Worker Group(Connector):** Select your on-prem Worker
GitBook Assistant
3
#### **Test and save**[#test-and-save](#test-and-save)

Test the connection and click **Save**.
GitBook Assistant
### Initial Scan[#initial-scan](#initial-scan)

After connecting, initiate your first scan manually or set an automatic schedule.
GitBook Assistant

- 

Scans run through the on-prem Worker using Confluence’s REST API.
GitBook Assistant
- 

Raw data and attachments remain inside your infrastructure.
GitBook Assistant

## System Requirements[#system-requirements](#system-requirements)
ComponentRequirement

**Confluence Version**
GitBook Assistant

7.0+
GitBook Assistant

**API Access**
GitBook Assistant

REST API enabled
GitBook Assistant

**Network**
GitBook Assistant

Outbound HTTPS (443) access from Worker to Entro Security
GitBook Assistant

**Authentication**
GitBook Assistant

Personal Access Token (PAT)
GitBook Assistant

**Permissions**
GitBook Assistant

Read access to spaces, pages, comments, and attachments
GitBook Assistant
## Managing Findings[#managing-findings](#managing-findings)

Once the scan completes, detected secrets appear in the **Findings** dashboard in Entro Security.
GitBook Assistant

Each finding includes:
GitBook Assistant

- 

Page title and space key
GitBook Assistant
- 

Secret type and exposure level
GitBook Assistant
- 

Direct link to the affected Confluence page
GitBook Assistant

You can:
GitBook Assistant

- 

Assign findings to team members
GitBook Assistant
- 

Sync or create Jira tickets for remediation
GitBook Assistant
- 

Mark verified false positives as **Resolved**
GitBook Assistant

## Generic vs Exposed Secrets[#generic-vs-exposed-secrets](#generic-vs-exposed-secrets)
TypeDefinitionExample

**Generic Secret**
GitBook Assistant

Potential secret identified by pattern or entropy.
GitBook Assistant

`abcdef12345`
GitBook Assistant

**Exposed Secret**
GitBook Assistant

Verified credential exposed in accessible content.
GitBook Assistant

`AWS_SECRET_ACCESS_KEY=ABC123...`
GitBook Assistant

Entro differentiates these states to reduce false positives and prioritize actionable findings.
GitBook Assistant
## Data Privacy & Security[#data-privacy-and-security](#data-privacy-and-security)

Entro Security **never stores raw Confluence content**. Only metadata and secret findings are retained for analysis and audit purposes. All communication between your Worker and Entro Cloud is encrypted (HTTPS/TLS).
GitBook Assistant

Compliance Alignment:
GitBook Assistant

- 

SOC 2 Type II
GitBook Assistant
- 

ISO 27001
GitBook Assistant
- 

Principle of least privilege (read-only API access)
GitBook Assistant
[PreviousJira Server - On-premise](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/jira-server-on-premise)[Next[Legacy] Atlassian (Jira & Confluence) - Cloud](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/legacy-atlassian-jira-and-confluence-cloud)

Last updated 4 months ago

- [Overview](#overview)
- [What Is Scanned](#what-is-scanned)
- [What Is Not Scanned](#what-is-not-scanned)
- [Installation & Configuration](#installation-and-configuration)
- [Prerequisites](#prerequisites)
- [Configure the Integration in Entro](#configure-the-integration-in-entro)
- [Initial Scan](#initial-scan)
- [System Requirements](#system-requirements)
- [Managing Findings](#managing-findings)
- [Generic vs Exposed Secrets](#generic-vs-exposed-secrets)
- [Data Privacy & Security](#data-privacy-and-security)
GitBook AssistantAskCopy
```
https://confluence.internal.company.com
```

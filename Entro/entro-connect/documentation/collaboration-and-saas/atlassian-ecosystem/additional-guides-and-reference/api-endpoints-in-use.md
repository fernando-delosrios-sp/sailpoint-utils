API Endpoints in Use | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/api-endpoints-in-use.md).

This page lists the **Atlassian REST API endpoints** Entro Security uses to perform secret scanning and metadata analysis across Jira and Confluence. All API calls are **read-only**, designed to ensure transparency and compliance with customer security policies.
GitBook Assistant
## Overview[#overview](#overview)

Entro Security interacts with Atlassian products using their official REST APIs. All requests are authenticated via:
GitBook Assistant

- 

**Personal Access Tokens (PATs)** for Server / Data Center
GitBook Assistant
- 

**API Tokens** for Atlassian Cloud
GitBook Assistant

Entro **never modifies or deletes** any data and does not perform any administrative or write operations.
GitBook Assistant
## Jira Server / Jira Cloud[#jira-server-jira-cloud](#jira-server-jira-cloud)
PurposeEndpointMethodDescription

List Projects
GitBook Assistant

`/rest/api/2/project`
GitBook Assistant

`GET`
GitBook Assistant

Retrieves accessible Jira projects for the integration user.
GitBook Assistant

Fetch Issues
GitBook Assistant

`/rest/api/2/search`
GitBook Assistant

`POST`
GitBook Assistant

Returns issue data (title, description, comments, attachments).
GitBook Assistant

Issue Comments
GitBook Assistant

`/rest/api/2/issue/{issueId}/comment`
GitBook Assistant

`GET`
GitBook Assistant

Retrieves all comments on a specific issue.
GitBook Assistant

Attachments
GitBook Assistant

`/rest/api/2/attachment/{id}`
GitBook Assistant

`GET`
GitBook Assistant

Fetches attachment metadata and download URL for text-based files.
GitBook Assistant

Users
GitBook Assistant

`/rest/api/2/user`
GitBook Assistant

`GET`
GitBook Assistant

Identifies integration user and permissions context.
GitBook Assistant

Entro scans issue descriptions, comments, and text attachments only (≤10MB).
GitBook Assistant
## Confluence Server / Confluence Cloud[#confluence-server-confluence-cloud](#confluence-server-confluence-cloud)
PurposeEndpointMethodDescription

List Spaces
GitBook Assistant

`/wiki/rest/api/space`
GitBook Assistant

`GET`
GitBook Assistant

Lists available spaces visible to the integration user.
GitBook Assistant

Retrieve Pages
GitBook Assistant

`/wiki/rest/api/content`
GitBook Assistant

`GET`
GitBook Assistant

Retrieves page metadata, content body, and attachments.
GitBook Assistant

Page Comments
GitBook Assistant

`/wiki/rest/api/content/{id}/child/comment`
GitBook Assistant

`GET`
GitBook Assistant

Fetches page comments for secret scanning.
GitBook Assistant

Attachments
GitBook Assistant

`/wiki/rest/api/content/{id}/child/attachment`
GitBook Assistant

`GET`
GitBook Assistant

Retrieves attachment metadata for supported file types.
GitBook Assistant

Entro scans page content, comments, and text-based attachments. Historical page versions and binary files are excluded.
GitBook Assistant

Entro does not modify repositories or push commits. All operations are read-only via HTTPS.
GitBook Assistant
## Rate Limits & Performance[#rate-limits-and-performance](#rate-limits-and-performance)

Entro respects Atlassian’s API rate limits:
GitBook Assistant

- 

Jira Cloud: **1,000 requests per 10 seconds per user**
GitBook Assistant
- 

Confluence Cloud: Standard REST API quotas apply
GitBook Assistant

For on-prem installations, Entro’s Worker automatically optimizes batch size and concurrency to reduce API load.
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

All API calls are **read-only** and made over HTTPS/TLS.
GitBook Assistant
- 

Tokens are scoped to minimal privileges (`read` only).
GitBook Assistant
- 

Entro never stores raw Atlassian content - only metadata and detected findings.
GitBook Assistant
- 

The integration fully aligns with **SOC 2 Type II**, **ISO 27001**, and **GDPR** compliance frameworks.
GitBook Assistant

All tokens and communications use secure practices and minimal privileges to ensure customer data protection.
GitBook Assistant[PreviousClassic Token Creation](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/classic-token-creation)[NextSupported Data Sources](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/supported-data-sources)

Last updated 4 months ago

- [Overview](#overview)
- [Jira Server / Jira Cloud](#jira-server-jira-cloud)
- [Confluence Server / Confluence Cloud](#confluence-server-confluence-cloud)
- [Rate Limits & Performance](#rate-limits-and-performance)
- [Security & Compliance](#security-and-compliance)

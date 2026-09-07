Salesforce | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/salesforce.md).

Entro integrates with Salesforce for Discovery and monitoring of Salesforce Connected Apps and External Client Apps, providing full visibility into their permissions, OAuth scopes, and owners. as well as scanning of service cases for exposed secrets. This integration utilizes the OAuth 2.0 Client Credentials flow via an External Client App to securely access and monitor your Salesforce instance.
GitBook Assistant
#### Purpose[#purpose](#purpose)

- 

Identify and track Salesforce's Non-Human Identities (NHIs) such as Connected Apps and External Client Apps.
GitBook Assistant
- 

Secret Scanning of Service Cases to detect leaked secrets:
GitBook Assistant

- 

Case Details**:** Subject and Description
GitBook Assistant
- 

Comments**:** Internal and external case comments
GitBook Assistant
- 

Attachments**:** Files uploaded to cases
GitBook Assistant
- 

*Email Messages****:**** Bodies of emails associated with cases ****(Coming soon)***
GitBook Assistant

#### Architecture[#architecture](#architecture)

Entro connects directly to the Salesforce REST API over HTTPS.
GitBook AssistantGitBook AssistantAskCopy
```
      +-----------------------------+
      |        Entro Console        |
      |       (Control Plane)       |
      +--------------+--------------+
                     |
                     | API Configuration
                     |
      +--------------v--------------+
      |        Worker Group         |
      |       (Connector)           |
      +--------------+--------------+
                     |
                     | HTTPS (OAuth 2.0)
                     |
      +--------------v--------------+
      |      Salesforce Cloud       |
      |    (Service Cloud API)      |
      +-----------------------------+
```

## Data Access & Security[#data-access-and-security](#data-access-and-security)

- 

All operations are **read-only**.
GitBook Assistant
- 

Authentication via External Client App (OAuth Client Credentials).
GitBook Assistant
- 

All communications over HTTPS/TLS 1.2+.
GitBook Assistant
- 

Secrets encrypted with AES-256 in Entro Worker.
GitBook Assistant
- 

Fully compliant with SOC 2 Type II, ISO 27001, and GDPR.
GitBook Assistant
[PreviousSlack Permissions Reference](/integrations/collaboration-and-saas/slack/slack-permissions-reference)[NextSalesforce Onboarding](/integrations/collaboration-and-saas/salesforce/salesforce-onboarding)

Last updated 4 months ago

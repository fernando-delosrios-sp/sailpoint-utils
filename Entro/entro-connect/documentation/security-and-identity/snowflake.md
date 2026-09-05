Snowflake | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/snowflake.md).

The Snowflake Integration enables Entro Security to collect your Snowflake Non-Human Identities metadata and provide visibility into your Snowflake users, roles, and credentials.
GitBook Assistant

This integration operates in read-only mode to ensure data integrity.
GitBook Assistant
## Purpose[#purpose](#purpose)

The integration connects to your Snowflake account to:
GitBook Assistant

- 

Inventory Snowflake users and classify each identity as a human user or a machine (service) user
GitBook Assistant
- 

Map the roles assigned to each identity and its warehouse-level permissions
GitBook Assistant
- 

Identify the authentication method of each identity (RSA key pair, password with MFA, or password without MFA)
GitBook Assistant
- 

Flag idle identities based on their last successful login
GitBook Assistant

## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
┌───────────────────────────────┐
│       Entro Security Cloud    │
│  (Secrets & NHI Visibility)   │
└──────────────┬────────────────┘
               │  HTTPS (TLS 1.2+)
               ▼  Snowflake REST API (key-pair / JWT auth)
┌───────────────────────────────┐
│         Snowflake Cloud       │
│     (Users, Roles, Grants)    │
└───────────────────────────────┘
```

## Security Model[#security-model](#security-model)

- 

Integration operates in **read-only** mode
GitBook Assistant
- 

Authentication uses a dedicated **Entro Role** and **User** within Snowflake
GitBook Assistant
- 

Authentication is key-pair based (RSA 2048-bit, JWT) - no password is created or stored for the integration user
GitBook Assistant
- 

Identity metadata is collected through the Snowflake REST API (users and grants endpoints); the granted scope is limited to the read-only `MONITOR` privilege and `SELECT` on the `ACCOUNT_USAGE` and `ORGANIZATION_USAGE` views
GitBook Assistant
- 

Tokens and credentials encrypted with **AES-256**
GitBook Assistant
- 

Communication secured with **HTTPS/TLS 1.2+**
GitBook Assistant
[PreviousOkta Troubleshooting & Validation](/integrations/security-and-identity/okta/okta-troubleshooting-and-validation)[NextSnowflake Onboarding](/integrations/security-and-identity/snowflake/snowflake-onboarding)

Last updated 2 months ago

- [Purpose](#purpose)
- [Architecture](#architecture)
- [Security Model](#security-model)

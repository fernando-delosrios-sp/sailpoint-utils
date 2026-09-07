Salesforce Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/salesforce/salesforce-permissions-reference.md).
## Authentication Model[#authentication-model](#authentication-model)

This integration uses the **OAuth 2.0 Client Credentials Flow** via an **External Client App**. It does not require periodic user re-authentication, as it authenticates directly using the App credentials and impersonates the configured "Run As" user.
GitBook Assistant

**Note:** If the "Run As" user loses these permissions or is deactivated, the integration will stop functioning.
GitBook Assistant
## Scope Requirements[#scope-requirements](#scope-requirements)

The App requires the following OAuth scope:
GitBook AssistantScopePermission NameReason

`api`
GitBook Assistant

`**Manage user data via APIs (api)**`
GitBook Assistant

Allows the integration to query standard objects (Cases, EmailMessages) via the REST API.
GitBook Assistant[PreviousSalesforce Troubleshooting And Validation](/integrations/collaboration-and-saas/salesforce/salesforce-troubleshooting-and-validation)[NextActive Directory](/integrations/security-and-identity/active-directory)

Last updated 4 months ago

- [Authentication Model](#authentication-model)
- [Scope Requirements](#scope-requirements)

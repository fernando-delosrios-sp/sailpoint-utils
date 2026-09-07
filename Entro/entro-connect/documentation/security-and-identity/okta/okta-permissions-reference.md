Okta Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/okta/okta-permissions-reference.md).

This section details the API scopes and admin role required for Entro's Okta integration.
GitBook Assistant
## Required API Scopes[#required-api-scopes](#required-api-scopes)
ScopePurpose

`okta.apps.read`
GitBook Assistant

Read application metadata
GitBook Assistant

`okta.appGrants.read`
GitBook Assistant

Read API grant permissions per app
GitBook Assistant

`okta.roles.read`
GitBook Assistant

List role assignments across users and apps
GitBook Assistant

`okta.users.read`
GitBook Assistant

Access user and employee profile data
GitBook Assistant

`okta.logs.read`
GitBook Assistant

Retrieve Okta audit logs
GitBook Assistant

`okta.apiTokens.read`
GitBook Assistant

Access API token metadata
GitBook Assistant
## Required Admin Roles[#required-admin-roles](#required-admin-roles)
RoleVisibility

**Super Administrator**
GitBook Assistant

Full visibility - includes API grant permissions per app
GitBook Assistant

**Custom Entro Role + Report Administrator**
GitBook Assistant

Partial visibility - API grant permissions per app not available
GitBook Assistant

Super Administrator is the only built-in Okta role that can list API grant permissions per app. This is required for complete NHI visibility in Entro. Refer to [Okta's documentation](https://help.okta.com/en-us/content/topics/security/administrators-admin-comparison.htm) for a full comparison of built-in admin roles.
GitBook Assistant
## Authentication Method[#authentication-method](#authentication-method)
PropertyValue

**Auth type**
GitBook Assistant

OAuth 2.0 - Client ID + Public Key pair
GitBook Assistant

**App type**
GitBook Assistant

API Service App
GitBook Assistant

**Key format**
GitBook Assistant

RSA public key (JWK)
GitBook Assistant

**Operations**
GitBook Assistant

Read-only - no write or delete actions performed
GitBook Assistant[PreviousOkta Custom Entro Role](/integrations/security-and-identity/okta/okta-custom-entro-role)[NextOkta Troubleshooting & Validation](/integrations/security-and-identity/okta/okta-troubleshooting-and-validation)

Last updated 2 months ago

- [Required API Scopes](#required-api-scopes)
- [Required Admin Roles](#required-admin-roles)
- [Authentication Method](#authentication-method)

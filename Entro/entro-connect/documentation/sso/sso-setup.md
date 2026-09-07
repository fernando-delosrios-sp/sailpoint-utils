SSO Setup | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-setup.md).
## Purpose[#purpose](#purpose)

Single Sign On (SSO) enables centralized identity and secure user access for Entro tenants. This document covers SAML SSO setup, validation, and troubleshooting. Keep one master page and link to vendor deep-dives for complex IdPs.
GitBook Assistant
## Supported IdP platforms[#supported-idp-platforms](#supported-idp-platforms)

- 

Auth0
GitBook Assistant
- 

Azure Entra ID
GitBook Assistant
- 

Classlink
GitBook Assistant
- 

CyberArk
GitBook Assistant
- 

Descope
GitBook Assistant
- 

Duo
GitBook Assistant
- 

Google Workspace
GitBook Assistant
- 

JumpCloud
GitBook Assistant
- 

Keycloak
GitBook Assistant
- 

LastPass
GitBook Assistant
- 

Microsoft ADFS
GitBook Assistant
- 

miniOrange
GitBook Assistant
- 

Okta
GitBook Assistant
- 

OneLogin
GitBook Assistant
- 

PingFederate / PingOne
GitBook Assistant
- 

Salesforce
GitBook Assistant

## Recommended structure (hybrid approach)[#recommended-structure-hybrid-approach](#recommended-structure-hybrid-approach)

- 

Keep one master SSO page for overview, standard templates, validation, and troubleshooting.
GitBook Assistant
- 

Create separate per-IdP deep-dive pages only for IdPs that require step-by-step vendor-specific commands (e.g., Okta, Azure Entra, OneLogin).
GitBook Assistant
- 

Master page contains quick links to vendor pages and common troubleshooting.
GitBook Assistant

Suggested filenames:
GitBook Assistant

- 

`SSO_Setup.md` (master)
GitBook Assistant
- 

`SSO_Okta.md` (Okta deep-dive)
GitBook Assistant
- 

`SSO_Azure_Entra_ID.md` (Azure Entra deep-dive)
GitBook Assistant
- 

`SSO_OneLogin.md` (OneLogin deep-dive)
GitBook Assistant

## Quick overview of steps[#quick-overview-of-steps](#quick-overview-of-steps)
1

Request SSO support from **Entro Support**.
GitBook Assistant2

Entro Support provides a unique setup link or SP metadata.
GitBook Assistant3

Configure your IdP using Entro-provided metadata.
GitBook Assistant4

Share IdP metadata/certificate and all user domains with Entro Support.
GitBook Assistant5

Entro Support enables SSO for your tenant and confirms activation.
GitBook Assistant6

Test login and confirm user-domain mappings.
GitBook Assistant

Note: SSO is not active for the tenant until Entro completes the step where they add IdP metadata/certificates and enable SSO.
GitBook Assistant
## Entro onboarding form fields (what Support will ask you)[#entro-onboarding-form-fields-what-support-will-ask-you](#entro-onboarding-form-fields-what-support-will-ask-you)

- 

Provider name (e.g., Okta)
GitBook Assistant
- 

IdP metadata URL or XML (or uploaded metadata file)
GitBook Assistant
- 

IdP x.509 certificate (PEM)
GitBook Assistant
- 

Entity ID (IdP)
GitBook Assistant
- 

Allowed user domains (e.g., corp.example.com)
GitBook Assistant
- 

Default relay/ACS URL (provided by Entro Support)
GitBook Assistant
- 

Single Logout URL (optional)
GitBook Assistant
- 

Enforce SSO (yes/no)
GitBook Assistant

## SAML configuration template (IdP-side)[#saml-configuration-template-idp-side](#saml-configuration-template-idp-side)

- 

Entity ID (SP): provided by Entro Support
GitBook Assistant
- 

ACS (Assertion Consumer Service) URL: provided by Entro Support
GitBook Assistant
- 

Single Logout URL: optional
GitBook Assistant
- 

NameID format: `urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress`
GitBook Assistant
- 

Required attributes:
GitBook Assistant

- 

`email` (primary, used for account mapping)
GitBook Assistant
- 

`givenName` or `firstName`
GitBook Assistant
- 

`familyName` or `lastName`
GitBook Assistant
- 

`groups` (optional, for group-based access)
GitBook Assistant

- 

Certificate: x.509 PEM for signing assertions
GitBook Assistant

Tell the IdP team to send either the full metadata XML or the metadata URL.
GitBook Assistant
## ASCII architecture[#ascii-architecture](#ascii-architecture)

## Validation & testing[#validation-and-testing](#validation-and-testing)
1

Entro Support enables SSO for your tenant.
GitBook Assistant2

From a private/incognito browser, open your tenant SSO URL and choose the IdP option.
GitBook Assistant3

Observe IdP login flow and redirection to Entro.
GitBook Assistant4

Entro side checks:
GitBook Assistant

- 

SSO logs show assertion received and mapped email.
GitBook Assistant
- 

`Status: Verified` in onboarding checklist.
GitBook Assistant
5

Use SAML tracer tools to inspect assertion and timestamps.
GitBook Assistant
## Common errors and resolutions[#common-errors-and-resolutions](#common-errors-and-resolutions)

- 

Certificate mismatch / invalid signature: Ensure IdP x.509 cert matches metadata.
GitBook Assistant
- 

Time skew / invalid NotBefore or NotOnOrAfter: Sync clocks via NTP. Tolerance 120s.
GitBook Assistant
- 

NameID or attribute mismatch: Confirm attribute names. Map `email` attribute to primary email.
GitBook Assistant
- 

Domain not allowed: Share all user domains with Entro Support and add to allow-list.
GitBook Assistant
- 

SAML response encrypted but Entro not configured for encryption: Disable encryption or provide SP decryption info.
GitBook Assistant
- 

Logout not working: Confirm Single Logout endpoints and certificates.
GitBook Assistant

## Advanced diagnostics[#advanced-diagnostics](#advanced-diagnostics)

- 

Capture SAML request/response with SAML tracer.
GitBook Assistant
- 

Check IdP audit logs for delivered assertions.
GitBook Assistant
- 

Verify Entro SSO logs show `assertion_id`, `email`, and `status=success`.
GitBook Assistant
- 

If using groups, validate attribute format and mapping.
GitBook Assistant

## Security & compliance notes[#security-and-compliance-notes](#security-and-compliance-notes)

- 

Assertions must be signed.
GitBook Assistant
- 

Transport via TLS only.
GitBook Assistant
- 

Enforce SSO per-tenant only after verification.
GitBook Assistant
- 

Maintain least-privilege access for delegated service accounts.
GitBook Assistant

## Troubleshooting commands/snippets[#troubleshooting-commands-snippets](#troubleshooting-commands-snippets)

Metadata URL example:
GitBook Assistant

Verify metadata contains x.509 cert and ACS endpoints.
GitBook Assistant

Time skew check (example):
GitBook Assistant

(or check NTP service status on IdP host)
GitBook Assistant
## Roles and group mapping[#roles-and-group-mapping](#roles-and-group-mapping)

- 

Example mapping:
GitBook Assistant

- 

IdP group `ent-ops` → Entro role `Admin`
GitBook Assistant
- 

IdP group `ent-dev` → Entro role `Developer`
GitBook Assistant

Send CSV or JSON mapping to Entro Support for bulk mapping.
GitBook Assistant
## Support contact[#support-contact](#support-contact)

- 

`support@entro.security` — include tenant name, IdP metadata, x.509 cert, failing assertion trace, test time and user email.
GitBook Assistant
[PreviousAggregating Entro NHIs & AI Agents in SailPoint ISC](/integrations/security-and-identity/sailpoint-isc/sailpoint-entro-identities-aggregation)[NextSSO Azure Onboarding](/integrations/sso/sso-azure-onboarding)

Last updated 4 months ago

- [Purpose](#purpose)
- [Supported IdP platforms](#supported-idp-platforms)
- [Recommended structure (hybrid approach)](#recommended-structure-hybrid-approach)
- [Quick overview of steps](#quick-overview-of-steps)
- [Entro onboarding form fields (what Support will ask you)](#entro-onboarding-form-fields-what-support-will-ask-you)
- [SAML configuration template (IdP-side)](#saml-configuration-template-idp-side)
- [ASCII architecture](#ascii-architecture)
- [Validation & testing](#validation-and-testing)
- [Common errors and resolutions](#common-errors-and-resolutions)
- [Advanced diagnostics](#advanced-diagnostics)
- [Security & compliance notes](#security-and-compliance-notes)
- [Troubleshooting commands/snippets](#troubleshooting-commands-snippets)
- [Roles and group mapping](#roles-and-group-mapping)
- [Support contact](#support-contact)
GitBook AssistantAskCopy
```
User Browser
    |
    v
IdP (Authn)  <----->  Entro SSO Endpoint (ACS / Metadata)
    |                         |
    v                         v
Entro Platform (User mapping, session issuance, RBAC)
```
GitBook AssistantAskCopy
```
https://<your-idp>/saml/metadata
```
GitBook AssistantAskCopy
```
ntpstat
```

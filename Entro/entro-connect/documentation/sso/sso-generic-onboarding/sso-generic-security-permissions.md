SSO Generic Security Permissions | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-generic-onboarding/sso-generic-security-permissions.md).
## Minimum security[#minimum-security](#minimum-security)

- 

Require signed assertions.
GitBook Assistant
- 

Use TLS for all IdP endpoints.
GitBook Assistant
- 

Keep PEM files and private keys confidential and access-restricted.
GitBook Assistant

## Attribute and group guidance[#attribute-and-group-guidance](#attribute-and-group-guidance)

- 

Use the `email` attribute for user mapping.
GitBook Assistant
- 

For groups, provide a clear claim format (CSV or array).
GitBook Assistant
- 

Provide a group → role mapping file to map IdP groups to application roles.
GitBook Assistant

## Certificate rotation[#certificate-rotation](#certificate-rotation)

- 

Provide the new certificate to the Entro staging endpoint.
GitBook Assistant
- 

Test the new certificate in staging before promoting to production.
GitBook Assistant

## Diagnostics[#diagnostics](#diagnostics)
Diagnostic data to capture and provide[#diagnostic-data-to-capture-and-provide](#diagnostic-data-to-capture-and-provide)

- 

Capture SAML request and response traces using a SAML tracer.
GitBook Assistant
- 

Provide IdP audit logs and assertion samples to Entro Support to assist in troubleshooting.
GitBook Assistant

## Recovery[#recovery](#recovery)

- 

Maintain a backup local admin account to allow access if SSO/IdP becomes unavailable.
GitBook Assistant
[PreviousSSO Generic Onboarding](/integrations/sso/sso-generic-onboarding)[NextSSO Okta Onboarding](/integrations/sso/sso-okta-onboarding)

Last updated 4 months ago

- [Minimum security](#minimum-security)
- [Attribute and group guidance](#attribute-and-group-guidance)
- [Certificate rotation](#certificate-rotation)
- [Diagnostics](#diagnostics)
- [Recovery](#recovery)

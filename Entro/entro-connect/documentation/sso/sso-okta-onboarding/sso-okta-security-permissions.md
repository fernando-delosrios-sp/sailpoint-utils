SSO Okta Security Permissions | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-okta-onboarding/sso-okta-security-permissions.md).
## Minimum security[#minimum-security](#minimum-security)

- 

Enforce signed assertions.
GitBook Assistant
- 

Use TLS 1.2+ on metadata and ACS endpoints.
GitBook Assistant
- 

Limit who can edit app configuration and certificate rotation in Okta.
GitBook Assistant

Keep administrative access and certificate rotation permissions tightly scoped to minimize risk.
GitBook Assistant
## Group mapping and RBAC[#group-mapping-and-rbac](#group-mapping-and-rbac)

- 

Use groups for role assignment only (do not use groups for other application logic).
GitBook Assistant
- 

Maintain a small admin group with tightly controlled membership.
GitBook Assistant
- 

Provide mapping JSON to Entro for role/group mappings.
GitBook Assistant

Ensure the mapping JSON includes the exact group identifiers Entro expects (no additional fields).
GitBook Assistant
## Cert rotation[#cert-rotation](#cert-rotation)
1
#### Upload replacement certificate[#upload-replacement-certificate](#upload-replacement-certificate)

Upload the new certificate into the Okta app configuration before swapping it to avoid downtime.
GitBook Assistant2
#### Validate with test user[#validate-with-test-user](#validate-with-test-user)

Validate the new certificate by signing in with a test user and confirming assertions are accepted.
GitBook Assistant3
#### Coordinate rotation window[#coordinate-rotation-window](#coordinate-rotation-window)

Coordinate the certificate swap window with Entro to ensure both sides switch at the agreed time.
GitBook Assistant
## SCIM / Provisioning notes (if used)[#scim-provisioning-notes-if-used](#scim-provisioning-notes-if-used)

- 

For SCIM, provide the SCIM base URL and SCIM key from Entro.
GitBook Assistant
- 

Ensure the SCIM key has minimal provisioning scopes required for the integration.
GitBook Assistant

Only grant provisioning scopes that are strictly necessary (least privilege).
GitBook Assistant
## Logging and audit[#logging-and-audit](#logging-and-audit)

- 

Check Okta System Logs for SAML transactions and related events.
GitBook Assistant
- 

Entro logs must capture assertion_id and email for correlation and troubleshooting.
GitBook Assistant
Logging details[#logging-details](#logging-details)

- 

Use assertion_id to correlate SAML assertions between Okta and Entro.
GitBook Assistant
- 

Include the user's email in logs for user-level auditing.
GitBook Assistant
- 

Review System Logs around certificate rotation windows to detect failures.
GitBook Assistant
[PreviousSSO Okta Onboarding](/integrations/sso/sso-okta-onboarding)[NextSSO SCIM Onboarding](/integrations/sso/sso-scim-onboarding)

Last updated 4 months ago

- [Minimum security](#minimum-security)
- [Group mapping and RBAC](#group-mapping-and-rbac)
- [Cert rotation](#cert-rotation)
- [SCIM / Provisioning notes (if used)](#scim-provisioning-notes-if-used)
- [Logging and audit](#logging-and-audit)

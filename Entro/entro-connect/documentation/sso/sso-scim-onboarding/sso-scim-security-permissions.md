SSO SCIM Security Permissions | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-scim-onboarding/sso-scim-security-permissions.md).
## Minimum security[#minimum-security](#minimum-security)

- 

SCIM endpoints require TLS 1.2+.
GitBook Assistant

- 

SCIM access key is treated as a secret. Rotate it regularly and store it securely.
GitBook Assistant

## SCIM scopes recommendation[#scim-scopes-recommendation](#scim-scopes-recommendation)

- 

Limit scopes to the minimum required for provisioning:
GitBook Assistant

- 

users:create, users:read, users:update, users:deactivate
GitBook Assistant
- 

groups:read, groups:update (if provisioning groups)
GitBook Assistant

## Rate limits and bulk operations[#rate-limits-and-bulk-operations](#rate-limits-and-bulk-operations)

- 

Use batched pushes when supported by the IdP to avoid throttling.
GitBook Assistant
- 

Monitor Entro SCIM logs for 429 or 5xx responses and act on rate-limit signals.
GitBook Assistant

## Audit and logging[#audit-and-logging](#audit-and-logging)

- 

Log SCIM request IDs and response codes.
GitBook Assistant
- 

Alert on repeated failures or provisioning errors.
GitBook Assistant

## Recovery and rotation[#recovery-and-rotation](#recovery-and-rotation)

- 

Coordinate SCIM key rotation with Entro.
GitBook Assistant

- 

Maintain emergency manual provisioning paths for admins in case automated provisioning is disrupted.
GitBook Assistant
[PreviousSSO SCIM Onboarding](/integrations/sso/sso-scim-onboarding)

Last updated 4 months ago

- [Minimum security](#minimum-security)
- [SCIM scopes recommendation](#scim-scopes-recommendation)
- [Rate limits and bulk operations](#rate-limits-and-bulk-operations)
- [Audit and logging](#audit-and-logging)
- [Recovery and rotation](#recovery-and-rotation)

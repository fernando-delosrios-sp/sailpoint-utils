SSO Azure Security Permissions | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-azure-onboarding/sso-azure-security-permissions.md).
## Minimum security[#minimum-security](#minimum-security)

- 

TLS 1.2+ on all endpoints.
GitBook Assistant
- 

Signed assertions (RSA 2048+).
GitBook Assistant
- 

Store PEM securely. Limit access.
GitBook Assistant

## Role & group mapping[#role-and-group-mapping](#role-and-group-mapping)

- 

Provide group->role CSV or JSON.
GitBook Assistant
- 

Map least-privilege groups to `Admin`, `Developer`, `Viewer`.
GitBook Assistant
- 

Test mapping with non-admin accounts.
GitBook Assistant

## Certificate rotation[#certificate-rotation](#certificate-rotation)
1
#### Generate new certificate on Azure[#generate-new-certificate-on-azure](#generate-new-certificate-on-azure)

Generate the new certificate/keys in Azure.
GitBook Assistant2
#### Upload metadata/PEM to Entro staging[#upload-metadata-pem-to-entro-staging](#upload-metadata-pem-to-entro-staging)

Upload the new metadata and PEM to the Entro staging environment.
GitBook Assistant3
#### Test with a test user[#test-with-a-test-user](#test-with-a-test-user)

Verify authentication and assertions using a test user account.
GitBook Assistant4
#### Schedule cutover and revoke old cert after validation[#schedule-cutover-and-revoke-old-cert-after-validation](#schedule-cutover-and-revoke-old-cert-after-validation)

Perform cutover once validation succeeds, then revoke the old certificate.
GitBook Assistant
## Diagnostics & logs[#diagnostics-and-logs](#diagnostics-and-logs)

- 

Check Azure Sign-in logs and Entro SSO logs.
GitBook Assistant
- 

Capture assertion_id, issuer, email, and timestamps.
GitBook Assistant
Fields to capture[#fields-to-capture](#fields-to-capture)

- 

assertion_id
GitBook Assistant
- 

issuer
GitBook Assistant
- 

email
GitBook Assistant
- 

timestamps
GitBook Assistant

## Recovery[#recovery](#recovery)

- 

Keep an emergency local admin not bound to SSO.
GitBook Assistant
- 

Document rollback steps and test quarterly.
GitBook Assistant
[PreviousSSO Azure Onboarding](/integrations/sso/sso-azure-onboarding)[NextSSO Generic Onboarding](/integrations/sso/sso-generic-onboarding)

Last updated 4 months ago

- [Minimum security](#minimum-security)
- [Role & group mapping](#role-and-group-mapping)
- [Certificate rotation](#certificate-rotation)
- [Diagnostics & logs](#diagnostics-and-logs)
- [Recovery](#recovery)

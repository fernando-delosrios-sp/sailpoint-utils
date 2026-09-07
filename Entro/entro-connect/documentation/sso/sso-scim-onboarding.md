SSO SCIM Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-scim-onboarding.md).
## Purpose[#purpose](#purpose)

SCIM 2.0 provisioning onboarding for Entro.
GitBook Assistant1
#### Decide provisioning mode[#decide-provisioning-mode](#decide-provisioning-mode)

Choose one of the provisioning modes:
GitBook Assistant

- 

JIT (default)
GitBook Assistant
- 

SCIM-only
GitBook Assistant
- 

Hybrid
GitBook Assistant
2
#### Select provider in Entro SCIM wizard[#select-provider-in-entro-scim-wizard](#select-provider-in-entro-scim-wizard)

In the Entro SCIM wizard select your provider or choose "General".
GitBook Assistant3
#### Obtain SCIM base URL[#obtain-scim-base-url](#obtain-scim-base-url)

Entro provides the SCIM base URL in the wizard. If you have a custom domain configured, the URL will use your custom domain.
GitBook Assistant4
#### Generate SCIM access key[#generate-scim-access-key](#generate-scim-access-key)

Generate the SCIM access key in the wizard.
GitBook Assistant5
#### Configure IdP with SCIM details[#configure-idp-with-scim-details](#configure-idp-with-scim-details)

Paste the Entro SCIM base URL and the generated access key into your IdP's SCIM configuration.
GitBook Assistant6
#### Map user attributes[#map-user-attributes](#map-user-attributes)

Map the following attributes between your IdP and Entro:
GitBook Assistant

- 

`userName` -> `email`
GitBook Assistant
- 

`displayName` -> `givenName` + `familyName`
GitBook Assistant
- 

`groups` -> group membership
GitBook Assistant
7
#### Configure provisioning actions[#configure-provisioning-actions](#configure-provisioning-actions)

Configure the provisioning actions you want to enable:
GitBook Assistant

- 

create
GitBook Assistant
- 

update
GitBook Assistant
- 

deactivate
GitBook Assistant
8
#### Test provisioning[#test-provisioning](#test-provisioning)

Run a test push for a test user and confirm the user appears in Entro.
GitBook Assistant
## What to send to Entro[#what-to-send-to-entro](#what-to-send-to-entro)

- 

Confirmation of provisioning mode
GitBook Assistant
- 

Attribute mapping
GitBook Assistant
- 

Test user and timestamp
GitBook Assistant
[PreviousSSO Okta Security Permissions](/integrations/sso/sso-okta-onboarding/sso-okta-security-permissions)[NextSSO SCIM Security Permissions](/integrations/sso/sso-scim-onboarding/sso-scim-security-permissions)

Last updated 4 months ago

- [Purpose](#purpose)
- [What to send to Entro](#what-to-send-to-entro)

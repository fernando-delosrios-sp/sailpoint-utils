SSO Okta Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-okta-onboarding.md).
## Purpose[#purpose](#purpose)

Okta SAML 2.0 onboarding steps for Entro.
GitBook Assistant
## Steps[#steps](#steps)
1
#### Request SSO support[#request-sso-support](#request-sso-support)

Request SSO support from Entro Support.
GitBook Assistant2
#### Receive SP metadata[#receive-sp-metadata](#receive-sp-metadata)

Entro returns SP metadata or SP values.
GitBook Assistant3
#### Create SAML app in Okta[#create-saml-app-in-okta](#create-saml-app-in-okta)

Okta Admin → Applications → Create App Integration → SAML 2.0 → Next.
GitBook Assistant4
#### Configure app basics[#configure-app-basics](#configure-app-basics)

Enter App name. Set Single sign-on URL = `SP Reply URL`. Set Audience URI = `SP Entity ID`.
GitBook Assistant5
#### Save and retrieve credentials[#save-and-retrieve-credentials](#save-and-retrieve-credentials)

Save and go to Sign On tab. Copy **Metadata URL** and X.509 cert if needed.
GitBook Assistant6
#### Configure Attribute Statements[#configure-attribute-statements](#configure-attribute-statements)

Configure Attribute Statements:
GitBook Assistant

- 

`email` -> `user.email`
GitBook Assistant
- 

`givenName` -> `user.firstName`
GitBook Assistant
- 

`familyName` -> `user.lastName`
GitBook Assistant
- 

`groups` -> optional
GitBook Assistant
7
#### Assign access[#assign-access](#assign-access)

Assign users or groups via Assignments tab.
GitBook Assistant8
#### Provide info to Entro[#provide-info-to-entro](#provide-info-to-entro)

Provide Metadata URL and cert to Entro. Share allowed domains.
GitBook Assistant9
#### Test login[#test-login](#test-login)

Test login in incognito. Use SAML tracer for assertions.
GitBook Assistant
## What to send to Entro[#what-to-send-to-entro](#what-to-send-to-entro)

- 

Metadata URL or XML
GitBook Assistant
- 

X.509 PEM
GitBook Assistant
- 

ACS URL and Entity ID
GitBook Assistant
- 

Attribute mapping
GitBook Assistant
- 

Test user and time
GitBook Assistant
[PreviousSSO Generic Security Permissions](/integrations/sso/sso-generic-onboarding/sso-generic-security-permissions)[NextSSO Okta Security Permissions](/integrations/sso/sso-okta-onboarding/sso-okta-security-permissions)

Last updated 4 months ago

- [Purpose](#purpose)
- [Steps](#steps)
- [What to send to Entro](#what-to-send-to-entro)

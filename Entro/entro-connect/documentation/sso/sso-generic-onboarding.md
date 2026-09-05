SSO Generic Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-generic-onboarding.md).
## Purpose[#purpose](#purpose)

Generic SAML IdP onboarding for Entro.
GitBook Assistant1
#### Request SSO support[#request-sso-support](#request-sso-support)

Request SSO support from Entro Support.
GitBook Assistant2
#### Receive SP metadata or SP values[#receive-sp-metadata-or-sp-values](#receive-sp-metadata-or-sp-values)

Entro provides SP metadata or SP values.
GitBook Assistant3
#### Provide IdP metadata[#provide-idp-metadata](#provide-idp-metadata)

Option A: Provide IdP Metadata URL to Entro.
GitBook Assistant4
#### Provide manual IdP fields[#provide-manual-idp-fields](#provide-manual-idp-fields)

Option B: Configure manual fields in Entro:
GitBook Assistant

- 

SSO URL (IdP SSO endpoint)
GitBook Assistant
- 

IdP Issuer (Entity ID)
GitBook Assistant
- 

X.509 Certificate (PEM)
GitBook Assistant
5
#### Create SAML app in IdP[#create-saml-app-in-idp](#create-saml-app-in-idp)

Create SAML app in IdP using SP values.
GitBook Assistant6
#### Map attributes[#map-attributes](#map-attributes)

Map attributes:
GitBook Assistant

- 

email → primary identifier
GitBook Assistant
- 

givenName / firstName
GitBook Assistant
- 

familyName / lastName
GitBook Assistant
- 

groups (if available)
GitBook Assistant
7
#### Configure group claim[#configure-group-claim](#configure-group-claim)

Configure group claim format and provide attribute name to Entro.
GitBook Assistant8
#### Assign users/groups[#assign-users-groups](#assign-users-groups)

Assign users or groups in IdP to the SAML app.
GitBook Assistant9
#### Share metadata and allowed domains[#share-metadata-and-allowed-domains](#share-metadata-and-allowed-domains)

Share metadata or manual fields and allowed domains with Entro.
GitBook Assistant10
#### Test and troubleshoot[#test-and-troubleshoot](#test-and-troubleshoot)

Test in an incognito/private window. If login fails, provide a sample SAML assertion to Entro for troubleshooting (include timestamps).
GitBook Assistant
## What to send to Entro[#what-to-send-to-entro](#what-to-send-to-entro)

- 

IdP Metadata URL OR SSO URL + Issuer + X.509 PEM
GitBook Assistant
- 

Allowed domains
GitBook Assistant
- 

Attribute mappings and group claim name
GitBook Assistant
- 

Test user email and timestamp
GitBook Assistant
[PreviousSSO Azure Security Permissions](/integrations/sso/sso-azure-onboarding/sso-azure-security-permissions)[NextSSO Generic Security Permissions](/integrations/sso/sso-generic-onboarding/sso-generic-security-permissions)

Last updated 4 months ago

- [Purpose](#purpose)
- [What to send to Entro](#what-to-send-to-entro)

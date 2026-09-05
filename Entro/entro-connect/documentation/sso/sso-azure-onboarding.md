SSO Azure Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/sso/sso-azure-onboarding.md).
## Purpose[#purpose](#purpose)

Step-by-step Azure Entra ID SAML onboarding for Entro.
GitBook Assistant1
#### Request SSO support[#request-sso-support](#request-sso-support)

Request SSO support from Entro Support. Provide tenant name and allowed domains.
GitBook Assistant2
#### Receive SP metadata[#receive-sp-metadata](#receive-sp-metadata)

Entro returns SP metadata or SP values (Entity ID, ACS, SLO).
GitBook Assistant3
#### Create application in Azure[#create-application-in-azure](#create-application-in-azure)

Microsoft Entra ID → Enterprise applications → New application → Create your own application (Non-gallery).
GitBook Assistant4
#### Configure SAML single sign-on[#configure-saml-single-sign-on](#configure-saml-single-sign-on)

Set up Single sign-on → SAML → Edit.
GitBook Assistant5
#### Add Identifier (Entity ID)[#add-identifier-entity-id](#add-identifier-entity-id)

Add Identifier (Entity ID) = `SP Entity ID` (from Entro).
GitBook Assistant6
#### Add Reply URL (ACS)[#add-reply-url-acs](#add-reply-url-acs)

Add Reply URL (ACS) = `SP Reply URL` (from Entro).
GitBook Assistant7
#### Download certificate[#download-certificate](#download-certificate)

Save and download **Certificate (Base64)** from SAML Certificates.
GitBook Assistant8
#### Provide Azure endpoints to Entro[#provide-azure-endpoints-to-entro](#provide-azure-endpoints-to-entro)

Copy **Login URL** and **Microsoft Entra Identifier** to Entro onboarding form.
GitBook Assistant9
#### Configure Attributes & Claims[#configure-attributes-and-claims](#configure-attributes-and-claims)

Configure Attributes & Claims:
GitBook Assistant

- 

`email` -> `user.mail` or `user.userPrincipalName`
GitBook Assistant
- 

`givenName` -> `givenName`
GitBook Assistant
- 

`familyName` -> `surname`
GitBook Assistant
- 

`groups` -> optional group claim
GitBook Assistant
10
#### Assign users and groups[#assign-users-and-groups](#assign-users-and-groups)

Users and groups → Add user/group → Select → Assign.
GitBook Assistant11
#### Notify Entro Support[#notify-entro-support](#notify-entro-support)

Notify Entro Support and request activation.
GitBook Assistant12
#### Test[#test](#test)

Test in incognito. Capture SAML assertion with tracer if issues.
GitBook Assistant
## What to send to Entro[#what-to-send-to-entro](#what-to-send-to-entro)

- 

Metadata XML or metadata URL
GitBook Assistant
- 

Certificate (Base64) PEM
GitBook Assistant
- 

Login URL
GitBook Assistant
- 

Microsoft Entra Identifier
GitBook Assistant
- 

Allowed domains
GitBook Assistant
- 

Attribute mapping examples
GitBook Assistant
- 

Test user email and time
GitBook Assistant
[PreviousSSO Setup](/integrations/sso/sso-setup)[NextSSO Azure Security Permissions](/integrations/sso/sso-azure-onboarding/sso-azure-security-permissions)

Last updated 4 months ago

- [Purpose](#purpose)
- [What to send to Entro](#what-to-send-to-entro)

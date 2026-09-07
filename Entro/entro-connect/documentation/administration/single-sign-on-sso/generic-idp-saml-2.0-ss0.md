Generic IdP SAML 2.0 (SS0) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/single-sign-on-sso/generic-idp-saml-2.0-ss0.md).
## Service Provider Information[#service-provider-information](#service-provider-information)

Copy the metadata URL to the IdP to retrieve the connection details dynamically:
GitBook Assistant

Or copy the following to the IdP: 
GitBook Assistant
## Identity Provider Information[#identity-provider-information](#identity-provider-information)

Enter the IdP's metadata URL: 
GitBook Assistant

Or enter the following details: 
GitBook Assistant

Either "IdP Metadata URL" or "Single Sign On (SSO) URL", "Identity Provider Issuer", and "X.509 Certificate" are required
GitBook Assistant
## Attribute Mapping[#attribute-mapping](#attribute-mapping)

#### User Attribute Mapping[#user-attribute-mapping](#user-attribute-mapping)

Map attribute names from your IdP to supported user attributes. This will sync on every user authentication. 
GitBook Assistant

**Group Mapping**
GitBook Assistant

Enter the name of the attribute used by your IdP for group associations. We will use it to retrieve group names that can later on be mapped to roles. 
GitBook Assistant
## SSO Domains[#sso-domains](#sso-domains)

Descope will provide you the domains that are used to determine which SSO configuration to load once a user chooses to authenticate using SSO.
GitBook Assistant
## Testing[#testing](#testing)

Once all the details have been completed, test your current SSO configuration to make sure all parts are set properly.
GitBook Assistant[PreviousOkta (SSO)](/administration/single-sign-on-sso/okta-sso)[NextSCIM Configuration (SSO)](/administration/single-sign-on-sso/scim-configuration-sso)

Last updated 11 months ago

- [Service Provider Information](#service-provider-information)
- [Identity Provider Information](#identity-provider-information)
- [Attribute Mapping](#attribute-mapping)
- [SSO Domains](#sso-domains)
- [Testing](#testing)

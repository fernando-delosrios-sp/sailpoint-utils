Okta (SSO) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/single-sign-on-sso/okta-sso.md).
#### User Attribute Mapping[#user-attribute-mapping](#user-attribute-mapping)

Map attribute names from OKTA to supported user attributes. This will sync on every user authentication.
GitBook Assistant
## Group Attribute Mapping[#group-attribute-mapping](#group-attribute-mapping)

You can also add group attribute statements on the same page. 
GitBook Assistant

**Group Mapping**
GitBook Assistant

Enter the name of the attribute used by OKTA for group associations. We will use it to retrieve group names that can later on be mapped to roles.
GitBook Assistant
## Identity Provider Information[#identity-provider-information](#identity-provider-information)

To get the IdP details, Follow those steps:
GitBook Assistant

- 

Click `Next`.
GitBook Assistant
- 

Click `Finish`. 
GitBook Assistant
- 

On the next screen, copy the `Metadata URL` and paste it here:Metadata URL *Metadata URL *
GitBook Assistant

"Metadata URL" is required
GitBook Assistant
## Assign Groups[#assign-groups](#assign-groups)

To give users permission to authenticate via this SAML app, you will need to assign users or groups. Select the `Assignments` tab and assign users or groups: 
GitBook Assistant
## SSO Domains[#sso-domains](#sso-domains)

Descope will provide you the domains that are used to determine which SSO configuration to load once a user chooses to authenticate using SSO.
GitBook Assistant
## Testing[#testing](#testing)

Once all the details have been completed, test your current SSO configuration to make sure all parts are set properly.
GitBook Assistant[PreviousMicrosoft Azure Entra ID (SSO)](/administration/single-sign-on-sso/microsoft-azure-entra-id-sso)[NextGeneric IdP SAML 2.0 (SS0)](/administration/single-sign-on-sso/generic-idp-saml-2.0-ss0)

Last updated 11 months ago

- [Group Attribute Mapping](#group-attribute-mapping)
- [Identity Provider Information](#identity-provider-information)
- [Assign Groups](#assign-groups)
- [SSO Domains](#sso-domains)
- [Testing](#testing)

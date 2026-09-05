Microsoft Azure Entra ID (SSO) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/single-sign-on-sso/microsoft-azure-entra-id-sso.md).

- 

On the left menu, click on `Users and groups`, and then on `Add user/group`. 
GitBook Assistant
- 

In the Users section on the left, click on `None Selected`. On the right side pane, select the users or groups you want to give access to your application. Finish by clicking on `Select` at the bottom. 
GitBook Assistant
- 

Click on `Assign` at the bottom. 
GitBook Assistant

## Identity Provider Information[#identity-provider-information](#identity-provider-information)

In the SAML application properties page, follow these steps:
GitBook Assistant

- 

Select `Single sign-on` from the left side panel and scroll down to section 3: `SAML Certificates`, and Download the `Certificate (Base64)` file. 
GitBook Assistant
- 

Open the file using text editor, copy it's content and paste it to the following field:Certificate (Base64) *Certificate (Base64) *
GitBook Assistant
- 

Scroll down to section 4: `Set up {App Name}`. Copy the `Login URL` and "`Microsoft Entra Identifier` values to the following fields: `Login URL` `Microsoft Entra Identifier `
GitBook Assistant

"Login URL" is required "Microsoft Entra Identifier" is required "Certificate (Base64)" is required
GitBook Assistant
## User Attribute Mapping[#user-attribute-mapping](#user-attribute-mapping)

You can add attributes to the SAML response by clicking the `edit` button on the `Attributes & Claims` tab. The default attributes are shown, select `Add new claim` to add more user attributes. Map the attributes from Entra ID here:
GitBook Assistant
#### User Attribute Mapping[#user-attribute-mapping-1](#user-attribute-mapping-1)

Map attribute names from Azure Entra ID to supported user attributes. This will sync on every user authentication.
GitBook Assistant
## Group Attribute Mapping[#group-attribute-mapping](#group-attribute-mapping)

To add group attribute, follow these steps:
GitBook Assistant

- 

click on `Add a group claim`. 
GitBook Assistant
- 

select which groups associated with the user should be returned in the claim and the source format. 
GitBook Assistant

**Group Mapping**
GitBook Assistant

Enter the name of the attribute used by Azure Entra ID for group associations. We will use it to retrieve group names that can later on be mapped to roles.
GitBook Assistant
## SSO Domains[#sso-domains](#sso-domains)

Descope will provide you the domains that are used to determine which SSO configuration to load once a user chooses to authenticate using SSO.
GitBook Assistant
## Testing[#testing](#testing)

Once all the details have been completed, test your current SSO configuration to make sure all parts are set properly.
GitBook Assistant[PreviousSetting up SAML SSO](/administration/single-sign-on-sso/setting-up-saml-sso)[NextOkta (SSO)](/administration/single-sign-on-sso/okta-sso)

Last updated 11 months ago

- [Identity Provider Information](#identity-provider-information)
- [User Attribute Mapping](#user-attribute-mapping)
- [Group Attribute Mapping](#group-attribute-mapping)
- [SSO Domains](#sso-domains)
- [Testing](#testing)

SCIM Configuration (SSO) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/single-sign-on-sso/scim-configuration-sso.md).

By default, Entro supports Just In Time (JIT) provisioning of administrators of the Entro platform when using Single Sign On (SSO). If desired, Entro also supports [SCIM 2.0 (System for Cross-domain Identity Management)](https://datatracker.ietf.org/doc/html/rfc7644), enabling identity providers (IdPs) such as Okta, Azure, Ping Identity, and others to automatically provision, update, and deprovision users and groups in your Entro portal.
GitBook Assistant

Once SCIM provisioning is configured, updates made in the IdP—such as user creation, profile edits, group assignments, or deactivation—are automatically pushed to your Entro tenant. These updates are applied to user sessions the next time the user logs in or refreshes their session token (JWT).
GitBook Assistant

SCIM enables centralized identity lifecycle management and ensures that Descope remains consistent with your IdP's directory.
GitBook Assistant

You can disable JIT provisioning if you would rather rely on just SCIM for user management. However, you can still use JIT provisioning to create users as they log in simultaneously with SCIM, which can be useful for certain use cases.
GitBook Assistant
### **Identity Provider (IdP) Selection**[#identity-provider-idp-selection](#identity-provider-idp-selection)

Once you have entered the SCIM configuration section, you'll be prompted to select your IdP; note that the list of supported providers can be expanded by selecting `Show More`. You can also generically configure SCIM by selecting the General icon.Note that user/group mapping is taken from the above SSO configuration, and any IdP custom attribute is supported.
GitBook Assistant
### **Configure SAML SCIM Provisioning**[#configure-saml-scim-provisioning](#configure-saml-scim-provisioning)

Once the user has selected a provider, the guide will populate and walk the user through configuring SCIM within the provider application.
GitBook Assistant
### **URL and Access Key Generation**[#url-and-access-key-generation](#url-and-access-key-generation)

While working through the SCIM configuration, you will be given the base URL for provisioning, which, if you have a custom domain configured, this URL will automatically be updated with your custom domain like `auth.example.com`.The configuration wizard will prompt you to generate the key to authenticate the SCIM actions. This will create a formatted access key with the correct permissions.
GitBook Assistant
### **Finishing the SCIM Configuration**[#finishing-the-scim-configuration](#finishing-the-scim-configuration)

Once you have finished configuring SCIM, you can click the finish button, which will return you to the start of the wizard if you need to make any additional changes. 
GitBook Assistant[PreviousGeneric IdP SAML 2.0 (SS0)](/administration/single-sign-on-sso/generic-idp-saml-2.0-ss0)[NextAccounts & Integrations](/administration/management/accounts-and-integrations)

Last updated 10 months ago

- [Identity Provider (IdP) Selection](#identity-provider-idp-selection)
- [Configure SAML SCIM Provisioning](#configure-saml-scim-provisioning)
- [URL and Access Key Generation](#url-and-access-key-generation)
- [Finishing the SCIM Configuration](#finishing-the-scim-configuration)

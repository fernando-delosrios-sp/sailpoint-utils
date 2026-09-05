Active Directory Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/active-directory/active-directory-permissions-reference.md).
## Summary[#summary](#summary)

Entro requires a single read-only LDAP bind account. The account must be able to enumerate users, groups, computers, and basic attributes. No administrative or write privileges are needed.
GitBook Assistant
## Required roles / access[#required-roles-access](#required-roles-access)

- 

Directory read access to:
GitBook Assistant

- 

`CN=Users,DC=<domain>`
GitBook Assistant
- 

`CN=Computers,DC=<domain>`
GitBook Assistant
- 

Any OU structures containing user/group objects
GitBook Assistant

- 

Ability to read these attributes:
GitBook Assistant

- 

`member`, `memberOf`, `sAMAccountName`, `userPrincipalName`, `lastLogon`, `objectSID`, `objectGUID`, `userAccountControl`, `servicePrincipalName`
GitBook Assistant

- 

If searching ACLs, the account must be able to read security descriptor metadata where allowed via LDAP.
GitBook Assistant

## Scopes and purpose[#scopes-and-purpose](#scopes-and-purpose)
Scope namePurpose

`ldap:bind`
GitBook Assistant

Bind to LDAP/LDAPS using service account
GitBook Assistant

`ldap:read:users`
GitBook Assistant

Read user objects and attributes
GitBook Assistant

`ldap:read:groups`
GitBook Assistant

Read group objects and nested membership
GitBook Assistant

`ldap:read:computers`
GitBook Assistant

Read computer accounts and SPNs
GitBook Assistant

`ldap:read:gpo`
GitBook Assistant

Read GPO metadata (if accessible)
GitBook Assistant
## Auth profile / policy mapping[#auth-profile-policy-mapping](#auth-profile-policy-mapping)

- 

LDAP binding uses the service account credentials entered in the integration form.
GitBook Assistant
- 

LDAP bind credentials authorize directory queries from the Worker Group.
GitBook Assistant

Recommended configuration and security notes:
GitBook Assistant

- 

Use TLS 1.2+ for LDAPS.
GitBook Assistant
- 

Entro maintains read-only behavior and logs access.
GitBook Assistant
- 

Ensure the service account follows Least Privilege.
GitBook Assistant
[PreviousActive Directory Troubleshooting And Validation](/integrations/security-and-identity/active-directory/active-directory-troubleshooting-and-validation)[NextCrowdStrike](/integrations/security-and-identity/crowdstrike)

Last updated 4 months ago

- [Summary](#summary)
- [Required roles / access](#required-roles-access)
- [Scopes and purpose](#scopes-and-purpose)
- [Auth profile / policy mapping](#auth-profile-policy-mapping)

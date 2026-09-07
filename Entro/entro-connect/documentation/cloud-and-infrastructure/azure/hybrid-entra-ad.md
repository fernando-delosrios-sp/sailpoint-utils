Hybrid Entra AD | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/hybrid-entra-ad.md).

This section explains how to enable all features for on-premises Active Directory (AD) synchronization with Microsoft Entra ID to extend Entro Security's Non-Human Identity (NHI) monitoring into hybrid environments. This part isn't needed if you've connected Entro natively via LDAP.
GitBook Assistant

To ensure complete visibility, additional LDAP attributes must be synced to Entra ID. These attributes improve Entro's mapping accuracy, classification of service accounts, and overall observability.
GitBook Assistant

Hybrid NHIs will appear within NHI Inventory as Identity Type `Entra Hybrid Service Account`
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

- 

Microsoft Ecosystem / Azure is already integrated on Entro
GitBook Assistant
- 

Microsoft Entra Connect (Azure AD Connect) must already be installed and configured.
GitBook Assistant
- 

Administrative permissions on the Entra Connect server are required.
GitBook Assistant
1
#### Step 1 - Open Azure AD Connect[#step-1-open-azure-a-d-connect](#step-1-open-azure-a-d-connect)

On your **Entra** Connect Sync server:
GitBook Assistant

- 

Launch the Azure AD Connect application. 
GitBook Assistant
- 

Select Customize synchronization options, then click Next. 
GitBook Assistant
2
#### Step 2 - Enable Directory Extension Attribute Sync[#step-2-enable-directory-extension-attribute-sync](#step-2-enable-directory-extension-attribute-sync)

- 

In Optional Features, check `Directory extension attribute sync` (if not already enabled). 
GitBook Assistant
- 

Continue through the wizard until you reach the Directory Extensions page. 
GitBook Assistant
3
#### Step - Select LDAP Attributes[#step-select-ldap-attributes](#step-select-ldap-attributes)

Add the following LDAP attributes under Selected Attributes.
GitBook Assistant

**Mandatory Attributes**
GitBook AssistantAttributeDescription

`sAMAccountName`
GitBook Assistant

Standard AD logon name used for identity mapping
GitBook Assistant

`userPrincipalName`
GitBook Assistant

Primary identity for synchronization
GitBook Assistant

`objectGUID`
GitBook Assistant

Unique identifier for directory objects
GitBook Assistant

`whenCreated`
GitBook Assistant

Used to detect account creation and aging
GitBook Assistant

`userAccountControl`
GitBook Assistant

Helps classify account type and status
GitBook Assistant

**Optional Attributes**
GitBook AssistantAttributeDescription

`description`
GitBook Assistant

Provides context on service account purpose
GitBook Assistant

`managedBy`
GitBook Assistant

Links account ownership
GitBook Assistant

`lastLogonTimestamp`
GitBook Assistant

Helps detect inactive accounts
GitBook Assistant

`memberOf`
GitBook Assistant

Improves visibility into group-based privileges
GitBook Assistant4
#### Step 4 - Complete the Synchronization[#step-4-complete-the-synchronization](#step-4-complete-the-synchronization)

- 

Click Next, then Configure.
GitBook Assistant
- 

Leave "full synchronization checkbox" checked
GitBook Assistant
- 

Wait a few minutes for the new attributes to propagate to your Entra ID tenant.
GitBook Assistant

## Q&A and Additional Notes[#q-and-a-and-additional-notes](#q-and-a-and-additional-notes)
How does Entro classify an AD user as a Non-Human Identity (NHI)?[#how-does-entro-classify-an-a-d-user-as-a-non-human-identity-nhi](#how-does-entro-classify-an-a-d-user-as-a-non-human-identity-nhi)

Entro combines directory attributes and contextual signals (e.g., `userAccountControl`, `lastLogonTimestamp`, `managedBy,Group membership,Description`) to identify programmatic service accounts distinct from human users.
GitBook Assistant

For custom classification or attribute mapping, contact the Entro Security Support Team.
GitBook AssistantWhat are the requirements to enable this feature in Entro?[#what-are-the-requirements-to-enable-this-feature-in-entro](#what-are-the-requirements-to-enable-this-feature-in-entro)

It should be picked up automatically once you integrate Microsoft Ecosystem (Azure).
GitBook AssistantWhat happens if additional LDAP attributes aren't synced?[#what-happens-if-additional-ldap-attributes-arent-synced](#what-happens-if-additional-ldap-attributes-arent-synced)

Without extra LDAP attributes, Entro's hybrid correlation is limited to:
GitBook Assistant

- 

Basic identity enumeration
GitBook Assistant
- 

Standard Entra ID attributes only
GitBook Assistant
- 

Reduced accuracy for service account detection
GitBook Assistant

## Summary[#summary](#summary)

Enabling Directory Extension Attribute Sync allows Entro to:
GitBook Assistant

- 

Classify and map on-prem AD accounts within Entra ID
GitBook Assistant
- 

Detect service account lifecycles, expirations, and privileges
GitBook Assistant
- 

Provide unified hybrid visibility across all Non-Human Identities
GitBook Assistant
[PreviousAzure Manual Onboarding](/integrations/cloud-and-infrastructure/azure/azure-manual-onboarding)[NextAzure Continuous Onboarding](/integrations/cloud-and-infrastructure/azure/azure-continuous-onboarding)

Last updated 2 months ago

- [Prerequisites](#prerequisites)
- [Q&A and Additional Notes](#q-and-a-and-additional-notes)
- [Summary](#summary)

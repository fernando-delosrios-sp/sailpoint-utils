2.18.0 - June 15, 2026 | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/release-notes/2.18.0-june-15-2026.md).
### New Features[#new-features](#new-features)

- 

**Consolidated risk for exposed secrets - **Ability to unify** **all occurrences of the same secret hash under one risk, which gets updated with any new occurrence that gets detected. Learn more [here](https://docs.entro.security/knowledge-base/threats-and-risks/risks/exposed-secrets/consolidated-risk-for-the-same-exposed-secret#optional-applying-to-existing-risks).
GitBook Assistant
- 

**GCP** - Cross-organization project discovery now automatically finds projects across any organization where your service account has access, dramatically expanding visibility beyond single-org boundaries.
GitBook Assistant
- 

**Salesforce** - Complete user inventory and classification signals are now collected via Bulk API 2.0, providing comprehensive visibility into all Salesforce users and their access patterns.
GitBook Assistant
- 

**GCP Service Accounts** - New NHI: Workload Identity Federation (WIF) auth methods for service accounts are now tracked as discrete inventory records, surfacing AWS, GitHub, SAML, and OIDC identities that can impersonate GCP service accounts.
GitBook Assistant
- 

**Okta** - New NHI: Service account users are automatically detected and classified as non-human identities, with dedicated metadata and drawer views for better visibility.
GitBook Assistant
- 

**Okta** - New NHI: Admin API Tokens are now automatically discovered and tracked as non-human identities, providing full visibility into token metadata, permissions, and lifecycle events.
GitBook Assistant
- 

**Export** - CSV export functionality added for employee audit logs with streamlined download workflows.
GitBook Assistant

### Improvements[#improvements](#improvements)

- 

**CrowdStrike** - Enhanced device scanning with cursor caching mechanism and prioritized device owner detection using last login user data.
GitBook Assistant

### Bug Fixes[#bug-fixes](#bug-fixes)

- 

**Okta** - Application token archiving flow fixed to properly disable and archive identity-only tokens when configuration flags are toggled.
GitBook Assistant
- 

**Accounts** - Missing import errors resolved in admin view for proper customer configuration handling.
GitBook Assistant
- 

**AI Lineage - **Visual bug fixes
GitBook Assistant
- 

**Slack** - Improved supported scale for [slack prevention](https://docs.entro.security/administration/settings/slack-configurations#prevention-mode-for-slack-enterprise-grid) capability 
GitBook Assistant
[Next2.17.0 - June 3, 2026](/release-notes/readme)

Last updated 2 months ago

- [New Features](#new-features)
- [Improvements](#improvements)
- [Bug Fixes](#bug-fixes)

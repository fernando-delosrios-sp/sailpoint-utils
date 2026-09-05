Secret Type Control | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/secret-type-control.md).

Configure customized rules for handling secrets **based on their type,** enabling tailored actions such as adjusting severity, modifying exposure status, or disabling scanning. This allows precise control over how different secret types are prioritized and managed across your environment.
GitBook Assistant

Rules can be configured under *"Settings" -> "Secret Type Control" *
GitBook Assistant
#### Available Actions:[#available-actions](#available-actions)

Each rule is applied to all **existing and future findings** of the selected secret type.
GitBook Assistant

- 

**Automatically Promote to Exposed** Add all findings of this secret type to the *Exposed Inventory and raise relevant risks associated.*
GitBook Assistant
- 

**Automatically Demote to Generic Exposed** Downgrade all findings of this secret type to *Generic Exposed Inventory*, and resolve any open risks.
GitBook Assistant
- 

**Automatically Increase Severity Score** Increase the severity score for all findings and risks associated with this secret type.
GitBook Assistant
- 

**Automatically Decrease Severity Score** Decrease the severity score for all findings and risks associated with this secret type.
GitBook Assistant
- 

**Disable Scanning for This Secret Type** Exclude this secret type from scanning. All current findings will be automatically archived and hidden from Inventory and Risks.
GitBook Assistant
[PreviousExclusion Rule](/administration/settings/exclusion-rule)[NextSlack Configurations](/administration/settings/slack-configurations)

Last updated 10 months ago

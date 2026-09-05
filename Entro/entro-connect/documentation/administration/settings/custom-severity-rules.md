Custom Severity Rules | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/custom-severity-rules.md).

**Custom Severity Rules** allows for configuring how severity is assigned to risks based on your organization's internal security policies, Instead of relying solely on Entro’s scoring calculation. 
GitBook Assistant

Each rule applies a final severity level to a detected risk, when all conditions match. This allows flexible, automated control over risk classification across different environments, platforms, and secret types.
GitBook Assistant
### Rule Configuration[#rule-configuration](#rule-configuration)

Each custom severity rule includes:
GitBook Assistant

- 

**Rule Name**: A label to help you identify the rule
GitBook Assistant
- 

**Description(optional)**: Add context, references, or reasoning behind the rule
GitBook Assistant
- 

**Conditions**: A set of filters that determine when the rule should apply (all must match)
GitBook Assistant
- 

**Action**: The severity level to assign (`Critical`, `High`, `Medium`, or `Low`)
GitBook Assistant

Rules only affect **new risks detected** from the time they are created. You can choose to delete rules at any time to stop them from applying going forward.
GitBook Assistant
#### Supported Conditions[#supported-conditions](#supported-conditions)

All conditions use **AND logic** — every condition in the rule must be met for the rule to apply. Each condition supports **multiple values**.
GitBook AssistantConditionDescriptionExample Values

**Secret Type**
GitBook Assistant

The type of secret detected
GitBook Assistant

`GitHub PAT`, `AWS_SECRET_ACCESS_KEY`
GitBook Assistant

**Account**
GitBook Assistant

Specific integrated account
GitBook Assistant

`prod-gitlab`, `corp-slack`
GitBook Assistant

**Account Type**
GitBook Assistant

Platform type where secret was found
GitBook Assistant

`Slack`, `GitHub`, `Google Drive`, `SharePoint`
GitBook Assistant

**Validity Status**
GitBook Assistant

Whether the secret is still active
GitBook Assistant

`Enabled`, `Unsupported`
GitBook Assistant

**Visibility**
GitBook Assistant

Exposure scope of the secret
GitBook Assistant

`Public`, `Private`, `Internal`
GitBook Assistant

**Environment**
GitBook Assistant

Environment type, configured on the account level
GitBook Assistant

`Production`, `Development`
GitBook Assistant

**Tags**
GitBook Assistant

Tags applied to finding level
GitBook Assistant

`customer-data`, `pci`, `gdpr`
GitBook Assistant
#### **Severity Evaluation & Audit Trail**[#severity-evaluation-and-audit-trail](#severity-evaluation-and-audit-trail)

When a new finding is detected:
GitBook Assistant

- 

Entro calculates a baseline severity using its internal scoring model.
GitBook Assistant
- 

Before assigning that score, the system checks for matching custom severity rules.
GitBook Assistant

- 

If an existing rule conditions match risk, **severity will get override to the selected one.**
GitBook Assistant
- 

If more then one rule matches a detected risk, The **highest matching severity** is applied.
GitBook Assistant

- 

If no rules match, the default Entro severity is used.
GitBook Assistant
- 

All rule-based severity changes are logged in the **Changelog **tab of the risk. 
GitBook Assistant

###  [#undefined](#undefined)
[PreviousCustom Detections](/administration/settings/custom-detections)[NextExposed Secrets](/administration/settings/exposed-secrets)

Last updated 7 months ago

- [Rule Configuration](#rule-configuration)
- [#undefined](#undefined)

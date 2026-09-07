Slack Configurations | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/slack-configurations.md).

The Slack Configuration allows organizations to control how Entro monitors Slack for exposed secrets. Teams can fine-tune scan coverage by excluding specific channels from detection, reducing noise from test or low-risk conversations, while ensuring sensitive areas remain protected. For Slack Enterprise Grid customers, Entro also supports Prevention Mode, which enables near real-time detection and automated mitigation of leaked secrets directly within Slack.
GitBook Assistant

#### **Prevention Mode (for Slack Enterprise Grid)**[#prevention-mode-for-slack-enterprise-grid](#prevention-mode-for-slack-enterprise-grid)

Slack Prevention Mode provides automated protection against secret leakage in Slack Enterprise Grid environments. When enabled, Entro continuously monitors recent messages across public and private channels to identify exposed secrets immediately after they are sent. This allows organizations to detect leaked secrets in near real-time, before they spread or are used maliciously.
GitBook Assistant

If a leaked secret is detected, Entro automatically mitigates the exposure by replacing the original message with a redacted version of it, while preserving the original context and masking only the secret itself. 
GitBook Assistant

Every mitigation event is logged in Entro's Prevention Logs for auditing and incident response. These logs include the detected secret type, owner, and exposed location, providing full visibility into prevented leaks across Slack. 
GitBook Assistant

1. 

It is reccomended to use a seperate connector for slack integration when enabling slack prevention, to support real time detection and redaction secrets 
GitBook Assistant
1. 

Secrets are redacted from all user-visible areas in Slack, although Workspace/Org Owners may still access the original content through Slack’s Discovery API—so exposed credentials should still be revoked or rotated.
GitBook Assistant
1. 

Generic secrets types (managed in the 'Generic' inventory) **will not** get mitigated when "Prevention Mode" is enabled
GitBook Assistant

**Targeted Channel Protection**
GitBook Assistant

Prevention Mode can be scoped to specific workspaces or channels instead of being applied globally. When enabling the '**Apply for specific workspace or channel' **toggle, select the relevant workspace, and optionally specify one or more channel IDs (If no channels are specified, Prevention Mode is applied across the entire selected workspace)
GitBook Assistant

Only messages sent in the selected workspace(s) or channel(s) will be monitored and automatically redacted.
GitBook Assistant

This configuration is useful for controlled rollout or focusing protection on high-sensitivity environments.
GitBook Assistant

**Manual Message Redaction**
GitBook Assistant

When enabling Slack Prevention, manual redaction can be triggered for messages sent in public/private channels **from the raised risk view.**
GitBook Assistant

On the risk page, use **Take Action → Redact Secret** to redact the exposed secret in the original Slack message while preserving the surrounding context around it. 
GitBook Assistant

This provides a fast and controlled way remediate exposures exposure, enabling teams to respond to incidents as they arise and reduce the risk of misuse or further spread.
GitBook Assistant
### **Channel Scan Exclusion**[#channel-scan-exclusion](#channel-scan-exclusion)

Channel exclusions define which Slack channels should be ignored by Entro’s secret scanner. Each exclusion rule consists of a **Channel Rule**, a **Matching Type**, and a **Pattern** that determine which channels are exempt from scanning. Rules can be configured using either the **channel name** or the **channel ID**, providing flexibility based on how your Slack workspace is organized.
GitBook Assistant

- 

When using a **Channel Name**, select the **Matching Type** to be used:
GitBook Assistant

- 

**Exact** — Excludes a specific channel that exactly matches the name.
GitBook Assistant
- 

**Starts With** — Excludes all channels whose names begin with the specified prefix.
GitBook Assistant
- 

**Contains** — Excludes any channel name that includes the defined text.
GitBook Assistant

Excluded channels appear in the list below the configuration form, where they can be reviewed or removed at any time.
GitBook Assistant

[PreviousSecret Type Control](/administration/settings/secret-type-control)[NextUser Management](/administration/settings/user-management)

Last updated 5 months ago

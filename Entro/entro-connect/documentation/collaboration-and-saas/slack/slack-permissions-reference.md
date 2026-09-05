Slack Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/slack/slack-permissions-reference.md).
## Private App Scopes[#private-app-scopes](#private-app-scopes)

#### User Token Scopes[#user-token-scopes](#user-token-scopes)
ScopeWhy it’s needed

`channels:read`
GitBook Assistant

List and identify public channels so Entro can determine monitoring coverage and attach correct channel context to findings.
GitBook Assistant

`channels:write`
GitBook Assistant

Perform channel-level actions required during onboarding/enablement flows (where Slack requires a user context).
GitBook Assistant

`channels:history`
GitBook Assistant

Read message history in public channels to detect exposures that already exist and to provide context around findings.
GitBook Assistant

`groups:read`
GitBook Assistant

List and identify private channels (“groups”) for coverage and context.
GitBook Assistant

`groups:write`
GitBook Assistant

Perform private-channel actions required during onboarding/enablement flows (where Slack requires a user context).
GitBook Assistant

`groups:history`
GitBook Assistant

Read message history in private channels to detect exposures and provide context around findings.
GitBook Assistant

`im:write`
GitBook Assistant

Send direct messages to users/security teams for alerts, triage, or remediation guidance.
GitBook Assistant

`im:history`
GitBook Assistant

Read DM history when needed for detection and context (if monitoring is enabled for DMs).
GitBook Assistant

`chat:write`
GitBook Assistant

Send messages as part of alerting/triage flows (general message posting capability).
GitBook Assistant

`team:read`
GitBook Assistant

Read workspace-level metadata (workspace identity/settings) used for tenant mapping, display, and correct workspace attribution.
GitBook Assistant

`files:read`
GitBook Assistant

Read file metadata/content where permitted, so Entro can scan uploaded/shared files for secrets and exposures.
GitBook Assistant

`search:read`
GitBook Assistant

Search Slack content to locate potential exposures and related context more efficiently than iterating everything.
GitBook Assistant
#### Bot Token Scopes[#bot-token-scopes](#bot-token-scopes)
ScopeWhy it’s needed

`app_mentions:read`
GitBook Assistant

Detect when users @mention the Entro bot (e.g., asking for status/help or interacting with findings).
GitBook Assistant

`channels:join`
GitBook Assistant

Allow the bot to join channels automatically so monitoring can work without manual channel-by-channel invites.
GitBook Assistant

`channels:manage`
GitBook Assistant

Perform channel management operations required for scalable monitoring enablement/maintenance.
GitBook Assistant

`channels:read`
GitBook Assistant

Read public channel metadata for monitoring coverage and enrichment context.
GitBook Assistant

`channels:history`
GitBook Assistant

Read public channel message history for detection (historical + ongoing context).
GitBook Assistant

`groups:read`
GitBook Assistant

Read private channel metadata for coverage and enrichment context.
GitBook Assistant

`groups:history`
GitBook Assistant

Read private channel message history for detection (historical + ongoing context).
GitBook Assistant

`im:read`
GitBook Assistant

Read DM metadata for monitoring context (where enabled).
GitBook Assistant

`im:write`
GitBook Assistant

Send DMs for alerts, triage, and remediation guidance.
GitBook Assistant

`im:history`
GitBook Assistant

Read DM message history where needed for detection and investigation context (where enabled).
GitBook Assistant

`mpim:history`
GitBook Assistant

Read multi-person DM history (MPIM) for detection and context where enabled.
GitBook Assistant

`chat:write`
GitBook Assistant

Post alert/triage messages in Slack as the bot (general posting capability).
GitBook Assistant

`chat:write.customize`
GitBook Assistant

Send richly formatted/customized alert messages (e.g., attachments/blocks, names/icons where allowed).
GitBook Assistant

`chat:write.public`
GitBook Assistant

Post messages into channels where the bot is allowed to post publicly (used for channel-based alerting).
GitBook Assistant

`incoming-webhook`
GitBook Assistant

Deliver notifications into specific channels via webhook-based delivery (commonly used for alert routing).
GitBook Assistant

`files:read`
GitBook Assistant

Read file metadata/content where permitted to scan uploads/shares for exposed secrets.
GitBook Assistant

`metadata.message:read`
GitBook Assistant

Read message metadata needed for context/enrichment and efficient processing (e.g., message identifiers/structure needed to correlate events and findings).
GitBook Assistant

`team:read`
GitBook Assistant

Read workspace-level metadata for correct tenant attribution and workspace context.
GitBook Assistant

`users:read`
GitBook Assistant

Enumerate users for enrichment (who posted/shared) and routing findings to the right owners/responders.
GitBook Assistant

`users.profile:read`
GitBook Assistant

Read user profile fields needed to enrich findings and map ownership (display name, profile info, etc.).
GitBook Assistant

`users:read.email`
GitBook Assistant

Map users to verified email identities (useful for identity correlation and routing).
GitBook Assistant

`users:write`
GitBook Assistant

Support user-level updates required by specific workflows (only where Slack requires it for the integration’s operations).
GitBook Assistant

`usergroups:read`
GitBook Assistant

Read user groups for routing/escalation (e.g., send alerts to the right responder groups).
GitBook Assistant

`usergroups:write`
GitBook Assistant

Manage user-group based routing/escalation flows where required (e.g., maintaining responder group mappings).
GitBook Assistant

`conversations.connect:manage`
GitBook Assistant

Enable monitoring in Slack Connect shared channels (cross-organization channels).
GitBook Assistant

`conversations.connect:read`
GitBook Assistant

Read Slack Connect conversation metadata for coverage and context.
GitBook Assistant

`conversations.connect:write`
GitBook Assistant

Post alerts into Slack Connect channels when required.
GitBook Assistant
#### Events subscription (Real time monitoring)[#events-subscription-real-time-monitoring](#events-subscription-real-time-monitoring)
EventPurpose

`channel_created`
GitBook Assistant

Automatically begin monitoring newly created channels.
GitBook Assistant

`file_created`
GitBook Assistant

Detect newly uploaded files for secret scanning.
GitBook Assistant

`file_shared`
GitBook Assistant

Trigger scanning when files are shared in conversations.
GitBook Assistant

`message.channels`
GitBook Assistant

Monitor new messages in public channels for exposed secrets.
GitBook Assistant

`message.groups`
GitBook Assistant

Monitor new messages in private channels for exposed secrets.
GitBook Assistant
## Enterprise Grid Scopes[#enterprise-grid-scopes](#enterprise-grid-scopes)
ScopePurpose

discovery:read
GitBook Assistant

Enumerate Slack users and messages
GitBook Assistant

discovery:write
GitBook Assistant

Write alert triage messages
GitBook Assistant

redacts messages with secrets (used for [Slack Prevention](/administration/settings/slack-configurations#prevention-mode-for-slack-enterprise-grid) capability)
GitBook Assistant

users:read
GitBook Assistant

Read workspace user information
GitBook Assistant[PreviousSlack Troubleshooting And Validation](/integrations/collaboration-and-saas/slack/slack-troubleshooting-and-validation)[NextSalesforce](/integrations/collaboration-and-saas/salesforce)

Last updated 2 months ago

- [Private App Scopes](#private-app-scopes)
- [Enterprise Grid Scopes](#enterprise-grid-scopes)

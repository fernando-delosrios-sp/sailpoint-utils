Slack Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/slack/slack-troubleshooting-and-validation.md).
## Validation After Connection[#validation-after-connection](#validation-after-connection)
1
#### Check Slack integration status[#check-slack-integration-status](#check-slack-integration-status)

In Entro Dashboard, navigate to **Management → Accounts & Integrations → Slack** and ensure the status shows **Verified**.
GitBook Assistant2
#### Confirm alerts are delivered[#confirm-alerts-are-delivered](#confirm-alerts-are-delivered)

Confirm Entro alerts appear in Slack.
GitBook Assistant3
#### Verify bot presence and posting[#verify-bot-presence-and-posting](#verify-bot-presence-and-posting)

Verify the bot is present in the channels and can post alerts.
GitBook Assistant
## Example API Validation[#example-api-validation](#example-api-validation)
auth.test (curl)GitBook AssistantAskCopy
```
curl -H "Authorization: <redacted> https://slack.com/api/auth.test
```

Expected response: Slack workspace and bot user info.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

team_not_authorized
GitBook Assistant

Discovery API not enabled
GitBook Assistant

Contact Slack Support to enable Discovery API
GitBook Assistant

missing_scope
GitBook Assistant

Incorrect manifest or OAuth permissions
GitBook Assistant

Re-create app using manifest
GitBook Assistant

bot not joining private channels
GitBook Assistant

Bot not invited
GitBook Assistant

Run `/invite @EntroSecurity` in channel
GitBook Assistant

connection timeout
GitBook Assistant

Socket Mode disabled
GitBook Assistant

Re-enable Socket Mode in Slack app settings
GitBook Assistant

[PreviousSlack Enterprise App Onboarding](/integrations/collaboration-and-saas/slack/slack-onboarding-1)[NextSlack Permissions Reference](/integrations/collaboration-and-saas/slack/slack-permissions-reference)

Last updated 2 months ago

- [Validation After Connection](#validation-after-connection)
- [Example API Validation](#example-api-validation)
- [Common Issues](#common-issues)

Slack Private App Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/slack/slack-onboarding.md).

Follow **Slack Private App** steps below if your organization uses Standard Slack Workspaces. Using a manifest is the fastest way to create your Slack app, as it pre-configures all the necessary settings, scopes, and event subscriptions automatically.
GitBook Assistant
## Configuration Steps[#configuration-steps](#configuration-steps)

### Part 1: Create Slack Private App[#part-1-create-slack-private-app](#part-1-create-slack-private-app)
1
#### Create a new app[#create-a-new-app](#create-a-new-app)

1. 

As an admin, login to the slack settings console 
GitBook Assistant
1. 

Navigate to [https://api.slack.com/apps](https://api.slack.com/apps) and click **Create New App**.
GitBook Assistant
1. 

In the dialog, choose **From a Manifest**.
GitBook Assistant

1. 

Pick the target workspace and click **Next**.
GitBook Assistant
23
#### Paste the manifest[#paste-the-manifest](#paste-the-manifest)

1. 

Click on the **YAML tab **and** **paste the following manifest:
GitBook Assistant
GitBook AssistantAskCopy
```
{
    "display_information": {
        "name": "Entro Security",
        "description": "Entro, Secret security. Reclaim control over your secrets",
        "background_color": "#0f0635"
    },
    "features": {
        "bot_user": {
            "display_name": "Entro Security",
            "always_online": false
        }
    },
    "oauth_config": {
        "scopes": {
            "user": [
                "channels:history",
                "channels:read",
                "channels:write",
                "chat:write",
                "groups:history",
                "groups:read",
                "im:history",
                "im:write",
                "team:read",
                "users:read",
                "groups:write",
                "search:read",
                "files:read"
            ],
            "bot": [
                "app_mentions:read",
                "channels:history",
                "channels:join",
                "channels:manage",
                "channels:read",
                "chat:write",
                "chat:write.customize",
                "chat:write.public",
                "conversations.connect:manage",
                "conversations.connect:read",
                "conversations.connect:write",
                "files:read",
                "groups:history",
                "groups:read",
                "groups:write",
                "im:history",
                "im:read",
                "im:write",
                "incoming-webhook",
                "metadata.message:read",
                "mpim:history",
                "team:read",
                "usergroups:read",
                "usergroups:write",
                "users.profile:read",
                "users:read",
                "users:read.email",
                "users:write"
            ]
        }
    },
    "settings": {
        "event_subscriptions": {
            "bot_events": [
                "channel_created",
                "file_created",
                "file_shared",
                "message.channels",
                "message.groups"
            ]
        },
        "interactivity": { "is_enabled": true },
        "org_deploy_enabled": false,
        "socket_mode_enabled": true,
        "token_rotation_enabled": false
    }
}
```
45
#### Review and create[#review-and-create](#review-and-create)

1. 

Click **Next**, review the settings, then click **Create**.
GitBook Assistant
1. 

Under **Basic Information → Display Information**, upload Entro icon [512x512.png](https://drive.google.com/file/d/16bECb1zcxE_G-aDn6kCZIXwqEjR74bgX/view?usp=sharing), to be shown in slack interactions with the app. 
GitBook Assistant

### Part 2 - Generate and Collect API Tokens[#part-2-generate-and-collect-api-tokens](#part-2-generate-and-collect-api-tokens)

With the app created, you will need to generate and collect three unique tokens required for the integration to connect to your workspace.
GitBook Assistant1
#### Enable Socket Mode & Get App-Level Token[#enable-socket-mode-and-get-app-level-token](#enable-socket-mode-and-get-app-level-token)

1. 

Navigate to **Basic Information -> App-Level Tokens**
GitBook Assistant
1. 

Click on **Generate Token and Scopes**
GitBook Assistant
1. 

Create a token named `socket‑mode‑token` with scope `connections:write`
GitBook Assistant
1. 

Copy the generated `xapp‑...` token immediately and store it securely.** **
GitBook Assistant
2
#### Install app and copy OAuth tokens[#install-app-and-copy-oauth-tokens](#install-app-and-copy-oauth-tokens)

1. 

Navigate to **Features → OAuth & Permissions**.
GitBook Assistant
1. 

Under **OAuth Tokens**, Click **Install to [Workspace Name]. **
GitBook Assistant
1. 

Follow the prompts to authorize the application for your workspace.
GitBook Assistant

1. 

Choose a channel to be used for webhooks sent by Entro
GitBook Assistant

1. 

After authorization, you will be sent back to the OAuth & Permissions page. Copy and save the following two tokens:
GitBook Assistant

- 

User OAuth Token (starts with `xoxp-`)
GitBook Assistant
- 

Bot User OAuth Token (starts with `xoxb-`)
GitBook Assistant

### Part 3 - Connect Slack to Entro Security[#part-3-connect-slack-to-entro-security](#part-3-connect-slack-to-entro-security)
1
#### Add New Integration[#add-new-integration](#add-new-integration)

1. 

In Entro, go to **Management → Accounts & Integrations → Add New Account → Slack **
GitBook Assistant
1. 

** **Select** Slack Private App**.
GitBook Assistant
1. 

Complete the connection form using the following details:
GitBook Assistant

1. 

**Environment**: Add a name for this account
GitBook Assistant
1. 

**Company Nickname: **Choose a display name to be used in the UI
GitBook Assistant
1. 

**User OAuth Token: **Paste `xoxp‑...` token
GitBook Assistant
1. 

**Bot User OAuth Token: **Paste `xoxb‑...` token
GitBook Assistant
1. 

**App‑Level Token: **Paste `xapp‑...` token
GitBook Assistant
1. 

**Worker Group (Connector): select the connector to be used for this integration**
GitBook Assistant

2
#### Save configuration[#save-configuration](#save-configuration)

Click **Save Configuration** to activate the integration.
GitBook Assistant
## How It Works[#how-it-works](#how-it-works)

- 

Uses Socket Mode for a direct, secure connection — no public webhook.
GitBook Assistant
- 

The bot joins all public channels automatically.
GitBook Assistant
- 

To add it to private channels, run `/invite @YourBotName`.
GitBook Assistant
[PreviousSlack](/integrations/collaboration-and-saas/slack)[NextSlack Enterprise App Onboarding](/integrations/collaboration-and-saas/slack/slack-onboarding-1)

Last updated 2 months ago

- [Configuration Steps](#configuration-steps)
- [Part 1: Create Slack Private App](#part-1-create-slack-private-app)
- [Part 2 - Generate and Collect API Tokens](#part-2-generate-and-collect-api-tokens)
- [Part 3 - Connect Slack to Entro Security](#part-3-connect-slack-to-entro-security)
- [How It Works](#how-it-works)

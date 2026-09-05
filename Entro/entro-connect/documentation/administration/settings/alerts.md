Alerts | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/alerts.md).

The **Alerts** page allows you to define automated alerting rules that notify your team about new risks and exposures. You can customize which alerts are sent, their severity level, and the delivery method (Slack, Webhook, or Email).
GitBook Assistant

### **Creating an Alert Rule**[#creating-an-alert-rule](#creating-an-alert-rule)

Navigate to **Settings > Alerts Configuration** to begin.
GitBook Assistant
#### **Step 1: Configure Conditions**[#step-1-configure-conditions](#step-1-configure-conditions)

In this step, you define the **criteria** that determine when an alert will be triggered. Each condition filters the alerts to ensure only relevant events are sent.
GitBook Assistant

You can add one or more conditions by clicking **“+ Add Condition”** Available condition types include:
GitBook Assistant

1. 

**Severity** Choose which severity levels should trigger the alert (multiple severity levels can be selected).
GitBook Assistant
1. 

**Risk Name** Filter alerts by a specific risk name or keyword pattern. Useful for monitoring particular types of risks across environments.
GitBook Assistant
1. 

**Category** Narrow down alerts by risk category (e.g., “Secret exposed in Github,” “Previously inactive token is active again”).
GitBook Assistant
1. 

**Source** Define the type of source where the risk originated (e.g., GitHub, AWS, Slack).
GitBook Assistant
1. 

**Account** Select the specific integrated accounts to monitor.
GitBook Assistant
1. 

**Secret Type** Limit alerts to a specific secret classification (e.g., *GitHub API token, AWS secret key) *
GitBook Assistant
1. 

**Account Tags** Filter alerts based on predefined account tags, allowing broader control across grouped environments.
GitBook Assistant

> 

Each rule can include multiple conditions. When all defined conditions are met, an alert will be triggered automatically. Once finished, click **Next** to proceed to the action configuration step.
GitBook Assistant
#### **Step 2: Select Action to Take**[#step-2-select-action-to-take](#step-2-select-action-to-take)

In this step, you define **how** and **where** alerts are delivered once the rule conditions are met.
GitBook Assistant

**Available Delivery Methods**
GitBook Assistant

1. 

**Slack** Send alerts directly to your organization’s Slack workspace.
GitBook Assistant

- 

Choose between **Channel** or **Direct Message** delivery.
GitBook Assistant
- 

Specify the workspace and target channel or user.
GitBook Assistant
- 

Optionally include a **custom message** for each alert (e.g., “Check out this critical risk”).
GitBook Assistant

1. 

**Webhook** Send alerts to any external service that supports incoming webhooks.
GitBook Assistant

- 

Provide the **Webhook URL** where notifications should be sent.
GitBook Assistant
- 

Ideal for integrating with ticketing systems, monitoring tools, or custom workflows.
GitBook Assistant

1. 

**Email** Deliver alerts to one or more email recipients.
GitBook Assistant

- 

Enter recipient email address
GitBook Assistant
- 

Emails include key risk details such as severity, account, and description.
GitBook Assistant

**Optional: Send Existing Alerts**
GitBook Assistant

Before saving, you can choose to **send messages about existing risks** that meet the new rule conditions. This ensures teams are immediately aware of any current issues matching the rule.
GitBook Assistant

When all settings are complete, click **Save** to activate the rule.
GitBook Assistant

Click **Save** to activate your new alert rule.
GitBook Assistant

Once the rule is active, whenever all configured conditions are met, the selected delivery method (Slack, Webhook, or Email) will automatically be triggered with a detailed alert.
GitBook Assistant

Each alert includes essential information about the detected risk — such as severity, environment, account, and discovery details — enabling teams to respond quickly and effectively.
GitBook Assistant

[PreviousEncrypting Integration Secrets](/administration/entro-outpost-on-prem/encrypting-integration-secrets)[NextAPI Keys](/administration/settings/api-keys)

Last updated 10 months ago

Webhooks | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/webhooks.md).

Webhook alerting enables integration between Entro and your automation or incident response workflows, ensuring your teams receive real-time notifications whenever a risk is detected. By configuring webhooks, organizations can automatically forward Entro alerts to external systems for faster triage, investigation, or remediation.
GitBook Assistant
### **Adding a New Webhook**[#adding-a-new-webhook](#adding-a-new-webhook)

To create a webhook, provide a **name** (optional) and the **destination URL** that will receive the alert payloads. All configured webhooks will receive notifications for every new risk detected by Entro.
GitBook Assistant
#### **Integration Types**[#integration-types](#integration-types)

Entro supports several webhook configuration options to align with your automation platform:
GitBook Assistant

- 

**Torq Webhook** — Use a dedicated Torq webhook URL for seamless integration with Torq workflows.
GitBook Assistant
- 

**Tines Webhook** — Connect to a Tines webhook using pre-defined header fields for easy setup.
GitBook Assistant
- 

**Custom Webhook** — Integrate with any third-party service by defining your own header fields and endpoint structure.
GitBook Assistant

After configuration, select **Save** to activate the webhook or **Reset** to clear any unsaved fields. You can edit, test, or remove webhooks at any time to keep integrations current and relevant.
GitBook Assistant[PreviousUser Management](/administration/settings/user-management)

Last updated 10 months ago

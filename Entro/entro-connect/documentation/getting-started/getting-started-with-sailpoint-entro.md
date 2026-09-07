Getting Started with SailPoint Entro | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/getting-started/getting-started-with-sailpoint-entro.md).
## Overview[#overview](#overview)

Entro Security helps organizations gain complete visibility and control over their secrets across all environments - cloud, code, and SaaS. This guide explains how to onboard your first accounts, connect integrations, and start scanning for exposed or mismanaged secrets.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

Before you begin:
GitBook Assistant

- 

Ensure you have an active Entro account and dashboard access.
GitBook Assistant
- 

Verify your user role includes **Integration Management** permissions.
GitBook Assistant
- 

Confirm outbound HTTPS access to Entro’s API endpoints (used by connectors).
GitBook Assistant
- 

Have credentials or tokens ready for the platforms you plan to integrate (AWS, Azure, GitHub, Atlassian, etc.).
GitBook Assistant

## Onboarding Your First Integration[#onboarding-your-first-integration](#onboarding-your-first-integration)
1
### Navigate to Integrations[#navigate-to-integrations](#navigate-to-integrations)

From the main dashboard: **Management → Accounts & Integrations → Add New Account (top right)**
GitBook Assistant

Choose your desired platform (for example, **Atlassian**, **AWS**, **Azure**, or **GitHub**).
GitBook Assistant2
### Select Connection Method[#select-connection-method](#select-connection-method)

Depending on the platform, Entro offers two connection options:
GitBook Assistant

- 

**Automatic Setup:** Uses Entro’s connector or provided script (e.g., CloudFormation for AWS). Ideal for streamlined onboarding with minimal manual configuration.
GitBook Assistant
- 

**Manual Setup:** Recommended for environments with strict access controls. Entro provides clear instructions for IAM roles, API tokens, or app registrations.
GitBook Assistant
3
### Assign a Connector[#assign-a-connector](#assign-a-connector)

Select any active **Entro Connector** to manage the integration. Each connector (e.g., *Quiet Koala*, *Shy Tiger*) represents a deployed Entro worker capable of scanning and monitoring accounts. If a connector displays *No Onboarded Accounts*, it can still be used - it simply has no linked integrations yet.
GitBook Assistant4
### Verify and Start Scanning[#verify-and-start-scanning](#verify-and-start-scanning)

Once connected:
GitBook Assistant

- 

The integration will appear under your **Accounts & Integrations** list.
GitBook Assistant
- 

Entro automatically performs an initial discovery scan.
GitBook Assistant
- 

You can view scan results, secrets, and findings in the **Inventory** and **Detections** sections.
GitBook Assistant

## What Happens Next[#what-happens-next](#what-happens-next)

After onboarding, Entro continuously:
GitBook Assistant

- 

Monitors connected environments for new or rotated secrets.
GitBook Assistant
- 

Detects leaked, overexposed, or stale credentials.
GitBook Assistant
- 

Correlates secrets with their owning systems and users.
GitBook Assistant

## Support and Troubleshooting[#support-and-troubleshooting](#support-and-troubleshooting)

If a connector or integration fails to activate:
GitBook Assistant

- 

Check your connector logs under **Management → Connectors**.
GitBook Assistant
- 

Verify network access and API permissions.
GitBook Assistant
- 

Contact Entro Support for assistance through your workspace portal.
GitBook Assistant
[PreviousDeployment](/getting-started/deployment)[NextPrivacy Policy](/legal-and-privacy/privacy-policy)

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Onboarding Your First Integration](#onboarding-your-first-integration)
- [Navigate to Integrations](#navigate-to-integrations)
- [Select Connection Method](#select-connection-method)
- [Assign a Connector](#assign-a-connector)
- [Verify and Start Scanning](#verify-and-start-scanning)
- [What Happens Next](#what-happens-next)
- [Support and Troubleshooting](#support-and-troubleshooting)

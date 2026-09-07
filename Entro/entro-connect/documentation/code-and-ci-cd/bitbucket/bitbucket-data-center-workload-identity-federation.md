Bitbucket Data Center (Workload Identity Federation) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/bitbucket/bitbucket-data-center-workload-identity-federation.md).

The **Bitbucket Data Center (Workload Identity Federation)** integration connects Entro Security to your **on-premises Bitbucket Server or Data Center instance** for continuous secret scanning.
GitBook Assistant

This method uses a **federated authentication token (HTTP Auth token)** instead of an App Password or API token, ensuring secure, scoped, and revocable access for self-hosted Bitbucket environments.
GitBook Assistant
#### Prerequisits[#prerequisits](#prerequisits)

- 

Ensure your Bitbucket Data Center instance is reachable from Entro’s deployed Connector.
GitBook Assistant
- 

Confirm that outbound HTTPS traffic to your Bitbucket domain (e.g., `https://bitbucket.organization.com:7990`) is allowed.
GitBook Assistant
- 

If the instance is behind a firewall, allowlist your Entro Connector IP or internal routing path.
GitBook Assistant

### Configuration Steps[#configuration-steps](#configuration-steps)
1
#### **Generate a Bitbucket HTTP Auth Token**[#generate-a-bitbucket-http-auth-token](#generate-a-bitbucket-http-auth-token)

1. 

Log in to your Bitbucket Data Center as an **admin user**.
GitBook Assistant
1. 

Navigate to **Administration → Access Management → Personal Access Tokens**.
GitBook Assistant
1. 

Click **Create personal access token**.
GitBook Assistant
1. 

Assign the following **read-only scopes**:
GitBook Assistant

**Category**
GitBook Assistant

**Permission**
GitBook Assistant

Projects
GitBook Assistant

Read
GitBook Assistant

Repositories
GitBook Assistant

Read
GitBook Assistant

Pull requests
GitBook Assistant

Read
GitBook Assistant

Webhooks
GitBook Assistant

Read
GitBook Assistant

Users
GitBook Assistant

Read
GitBook Assistant

1. 

Click **Create** and copy the generated token (for example: `BBDC-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`).
GitBook Assistant
1. 

Store it securely - it will be entered in the Entro form.
GitBook Assistant
2
#### Complete Entro onboarding form[#complete-entro-onboarding-form](#complete-entro-onboarding-form)

1. 

In the Entro Platform, go to **Management → Accounts & Integrations → Add new account → BitBucket. **
GitBook Assistant
1. 

Choose** Workload Identity Federation (Bitbucket Data Center)**
GitBook Assistant
1. 

Fill in the connection form with the following fields:
GitBook Assistant

1. 

**Environment Type** - choose the relevant environment for the integrated account.
GitBook Assistant
1. 

**Environment**- the name you wish to give to that specific account.
GitBook Assistant
1. 

**Bitbucket Data Center Server (Hostname / IP) - **for example: `http://bitbucket.organization.com:7990`
GitBook Assistant
1. 

**BitBucket Username** - enter the user email address
GitBook Assistant
1. 

**BitBucket HTTP Auth Token** - enter the token generated in the previous step.
GitBook Assistant
1. 

**Allowed workspaces(optional): if you wish to scan specific workspaces and not the full account**
GitBook Assistant
1. 

**Worker Group **- choose the connector you wish to use for this integration 
GitBook Assistant

3
#### **Verify Integration**[#verify-integration](#verify-integration)

Once connected, Entro will validate your credentials and start the initial repository synchronization.
GitBook Assistant

1. 

Go to **Integrations → Bitbucket** in the Entro Dashboard.
GitBook Assistant
1. 

Confirm that the integration status is **Active**.
GitBook Assistant
1. 

Verify that repositories are listed and scanning is in progress.
GitBook Assistant
1. 

Check the **Last Verified **timestamp.
GitBook Assistant

Your Bitbucket integration is now active.
GitBook Assistant[PreviousBitBucket Cloud Onboarding](/integrations/code-and-ci-cd/bitbucket/bitbucket-onboarding)[NextGitHub](/integrations/code-and-ci-cd/github)

Last updated 2 months ago

BitBucket Cloud Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/bitbucket/bitbucket-onboarding.md).
## Configuration Steps[#configuration-steps](#configuration-steps)
1
#### **Create an API Token**[#create-an-api-token](#create-an-api-token)

1. 

Using BitBucket admin user, got to [Atlassian API Token management](https://id.atlassian.com/manage-profile/security/api-tokens) and click on "Create API token with scopes".
GitBook Assistant
1. 

Give it a name (for example : `Entro Security Integration`) and select an **expiration date**. Click **Next**. 
GitBook Assistant

1. 

Choose the **Bitbucket** application, then click **Next**.
GitBook Assistant

1. 

In the search box, type **read** and enable **all read permissions that are not marked “Classic”** (16 scopes total). 
GitBook Assistant
1. 

Ensure BitBucket is the chosen application and all 15 read permissions are given. 
GitBook Assistant
1. 

Click on Create token. Copy the token immediately and store it securely.
GitBook Assistant
2
#### Complete Entro onboarding form[#complete-entro-onboarding-form](#complete-entro-onboarding-form)

1. 

In the Entro Platform, go to **Management → Accounts & Integrations → Add new account → BitBucket. **Choose** BitBucket Cloud**
GitBook Assistant
1. 

Fill in the connection form with the following fields:
GitBook Assistant

- 

**Environment Type** - choose the relevant environment for the integrated account.
GitBook Assistant
- 

**Environment**- the name you wish to give to that specific account.
GitBook Assistant
- 

**BitBucket Username** - paste the username or email address
GitBook Assistant
- 

**BitBucket API Token** - enter the token generated in the previous step.
GitBook Assistant
- 

**Allowed workspaces(optional): if you wish to scan specific workspaces and not the full account**
GitBook Assistant
- 

**Worker Group **- choose the connector you wish to use for this integration 
GitBook Assistant

1. 

Click on **Create Account**.
GitBook Assistant

3
### ** Verify Integration**[#verify-integration](#verify-integration)

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

Check the** Last Verified ** timestamp.
GitBook Assistant

Your Bitbucket Cloud integration is now active.
GitBook Assistant

[PreviousBitBucket](/integrations/code-and-ci-cd/bitbucket)[NextBitbucket Data Center (Workload Identity Federation)](/integrations/code-and-ci-cd/bitbucket/bitbucket-data-center-workload-identity-federation)

Last updated 2 months ago

- [Configuration Steps](#configuration-steps)
- [Verify Integration](#verify-integration)

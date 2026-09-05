Buildkite Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/buildkite/buildkite-onboarding.md).
## Configuration Steps[#configuration-steps](#configuration-steps)
1
#### Log in to Buildkite[#log-in-to-buildkite](#log-in-to-buildkite)

- 

Click your profile avatar in the top-right corner.
GitBook Assistant
- 

Select **Personal Settings**.
GitBook Assistant

2
#### Create an API Access Token[#create-an-api-access-token](#create-an-api-access-token)

- 

Navigate to **API Access Tokens **and click on **New API Access Token**.
GitBook Assistant

- 

Under **Description** add `Entro Integration`.
GitBook Assistant
- 

Choose the relevant **Organization Access **for token scope.
GitBook Assistant
- 

Choose a** Token Expiry** time, per your organization policy
GitBook Assistant
- 

Under **REST API Scopes** grant the token all **Read permissions**.
GitBook Assistant
- 

Click **Create Token** and copy the generated token immediately. store it securely.
GitBook Assistant

3
#### Complete Entro onboarding form[#complete-entro-onboarding-form](#complete-entro-onboarding-form)

1. 

In the Entro Platform, go to **Management → Accounts & Integrations → Add new account → BuildKite** 
GitBook Assistant
1. 

Fill in the connection form in Entro with the following fields:
GitBook Assistant

1. 

**Environment Nickname: **Enter a descriptive name (e.g., CICD-BUILDKITE)
GitBook Assistant
1. 

**Environment Type: **Select your environment type (e.g., Production)
GitBook Assistant
1. 

**Personal Access Token (PAT): **Paste the token generated in Buildkite
GitBook Assistant
1. 

**Worker Group (Connector): **Choose an Entro Worker
GitBook Assistant

1. 

Click **Confirm** to validate and establish the integration.
GitBook Assistant

[PreviousBuildkite](/integrations/code-and-ci-cd/buildkite)[NextJFrog Artifactory](/integrations/container-registries/jfrog-artifactory)

Last updated 2 months ago

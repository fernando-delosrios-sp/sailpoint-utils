GitHub Cloud Fine-grained Token Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-finegrained-token-onboarding.md).

GitHub onboarding using Fine-Grained Personal Access Tokens (PATs) is supported and recommended for minimal read-only scope usage.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

- 

Organization fine-grained tokens enabled in GitHub - navigate to the personal access token settings under your organization, and make sure the “Allow access via fine-grained personal access tokens” is selected.
GitBook Assistant
- 

Token needs to be created by an **Organization Owner**. 
GitBook Assistant

## Configuration Steps[#configuration-steps](#configuration-steps)
1
#### Navigate to Developer Setting[#navigate-to-developer-setting](#navigate-to-developer-setting)

Navigate to [Profile → Settings → Developer Settings → Personal Access Tokens.](https://github.com/settings/personal-access-tokens/new)
GitBook Assistant

Ensure **Allow access via fine-grained personal access tokens** is enabled.
GitBook Assistant2
#### Create a Fine-grained Token[#create-a-fine-grained-token](#create-a-fine-grained-token)

Genetate a new fine-grained token with following parameters:
GitBook Assistant

- 

**Token name: **Entro
GitBook Assistant
- 

**Resource owner:** Select your organization
GitBook Assistant
- 

**Expiration**: choose 'No expiration'
GitBook Assistant
3
### Select Permissions[#select-permissions](#select-permissions)

1. 

Under **Repository access:** select **All repositories**
GitBook Assistant
1. 

Under** Permissions:**
GitBook Assistant

1. 

**For Repositories**, Click "+ Add permissions" and select **Read-only** for all items listed below
GitBook Assistant

- 

Actions
GitBook Assistant
- 

Administration
GitBook Assistant
- 

Commit statuses
GitBook Assistant
- 

Contents
GitBook Assistant
- 

Dependabot secrets
GitBook Assistant
- 

Environments
GitBook Assistant
- 

Metadata
GitBook Assistant
- 

Pull requests
GitBook Assistant
- 

Secrets
GitBook Assistant
- 

Variables
GitBook Assistant

1. 

**For Organizations**, Click "+ Add permissions" and select **Read-only** for all items listed below
GitBook Assistant

- 

Administration 
GitBook Assistant
- 

Custom repository roles 
GitBook Assistant
- 

Members 
GitBook Assistant
- 

Organization codespaces secrets 
GitBook Assistant
- 

Organization codespaces settings 
GitBook Assistant
- 

Organization dependabot secrets 
GitBook Assistant
- 

Projects 
GitBook Assistant
- 

Secrets 
GitBook Assistant
- 

Variables 
GitBook Assistant

4
### Generate Token[#generate-token](#generate-token)

Click **Generate token** and copy the value starting with `ghp_`.
GitBook Assistant5
### Complete Entro onboarding form[#complete-entro-onboarding-form](#complete-entro-onboarding-form)

1. 

In the Entro Platform, go to **Management → Accounts & Integrations → Add new account → GitHub** and select **GitHub Cloud - Legacy**.
GitBook Assistant
1. 

Fill out the onboarding form in Entro:
GitBook Assistant

- 

**Display name:**Choose or create a name for this organization.
GitBook Assistant
- 

**Company Nickname**: Choose or create a name for this organization.
GitBook Assistant
- 

**Github access token**: Paste the token generated previously
GitBook Assistant
- 

**Worker Group (Connector)**: Select your designated connector agent.
GitBook Assistant

[PreviousGitHub Cloud Enterprise S3 Logs Streaming](/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-enterprise-s3-logs-streaming)[NextGitHub Cloud Classic Token Onboarding - Legacy](/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-classic-token-onboarding)

Last updated 2 months ago

- [Prerequisites](#prerequisites)
- [Configuration Steps](#configuration-steps)
- [Select Permissions](#select-permissions)
- [Generate Token](#generate-token)
- [Complete Entro onboarding form](#complete-entro-onboarding-form)

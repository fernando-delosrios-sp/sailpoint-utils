GitHub Enterprise Server Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-classic-token-onboarding-1.md).

Integrate your GitHub On premises organization with Entro's System
GitBook Assistant
#### Prerequisits[#dependencies](#dependencies)

- 

Browser logged into a GitHub session with Administrator permissions over the GitHub organization
GitBook Assistant
- 

Onboarding process must be done for each GitHub organization seperatly.
GitBook Assistant

## Configuration Steps[#configuration-steps](#configuration-steps)
1
### Navigate to Developer Setting[#navigate-to-developer-setting](#navigate-to-developer-setting)

1. 

Navigate to [Profile → Settings → Developer Settings → Personal Access Tokens.](https://github.com/settings/personal-access-tokens/new)
GitBook Assistant
1. 

Click on "Generate new token" and choose **classic** token 
GitBook Assistant
2
### Create a Classic Token[#create-a-classic-token](#create-a-classic-token)

with following parameters:
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
- 

**Permissions:** Select following permissions 
GitBook Assistant

- 

repo
GitBook Assistant
- 

read:packages
GitBook Assistant
- 

read:org
GitBook Assistant
- 

read:public_key
GitBook Assistant
- 

read:repo_hook
GitBook Assistant
- 

notifications
GitBook Assistant
- 

user
GitBook Assistant
- 

read:discussion
GitBook Assistant
- 

read:enterprise
GitBook Assistant
- 

read:audit_log
GitBook Assistant
- 

read:project
GitBook Assistant
- 

read:gpg_key
GitBook Assistant
- 

read:ssh_signing_key
GitBook Assistant

3
### Generate Token[#generate-token](#generate-token)

Click **Generate token** and copy the value starting with `ghp_`.
GitBook Assistant4
### Complete Entro onboarding form[#complete-entro-onboarding-form](#complete-entro-onboarding-form)

1. 

In the Entro Platform, go to **Management → Accounts & Integrations → Add new account → GitHub** and select **GitHub Enterprise Server** .
GitBook Assistant
1. 

Fill out the onboarding form in Entro:
GitBook Assistant

- 

**Display name: **Create a name for this organization.
GitBook Assistant
- 

**Environment Type: Select **Production / Development etc.
GitBook Assistant
- 

**Github server hostname**: add your server
GitBook Assistant
- 

**Github access token**: Paste the token generated previously
GitBook Assistant
- 

**Worker Group (Connector)**: Select your designated connector agent.
GitBook Assistant

[PreviousGitHub Cloud Classic Token Onboarding - Legacy](/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-classic-token-onboarding)[NextGitHub Real-Time Scanning](/integrations/code-and-ci-cd/github/github-real-time-scanning)

Last updated 2 months ago

- [Configuration Steps](#configuration-steps)
- [Navigate to Developer Setting](#navigate-to-developer-setting)
- [Create a Classic Token](#create-a-classic-token)
- [Generate Token](#generate-token)
- [Complete Entro onboarding form](#complete-entro-onboarding-form)

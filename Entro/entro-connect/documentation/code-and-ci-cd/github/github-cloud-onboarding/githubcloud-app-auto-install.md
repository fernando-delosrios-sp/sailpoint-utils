GitHubCloud App Install | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/github/github-cloud-onboarding/githubcloud-app-auto-install.md).
### Prerequisites[#prerequisites](#prerequisites)

- 

GitHub account with admin access
GitBook Assistant
- 

Entro Security credentials (Admin / Integrator role)
GitBook Assistant

## Installation[#installation](#installation)
1
#### Unpack and install[#unpack-and-install](#unpack-and-install)

Run the following commands to unzip the package, install dependencies and install Playwright browsers:
GitBook AssistantGitBook AssistantAskCopy
```
unzip onboard-script.zip
cd onboard-script
npm i
npx playwright install
```
2
#### Configure environment[#configure-environment](#configure-environment)

Create and edit the environment file:
GitBook AssistantGitBook AssistantAskCopy
```
touch .env
vi .env
```

Populate the file as shown in the `.env Configuration` section below.
GitBook Assistant3
#### Run the onboarding script[#run-the-onboarding-script](#run-the-onboarding-script)
GitBook AssistantAskCopy
```
npm run onboard-github
```

## .env Configuration[#env-configuration](#env-configuration)
GitBook AssistantAskCopy
```
# Github
GITHUB_ORG_ACCESS_TOKEN=ghp_....
GITHUB_USERNAME=<Your Github Username>
GITHUB_PASSWORD=<Your Github Password>
GITHUB_TOTP_SETUP_KEY=<Github TOTP Key>

# Entro
ENTRO_PREFIX_DOMAIN= #(e.g app for app.entro.security)
ENTRO_USERNAME=<Your Entro Username>
ENTRO_PASSWORD=<Your Entro Password>
ENTRO_REMOTE_AGENT_UUID=<Available in the UI>
```

Inspect the script before use. It automates browser and API operations — review the code and environment variables to ensure they meet your security policies and expectations.
GitBook Assistant
## Running the Automation[#running-the-automation](#running-the-automation)

Last updated 2 months ago

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [.env Configuration](#env-configuration)
- [Running the Automation](#running-the-automation)
GitBook AssistantAskCopy
```
npm run onboard-github
```

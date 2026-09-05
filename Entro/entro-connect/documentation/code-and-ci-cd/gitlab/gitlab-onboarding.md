GitLab Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/gitlab/gitlab-onboarding.md).
## Configuration Steps[#configuration-steps](#configuration-steps)
1
#### Option 1: Generate a Group Access Token (Preferred)[#option-1-generate-a-group-access-token-preferred](#option-1-generate-a-group-access-token-preferred)

1. 

Log in to your organization's Gitlab console as an administrator.
GitBook Assistant
1. 

Navigate to **Groups → [Select Group] → Settings → Access Tokens**. 
GitBook Assistant

In case Group Access Tokens aren't enabled, try to enable them from the "Group settings" -> Permissions and group features -> Allow group and project access tokens This setting is available in Gitlab self-managed instances, or Ultimate / Premium tiers in Gitlab.com. Use the PAT Onboarding as an alternative if Group Access Tokens are unavailable.
GitBook Assistant

1. 

Click **Add new token**. Configure:
GitBook Assistant

1. 

**Token name:** `entro_svc` (optional)
GitBook Assistant
1. 

**Role:** `owner`
GitBook Assistant
1. 

**Rotation date:** per your internal policy
GitBook Assistant
1. 

**Selected Scopes:** `read_api, read_user, read_repository` 
GitBook Assistant
1. 

Click **Create token**.
GitBook Assistant

1. 

Copy the token immediately and store it securely. 
GitBook Assistant
2
#### Option 2: Generate a Personal Access Token [#option-2-generate-a-personal-access-token](#option-2-generate-a-personal-access-token)

1. 

In GitLab, open your **User Profile → Access Tokens**. 
GitBook Assistant
1. 

Click **Add new token**. Configure:
GitBook Assistant

1. 

**Token name:** `entro_pat` (optional)
GitBook Assistant
1. 

**Expiration date:** per your internal policy
GitBook Assistant
1. 

**Scopes:** Select: All `read` scopes as-well as the `api` scope
GitBook Assistant

1. 

Click **Create token**.
GitBook Assistant
1. 

Copy the generated token and store it securely.
GitBook Assistant
1. 

Navigate to **User Settings → Account** and copy your **username**.  
GitBook Assistant
3
#### Complete Entro onboarding form[#complete-entro-onboarding-form](#complete-entro-onboarding-form)

1. 

In the Entro Platform, go to **Management → Accounts & Integrations → Add new account → GitLab** 
GitBook Assistant
1. 

Fill in the connection form in Entro with the following fields:
GitBook Assistant

- 

**Nickname: **any nickname to tag your Gitlab environment
GitBook Assistant
- 

**Destination server:**
GitBook Assistant

1. 

For Gitlab cloud, enter this server name: `https://gitlab.com`
GitBook Assistant
1. 

For on-premise server, the input is the target IP or Hostname of your self-hosted Gitlab server: `https://my-gitlab-srv.acme.com`
GitBook Assistant

- 

**Port:**
GitBook Assistant

1. 

For Gitlab cloud: `443`
GitBook Assistant
1. 

For on-premise server, the port of your Gitlab server.
GitBook Assistant

- 

**User:** the username copied during step 7
GitBook Assistant
- 

**GitLab personal access token: **the token copied dfrom step above
GitBook Assistant
- 

**Worker Group:** Select a connector agent in the dropdown menu
GitBook Assistant
- 

**Self managed:** tick this box in case this is a self-managed private Gitlab server that can't be accessed directly from the internet.
GitBook Assistant

1. 

Click **Connect**. Entro validates the credentials and establishes a secure connection. When complete, status displays **Verified**.
GitBook Assistant

[PreviousGitLab](/integrations/code-and-ci-cd/gitlab)[NextGitLab Troubleshooting And Validation](/integrations/code-and-ci-cd/gitlab/gitlab-troubleshooting-and-validation)

Last updated 2 months ago

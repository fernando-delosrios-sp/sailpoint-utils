GitHub Real-Time Scanning | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/github/github-real-time-scanning.md).

Entro's GitHub real-time scanning monitors every push to your repositories the moment it happens. When a commit is pushed to the repository, Entro triggers a scan instantly via a GitHub webhook and and detects any leaked secrets before the exposure window widens.
GitBook Assistant

This integration complements Entro's historical scanning (which scans your full commit history) by ensuring new secrets are caught near real time
GitBook Assistant
### How It Works[#how-it-works](#how-it-works)

1. 

Through Entro API, generate a unique webhook endpoint and authorization secret for your account.
GitBook Assistant
1. 

Register that webhook in GitHub at either the **repository** or **organization** level.
GitBook Assistant
1. 

On every `push` event, GitHub sends the commit payload to Entro.
GitBook Assistant
1. 

Entro scans the diff for secrets and surfaces any findings in the dashboard in real time.
GitBook Assistant

### Setup[#setup](#setup)

#### Step 1: Generate your webhook credentials in Entro[#step-1-generate-your-webhook-credentials-in-entro](#step-1-generate-your-webhook-credentials-in-entro)

1. 

use following API to generate the webhook. (fill in an active, full access Entro API key)
GitBook Assistant
GitBook AssistantAskCopy
```
curl -X 'POST' \
  'https://{provider-}api.entro.security/v1/entroKeys/github/webhook' \
  -H 'accept: application/json' \
  -H 'Authorization: ENTRO_API_KEY' \
  -d ''
```

1. 

Copy the two values from the response:
GitBook Assistant

- 

**Payload URL** — the Entro endpoint that will receive GitHub events
GitBook Assistant
- 

**Secret** — the authorization token used to validate requests
GitBook Assistant

**Note**: this can also be done through [Entro's API docs](https://apidocs.entro.security/?endpoint=https://api.entro.security)using an active API token. just log in using an active API token, and navigate to **/v1/entroKeys/{provider}/webhook. **
GitBook Assistant

More info on Entro API can be found here - [https://docs.entro.security/api-reference](https://docs.entro.security/api-reference)
GitBook Assistant
#### Step 2: Configure the webhook in GitHub[#step-2-configure-the-webhook-in-github](#step-2-configure-the-webhook-in-github)

1. 

You can create the webhook at the **repository level** (monitors one repo) or at the **organization level** (monitors all repos in the org). The steps are the same for both.
GitBook Assistant

- 

**Repository-level:** Go to your repository → **Settings → Webhooks → Add webhook**
GitBook Assistant
- 

**Organization-level:** Go to your organization → **Settings → Webhooks → Add webhook**
GitBook Assistant

1. 

**fill in the webhook form**:
GitBook Assistant
FieldValue

**Payload URL**
GitBook Assistant

Paste the Payload URL from Entro
GitBook Assistant

**Content type**
GitBook Assistant

`application/json` 
GitBook Assistant

**Secret**
GitBook Assistant

Paste the Secret from Entro
GitBook Assistant

**Which events would you like to trigger this webhook?**
GitBook Assistant

select **Just the **`**push**`** event**
GitBook Assistant

**Active**
GitBook Assistant

Checked
GitBook Assistant

1. 

Click **Add webhook** to save
GitBook Assistant

### Verifying the Integration[#verifying-the-integration](#verifying-the-integration)

After saving, GitHub sends a ping event to verify the endpoint is reachable. You can confirm the webhook is working from the **Recent Deliveries** tab on the webhook settings page in GitHub. a green checkmark indicates a successful delivery.
GitBook Assistant

Once a push is made to a monitored repository, Entro will scan the changed files in that commit. Any detected secrets will appear in the **Secrets inventory **and exposed secret** risks **will be generated.
GitBook Assistant
### Troubleshooting[#troubleshooting](#troubleshooting)

1. 

**Webhook returns 400 Bad Request: **The most common cause is the wrong Content type. Ensure it is set to `application/json` in GitHub's webhook settings.
GitBook Assistant
1. 

**No findings appear after a push** Check the following:
GitBook Assistant

- 

Confirm the webhook delivered successfully in GitHub (Settings → Webhooks → Recent Deliveries).
GitBook Assistant
- 

Make sure the repository is not excluded by any exclusion rules configured in Entro.
GitBook Assistant
- 

Note that Entro deduplicates commits — if the same commit SHA was already processed within the past month, it will not be re-scanned. This can happen if you trigger a redelivery for a commit that was already scanned successfully.
GitBook Assistant

1. 

**Push event is not triggering a scan:** Ensure the webhook is set to listen to `push` events. In GitHub's webhook settings, under **Which events would you like to trigger this webhook?**, select **Just the push event** or a custom set that includes `push`.
GitBook Assistant

### Scope and Coverage[#scope-and-coverage](#scope-and-coverage)
ScopeSetup location

Single repository
GitBook Assistant

Repository → Settings → Webhooks
GitBook Assistant

All repositories in an org
GitBook Assistant

Organization → Settings → Webhooks
GitBook Assistant
> 

Organization-level webhooks apply to all current and future repositories in the organization and are the recommended approach for broad coverage.
GitBook Assistant[PreviousGitHub Enterprise Server Onboarding](/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-classic-token-onboarding-1)[NextGitHub Cloud Troubleshooting And Validation](/integrations/code-and-ci-cd/github/github-cloud-troubleshooting-and-validation)

Last updated 2 months ago

- [How It Works](#how-it-works)
- [Setup](#setup)
- [Verifying the Integration](#verifying-the-integration)
- [Troubleshooting](#troubleshooting)
- [Scope and Coverage](#scope-and-coverage)
GitBook AssistantAskCopy
```
{
  "webhook": "https://app.entro.security/api/entroApi/webhooks/github/12345678-1234-1234-1234-123456789123",
  "Authorization": "ent_**************************************************"
}
```

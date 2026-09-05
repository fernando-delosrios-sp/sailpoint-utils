Open AI Agent Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/open-ai-agent-onboarding.md).
## Step 1: Create an Admin Key[#step-1-create-an-admin-key](#step-1-create-an-admin-key)

1. 

Go to [platform.openai.com](https://platform.openai.com/)
GitBook Assistant
1. 

Sign in as an **Org Owner** or **Admin**
GitBook Assistant
1. 

Navigate to **Settings → Organization → Admin API keys**
GitBook Assistant
1. 

Click **Create new admin key**
GitBook Assistant
1. 

Name it (e.g. "Entro Security Integration")
GitBook Assistant
1. 

Copy the key - it starts with `sk-admin-`
GitBook Assistant

Only Org Owners and Admins can create admin keys. If you don't see the option, ask your org owner.
GitBook Assistant
## Step 2: Enter your Admin key in the Entro Onboarding form[#step-2-enter-your-admin-key-in-the-entro-onboarding-form](#step-2-enter-your-admin-key-in-the-entro-onboarding-form)

## What Happens Next[#what-happens-next](#what-happens-next)

Once we receive the key, our platform automatically:
GitBook Assistant1

**Discovers your org**
GitBook Assistant

- 

users, roles, pending invites
GitBook Assistant
2

**Enumerates all projects**
GitBook Assistant

- 

active and archived
GitBook Assistant
3

**For each project, collects:**
GitBook Assistant

- 

Project members and their roles
GitBook Assistant
- 

API keys and their owners (human or service account)
GitBook Assistant
- 

Service accounts
GitBook Assistant
4

**Creates a temporary read-only service account per project to access:**
GitBook Assistant

- 

Assistants (AI agents) - name, tools, instructions, model
GitBook Assistant
- 

Files and vector stores (knowledge bases)
GitBook Assistant
5

**Pulls usage data**
GitBook Assistant

- 

completions, embeddings, images, audio
GitBook Assistant
6

**Pulls audit logs**
GitBook Assistant

- 

activity events (requires Org Owner + Data Controls enabled)
GitBook Assistant
7

**Builds the agent inventory**
GitBook Assistant

- 

stitches everything into identity graphs with risk scoring
GitBook Assistant

No manual configuration. No webhooks. No additional keys needed.
GitBook Assistant
## Permissions Required[#permissions-required](#permissions-required)

The admin key needs these scopes (granted by default to admin keys):
GitBook Assistant

- 

`organization.read`
GitBook Assistant
- 

`organization.projects.read`
GitBook Assistant
- 

`organization.audit_logs.read`
GitBook Assistant
- 

`organization.usage.read`
GitBook Assistant

For audit logs to contain data, the **Org Owner** must enable **Data Controls** in the OpenAI dashboard.
GitBook Assistant
## FAQ[#faq](#faq)
Q: Is the admin key read-only?[#q-is-the-admin-key-read-only](#q-is-the-admin-key-read-only)

A: Admin keys have broad access. We only perform read operations. The one write operation is creating a temporary service account per project (required to read assistant data). These can be cleaned up after the scan.
GitBook AssistantQ: How often do you scan?[#q-how-often-do-you-scan](#q-how-often-do-you-scan)

A: Configurable. Default is daily.
GitBook AssistantQ: Do you need access to our cloud infrastructure?[#q-do-you-need-access-to-our-cloud-infrastructure](#q-do-you-need-access-to-our-cloud-infrastructure)

A: No. We only need the OpenAI admin key. We detect agent capabilities (tools, knowledge files, access) from the OpenAI API. For full NHI correlation, you can optionally connect your vault/cloud separately.
GitBook AssistantQ: What if we have 100+ projects?[#q-what-if-we-have-100-projects](#q-what-if-we-have-100-projects)

A: The scan iterates through all projects automatically. No manual setup per project.
GitBook AssistantQ: Can we revoke access?[#q-can-we-revoke-access](#q-can-we-revoke-access)

A: Delete the admin key at any time in the OpenAI dashboard. Access is immediately revoked.
GitBook Assistant

Last updated 4 months ago

- [Step 1: Create an Admin Key](#step-1-create-an-admin-key)
- [Step 2: Enter your Admin key in the Entro Onboarding form](#step-2-enter-your-admin-key-in-the-entro-onboarding-form)
- [What Happens Next](#what-happens-next)
- [Permissions Required](#permissions-required)
- [FAQ](#faq)

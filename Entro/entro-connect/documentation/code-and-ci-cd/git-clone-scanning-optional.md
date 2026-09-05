Git Clone Scanning (optional) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/git-clone-scanning-optional.md).

Entro's **Git Clone** capability enables **faster scanning of full commit history** by cloning repository data directly to the connector (Worker Group) to perform a full history scan directly from disk Instead of fetching commit diffs periodically via the source control API. This approach eliminates the performance and scale constraints of API-based scanning: local git operations are orders of magnitude faster than REST API calls, and there are no pagination limits or rate limits — Entro can walk the entire commit history of every branch without throttling.
GitBook Assistant

**Supported Platforms**
GitBook Assistant

- 

GitHub (Cloud and Enterprise Server)
GitBook Assistant
- 

GitLab
GitBook Assistant
- 

Bitbucket
GitBook Assistant

**Deployment Options**
GitBook Assistant

Git Clone scanning can be enabled in two deployment modes:
GitBook Assistant

1. 

**Cloud connector** — Entro manages the connector infrastructure. Repositories are cloned within Entro's cloud environment.
GitBook Assistant
1. 

**Remote connector (customer-hosted)** — The connector runs inside your own environment (e.g., on-premises or in your cloud account). Repositories are cloned locally within your infrastructure and never leave it. This is the recommended option for organizations with strict data residency requirements or air-gapped environments.
GitBook Assistant

In both modes, cloned data stays in the connector's local storage and is not uploaded or transmitted externally.
GitBook Assistant

To enable git clone for your organization, contact [Entro Support](mailto:support@entro.security).
GitBook Assistant

Rollout can be gradual: enable for specific account integration or the full organization.
GitBook Assistant
#### **How It Works**[#how-it-works](#how-it-works)

Git Clone scanning runs through six stages:
GitBook Assistant

1. 

**Trigger** — The Entro Platform initiates a scan request for an integration.
GitBook Assistant
1. 

**Discovery Scan** — The connector orchestrates a discovery scan of the organization:
GitBook Assistant

- 

Lists all repositories in the organization
GitBook Assistant
- 

Enumerates branches per repository and triggers a git clone
GitBook Assistant
- 

Iterates the commit history on each branch
GitBook Assistant
- 

Extracts file diffs per commit
GitBook Assistant
- 

Sends each diff to the secret scanner engine
GitBook Assistant
- 

Enriches results with repo/commit metadata and encrypts detected secret values
GitBook Assistant

1. 

**Clone Locally** — A git server component clones each repository as a bare git repo onto a shared local disk volume. All reads happen from disk, not from the API.
GitBook Assistant
1. 

**Secret Scanning** — Entro's engine scans each diff for exposed secrets. Detected secrets are reported back to the Entro Platform with full context: repository, branch, commit, file path, and line number.
GitBook Assistant

#### **Security & Data Handling**[#security-and-data-handling](#security-and-data-handling)

- 

Cloned repositories are stored as bare git repos on the connector's local disk volume
GitBook Assistant
- 

Clones are **not uploaded anywhere** — they remain scoped to the connector environment
GitBook Assistant

- 

Clones persist until the connector is deleted or manually removed
GitBook Assistant
- 

For the remote connector deployment, all data stays within your own infrastructure
GitBook Assistant

- 

Secret values detected during scanning are encrypted before being reported back to the Entro Platform
GitBook Assistant

​
GitBook Assistant[PreviousGitLab Troubleshooting And Validation](/integrations/code-and-ci-cd/gitlab/gitlab-troubleshooting-and-validation)[NextEntro Command Line Interface (CLI)](/integrations/code-and-ci-cd/entro-command-line-interface-cli)

Last updated 2 months ago

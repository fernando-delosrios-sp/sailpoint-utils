BitBucket | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/bitbucket.md).

The **Bitbucket Integration** enables Entro Security to continuously scan repositories and commits across **Bitbucket Cloud** and **Bitbucket Data Center (on-prem)** for exposed secrets, credentials, and tokens.
GitBook Assistant

Entro connects securely using read-only authentication methods - either a **Bitbucket API Token / App Password** or a **Workload Identity Federation (WIF) token** - ensuring zero write or modification actions on your repositories.
GitBook Assistant

### Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
Entro Security Cloud
        ↕  (HTTPS/TLS)
Bitbucket Cloud or Data Center
   ├── Repositories
   ├── Commits
   └── Branches
```

Entro’s integration interacts directly with the Bitbucket API to enumerate repositories, commits, and branches, then performs in-memory secret scanning through its secure cloud engine or local connector.
GitBook Assistant

### Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

All operations are **read-only**.
GitBook Assistant
- 

Source code is never stored — only hashed metadata and secret context.
GitBook Assistant
- 

Credentials (App Passwords, API Tokens, or WIF tokens) are encrypted using **AES-256**.
GitBook Assistant
- 

All communications occur via **TLS 1.2+**.
GitBook Assistant
- 

Entro complies with:
GitBook Assistant

- 

**SOC 2 Type II**
GitBook Assistant
- 

**ISO 27001**
GitBook Assistant
- 

**GDPR**
GitBook Assistant

[PreviousRemote File System Troubleshooting And Validation](/integrations/cloud-and-infrastructure/remote-file-system/remote-file-system-troubleshooting-and-validation)[NextBitBucket Cloud Onboarding](/integrations/code-and-ci-cd/bitbucket/bitbucket-onboarding)

Last updated 2 months ago

- [Architecture](#architecture)
- [Security & Compliance](#security-and-compliance)

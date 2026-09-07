Buildkite | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/buildkite.md).

The **Buildkite Integration** provides Entro Security with continuous, read-only visibility into build log output across your Buildkite pipelines. Once connected, Entro scans job and build logs for secrets accidentally printed during pipeline execution — such as API keys, tokens, and credentials echoed in build steps and alerts on exposures before they can be exploited.
GitBook Assistant
## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
┌───────────────────────────────┐
│       Entro Security Cloud    │
│  (Secret Detection Engine)    │
└──────────────┬────────────────┘
               │  HTTPS (TLS 1.2+)
               ▼
┌───────────────────────────────┐
│       Buildkite Cloud         │
│ (Pipelines, Builds, Secrets)  │
└───────────────────────────────┘
```

Entro connects to Buildkite through a **Personal Access Token (PAT)** with read-only permissions.
GitBook Assistant

#### Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

All connections occur over **HTTPS/TLS 1.2+**
GitBook Assistant
- 

Access tokens are **AES-256 encrypted at rest** within Entro
GitBook Assistant
- 

No write, modification, or destructive actions are performed
GitBook Assistant
- 

Tokens can be revoked anytime from the Buildkite user settings
GitBook Assistant
- 

Full audit logging available in Entro’s event logs
GitBook Assistant
[PreviousJenkins Troubleshooting And Validation](/integrations/code-and-ci-cd/jenkins/jenkins-troubleshooting-and-validation)[NextBuildkite Onboarding](/integrations/code-and-ci-cd/buildkite/buildkite-onboarding)

Last updated 2 months ago

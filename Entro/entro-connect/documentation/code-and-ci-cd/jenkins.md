Jenkins | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/jenkins.md).

The **Jenkins Integration** connects Entro Security with your Jenkins CI/CD environment to gain visibility into secrets exposed during your CI/CD build processes. This integration operates in read-only mode, ensuring full visibility without modifying your Jenkins environment.
GitBook Assistant
#### Supported scope[#supported-scope](#supported-scope)

Once connected, Entro will analyzes Jenkins build logs across all pipelines to detect exposed secrets.
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
│        Jenkins Server         │
│ (Jobs, Pipelines, Builds)     │
└───────────────────────────────┘
```

Entro connects to Jenkins using your **User ID**, **Access Token**, and **Instance URL**, establishing secure read-only communication.
GitBook Assistant
#### Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Communication encrypted via **TLS 1.2+**
GitBook Assistant
- 

API tokens stored securely using **AES-256 encryption**
GitBook Assistant
- 

Read-only access enforced for all operations
GitBook Assistant
- 

Integration complies with **SOC 2 Type II**, **ISO 27001**, and **GDPR**
GitBook Assistant
[PreviousEntro Command Line Interface (CLI)](/integrations/code-and-ci-cd/entro-command-line-interface-cli)[NextJenkins Onboarding](/integrations/code-and-ci-cd/jenkins/jenkins-onboarding)

Last updated 2 months ago

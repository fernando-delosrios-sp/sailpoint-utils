Azure DevOps | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure-devops.md).

The Azure DevOps Integration provides Entro Security with continuous, read-only visibility into repositories, pipelines, and projects across your Azure DevOps organization. It enables automatic detection of exposed secrets, misconfigured credentials, and high-risk tokens within source code and CI/CD environments.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account (top right) → Azure DevOps
GitBook Assistant
## Purpose[#purpose](#purpose)

Azure DevOps often contains sensitive data embedded in:
GitBook Assistant

- 

Pipeline variables and YAML definitions
GitBook Assistant
- 

Repository code and configuration files
GitBook Assistant
- 

Build scripts and deployment manifests
GitBook Assistant

Entro scans these components securely to identify and alert on exposed secrets before they can be exploited.
GitBook Assistant
## Supported Resources[#supported-resources](#supported-resources)

Once connected, Entro analyzes:
GitBook Assistant

- 

Repositories (including all active branches and commits)
GitBook Assistant
- 

Pipelines and build definitions
GitBook Assistant
- 

Service connections and automation tokens
GitBook Assistant
- 

Variable groups and project configurations
GitBook Assistant

## Architecture[#architecture](#architecture)

Entro communicates with Azure DevOps using OAuth 2.0 bearer tokens generated via the Microsoft Identity Platform.
GitBook Assistant
## Security Model[#security-model](#security-model)

- 

All communication occurs via HTTPS/TLS 1.2+
GitBook Assistant
- 

Entro performs no write or modification actions
GitBook Assistant
- 

Client secret can be revoked anytime via the Entro application in Entra ID
GitBook Assistant

## Integration Flow[#integration-flow](#integration-flow)
1
#### Add Entro Application to Azure DevOps Org[#add-entro-application-to-azure-devops-org](#add-entro-application-to-azure-devops-org)

Add the integrated Entro application (Service Principal) to the Azure DevOps organization and assign the relevant projects and groups.
GitBook Assistant2
#### Submit Application Details to Entro[#submit-application-details-to-entro](#submit-application-details-to-entro)

Provide the Entro application details and client secret.
GitBook Assistant3
#### Entro validates access[#entro-validates-access](#entro-validates-access)

Entro validates the client secret and the permitted scopes.
GitBook Assistant4
#### Scanning begins[#scanning-begins](#scanning-begins)

Entro begins scanning connected repositories, pipelines, and configurations.
GitBook Assistant5
#### Findings in Entro Console[#findings-in-entro-console](#findings-in-entro-console)

Findings appear in the Entro Console with metadata and remediation guidance.
GitBook Assistant[PreviousPermissions Reference](/integrations/cloud-and-infrastructure/azure/permissions-reference)[NextAzure DevOps Onboarding](/integrations/cloud-and-infrastructure/azure-devops/azure-devops-onboarding)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Purpose](#purpose)
- [Supported Resources](#supported-resources)
- [Architecture](#architecture)
- [Security Model](#security-model)
- [Integration Flow](#integration-flow)
ArchitectureGitBook AssistantAskCopy
```
+-------------------+          +-----------------------+
|   Entro Console   |          |    Azure DevOps API   |
|  (Control Plane)  | <------> |   (Projects/Users)    |
+-------------------+          +-----------------------+
          ^                                ^
          |          +-----------+         |
          +--------> | Entra ID  | <-------+
                     | (App Reg) |
                     +-----------+
```

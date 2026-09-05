JFrog Artifactory Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/container-registries/jfrog-artifactory/jfrog-artifactory-onboarding.md).
## Configuration Steps[#configuration-steps](#configuration-steps)
1
#### Generate a Read-Only Access Token in JFrog[#generate-a-read-only-access-token-in-jfrog](#generate-a-read-only-access-token-in-jfrog)

1. 

Log in to **JFrog Artifactory** as an administrator.
GitBook Assistant
1. 

Go to **Administration → User Management → Access Tokens**.
GitBook Assistant
1. 

Click **Generate a Token**.
GitBook Assistant
1. 

In the creation dialog, configure:
GitBook Assistant

- 

**Description:** `entro-token`
GitBook Assistant
- 

**Token Scope:** *Group*
GitBook Assistant
- 

**Groups:** *readers* (default group with read-only access to all repositories)
GitBook Assistant
- 

**Expiration time: **Never
GitBook Assistant

1. 

Click **Generate**.
GitBook Assistant
1. 

Copy the generated token immediately and store it securely.
GitBook Assistant

2
#### Connect JFrog Artifactory in Entro[#connect-jfrog-artifactory-in-entro](#connect-jfrog-artifactory-in-entro)

1. 

In the Entro Dashboard, navigate to **Management → Accounts & Integrations → Add New Account → JFrog Artifactory**
GitBook Assistant
1. 

Fill in the connection details:
GitBook Assistant
FieldDescription

**Artifactory URL**
GitBook Assistant

Base URL of your JFrog instance (e.g., `https://artifactory.example.com`)
GitBook Assistant

**Username**
GitBook Assistant

Username of the account used for token creation
GitBook Assistant

**Access Token**
GitBook Assistant

Scoped read-only Access Token
GitBook Assistant

**Environment Nickname**
GitBook Assistant

Descriptive name for the integration
GitBook Assistant

**Environment Type**
GitBook Assistant

Select relevant environment
GitBook Assistant

**Worker Group (Connector)**
GitBook Assistant

Choose the appropriate Entro worker group
GitBook Assistant

1. 

Click **Connect**. Entro validates the credentials and establishes a secure link.
GitBook Assistant
1. 

When successful, the integration status displays **Verified.**
GitBook Assistant
[PreviousJFrog Artifactory](/integrations/container-registries/jfrog-artifactory)[NextJFrogArtifactory Troubleshooting And Validation](/integrations/container-registries/jfrog-artifactory/jfrogartifactory-troubleshooting-and-validation)

Last updated 2 months ago

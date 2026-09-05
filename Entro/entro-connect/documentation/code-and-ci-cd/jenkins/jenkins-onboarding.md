Jenkins Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/jenkins/jenkins-onboarding.md).
## Configuration Steps[#configuration-steps](#configuration-steps)
1
#### Optional: create a dedication user[#optional-create-a-dedication-user](#optional-create-a-dedication-user)

To ensure secure read-only access, it is recommended to generate the API token from a **dedicated service user** with **read-only** permissions, to ensure the integration has the minimum necessary access to your system.
GitBook Assistant

1. 

Install the [**Role-Based Authorization Strategy**](https://plugins.jenkins.io/role-strategy/)** **plugin in your jenkins server
GitBook Assistant
1. 

Navigate to **Manage Jenkins > Manage and Assign Roles > Manage Roles**
GitBook Assistant
1. 

**Create a role with following permissions: **
GitBook Assistant

1. 

Overall/Read
GitBook Assistant
1. 

Job/Read
GitBook Assistant

1. 

Create a **new user for this role**, to be used for this integration
GitBook Assistant
2
#### Generate a Jenkins API Token[#generate-a-jenkins-api-token](#generate-a-jenkins-api-token)

An API token is required for Entro to securely connect to Jenkins.
GitBook Assistant

- 

Log in to the Jenkins account intended for integration.
GitBook Assistant
- 

Click your **username** in the top-right corner and select **Security**.
GitBook Assistant
- 

Under **API Token**, click **Add new Token** and provide a descriptive name (e.g., `Entro_Integration`).
GitBook Assistant
- 

Copy the generated token immediately and store it securely.
GitBook Assistant
3
#### Step 2 - Connect Jenkins to Entro Security[#step-2-connect-jenkins-to-entro-security](#step-2-connect-jenkins-to-entro-security)

1. 

In the Entro platform, navigate to: **Management → Accounts & Integrations → Add New Account → Jenkins**
GitBook Assistant
1. 

Complete the connection form using the following details:
GitBook Assistant

1. 

**URL: **The base URL of your Jenkins instance
GitBook Assistant
1. 

**User ID:** The Jenkins user ID associated with the API token
GitBook Assistant
1. 

**Access Token: **Paste the API token generated in the previous step
GitBook Assistant
1. 

**Environment Nickname: **Enter a descriptive name (e.g., CICD-Jenkins)
GitBook Assistant
1. 

**Environment Type: **Select the relevant environment (e.g., Production)
GitBook Assistant
1. 

**Worker Group (Connector): **Choose the Entro Worker handling the scan
GitBook Assistant

1. 

Click **Create Account**. 
GitBook Assistant
4
#### Step 3 - Validation and Scanning[#step-3-validation-and-scanning](#step-3-validation-and-scanning)

Once connected:
GitBook Assistant

- 

Entro validates the token against the Jenkins REST API, and verifies required permissions are granted.
GitBook Assistant
- 

Jenkins data is scanned for secret exposures across pipeline logs and configurations.
GitBook Assistant
- 

Findings appear in your Entro Console with metadata and severity context.
GitBook Assistant
[PreviousJenkins](/integrations/code-and-ci-cd/jenkins)[NextJenkins Troubleshooting And Validation](/integrations/code-and-ci-cd/jenkins/jenkins-troubleshooting-and-validation)

Last updated 2 months ago

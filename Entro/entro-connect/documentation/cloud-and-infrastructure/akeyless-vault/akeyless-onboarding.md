Akeyless Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/akeyless-vault/akeyless-onboarding.md).

This section describes how to securely connect your **Akeyless Vault** with **Entro Security** for continuous monitoring and discovery.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → Akeyless**
GitBook Assistant
## Overview[#overview](#overview)

Entro connects to Akeyless via secure API sessions authenticated through **Universal Identity** or **API Key** methods. All operations are strictly **read-only** and performed through encrypted communication channels.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

- 

You have **Administrator** permissions in Akeyless Vault
GitBook Assistant
- 

Entro Security integration permissions are enabled
GitBook Assistant
- 

Network connectivity allows outbound **HTTPS (443)** connections
GitBook Assistant

## Universal Identity Onboarding[#universal-identity-onboarding](#universal-identity-onboarding)
1
#### Create Universal Identity in Akeyless[#create-universal-identity-in-akeyless](#create-universal-identity-in-akeyless)

- 

Log in to your **Akeyless Vault Console**.
GitBook Assistant
- 

Navigate to **Users & Auth Methods → Create Auth Method**.
GitBook Assistant
- 

Select **Universal Identity** and name it `Entro_Universal`.
GitBook Assistant
- 

Complete the creation wizard and note the **Access ID** and **UID** values.
GitBook Assistant
2
#### Configure Entro[#configure-entro](#configure-entro)

- 

In Entro, open **Management → Accounts & Integrations → Add New Account → Akeyless**.
GitBook Assistant
- 

Enter the following:
GitBook Assistant

- 

**Environment nickname:** Production
GitBook Assistant
- 

**Authorization method:** Universal Identity
GitBook Assistant
- 

**Access ID:** your Akeyless Access ID
GitBook Assistant
- 

**UID:** the Universal Identity ID from Akeyless
GitBook Assistant
- 

**Worker Group (Connector):** select your active connector
GitBook Assistant

- 

Click **Create Account** to validate and establish the connection.
GitBook Assistant

## API Key Onboarding[#api-key-onboarding](#api-key-onboarding)
1
#### Create API Key in Akeyless[#create-api-key-in-akeyless](#create-api-key-in-akeyless)

- 

Log in to **Akeyless Vault Console**.
GitBook Assistant
- 

Navigate to **Users & Auth Methods → Create API Key**.
GitBook Assistant
- 

Name the key `Entro_INT_Token` and click **Finish**.
GitBook Assistant
- 

Copy your **Access ID** and **Access Key**.
GitBook Assistant
2
#### Configure Access Roles in Akeyless[#configure-access-roles-in-akeyless](#configure-access-roles-in-akeyless)

- 

In **Access Roles**, create a new role `EntroSecurity_ReadOnlyRole`.
GitBook Assistant
- 

Associate the role with the **Entro_INT_Token** auth method.
GitBook Assistant
- 

Add the following rule types with **List** and **Read** permissions:
GitBook Assistant

- 

**Items** (apply recursively)
GitBook Assistant
- 

**Access Roles**
GitBook Assistant
- 

**Auth Methods**
GitBook Assistant

3
#### Configure Entro[#configure-entro-1](#configure-entro-1)

- 

Return to Entro and navigate to **Add New Account → Akeyless**.
GitBook Assistant
- 

Fill in:
GitBook Assistant

- 

**Environment nickname:** Production
GitBook Assistant
- 

**Authorization method:** API Key
GitBook Assistant
- 

**Access ID / Access Key:** copied from Akeyless
GitBook Assistant
- 

**Worker Group (Connector):** select your connector
GitBook Assistant

- 

Click **Create Account** to complete onboarding.
GitBook Assistant

## System Requirements[#system-requirements](#system-requirements)

- 

Outbound HTTPS connectivity (port 443)
GitBook Assistant
- 

Active Entro Worker (Connector) with assigned role
GitBook Assistant
- 

Akeyless API endpoints reachable from the Entro environment
GitBook Assistant

## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

All Entro–Akeyless interactions occur via **TLS 1.2+**
GitBook Assistant
- 

No secret values are ever retrieved or stored
GitBook Assistant
- 

Keys are securely managed in the Entro Worker
GitBook Assistant
- 

Integration operates under **least-privilege** principles
GitBook Assistant
[PreviousAkeyless Vault](/integrations/cloud-and-infrastructure/akeyless-vault)[NextAkeyless Troubleshooting And Validation](/integrations/cloud-and-infrastructure/akeyless-vault/akeyless-troubleshooting-and-validation)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Universal Identity Onboarding](#universal-identity-onboarding)
- [API Key Onboarding](#api-key-onboarding)
- [System Requirements](#system-requirements)
- [Security & Compliance](#security-and-compliance)

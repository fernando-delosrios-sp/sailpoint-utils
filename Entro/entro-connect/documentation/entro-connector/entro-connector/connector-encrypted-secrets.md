Connector Encrypted Secrets | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/entro-connector/entro-connector/connector-encrypted-secrets.md).
## Purpose[#purpose](#purpose)

For organizations that require all secrets stay within their data boundaries thus requiring Entro to never store the actual secret value when onboarding customer's integrations.
GitBook Assistant
## Overview[#overview](#overview)

- 

Generate a new 2048-bit RSA key pair on the Entro Outpost Connector.
GitBook Assistant
- 

Set the the `SECRET_PRIVATE_KEY=` value in the `.env-connector` file for the Entro Outpost Connector container.
GitBook Assistant
- 

Encrypt Service Account secret/credentials that will be used by Entro to connect to integration service with new RSA key.
GitBook Assistant
- 

Configure integration(s) in Entro UI (Accounts & Integrations page) using newly encrypted secret/credential.
GitBook Assistant

Treat private keys and decrypted secrets as highly sensitive.
GitBook Assistant

Rotate keys per your security policy and coordinate rotations with Entro Security.
GitBook Assistant

Customers are advised to backup generated RSA key pair using their sanctioned backup solution.
GitBook Assistant
## Steps to Use Connector Encrypted Secrets feature[#steps-to-use-connector-encrypted-secrets-feature](#steps-to-use-connector-encrypted-secrets-feature)

### Public/Private key pair generation[#public-private-key-pair-generation](#public-private-key-pair-generation)

On the Entro Outpost Connector perform the following steps with the openssl tools to create the RSA key pair.
GitBook Assistant

1. 

Verify the openssl tools are installed. If not installed, use the appropriate tools to install on the Connector.
GitBook AssistantGitBook AssistantAskCopy
```
openssl version
```

1. 

Generate the Private Key
GitBook AssistantGitBook AssistantAskCopy
```
openssl genpkey -algorithm RSA -out private.key -pkeyopt rsa_keygen_bits:2048
```

1. 

Generate the Public key
GitBook AssistantGitBook AssistantAskCopy
```
openssl rsa -in private.key -pubout -out public.key
```

### Setting up the Connector container[#setting-up-the-connector-container](#setting-up-the-connector-container)

1. 

Ensure that the Entro Outpost Connector container has been stopped
GitBook Assistant
1. 

Encode the private key
GitBook Assistant
1. 

Add encoded value from `private.key` to the Connector's environment variables file, `.env-connector`
GitBook Assistant
1. 

Restart the Entro Outpost Connector container
GitBook Assistant

### Secrets Encryption[#secrets-encryption](#secrets-encryption)

In order for Entro to use the encrypted secrets you will need to encrypt them with the public key and then encode them with base64. The following steps will need to be performed for all integrations configured in the Accounts & Integrations page of the Entro UI.
GitBook Assistant

1. 

Create the service account and associated secret/token/API key in the desired integration service.
GitBook Assistant
1. 

Store the plaintext secret/token/API key in a file on Entro Outpost Connector named `creds.txt`
GitBook Assistant
1. 

Encrypt using the generated public key from earlier
GitBook Assistant
1. 

Encode with base64
GitBook Assistant
1. 

Copy the now encrpted and encoded secret/token/API key value from the `creds.encrypted.b64.txt` file.
GitBook Assistant
1. 

Navigate to Entro Portal UI then Management > Accounts & Integrations. Click "+ Add new account" button and choose the desired integration's tile. Paste the encrypted & encoded value from Step 5 into the relevant secret/token field. For example, for Atlassian integration paste into the "Atlassian token" field:
GitBook Assistant
[PreviousK8S Connector](/integrations/entro-connector/entro-connector/k8s-connector)[NextConnector versions](/integrations/entro-connector/entro-connector/connector-versions)

Last updated 3 months ago

- [Purpose](#purpose)
- [Overview](#overview)
- [Steps to Use Connector Encrypted Secrets feature](#steps-to-use-connector-encrypted-secrets-feature)
- [Public/Private key pair generation](#public-private-key-pair-generation)
- [Setting up the Connector container](#setting-up-the-connector-container)
- [Secrets Encryption](#secrets-encryption)
GitBook AssistantAskCopy
```
cat private.key | base64
```
GitBook AssistantAskCopy
```
SECRET_PRIVATE_KEY="base64 encoded private key value from above step"
```
GitBook AssistantAskCopy
```
openssl pkeyutl -encrypt -pubin -inkey public.key -in creds.txt -out creds.encrypted
```
GitBook AssistantAskCopy
```
base64 -i creds.encrypted > creds.encrypted.b64.txt
```

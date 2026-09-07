Encrypting Integration Secrets | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/entro-outpost-on-prem/encrypting-integration-secrets.md).

If service account secrets are required by your organization to be encrypted before being stored in the Entro integrations settings (Mangement > Accounts & Integrations page), this guide will walk you through the process of encrypting the integrations secrets such that the Outpost can successfully utilize them when later connecting to the integrated services.
GitBook Assistant
#### Public/Private Keypair generation[#public-private-keypair-generation](#public-private-keypair-generation)

1. 

Generate the Private Keyopenssl genpkey -algorithm RSA -out private.key -pkeyopt rsa_keygen_bits:2048
GitBook Assistant
1. 

Generate the public keyopenssl rsa -in private.key -pubout -out public.key
GitBook Assistant

#### Setting up the connector[#setting-up-the-connector](#setting-up-the-connector)

1. 

Encode the private key\cat private.key | base64
GitBook Assistant
1. 

Add it to the Connector's environment variables - \SECRET_PRIVATE_KEY="replace with base64 encoded private key"
GitBook Assistant

#### Secrets Encryption[#secrets-encryption](#secrets-encryption)

In order for Entro to use the encrypted secrets you will need to encrypt them with the public key and then encode them with base64.Store the secret in a file, e.g - creds.txt
GitBook Assistant

1. 

Encrypt using the generated public key\openssl pkeyutl -encrypt -pubin -inkey public.key -in creds.txt -out creds.encrypted
GitBook Assistant
1. 

Encode with base64\base64 -i creds.encrypted > creds.encrypted.b64.txt
GitBook Assistant
1. 

Copy the encoded value from the *creds.encrypted.b64.txt* file
GitBook Assistant
1. 

Paste into the relevant **secret** field, e.g, in Atlassian's case - Where the Atlassian token is
GitBook Assistant

[PreviousOutpost Scanning Scheduler](/administration/entro-outpost-on-prem/outpost-scanning-scheduler)[NextAlerts](/administration/settings/alerts)

Last updated 11 months ago

HashiCorp Vault Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-onboarding.md).

This section describes how to connect **HashiCorp Vault** to **Entro Security** using a read-only ACL policy and access token.
GitBook Assistant
## Configuration steps[#configuration-steps](#configuration-steps)
1
#### Create an ACL Policy[#create-an-acl-policy](#create-an-acl-policy)

1. 

In your HashiCorp Vault, navigate to** Policies -> ACL Policies**
GitBook Assistant
1. 

Click on "**+ Create ACL Policy**"
GitBook Assistant

1. 

Add the name "entro-policy" and provide following read permissions:
GitBook Assistant
GitBook AssistantAskCopy
```
path "*" {
  capabilities = ["list", "read"]
}
path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}
path "auth/token/accessors" {
  capabilities = ["list", "sudo"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
```
2
#### Create a Token for Entro[#create-a-token-for-entro](#create-a-token-for-entro)

Use the Vault CLI tool to run the following command and create a token using the newly defined policy:
GitBook AssistantGitBook AssistantAskCopy
```
write auth/token/create policies=entro-policy no_default_policy=true ttl=30d period=30d renewable=true
```

For older versions of HashiCorp Vault, use one of these alternate command:
GitBook AssistantGitBook AssistantAskCopy
```
vault token create -policy="entro-policy" -no-default-policy=1 -ttl="30d" -period="30d" -renewable=1

vault token create -policy="entro-policy" -no-default-policy=1 -ttl=432000 -period=432000 -renewable=1
```

Copy the token value and store it securely. 
GitBook Assistant3
#### Connect to Entro Security[#connect-to-entro-security](#connect-to-entro-security)

1. 

Navigate to **Management → Accounts & Integrations → Add New Account → HashiCorp Vault**
GitBook Assistant
1. 

Fill in the following fields:
GitBook Assistant

1. 

**Environment: **A descriptive name for this Vault integration
GitBook Assistant
1. 

**Vault Server URL: **The URL or IP address (including port) of your Vault instance
GitBook Assistant
1. 

**Access Token: **The token generated in the previous step
GitBook Assistant
1. 

**Worker Group (Connector): **Select the relevant Worker Group handling Vault scans
GitBook Assistant

1. 

Click **Create Account**.
GitBook Assistant
1. 

Entro validates access and begins scanning
GitBook Assistant
[PreviousHashiCorp Vault](/integrations/cloud-and-infrastructure/hashicorp-vault)[NextHashiCorp Vault Troubleshooting And Validation](/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-troubleshooting-and-validation)

Last updated 1 month ago

Connector Network Requirements | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/entro-connector/entro-connector/connector-network-requirements.md).
## Purpose[#purpose](#purpose)

Lists external endpoints and local connectivity requirements for Entro Connectors.
GitBook Assistant
## Local access[#local-access](#local-access)

- 

Connector must be able to reach every onboarded integration inside your perimeter (Bitbucket, GitLab, SMB, Vault, etc).
GitBook Assistant
- 

Ensure no firewall/proxy/DPI blocks these connections.
GitBook Assistant
- 

SMB file share scanning requires local network access to file servers.
GitBook Assistant

Note: Connector needs direct network access to the resources it scans. If your environment restricts internal connectivity, adjust firewall rules or provide a routing path (VPN, VPC peering, etc.) so the connector can reach those services.
GitBook Assistant
## Entro & AWS endpoints[#entro-and-aws-endpoints](#entro-and-aws-endpoints)

Connector needs outbound access to Entro services and various AWS endpoints used for logging and storage. Common AWS endpoints include:
GitBook Assistant

- 

`*.s3.amazonaws.com`
GitBook Assistant
- 

`*.s3.{region}.amazonaws.com`
GitBook Assistant
- 

`iam.amazonaws.com`
GitBook Assistant
- 

`logs.{region}.amazonaws.com`
GitBook Assistant
- 

`secretsmanager.{region}.amazonaws.com`
GitBook Assistant
- 

`sqs.{region}.amazonaws.com`
GitBook Assistant
- 

`sts.{region}.amazonaws.com`
GitBook Assistant
- 

`s3express-control.{region}.amazonaws.com`
GitBook Assistant
- 

`monitoring.us-east-1.amazonaws.com` (and FIPS variants)
GitBook Assistant
- 

`*api.entro.security` - Entro's own API endpoint
GitBook Assistant

The connector **does not** communicate directly with Entro's UI (app.entro.security)
GitBook Assistant

Default region is `us-east-1` unless specified otherwise. Replace `{region}` accordingly.
GitBook Assistant
## Firewall / proxy notes[#firewall-proxy-notes](#firewall-proxy-notes)

**Do not perform SSL stripping or MITM on Entro traffic.**
GitBook Assistant

- 

Allow outbound HTTPS to Entro API hosts and required AWS endpoints above.
GitBook Assistant
- 

If using Entro SaaS perimeter static IPs, see the [IP list on the SaaS-perimeter page](https://docs.entro.security/integrations/entro-connector/entro-connector/entro-saas-perimeter-ips).
GitBook Assistant
- 

If a proxy is required, make sure the [proxy is configured](/integrations/entro-connector/entro-connector/docker-compose) in the `.env-connector` file.
GitBook Assistant

## Troubleshooting[#troubleshooting](#troubleshooting)
Troubleshooting steps[#troubleshooting-steps](#troubleshooting-steps)

- 

If connector fails to reach a service, capture tcpdump and check DNS resolution and proxy logs.
GitBook Assistant
- 

Verify proxy authentication and TLS interception are not interfering.
GitBook Assistant
- 

Confirm outbound HTTPS to the relevant Entro and AWS hosts is permitted and not being altered by DPI.
GitBook Assistant

End of network requirements.
GitBook Assistant[PreviousDocker Compose](/integrations/entro-connector/entro-connector/docker-compose)[NextEntro SaaS Perimeter IPs](/integrations/entro-connector/entro-connector/entro-saas-perimeter-ips)

Last updated 4 months ago

- [Purpose](#purpose)
- [Local access](#local-access)
- [Entro & AWS endpoints](#entro-and-aws-endpoints)
- [Firewall / proxy notes](#firewall-proxy-notes)
- [Troubleshooting](#troubleshooting)

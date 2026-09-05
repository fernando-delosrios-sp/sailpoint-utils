Docker Compose | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/entro-connector/entro-connector/docker-compose.md).
## Purpose[#purpose](#purpose)

On‑premise Entro Connector for network‑restricted assets. The connector runs on an EC2/VM using Docker Compose and securely transmits findings metadata to Entro.
GitBook Assistant

Supported local resources:
GitBook Assistant

- 

Bitbucket Data Center / Server
GitBook Assistant
- 

GitLab (self‑hosted)
GitBook Assistant
- 

GitHub Enterprise (on‑prem)
GitBook Assistant
- 

Atlassian Jira Server / Confluence Server
GitBook Assistant
- 

SMB File Shares
GitBook Assistant
- 

HashiCorp Vault
GitBook Assistant

When to choose self‑managed
GitBook Assistant

Choose self‑managed only if required by your network constraints. Self‑managed instances need manual updates and lack Entro cloud uptime monitoring. Prefer Entro cloud connectors if possible.
GitBook Assistant
## EC2 / VM instance requirements[#ec2-vm-instance-requirements](#ec2-vm-instance-requirements)

**Sizing (standard)**
GitBook Assistant

- 

8 CPU cores
GitBook Assistant
- 

32 GB RAM
GitBook Assistant
- 

64 GB SSD (minimum)
GitBook Assistant

**Sizing (large orgs)**
GitBook Assistant

- 

16 CPU cores
GitBook Assistant
- 

32 GB RAM
GitBook Assistant
- 

64 GB SSD (minimum)
GitBook Assistant

**OS / Architecture**
GitBook Assistant

- 

Amazon Linux 2023
GitBook Assistant
- 

Architecture: AMD64
GitBook Assistant

**Access & Connectivity**
GitBook Assistant

- 

Root‑level user access required
GitBook Assistant
- 

SSH access to the instance
GitBook Assistant
- 

Outbound (egress) Internet communication required
GitBook Assistant
- 

Connectivity to target services (GitLab on‑prem, Bitbucket Server, SMB, Vault)
GitBook Assistant
- 

Outbound ports: any (*)
GitBook Assistant

**Required software**
GitBook Assistant

- 

Docker
GitBook Assistant
- 

Docker Compose
GitBook Assistant

## Files in the provided package[#files-in-the-provided-package](#files-in-the-provided-package)

When Entro provides the connector ZIP it includes:
GitBook Assistant

- 

`docker-compose.yaml` — container definitions
GitBook Assistant
- 

`.env` — general docker configuration
GitBook Assistant
- 

`.env-connector` — connector configuration
GitBook Assistant
- 

`.env-scanner` — scanner configuration
GitBook Assistant
- 

`.env-nats` — NATS configuration
GitBook Assistant

## Installation (step-by-step)[#installation-step-by-step](#installation-step-by-step)
1
#### Receive the package[#receive-the-package](#receive-the-package)

Receive ZIP via 1Password from Entro.
GitBook Assistant2
#### Prepare host[#prepare-host](#prepare-host)
3
#### Edit connector environment[#edit-connector-environment](#edit-connector-environment)

Edit `.env-connector` and populate values provided by Entro:
GitBook Assistant4
#### Authenticate to Entro container registry[#authenticate-to-entro-container-registry](#authenticate-to-entro-container-registry)

Replace `<GITHUB_TOKEN>` with token Entro provided:
GitBook Assistant5
#### Pull and start containers[#pull-and-start-containers](#pull-and-start-containers)
6
#### Verify[#verify](#verify)

## Custom mounts (required volumes)[#custom-mounts-required-volumes](#custom-mounts-required-volumes)

Starting v2.0 the connector requires these volumes:
GitBook Assistant

- 

`var/nats` : 10 GB minimum — message queue storage
GitBook Assistant
- 

`/clones` : 20 GB minimum — repository clone storage (when scanning repos)
GitBook Assistant

Create mounts on the host and bind them into the container as shown in `docker-compose.yaml`.
GitBook Assistant
## Upgrade instructions[#upgrade-instructions](#upgrade-instructions)

To upgrade images either use `:latest` tags or pin versions.
GitBook Assistant

Example env variables to pin exact versions:
GitBook Assistant

Upgrade procedure:
GitBook Assistant
## Notes & operational tips[#notes-and-operational-tips](#notes-and-operational-tips)

- 

Coordinate credential, token, and certificate handling with Entro Security.
GitBook Assistant
- 

Monitor disk usage for `var/nats` and `/clones`.
GitBook Assistant
- 

For large organizations, scale CPU and memory per the "large orgs" sizing above.
GitBook Assistant
- 

For custom mounts or advanced host configuration, contact Entro for guidance.
GitBook Assistant

## Architecture (ASCII)[#architecture-ascii](#architecture-ascii)
View architecture diagram[#view-architecture-diagram](#view-architecture-diagram)[PreviousEntro Connector](/integrations/entro-connector/entro-connector)[NextConnector Network Requirements](/integrations/entro-connector/entro-connector/connector-network-requirements)

Last updated 4 months ago

- [Purpose](#purpose)
- [EC2 / VM instance requirements](#ec2-vm-instance-requirements)
- [Files in the provided package](#files-in-the-provided-package)
- [Installation (step-by-step)](#installation-step-by-step)
- [Custom mounts (required volumes)](#custom-mounts-required-volumes)
- [Upgrade instructions](#upgrade-instructions)
- [Notes & operational tips](#notes-and-operational-tips)
- [Architecture (ASCII)](#architecture-ascii)
GitBook AssistantAskCopy
```
unzip docker-compose.zip
cd docker-compose
```
GitBook AssistantAskCopy
```
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
OUTPUT_BUCKET=
SQS_QUEUE_URL=
REDSHIFT_BUCKET=
LOG_STREAMER_LOG_STREAM=
LOG_STREAMER_LOG_GROUP=
LOG_STREAMER_TYPE=cloudwatch
LOG_STREAMER_ENABLED=true

# If using encrypted secrets:
SECRET_PRIVATE_KEY=

# If using a HTTP/HTTPS Proxy:
HTTP_PROXY=
NO_PROXY= //addresses to bypass proxy
```
GitBook AssistantAskCopy
```
echo <GITHUB_TOKEN> | docker login ghcr.io -u entro-registry --password-stdin
```
GitBook AssistantAskCopy
```
docker compose pull
docker compose up -d
```
GitBook AssistantAskCopy
```
docker compose ps
docker compose logs -f
```
GitBook AssistantAskCopy
```
CONNECTOR_IMAGE=ghcr.io/entro-security-registry/entro-connector:2.6.10
SCANNER_IMAGE=ghcr.io/entro-security-registry/entro-scanner:1.7.5
TIKA_IMAGE=ghcr.io/entro-security-registry/entro-tika:1.7.0
NATS_IMAGE=ghcr.io/entro-security-registry/entro-nats-{arch}:1.7.0
```
GitBook AssistantAskCopy
```
# stop
docker compose down

# pull new images
docker compose pull

# restart
docker compose up -d
```
GitBook AssistantAskCopy
```
EC2 / VM host (Docker)
 └─ Entro Connector containers
     ├─ connector
     ├─ scanner
     ├─ tika
     └─ nats
Outbound HTTPS -> Entro API (findings metadata)
Local access -> Target services (GitLab, Bitbucket, SMB, Vault)
```

Docker Installation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/entro-outpost-on-prem/outpost-installation/docker-installation.md).
## Outpost Docker Installation[#outpost-docker-installation](#outpost-docker-installation)

The Entro team will share a zip file that contains the files below, please unzip it in the location you want to install the connector, and follow the steps below
GitBook AssistantFileDescription

docker-compose.yaml
GitBook Assistant

Defines the containers
GitBook Assistant

.env
GitBook Assistant

General docker configuration file
GitBook Assistant

.env-connector
GitBook Assistant

Connector configuration file
GitBook Assistant

.env-scanner
GitBook Assistant

Scanner configuration file
GitBook Assistant

.env-nats
GitBook Assistant

NATS configuration file
GitBook Assistant

**File preparation**
GitBook Assistant

Open the .env-connector file and fill the following lines with the information provided by Entro Security:
GitBook AssistantGitBook AssistantAskCopy
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
```

If you use "Encrypted Integration Secrets" go through the [instructions](/administration/entro-outpost-on-prem/encrypting-integration-secrets) here and fill this environment variables
GitBook Assistant

**Connect to Entro Repository**
GitBook Assistant

Note: Replace the <GITHUB_TOKEN> with the token provided by Entro and run the following command:
GitBook Assistant

**Starting the Entro Connector Environment**
GitBook Assistant

Run the following command to download, build and start the Entro Connector environment:
GitBook Assistant[PreviousOutpost Installation](/administration/entro-outpost-on-prem/outpost-installation)[NextKubernetes Installation](/administration/entro-outpost-on-prem/outpost-installation/kubernetes-installation)

Last updated 11 months ago
GitBook AssistantAskCopy
```
SECRET_PRIVATE_KEY=
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

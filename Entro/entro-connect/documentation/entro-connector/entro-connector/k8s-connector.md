K8S Connector | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/entro-connector/entro-connector/k8s-connector.md).
## Purpose[#purpose](#purpose)

Kubernetes deployment of the Entro Connector via Helm. Use when you run Kubernetes and prefer cluster deployment.
GitBook Assistant
## Cluster / Pod requirements[#cluster-pod-requirements](#cluster-pod-requirements)

Entro deploys 3 pods (scanner, connector, nats). Per‑pod minimum:
GitBook Assistant

- 

2 CPU cores
GitBook Assistant
- 

4 GB RAM
GitBook Assistant
- 

10 GB SSD (minimum)
GitBook Assistant

Instance OS: Linux Architecture: AMD64 Root level access required for installation.
GitBook Assistant
## Installation (high level)[#installation-high-level](#installation-high-level)

Entro provides:
GitBook Assistant

- 

Helm chart location (OCI): `oci://ghcr.io/entro-security-registry/entro-connector-helm`
GitBook Assistant
- 

Chart version (provided by Entro)
GitBook Assistant
- 

Secrets and values to be set by your team
GitBook Assistant
1
#### Set environment variables[#set-environment-variables](#set-environment-variables)

Set the environment variables required for the install, for example:
GitBook AssistantSet environment variablesGitBook AssistantAskCopy
```
export ENTRO_AWS_ACCESS_KEY_ID=""
export ENTRO_AWS_SECRET_ACCESS_KEY=""
export ENTRO_CONNECTOR_UID=""
export ENTRO_LOG_GROUP=""
export ENTRO_HELM_CHART_VERSION=""
export ENTRO_KUBERNETES_NAMESPACE="entro"
export ENTRO_HELM_RELEASE_NAME="entro"

export ENTRO_HELM_CHART="oci://ghcr.io/entro-security-registry/entro-connector-helm"
```
2
#### Authenticate to GitHub Container Registry[#authenticate-to-github-container-registry](#authenticate-to-github-container-registry)

Login to ghcr.io to allow pulling the Helm chart:
GitBook AssistantHelm registry loginGitBook AssistantAskCopy
```
echo "$CR_PAT" | helm registry login ghcr.io  --username entro-registry --password-stdin
```
3
#### Pull the Helm chart[#pull-the-helm-chart](#pull-the-helm-chart)

Download the specified chart version:
GitBook AssistantHelm pull chartGitBook AssistantAskCopy
```
helm pull "$ENTRO_HELM_CHART" --version "$ENTRO_HELM_CHART_VERSION"
```
4
#### Install the Helm release[#install-the-helm-release](#install-the-helm-release)

Install the chart into the target namespace with required overrides:
GitBook AssistantHelm installGitBook AssistantAskCopy
```
helm install "$ENTRO_HELM_RELEASE_NAME" "$ENTRO_HELM_CHART" -n "$ENTRO_KUBERNETES_NAMESPACE" --create-namespace \
  --set scanner.replicaCount=1 \
  --set connector.replicaCount=1 \
  --set-string entro.awsAccountId="937217723901" \
  --set entro.awsAccessKeyId="$ENTRO_AWS_ACCESS_KEY_ID" \
  --set entro.awsSecretAccessKey="$ENTRO_AWS_SECRET_ACCESS_KEY" \
  --set entro.password="$CR_PAT" \
  --set entro.connectorId="$ENTRO_CONNECTOR_UID" \
  --set env.HTTP_PROXY="$ENTRO_HTTP_PROXY" \
  --set env.NO_PROXY="$ENTRO_NO_PROXY" \
  --set env.LOG_GROUP="$ENTRO_LOG_GROUP"
```

Helm values and secrets will be provided by Entro Security. Ensure network access for outbound egress to Entro API and connectivity to target services.
GitBook Assistant[PreviousEntro SaaS Perimeter IPs](/integrations/entro-connector/entro-connector/entro-saas-perimeter-ips)[NextConnector Encrypted Secrets](/integrations/entro-connector/entro-connector/connector-encrypted-secrets)

Last updated 4 months ago

- [Purpose](#purpose)
- [Cluster / Pod requirements](#cluster-pod-requirements)
- [Installation (high level)](#installation-high-level)

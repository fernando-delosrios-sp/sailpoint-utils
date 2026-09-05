Kubernetes Installation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/entro-outpost-on-prem/outpost-installation/kubernetes-installation.md).
#### Outpost Kubernetes Installation[#outpost-kubernetes-installation](#outpost-kubernetes-installation)

You will receive:
GitBook Assistant

1. 

The following installation script below
GitBook Assistant
1. 

Installation Helm Chart
GitBook Assistant
1. 

Secrets sent by Entro Security in a separate mail
GitBook Assistant
GitBook AssistantAskCopy
```
# TO BE SET BY THE YOUR TEAM WITH ENTRO'S DATA
export ENTRO_AWS_SECRET_ACCESS_KEY="WILL BE SENT IN SEPARATE EMAIL"
export CR_PAT="WILL BE SENT IN SEPARATE EMAIL"

# THE VALUES WILL BE SENT BY ENTRO
export ENTRO_AWS_ACCESS_KEY_ID="" 
export ENTRO_CONNECTOR_UID=""
export ENTRO_LOG_GROUP=""
export ENTRO_HELM_CHART_VERSION=""

# TO BE SET BY YOUR TEAM
export ENTRO_KUBERNETES_NAMESPACE="entro"
export ENTRO_HELM_RELEASE_NAME="entro"
export ENTRO_HTTP_PROXY=
export ENTRO_NO_PROXY=

export ENTRO_HELM_CHART="oci://ghcr.io/entro-security-registry/entro-connector-helm"
echo "$CR_PAT" | helm registry login ghcr.io  --username entro-registry --password-stdin
helm pull "$ENTRO_HELM_CHART" --version "$ENTRO_HELM_CHART_VERSION"

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
[PreviousDocker Installation](/administration/entro-outpost-on-prem/outpost-installation/docker-installation)[NextOutpost Upgrade](/administration/entro-outpost-on-prem/outpost-upgrade)

Last updated 11 months ago

#!/usr/bin/env bash
set -euo pipefail

# Generated from integrations/google-gcp/Entro GCP Terraform onboarding.zip.
# Source SHA-256: sha256:904b1ef405d86d59a759347dc3c45a0d512925b351a71ad7225f01c990a1bbe0
ORGANIZATION_PROJECT_SERVICES=(
  'cloudresourcemanager.googleapis.com'
  'iam.googleapis.com'
  'recommender.googleapis.com'
)
HOST_PROJECT_SERVICES=(
  'cloudresourcemanager.googleapis.com'
  'iam.googleapis.com'
  'recommender.googleapis.com'
  'policyanalyzer.googleapis.com'
  'pubsub.googleapis.com'
  'cloudasset.googleapis.com'
  'admin.googleapis.com'
  'drive.googleapis.com'
)
BILLING_DEPENDENT_SERVICES=(
  'secretmanager.googleapis.com'
  'discoveryengine.googleapis.com'
)

: "${PROJECT_ID:?set PROJECT_ID to the Terraform host project}"
: "${ORGANIZATION_ID:?set ORGANIZATION_ID}"
MODE="${1:-apply}"
ENABLE_SERVICES_ON_ALL_PROJECTS=true
USE_BILLING_REQUIRED_SERVICES=true
ORGANIZATION_PROJECTS=()

enable_services() {
  local project="$1"
  shift
  (("$#" > 0)) || return 0
  gcloud services enable "$@" --project="$project"
}

verify_services() {
  local project="$1"
  shift
  local service
  for service in "$@"; do
    gcloud services list --enabled --project="$project"       --filter="config.name=$service" --format='value(config.name)' |
      grep -Fxq "$service"
  done
}

discover_organization_projects() {
  local gsuite_folder query resource
  gsuite_folder="$(
    gcloud asset search-all-resources       --scope="organizations/${ORGANIZATION_ID}"       --asset-types="cloudresourcemanager.googleapis.com/Folder"       --query="displayName:system-gsuite"       --format='value(name)' | awk -F/ 'NR == 1 { print $NF }'
  )"
  query="state:ACTIVE"
  if [[ -n "$gsuite_folder" ]]; then
    query="$query AND NOT folders:$gsuite_folder"
  fi
  while IFS= read -r resource; do
    [[ -z "$resource" ]] ||       ORGANIZATION_PROJECTS[${#ORGANIZATION_PROJECTS[@]}]="${resource##*/}"
  done < <(
    gcloud asset search-all-resources       --scope="organizations/${ORGANIZATION_ID}"       --asset-types="cloudresourcemanager.googleapis.com/Project"       --query="$query"       --format='value(name)'
  )
}

run_for_project() {
  local operation="$1"
  local project="$2"
  shift 2
  case "$operation" in
    apply) enable_services "$project" "$@" ;;
    verify) verify_services "$project" "$@" ;;
  esac
}

case "$MODE" in
  apply|verify) ;;
  *) echo "usage: $0 [apply|verify]" >&2; exit 2 ;;
esac

run_for_project "$MODE" "$PROJECT_ID" "${HOST_PROJECT_SERVICES[@]}"

if [[ "$ENABLE_SERVICES_ON_ALL_PROJECTS" == true ]]; then
  discover_organization_projects
  for project in "${ORGANIZATION_PROJECTS[@]}"; do
    run_for_project "$MODE" "$project" "${ORGANIZATION_PROJECT_SERVICES[@]}"
    if [[ "$USE_BILLING_REQUIRED_SERVICES" == true ]]; then
      run_for_project "$MODE" "$project" "${BILLING_DEPENDENT_SERVICES[@]}"
    fi
  done
fi

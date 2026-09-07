#!/usr/bin/env bash
set -euo pipefail

# Generated from integrations/google-gcp/Entro GCP Terraform onboarding.zip.
# Source SHA-256: sha256:904b1ef405d86d59a759347dc3c45a0d512925b351a71ad7225f01c990a1bbe0
CUSTOM_ROLE_PERMISSIONS=(
  'logging.buckets.get'
  'logging.buckets.list'
  'logging.exclusions.get'
  'logging.exclusions.list'
  'logging.links.get'
  'logging.links.list'
  'logging.locations.get'
  'logging.locations.list'
  'logging.logEntries.download'
  'logging.logEntries.list'
  'logging.logMetrics.get'
  'logging.logMetrics.list'
  'logging.logServiceIndexes.list'
  'logging.logServices.list'
  'logging.logs.list'
  'logging.operations.get'
  'logging.operations.list'
  'logging.privateLogEntries.list'
  'logging.queries.create'
  'logging.queries.delete'
  'logging.queries.get'
  'logging.queries.list'
  'logging.queries.listShared'
  'logging.queries.update'
  'logging.sinks.get'
  'logging.sinks.list'
  'logging.usage.get'
  'logging.views.access'
  'logging.views.get'
  'logging.views.list'
  'logging.views.listLogs'
  'logging.views.listResourceKeys'
  'logging.views.listResourceValues'
  'resourcemanager.organizations.get'
  'secretmanager.versions.access'
  'secretmanager.secrets.list'
  'secretmanager.versions.list'
  'secretmanager.locations.list'
  'secretmanager.secrets.getIamPolicy'
  'iam.serviceAccounts.list'
  'iam.serviceAccounts.get'
  'iam.serviceAccounts.getIamPolicy'
  'iam.serviceAccountKeys.get'
  'iam.serviceAccountKeys.list'
  'iam.roles.get'
  'cloudfunctions.functions.get'
  'cloudfunctions.functions.list'
  'cloudbuild.builds.get'
  'cloudbuild.builds.list'
  'cloudbuild.operations.get'
  'cloudbuild.operations.list'
  'recommender.iamPolicyInsights.get'
  'recommender.iamPolicyInsights.list'
  'recommender.iamPolicyLateralMovementInsights.get'
  'recommender.iamPolicyLateralMovementInsights.list'
  'recommender.iamPolicyRecommendations.get'
  'recommender.iamPolicyRecommendations.list'
  'recommender.iamPolicyRecommenderConfig.get'
  'recommender.iamServiceAccountInsights.get'
  'recommender.iamServiceAccountInsights.list'
  'recommender.locations.get'
  'recommender.locations.list'
  'recommender.cloudAssetInsights.get'
  'recommender.cloudAssetInsights.list'
  'resourcemanager.projects.get'
  'resourcemanager.projects.list'
  'cloudasset.assets.listResource'
  'cloudasset.assets.listIamPolicy'
  'cloudasset.assets.listOrgPolicy'
  'cloudasset.assets.listAccessPolicy'
  'cloudasset.assets.listOSInventories'
  'policyanalyzer.serviceAccountKeyLastAuthenticationActivities.query'
  'policyanalyzer.serviceAccountLastAuthenticationActivities.query'
  'serviceusage.quotas.get'
  'serviceusage.services.get'
  'serviceusage.services.list'
  'iam.roles.list'
  'resourcemanager.organizations.getIamPolicy'
  'resourcemanager.projects.getIamPolicy'
  'resourcemanager.folders.getIamPolicy'
  'resourcemanager.folders.get'
)
PREDEFINED_ROLES=(
  'roles/logging.privateLogViewer'
  'roles/resourcemanager.organizationViewer'
  'roles/secretmanager.viewer'
  'roles/iam.supportUser'
  'roles/cloudfunctions.viewer'
  'roles/recommender.iamViewer'
  'roles/cloudasset.viewer'
  'roles/policyanalyzer.activityAnalysisViewer'
  'roles/iam.securityReviewer'
  'roles/resourcemanager.folderViewer'
  'roles/serviceusage.apiKeysViewer'
  'roles/discoveryengine.viewer'
)

: "${ORGANIZATION_ID:?set ORGANIZATION_ID}"
: "${PROJECT_ID:?set PROJECT_ID}"
: "${SERVICE_ACCOUNT_NAME:?set SERVICE_ACCOUNT_NAME}"

MODE="${1:-apply}"
MEMBER="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
ROLE_ID_PREFIX='entroLoggingRole_'
ROLE_SUFFIX_MIN=1
ROLE_SUFFIX_MAX=1000
STATE_FILE="${ENTRO_GCP_IAM_STATE:-${TMPDIR:-/tmp}/entro-gcp-iam-${ORGANIZATION_ID}-${PROJECT_ID}-${SERVICE_ACCOUNT_NAME}.state}"

binding_exists() {
  gcloud organizations get-iam-policy "$ORGANIZATION_ID"     --flatten=bindings --filter="bindings.role=$1"     --format='value(bindings.members)' | tr ';' '\n' | grep -Fxq "$MEMBER"
}

state_custom_role_id() {
  awk -F '\t' '$1 == "custom-role" { print $2; exit }' "$STATE_FILE"
}

bound_custom_role_id() {
  local role match='' count=0
  while IFS= read -r role; do
    if [[ "$role" =~ ^organizations/${ORGANIZATION_ID}/roles/${ROLE_ID_PREFIX}[0-9]+$ ]]; then
      match="${role##*/}"
      count=$((count + 1))
    fi
  done < <(
    gcloud organizations get-iam-policy "$ORGANIZATION_ID"       --flatten=bindings --filter="bindings.members=$MEMBER"       --format='value(bindings.role)'
  )
  [[ "$count" -eq 1 ]] || {
    echo "expected exactly one ${ROLE_ID_PREFIX}* role bound to $MEMBER; found $count" >&2
    return 1
  }
  printf '%s\n' "$match"
}

verify() {
  local role custom_role_id custom_role included expected_permissions actual_permissions
  custom_role_id="$(bound_custom_role_id)"
  custom_role="organizations/${ORGANIZATION_ID}/roles/${custom_role_id}"
  included="$(gcloud iam roles describe "$custom_role_id"     --organization="$ORGANIZATION_ID" --format='value(includedPermissions)')"
  expected_permissions="$(printf '%s\n' "${CUSTOM_ROLE_PERMISSIONS[@]}" | sort)"
  actual_permissions="$(tr ';,' '\n\n' <<<"$included" | sed '/^$/d' | sort)"
  [[ "$actual_permissions" == "$expected_permissions" ]] || {
    echo "custom role permissions differ from the pinned Terraform source" >&2
    return 1
  }
  binding_exists "$custom_role"
  for role in "${PREDEFINED_ROLES[@]}"; do
    binding_exists "$role"
  done
}

choose_custom_role_id() {
  local span start offset suffix candidate
  span=$((ROLE_SUFFIX_MAX - ROLE_SUFFIX_MIN + 1))
  start="$(awk -v min="$ROLE_SUFFIX_MIN" -v span="$span"     'BEGIN { srand(); print min + int(rand() * span) }')"
  offset=0
  while ((offset < span)); do
    suffix=$((ROLE_SUFFIX_MIN + (start - ROLE_SUFFIX_MIN + offset) % span))
    candidate="${ROLE_ID_PREFIX}${suffix}"
    if ! gcloud iam roles describe "$candidate"       --organization="$ORGANIZATION_ID" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
    offset=$((offset + 1))
  done
  echo "all Terraform-compatible Entro custom role IDs already exist" >&2
  return 1
}

apply_grants() {
  [[ ! -e "$STATE_FILE" ]] || {
    echo "run state already exists: $STATE_FILE" >&2
    return 1
  }
  umask 077
  : >"$STATE_FILE"
  local custom_role_id custom_role
  custom_role_id="$(choose_custom_role_id)"
  custom_role="organizations/${ORGANIZATION_ID}/roles/${custom_role_id}"
  gcloud iam roles create "$custom_role_id"     --organization="$ORGANIZATION_ID"     --title='Entro Logging Role'     --description='This role is used by entro to access logging resources.'     --permissions="$(IFS=,; echo "${CUSTOM_ROLE_PERMISSIONS[*]}")"
  printf 'custom-role\t%s\n' "$custom_role_id" >>"$STATE_FILE"
  gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID"     --member="$MEMBER" --role="$custom_role"
  printf 'binding\t%s\n' "$custom_role" >>"$STATE_FILE"
  local role
  for role in "${PREDEFINED_ROLES[@]}"; do
    if ! binding_exists "$role"; then
      gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID"         --member="$MEMBER" --role="$role"
      printf 'binding\t%s\n' "$role" >>"$STATE_FILE"
    fi
  done
  verify
}

rollback() {
  [[ -f "$STATE_FILE" ]] || {
    echo "run state not found: $STATE_FILE" >&2
    return 1
  }
  local kind value custom_role_id='' index
  local bindings=()
  while IFS=$'\t' read -r kind value; do
    case "$kind" in
      binding) bindings[${#bindings[@]}]="$value" ;;
      custom-role) custom_role_id="$value" ;;
      *) echo "invalid run state entry: $kind" >&2; return 1 ;;
    esac
  done <"$STATE_FILE"
  for ((index=${#bindings[@]} - 1; index >= 0; index--)); do
    gcloud organizations remove-iam-policy-binding "$ORGANIZATION_ID"       --member="$MEMBER" --role="${bindings[$index]}"
  done
  if [[ -n "$custom_role_id" ]]; then
    gcloud iam roles delete "$custom_role_id"       --organization="$ORGANIZATION_ID" --quiet
  fi
  rm -f "$STATE_FILE"
}

case "$MODE" in
  apply) apply_grants ;;
  verify) verify ;;
  rollback) rollback ;;
  *) echo "usage: $0 [apply|verify|rollback]" >&2; exit 2 ;;
esac

"""Curated Add New Account target catalog for integrations.json.

An Add New Account target is one row. A Coverage is an operator-named surface
that row can unlock after connect (SharePoint / OneDrive, Copilot Studio), not
the target itself and not a Graph permission-group heading (Copilot chats,
Defender, Teams secrets).

Each row lists Configuration tools (operator CLIs and first-party vendor MCP
servers, with Fit) and Hosting (`public`, `self-hosted`, or
`operator-selected`). Connector deployment topology is derived from Hosting,
not stored on the row. Coverages may add extras; an empty list means inherit the
parent row. Install, auth-once, optional Configure once (command, check, prompts
with where each wizard value comes from, and docsUrl), and Credential
boundary live once per CLI binary or MCP id in the root Tool install catalog
(`toolInstall`), which also carries presence, Capability probe, auth-check, and
Platform identity. Each row also
carries a `summary`, vendor `connectionFields`, `prepSteps` (on Setup
methods when present, otherwise on the row), Operator inputs, and Typed actions
on Fit `preferred` paths so a Connect run does not open
`documentation/`. The same writer emits the ingest index and a Skill catalog
tree under both `.agents/skills/entro-connect/` and `skills/entro-connect/`
(thin index, Tool install file, row folders). Secrets stay in the
vendor CLI token cache, MCP client OAuth session, or
a gitignored env file — never in agent context.
"""

from __future__ import annotations

import json
import re
import shutil
from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path
from typing import Literal
from zipfile import BadZipFile, ZipFile

from catalog_contracts import (
    ADO_ACTIONS,
    AKEYLESS_ACTIONS,
    AWS_ACCESS_KEY_DOCS,
    AWS_ACCESS_KEY_PROMPTS,
    AWS_CONFIGURE_ONCE_RETRIEVED,
    AWS_IDC_PROMPTS,
    AWS_IAM_IDC_AUTH_DOCS,
    AWS_MANUAL_ACTIONS,
    AWS_SSO_PROFILE_DOCS,
    AWS_TERRAFORM_ACTIONS,
    CensusEntry,
    COPILOT_ACTIONS,
    DATAVERSE_ENV_ID,
    DISPLAY,
    ENTRA_APP_NAME,
    ENV_FIELD,
    ENV_NICK,
    ENV_NICK_ADO,
    ENV_TYPE_INPUT,
    EXTERNAL_ID,
    GCP_ENTRO_AWS_ROLE_ARN,
    GCP_ORGANIZATION_DOMAIN,
    GCP_ORGANIZATION_ID,
    GCP_PROJECT_ID,
    GCP_SERVICE_ACCOUNT,
    GITLAB_ACTIONS,
    INDEX_ENTRY_KEYS,
    INDEX_FORBIDDEN_KEYS,
    INTEGRATION_DOCUMENTATION_FOLDERS,
    INTEGRATIONS_DIR,
    JFROG_ACTIONS,
    JENKINS_ACTIONS,
    MS_AUTO_ACTIONS,
    MS_MANUAL_ACTIONS,
    MethodWaiver,
    NAMING_FIELD_NAMES,
    NICKNAME,
    COMPANY_NICK,
    OCI_ACTIONS,
    OKTA_ACTIONS,
    REMOTE_AGENT,
    ROLE_NAME,
    ROW_CATALOG_NAME,
    S3_BUCKET_INPUT,
    S3_COVERAGE_STEPS_ACTIONS,
    SNS_TOPIC_ARN_SUFFIX,
    SNOWFLAKE_ACTIONS,
    SNOWFLAKE_USER,
    TEAMS_ACTIONS,
    TERRAFORM_DIR,
    TOOL_INSTALL_FILE,
    TOOL_INSTALL_OBJECT_KEYS,
    VAULT_ACTIONS,
    AuthenticationRoute,
    CatalogCheck,
    ConfigureOnce,
    OperatorInput,
    PinnedScript,
    PlatformIdentityQuery,
    TypedAction,
    action_to_dict,
    actions_to_list,
    gcp_actions,
    catalog_path_for,
    census_entry_to_dict,
    check_to_dict,
    configure_once_to_dict,
    identity_to_dict,
    inputs_to_list,
    method_waiver_to_dict,
    probe_fields_present,
    probes_for,
    validate_prep_step_coverage,
)

import skill_held
from skill_held import (
    SKILL_ROOTS,
    copy_skill_held_tree,
    migrate_vendor_into_row_folders,
    remove_vendor_trees,
    validate_harvest_coverage,
    validate_script_pin,
)

Hosting = Literal["public", "self-hosted", "operator-selected"]
HOSTINGS: frozenset[str] = frozenset(("public", "self-hosted", "operator-selected"))
FormHosting = Literal["public", "self-hosted"]

ConnectorDeployment = Literal[
    "entro-cloud",
    "saas-perimeter",
    "self-managed-docker",
    "self-managed-kubernetes",
]

ALL_CONNECTOR_DEPLOYMENTS: tuple[ConnectorDeployment, ...] = (
    "entro-cloud",
    "saas-perimeter",
    "self-managed-docker",
    "self-managed-kubernetes",
)

CONNECTOR_TOPOLOGY_PAGES: tuple[str, ...] = (
    "entro-connector/entro-connector.md",
    "entro-connector/entro-connector/docker-compose.md",
    "entro-connector/entro-connector/k8s-connector.md",
    "entro-connector/entro-connector/entro-saas-perimeter-ips.md",
)

_CONNECTOR_DEPLOYMENT_PAGE: dict[ConnectorDeployment, str] = {
    "entro-cloud": CONNECTOR_TOPOLOGY_PAGES[0],
    "self-managed-docker": CONNECTOR_TOPOLOGY_PAGES[1],
    "self-managed-kubernetes": CONNECTOR_TOPOLOGY_PAGES[2],
    "saas-perimeter": CONNECTOR_TOPOLOGY_PAGES[3],
}
_TOPOLOGY_LIST_KEYS = frozenset(
    ("connectorDeployments", "connectorDocumentation", "topologies")
)

REPO_ROOT = Path(__file__).resolve().parent
SKILL_CATALOG_PATH = SKILL_ROOTS[0] / "integrations.json"
SKILL_CATALOG_PATHS = tuple(root / "integrations.json" for root in SKILL_ROOTS)
GCP_TERRAFORM_ARCHIVE_SKILL_PATH = (
    "integrations/google-gcp/Entro GCP Terraform onboarding.zip"
)
GCP_TERRAFORM_ARCHIVE_CHECKSUM = (
    "sha256:904b1ef405d86d59a759347dc3c45a0d512925b351a71ad7225f01c990a1bbe0"
)
GCP_TERRAFORM_ARCHIVE_ROOT = "Entro GCP Terraform onboarding/"
GCP_IAM_ARTIFACT_SKILL_PATH = "integrations/google-gcp/entro-gcp-iam-grants.sh"
GCP_API_ARTIFACT_SKILL_PATH = "integrations/google-gcp/entro-gcp-enable-apis.sh"
_GCP_EXPECTED_PERMISSION_COUNT = 81
_GCP_EXPECTED_ROLE_COUNT = 12
_GCP_EXPECTED_API_COUNTS = {
    "organization-project": 3,
    "host-project": 8,
    "billing-dependent": 2,
}
WORKER_GROUP_NAMES = frozenset(("worker group", "worker group (connector)"))
_SECRET_SHAPED = re.compile(
    r"(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}"
    r"|xox[baprs]-[\w-]{10,}|AKIA[0-9A-Z]{16}|sk_live_[A-Za-z0-9]+"
    r"|password\s*=\s*\S+|secret_key\s*=)",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class GcpTerraformContract:
    """Source values distilled from Entro's pinned GCP Terraform archive."""

    source_checksum: str
    custom_role_id_prefix: str
    custom_role_title: str
    custom_role_description: str
    random_suffix_min: int
    random_suffix_max: int
    custom_role_permissions: tuple[str, ...]
    predefined_roles: tuple[str, ...]
    organization_project_services: tuple[str, ...]
    host_project_services: tuple[str, ...]
    billing_dependent_services: tuple[str, ...]
    use_billing_required_services_default: bool


@dataclass(frozen=True)
class GeneratedSkillArtifact:
    """Deterministic generated bytes and metadata for a Skill row folder."""

    skill_path: str
    content: bytes
    checksum: str
    executable: bool
    source_skill_path: str
    source_checksum: str


def _terraform_list(source: str, label: str, pattern: str) -> tuple[str, ...]:
    match = re.search(pattern, source, flags=re.DOTALL)
    if match is None:
        raise ValueError(f"GCP Terraform archive is missing {label}")
    values = tuple(re.findall(r'"([^"]+)"', match.group(1)))
    if not values or len(values) != len(set(values)):
        raise ValueError(f"GCP Terraform archive has empty or duplicate {label}")
    return values


def _terraform_variable_list(source: str, name: str) -> tuple[str, ...]:
    return _terraform_list(
        source,
        f"variable {name}",
        rf'variable "{re.escape(name)}"\s*\{{.*?default\s*=\s*\[(.*?)\]\s*\}}',
    )


def extract_gcp_terraform_contract(
    archive_path: Path | None = None,
) -> GcpTerraformContract:
    """Read and validate the pinned GCP Terraform onboarding contract."""

    path = archive_path or (SKILL_ROOTS[0] / GCP_TERRAFORM_ARCHIVE_SKILL_PATH)
    try:
        archive_bytes = path.read_bytes()
    except OSError as exc:
        raise ValueError(f"cannot read pinned GCP Terraform archive: {path}") from exc
    try:
        with ZipFile(path) as archive:
            sources = {
                name: archive.read(GCP_TERRAFORM_ARCHIVE_ROOT + name).decode("utf-8")
                for name in ("iam.tf", "main.tf", "services.tf", "utils.tf", "variables.tf")
            }
    except (BadZipFile, KeyError, UnicodeDecodeError) as exc:
        raise ValueError(
            "pinned GCP Terraform archive must contain UTF-8 iam.tf, main.tf, "
            "services.tf, utils.tf, and variables.tf"
        ) from exc

    custom_role = re.search(
        r'resource "google_organization_iam_custom_role" "custom_role"\s*\{'
        r'.*?role_id\s*=\s*"([^"]+)\$\{random_integer\.random_int\.result\}"'
        r'.*?title\s*=\s*"([^"]+)"'
        r'.*?description\s*=\s*"([^"]+)"'
        r'.*?permissions\s*=\s*\[(.*?)\]\s*\}',
        sources["iam.tf"],
        flags=re.DOTALL,
    )
    random_suffix = re.search(
        r'resource "random_integer" "random_int"\s*\{'
        r'.*?min\s*=\s*(\d+)'
        r'.*?max\s*=\s*(\d+)'
        r'.*?\}',
        sources["utils.tf"],
        flags=re.DOTALL,
    )
    project_discovery = (
        'data "google_cloud_asset_search_all_resources" "gcloud_folder"'
        in sources["main.tf"]
        and 'data "google_cloud_asset_search_all_resources" "all_projects"'
        in sources["main.tf"]
        and "state:ACTIVE" in sources["main.tf"]
        and "system-gsuite" in sources["main.tf"]
    )
    if custom_role is None or random_suffix is None or not project_discovery:
        raise ValueError(
            "GCP Terraform archive is missing custom-role identity, random suffix "
            "bounds, or active organization-project discovery"
        )
    permissions = _terraform_list(
        custom_role.group(4),
        "custom organization role permissions",
        r"(.*)",
    )
    roles = _terraform_variable_list(sources["variables.tf"], "gcp_roles_to_grant_list")
    api_groups = {
        "organization-project": _terraform_variable_list(
            sources["variables.tf"], "gcp_services_to_enable_on_projects_list"
        ),
        "host-project": _terraform_variable_list(
            sources["variables.tf"], "gcp_services_to_enable_on_host_project_list"
        ),
        "billing-dependent": _terraform_variable_list(
            sources["variables.tf"],
            "gcp_billing_required_services_to_enable_list",
        ),
    }
    count_errors = []
    if len(permissions) != _GCP_EXPECTED_PERMISSION_COUNT:
        count_errors.append(
            f"{len(permissions)} custom-role permissions "
            f"(expected {_GCP_EXPECTED_PERMISSION_COUNT})"
        )
    if len(roles) != _GCP_EXPECTED_ROLE_COUNT:
        count_errors.append(
            f"{len(roles)} predefined roles (expected {_GCP_EXPECTED_ROLE_COUNT})"
        )
    for group, expected in _GCP_EXPECTED_API_COUNTS.items():
        if len(api_groups[group]) != expected:
            count_errors.append(
                f"{len(api_groups[group])} {group} APIs (expected {expected})"
            )
    if count_errors:
        raise ValueError("GCP Terraform archive has " + ", ".join(count_errors))

    billing_default = re.search(
        r'variable "use_billing_required_services"\s*\{'
        r'.*?default\s*=\s*(true|false)\b.*?\}',
        sources["variables.tf"],
        flags=re.DOTALL,
    )
    billing_resource = re.search(
        r'resource "google_project_service" "billing_required"\s*\{'
        r'.*?for_each\s*=\s*'
        r'var\.enable_services_on_all_projects\s*&&\s*'
        r'var\.use_billing_required_services\s*\?',
        sources["services.tf"],
        flags=re.DOTALL,
    )
    if billing_default is None or billing_resource is None:
        raise ValueError(
            "GCP Terraform archive is missing the billing-required default or condition"
        )
    return GcpTerraformContract(
        source_checksum="sha256:" + sha256(archive_bytes).hexdigest(),
        custom_role_id_prefix=custom_role.group(1),
        custom_role_title=custom_role.group(2),
        custom_role_description=custom_role.group(3),
        random_suffix_min=int(random_suffix.group(1)),
        random_suffix_max=int(random_suffix.group(2)),
        custom_role_permissions=permissions,
        predefined_roles=roles,
        organization_project_services=api_groups["organization-project"],
        host_project_services=api_groups["host-project"],
        billing_dependent_services=api_groups["billing-dependent"],
        use_billing_required_services_default=billing_default.group(1) == "true",
    )


def _bash_array(name: str, values: tuple[str, ...]) -> str:
    if any(not re.fullmatch(r"[A-Za-z0-9._/-]+", value) for value in values):
        raise ValueError(f"{name} contains a value unsafe for deterministic shell output")
    return "\n".join((f"{name}=(", *(f"  '{value}'" for value in values), ")"))


def _render_gcp_iam_artifact(contract: GcpTerraformContract) -> bytes:
    permissions = _bash_array("CUSTOM_ROLE_PERMISSIONS", contract.custom_role_permissions)
    roles = _bash_array("PREDEFINED_ROLES", contract.predefined_roles)
    role_prefix = contract.custom_role_id_prefix
    role_title = contract.custom_role_title.replace("'", "'\"'\"'")
    role_description = contract.custom_role_description.replace("'", "'\"'\"'")
    body = f"""#!/usr/bin/env bash
set -euo pipefail

# Generated from {GCP_TERRAFORM_ARCHIVE_SKILL_PATH}.
# Source SHA-256: {contract.source_checksum}
{permissions}
{roles}

: "${{ORGANIZATION_ID:?set ORGANIZATION_ID}}"
: "${{PROJECT_ID:?set PROJECT_ID}}"
: "${{SERVICE_ACCOUNT_NAME:?set SERVICE_ACCOUNT_NAME}}"

MODE="${{1:-apply}}"
MEMBER="serviceAccount:${{SERVICE_ACCOUNT_NAME}}@${{PROJECT_ID}}.iam.gserviceaccount.com"
ROLE_ID_PREFIX='{role_prefix}'
ROLE_SUFFIX_MIN={contract.random_suffix_min}
ROLE_SUFFIX_MAX={contract.random_suffix_max}
STATE_FILE="${{ENTRO_GCP_IAM_STATE:-${{TMPDIR:-/tmp}}/entro-gcp-iam-${{ORGANIZATION_ID}}-${{PROJECT_ID}}-${{SERVICE_ACCOUNT_NAME}}.state}}"

binding_exists() {{
  gcloud organizations get-iam-policy "$ORGANIZATION_ID" \
    --flatten=bindings --filter="bindings.role=$1" \
    --format='value(bindings.members)' | tr ';' '\\n' | grep -Fxq "$MEMBER"
}}

state_custom_role_id() {{
  awk -F '\\t' '$1 == "custom-role" {{ print $2; exit }}' "$STATE_FILE"
}}

bound_custom_role_id() {{
  local role match='' count=0
  while IFS= read -r role; do
    if [[ "$role" =~ ^organizations/${{ORGANIZATION_ID}}/roles/${{ROLE_ID_PREFIX}}[0-9]+$ ]]; then
      match="${{role##*/}}"
      count=$((count + 1))
    fi
  done < <(
    gcloud organizations get-iam-policy "$ORGANIZATION_ID" \
      --flatten=bindings --filter="bindings.members=$MEMBER" \
      --format='value(bindings.role)'
  )
  [[ "$count" -eq 1 ]] || {{
    echo "expected exactly one ${{ROLE_ID_PREFIX}}* role bound to $MEMBER; found $count" >&2
    return 1
  }}
  printf '%s\\n' "$match"
}}

verify() {{
  local role custom_role_id custom_role included expected_permissions actual_permissions
  custom_role_id="$(bound_custom_role_id)"
  custom_role="organizations/${{ORGANIZATION_ID}}/roles/${{custom_role_id}}"
  included="$(gcloud iam roles describe "$custom_role_id" \
    --organization="$ORGANIZATION_ID" --format='value(includedPermissions)')"
  expected_permissions="$(printf '%s\\n' "${{CUSTOM_ROLE_PERMISSIONS[@]}}" | sort)"
  actual_permissions="$(tr ';,' '\\n\\n' <<<"$included" | sed '/^$/d' | sort)"
  [[ "$actual_permissions" == "$expected_permissions" ]] || {{
    echo "custom role permissions differ from the pinned Terraform source" >&2
    return 1
  }}
  binding_exists "$custom_role"
  for role in "${{PREDEFINED_ROLES[@]}}"; do
    binding_exists "$role"
  done
}}

choose_custom_role_id() {{
  local span start offset suffix candidate
  span=$((ROLE_SUFFIX_MAX - ROLE_SUFFIX_MIN + 1))
  start="$(awk -v min="$ROLE_SUFFIX_MIN" -v span="$span" \
    'BEGIN {{ srand(); print min + int(rand() * span) }}')"
  offset=0
  while ((offset < span)); do
    suffix=$((ROLE_SUFFIX_MIN + (start - ROLE_SUFFIX_MIN + offset) % span))
    candidate="${{ROLE_ID_PREFIX}}${{suffix}}"
    if ! gcloud iam roles describe "$candidate" \
      --organization="$ORGANIZATION_ID" >/dev/null 2>&1; then
      printf '%s\\n' "$candidate"
      return 0
    fi
    offset=$((offset + 1))
  done
  echo "all Terraform-compatible Entro custom role IDs already exist" >&2
  return 1
}}

apply_grants() {{
  [[ ! -e "$STATE_FILE" ]] || {{
    echo "run state already exists: $STATE_FILE" >&2
    return 1
  }}
  umask 077
  : >"$STATE_FILE"
  local custom_role_id custom_role
  custom_role_id="$(choose_custom_role_id)"
  custom_role="organizations/${{ORGANIZATION_ID}}/roles/${{custom_role_id}}"
  gcloud iam roles create "$custom_role_id" \
    --organization="$ORGANIZATION_ID" \
    --title='{role_title}' \
    --description='{role_description}' \
    --permissions="$(IFS=,; echo "${{CUSTOM_ROLE_PERMISSIONS[*]}}")"
  printf 'custom-role\\t%s\\n' "$custom_role_id" >>"$STATE_FILE"
  gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID" \
    --member="$MEMBER" --role="$custom_role"
  printf 'binding\\t%s\\n' "$custom_role" >>"$STATE_FILE"
  local role
  for role in "${{PREDEFINED_ROLES[@]}}"; do
    if ! binding_exists "$role"; then
      gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID" \
        --member="$MEMBER" --role="$role"
      printf 'binding\\t%s\\n' "$role" >>"$STATE_FILE"
    fi
  done
  verify
}}

rollback() {{
  [[ -f "$STATE_FILE" ]] || {{
    echo "run state not found: $STATE_FILE" >&2
    return 1
  }}
  local kind value custom_role_id='' index
  local bindings=()
  while IFS=$'\\t' read -r kind value; do
    case "$kind" in
      binding) bindings[${{#bindings[@]}}]="$value" ;;
      custom-role) custom_role_id="$value" ;;
      *) echo "invalid run state entry: $kind" >&2; return 1 ;;
    esac
  done <"$STATE_FILE"
  for ((index=${{#bindings[@]}} - 1; index >= 0; index--)); do
    gcloud organizations remove-iam-policy-binding "$ORGANIZATION_ID" \
      --member="$MEMBER" --role="${{bindings[$index]}}"
  done
  if [[ -n "$custom_role_id" ]]; then
    gcloud iam roles delete "$custom_role_id" \
      --organization="$ORGANIZATION_ID" --quiet
  fi
  rm -f "$STATE_FILE"
}}

case "$MODE" in
  apply) apply_grants ;;
  verify) verify ;;
  rollback) rollback ;;
  *) echo "usage: $0 [apply|verify|rollback]" >&2; exit 2 ;;
esac
"""
    return body.encode("utf-8")


def _render_gcp_api_artifact(contract: GcpTerraformContract) -> bytes:
    organization = _bash_array(
        "ORGANIZATION_PROJECT_SERVICES", contract.organization_project_services
    )
    host = _bash_array("HOST_PROJECT_SERVICES", contract.host_project_services)
    billing = _bash_array(
        "BILLING_DEPENDENT_SERVICES", contract.billing_dependent_services
    )
    billing_default = "true" if contract.use_billing_required_services_default else "false"
    body = f"""#!/usr/bin/env bash
set -euo pipefail

# Generated from {GCP_TERRAFORM_ARCHIVE_SKILL_PATH}.
# Source SHA-256: {contract.source_checksum}
{organization}
{host}
{billing}

: "${{PROJECT_ID:?set PROJECT_ID to the Terraform host project}}"
: "${{ORGANIZATION_ID:?set ORGANIZATION_ID}}"
MODE="${{1:-apply}}"
ENABLE_SERVICES_ON_ALL_PROJECTS=true
USE_BILLING_REQUIRED_SERVICES={billing_default}
ORGANIZATION_PROJECTS=()

enable_services() {{
  local project="$1"
  shift
  (("$#" > 0)) || return 0
  gcloud services enable "$@" --project="$project"
}}

verify_services() {{
  local project="$1"
  shift
  local service
  for service in "$@"; do
    gcloud services list --enabled --project="$project" \
      --filter="config.name=$service" --format='value(config.name)' |
      grep -Fxq "$service"
  done
}}

discover_organization_projects() {{
  local gsuite_folder query resource
  gsuite_folder="$(
    gcloud asset search-all-resources \
      --scope="organizations/${{ORGANIZATION_ID}}" \
      --asset-types="cloudresourcemanager.googleapis.com/Folder" \
      --query="displayName:system-gsuite" \
      --format='value(name)' | awk -F/ 'NR == 1 {{ print $NF }}'
  )"
  query="state:ACTIVE"
  if [[ -n "$gsuite_folder" ]]; then
    query="$query AND NOT folders:$gsuite_folder"
  fi
  while IFS= read -r resource; do
    [[ -z "$resource" ]] || \
      ORGANIZATION_PROJECTS[${{#ORGANIZATION_PROJECTS[@]}}]="${{resource##*/}}"
  done < <(
    gcloud asset search-all-resources \
      --scope="organizations/${{ORGANIZATION_ID}}" \
      --asset-types="cloudresourcemanager.googleapis.com/Project" \
      --query="$query" \
      --format='value(name)'
  )
}}

run_for_project() {{
  local operation="$1"
  local project="$2"
  shift 2
  case "$operation" in
    apply) enable_services "$project" "$@" ;;
    verify) verify_services "$project" "$@" ;;
  esac
}}

case "$MODE" in
  apply|verify) ;;
  *) echo "usage: $0 [apply|verify]" >&2; exit 2 ;;
esac

run_for_project "$MODE" "$PROJECT_ID" "${{HOST_PROJECT_SERVICES[@]}}"

if [[ "$ENABLE_SERVICES_ON_ALL_PROJECTS" == true ]]; then
  discover_organization_projects
  for project in "${{ORGANIZATION_PROJECTS[@]}}"; do
    run_for_project "$MODE" "$project" "${{ORGANIZATION_PROJECT_SERVICES[@]}}"
    if [[ "$USE_BILLING_REQUIRED_SERVICES" == true ]]; then
      run_for_project "$MODE" "$project" "${{BILLING_DEPENDENT_SERVICES[@]}}"
    fi
  done
fi
"""
    return body.encode("utf-8")


def gcp_generated_artifacts(
    archive_path: Path | None = None,
) -> tuple[GeneratedSkillArtifact, GeneratedSkillArtifact]:
    """Return deterministic IAM and API artifacts for catalog publication."""

    contract = extract_gcp_terraform_contract(archive_path)
    rendered = (
        (GCP_IAM_ARTIFACT_SKILL_PATH, _render_gcp_iam_artifact(contract)),
        (GCP_API_ARTIFACT_SKILL_PATH, _render_gcp_api_artifact(contract)),
    )
    artifacts = tuple(
        GeneratedSkillArtifact(
            skill_path=skill_path,
            content=content,
            checksum="sha256:" + sha256(content).hexdigest(),
            executable=True,
            source_skill_path=GCP_TERRAFORM_ARCHIVE_SKILL_PATH,
            source_checksum=contract.source_checksum,
        )
        for skill_path, content in rendered
    )
    return artifacts[0], artifacts[1]


def _validate_gcp_source_archive(path: Path) -> list[str]:
    """Validate one committed Terraform source before publishing from it."""

    if not path.is_file():
        return [f"pinned GCP Terraform archive missing at {path}"]
    actual = "sha256:" + sha256(path.read_bytes()).hexdigest()
    errors: list[str] = []
    if actual != GCP_TERRAFORM_ARCHIVE_CHECKSUM:
        errors.append(
            f"{path}: pinned GCP Terraform archive checksum drift "
            f"({actual}, expected {GCP_TERRAFORM_ARCHIVE_CHECKSUM})"
        )
    try:
        contract = extract_gcp_terraform_contract(path)
    except ValueError as exc:
        errors.append(f"{path}: {exc}")
    else:
        if contract.source_checksum != actual:
            errors.append(f"{path}: extracted GCP Terraform source checksum disagrees")
    return errors


def _validate_gcp_source_archives() -> list[str]:
    errors: list[str] = []
    bodies: list[bytes] = []
    for root in SKILL_ROOTS:
        path = root / GCP_TERRAFORM_ARCHIVE_SKILL_PATH
        errors.extend(_validate_gcp_source_archive(path))
        if path.is_file():
            bodies.append(path.read_bytes())
    if len(bodies) == len(SKILL_ROOTS) and len(set(bodies)) != 1:
        errors.append(
            f"{GCP_TERRAFORM_ARCHIVE_SKILL_PATH}: Skill trees are not byte-identical"
        )
    return errors


def _generated_gcp_actions() -> tuple[TypedAction, ...]:
    iam_artifact, api_artifact = gcp_generated_artifacts()

    def pin(artifact: GeneratedSkillArtifact, label: str) -> PinnedScript:
        return PinnedScript(
            skill_path=artifact.skill_path,
            version=(
                f"{label}; generated from {artifact.source_skill_path} "
                f"at {artifact.source_checksum}"
            ),
            checksum=artifact.checksum,
        )

    return gcp_actions(
        pin(iam_artifact, "Terraform-derived GCP IAM grants"),
        pin(api_artifact, "Terraform-default GCP API enablement"),
    )


GCP_ACTIONS = _generated_gcp_actions()


def derive_connector_deployments(
    hosting: Hosting,
    *,
    cluster_native: bool = False,
    form_choice: FormHosting | None = None,
) -> tuple[ConnectorDeployment, ...]:
    resolved: Hosting | FormHosting = hosting
    if hosting == "operator-selected":
        if form_choice is None:
            raise ValueError("operator-selected hosting follows the form choice")
        resolved = form_choice
    if resolved == "public":
        return ("saas-perimeter",)
    if resolved == "self-hosted":
        if cluster_native:
            return ("self-managed-kubernetes", "self-managed-docker")
        return ("self-managed-docker", "self-managed-kubernetes")
    raise ValueError(f"unknown hosting {hosting!r}")


def connector_topology_pages(
    deployments: tuple[ConnectorDeployment, ...],
) -> tuple[str, ...]:
    return tuple(_CONNECTOR_DEPLOYMENT_PAGE[item] for item in deployments)


@dataclass(frozen=True)
class ConnectionField:
    name: str
    obtained_how: str
    secret: bool = False


@dataclass(frozen=True)
class OperatorOnly:
    reason: str
    evidence: str


@dataclass(frozen=True)
class PrepStep:
    title: str
    instruction: str
    evidence: str
    operator_only: OperatorOnly | None = None


@dataclass(frozen=True)
class DocumentedMethod:
    name: str
    documentation: str
    prep_steps: tuple[PrepStep, ...] = ()
    typed_actions: tuple[TypedAction, ...] = ()
    connection_fields: tuple[ConnectionField, ...] = ()
    operator_inputs: tuple[OperatorInput, ...] = ()


Fit = Literal["preferred", "usable", "env-backed", "none"]
FITS: frozenset[str] = frozenset(("preferred", "usable", "env-backed", "none"))
ToolKind = Literal["cli", "mcp"]
KINDS: frozenset[str] = frozenset(("cli", "mcp"))


@dataclass(frozen=True)
class ConfigurationTool:
    fit: Fit
    kind: ToolKind = "cli"
    binary: str | None = None
    id: str | None = None
    name: str | None = None


@dataclass(frozen=True)
class OsInstall:
    method: str
    docs_url: str
    command: str | None = None


@dataclass(frozen=True)
class ToolInstall:
    auth_once: str
    credential_boundary: str
    docs_url: str
    windows: OsInstall
    macos: OsInstall
    linux: OsInstall
    presence: CatalogCheck
    capability: CatalogCheck
    auth_check: CatalogCheck
    platform_identity: PlatformIdentityQuery
    configure_once: ConfigureOnce | None = None


@dataclass(frozen=True)
class Coverage:
    name: str
    documentation: tuple[str, ...]
    configuration_tools: tuple[ConfigurationTool, ...] = ()
    prep_steps: tuple[PrepStep, ...] = ()
    typed_actions: tuple[TypedAction, ...] = ()
    operator_inputs: tuple[OperatorInput, ...] = ()


PathEvidence = Literal["ui-verified", "documentation-derived", "capture-required"]


@dataclass(frozen=True)
class IntegrationPath:
    name: str
    documentation: tuple[str, ...]
    path_evidence: PathEvidence = "documentation-derived"
    implicit: bool = False
    hosting: Hosting | None = None
    configuration_tools: tuple[ConfigurationTool, ...] = ()
    connection_fields: tuple[ConnectionField, ...] = ()
    prep_steps: tuple[PrepStep, ...] = ()
    operator_inputs: tuple[OperatorInput, ...] = ()
    typed_actions: tuple[TypedAction, ...] = ()


@dataclass(frozen=True)
class OptionalCapability:
    name: str
    documentation: tuple[str, ...]
    configuration_tools: tuple[ConfigurationTool, ...] = ()
    prep_steps: tuple[PrepStep, ...] = ()
    typed_actions: tuple[TypedAction, ...] = ()
    operator_inputs: tuple[OperatorInput, ...] = ()


@dataclass(frozen=True)
class LegacyIntegrationDefinition:
    tile: str
    target_selection: str | None
    category: str
    documentation: tuple[str, ...]
    setup_methods: tuple[DocumentedMethod, ...]
    authentication_methods: tuple[DocumentedMethod, ...]
    configuration_tools: tuple[ConfigurationTool, ...]
    hosting: Hosting
    summary: str
    connection_fields: tuple[ConnectionField, ...]
    coverages: tuple[Coverage, ...] = ()
    prep_steps: tuple[PrepStep, ...] = ()
    operator_inputs: tuple[OperatorInput, ...] = ()
    typed_actions: tuple[TypedAction, ...] = ()
    method_waivers: tuple[MethodWaiver, ...] = ()
    fork_census: tuple[CensusEntry, ...] = ()


@dataclass(frozen=True)
class IntegrationDefinition:
    tile: str
    category: str
    documentation: tuple[str, ...]
    integration_paths: tuple[IntegrationPath, ...]
    optional_capabilities: tuple[OptionalCapability, ...]
    configuration_tools: tuple[ConfigurationTool, ...]
    hosting: Hosting
    summary: str
    connection_fields: tuple[ConnectionField, ...]
    capture_required: bool = False
    path_evidence: PathEvidence = "documentation-derived"
    method_waivers: tuple[MethodWaiver, ...] = ()
    fork_census: tuple[CensusEntry, ...] = ()


def _field(name: str, obtained_how: str, *, secret: bool = False) -> ConnectionField:
    return ConnectionField(name=name, obtained_how=obtained_how, secret=secret)


def _step(
    title: str,
    instruction: str,
    evidence: str,
    operator_only: OperatorOnly | None = None,
) -> PrepStep:
    return PrepStep(
        title=title,
        instruction=instruction,
        evidence=evidence,
        operator_only=operator_only,
    )


def _method(
    name: str,
    documentation: str,
    prep_steps: tuple[PrepStep, ...] = (),
    typed_actions: tuple[TypedAction, ...] = (),
    connection_fields: tuple[ConnectionField, ...] = (),
    operator_inputs: tuple[OperatorInput, ...] = (),
) -> DocumentedMethod:
    return DocumentedMethod(
        name=name,
        documentation=documentation,
        prep_steps=prep_steps,
        typed_actions=typed_actions,
        connection_fields=connection_fields,
        operator_inputs=operator_inputs,
    )


def _coverage(
    name: str,
    documentation: str | tuple[str, ...],
    configuration_tools: tuple[ConfigurationTool, ...] = (),
    prep_steps: tuple[PrepStep, ...] = (),
    typed_actions: tuple[TypedAction, ...] = (),
    operator_inputs: tuple[OperatorInput, ...] = (),
) -> Coverage:
    pages = (documentation,) if isinstance(documentation, str) else documentation
    return Coverage(
        name=name,
        documentation=pages,
        configuration_tools=configuration_tools,
        prep_steps=prep_steps,
        typed_actions=typed_actions,
        operator_inputs=operator_inputs,
    )


def _tool(binary: str, fit: Fit, name: str | None = None) -> ConfigurationTool:
    return ConfigurationTool(fit=fit, kind="cli", binary=binary, name=name)


def _mcp(tool_id: str, fit: Fit = "usable", name: str | None = None) -> ConfigurationTool:
    return ConfigurationTool(fit=fit, kind="mcp", id=tool_id, name=name)


def _none(name: str | None = None) -> ConfigurationTool:
    return ConfigurationTool(fit="none", kind="cli", name=name)


def _os(method: str, docs_url: str, command: str | None = None) -> OsInstall:
    return OsInstall(method=method, docs_url=docs_url, command=command)


def _install(
    docs_url: str,
    auth_once: str,
    credential_boundary: str,
    windows: OsInstall,
    macos: OsInstall,
    linux: OsInstall,
    *,
    tool_key: str,
    configure_once: ConfigureOnce | None = None,
) -> ToolInstall:
    probes = probes_for(tool_key)
    presence = probes["presence"]
    capability = probes["capability"]
    auth_check = probes["auth"]
    identity = probes["identity"]
    assert isinstance(presence, CatalogCheck)
    assert isinstance(capability, CatalogCheck)
    assert isinstance(auth_check, CatalogCheck)
    assert isinstance(identity, PlatformIdentityQuery)
    return ToolInstall(
        auth_once=auth_once,
        credential_boundary=credential_boundary,
        docs_url=docs_url,
        windows=windows,
        macos=macos,
        linux=linux,
        presence=presence,
        capability=capability,
        auth_check=auth_check,
        platform_identity=identity,
        configure_once=configure_once,
    )


def _mcp_os(docs_url: str) -> OsInstall:
    return _os("mcp-config", docs_url, None)


def _mcp_install(
    docs_url: str,
    auth_once: str,
    tool_key: str,
    credential_boundary: str = "MCP client OAuth session or vendor token cache",
) -> ToolInstall:
    os_install = _mcp_os(docs_url)
    return _install(
        docs_url,
        auth_once,
        credential_boundary,
        os_install,
        os_install,
        os_install,
        tool_key=tool_key,
    )


def _row(
    tile: str,
    category: str,
    documentation: str | tuple[str, ...],
    configuration_tools: tuple[ConfigurationTool, ...],
    *,
    hosting: Hosting,
    summary: str,
    connection_fields: tuple[ConnectionField, ...],
    target_selection: str | None = None,
    setup_methods: tuple[DocumentedMethod, ...] = (),
    authentication_methods: tuple[DocumentedMethod, ...] = (),
    coverages: tuple[Coverage, ...] = (),
    prep_steps: tuple[PrepStep, ...] = (),
    operator_inputs: tuple[OperatorInput, ...] = (),
    typed_actions: tuple[TypedAction, ...] = (),
    method_waivers: tuple[MethodWaiver, ...] = (),
    fork_census: tuple[CensusEntry, ...] = (),
) -> LegacyIntegrationDefinition:
    pages = (documentation,) if isinstance(documentation, str) else documentation
    return LegacyIntegrationDefinition(
        tile=tile,
        target_selection=target_selection,
        category=category,
        documentation=pages,
        setup_methods=setup_methods,
        authentication_methods=authentication_methods,
        configuration_tools=configuration_tools,
        hosting=hosting,
        summary=summary,
        connection_fields=connection_fields,
        coverages=coverages,
        prep_steps=prep_steps,
        operator_inputs=operator_inputs,
        typed_actions=typed_actions,
        method_waivers=method_waivers,
        fork_census=fork_census,
    )


def _waiver(page: str, reason: str) -> MethodWaiver:
    return MethodWaiver(page=page, reason=reason)


def _census(
    page: str,
    documented_method: str,
    evidence: str,
    bound_method: str | None = None,
    waiver_reason: str | None = None,
) -> CensusEntry:
    return CensusEntry(
        page=page,
        documented_method=documented_method,
        evidence=evidence,
        bound_method=bound_method,
        waiver_reason=waiver_reason,
    )


CATALOG_GAP_WAIVERS: tuple[MethodWaiver, ...] = (
    _waiver('cloud-and-infrastructure/akeyless-vault/akeyless-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('cloud-and-infrastructure/akeyless-vault/akeyless-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/akeyless-vault.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/amazon-web-services/aws-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('cloud-and-infrastructure/amazon-web-services/aws-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/amazon-web-services.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/azure/hybrid-entra-ad.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('cloud-and-infrastructure/azure/permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('cloud-and-infrastructure/azure/troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/azure-devops/azure-devops-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/azure-devops.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/azure.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform/gcp-console-onboarding-manual.md', 'Duplicate ingest tree; the catalog cites google-cloud-platform-1.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform/gcp-permissions-reference.md', 'Duplicate ingest tree; the catalog cites google-cloud-platform-1.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform/gcp-pre-onboarding-check.md', 'Duplicate ingest tree; the catalog cites google-cloud-platform-1.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform/gcp-terraform-onboarding-automated.md', 'Duplicate ingest tree; the catalog cites google-cloud-platform-1.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform/gcp-troubleshooting-and-validation.md', 'Duplicate ingest tree; the catalog cites google-cloud-platform-1.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform/gcp-wif-terraform.md', 'Duplicate ingest tree; the catalog cites google-cloud-platform-1.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform/gcp-workload-identity-federation.md', 'Duplicate ingest tree; the catalog cites google-cloud-platform-1.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform-1/gcp-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform-1/gcp-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform-1.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/google-cloud-platform.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/hashicorp-vault.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/oci/oci-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('cloud-and-infrastructure/oci/oci-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/oci.md', 'GitBook section index; not a Documented method.'),
    _waiver('cloud-and-infrastructure/remote-file-system/copy-of-smb-file-shares-onboarding.md', 'GitBook duplicate copy of an already cited onboarding page; not a second Documented method.'),
    _waiver('cloud-and-infrastructure/remote-file-system/remote-file-system-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('cloud-and-infrastructure/remote-file-system.md', 'GitBook section index; not a Documented method.'),
    _waiver('collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/api-endpoints-in-use.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/classic-token-creation.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/dedicated-atlassian-user-creation.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/supported-data-sources.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('collaboration-and-saas/atlassian-ecosystem.md', 'GitBook section index; not a Documented method.'),
    _waiver('collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('collaboration-and-saas/google-workspace-google-drive.md', 'GitBook section index; not a Documented method.'),
    _waiver('collaboration-and-saas/microsoft-teams/microsoft-teams-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('collaboration-and-saas/microsoft-teams/microsoft-teams-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('collaboration-and-saas/microsoft-teams.md', 'GitBook section index; not a Documented method.'),
    _waiver('collaboration-and-saas/salesforce/salesforce-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('collaboration-and-saas/salesforce/salesforce-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('collaboration-and-saas/salesforce.md', 'GitBook section index; not a Documented method.'),
    _waiver('collaboration-and-saas/servicenow/servicenow-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('collaboration-and-saas/servicenow/servicenow-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('collaboration-and-saas/servicenow.md', 'GitBook section index; not a Documented method.'),
    _waiver('collaboration-and-saas/slack/slack-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('collaboration-and-saas/slack/slack-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('collaboration-and-saas/slack.md', 'GitBook section index; not a Documented method.'),
    _waiver('code-and-ci-cd/bitbucket.md', 'GitBook section index; not a Documented method.'),
    _waiver('code-and-ci-cd/buildkite/buildkite-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('code-and-ci-cd/buildkite/buildkite-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('code-and-ci-cd/buildkite.md', 'GitBook section index; not a Documented method.'),
    _waiver('code-and-ci-cd/entro-command-line-interface-cli/entro-cli-onboarding.md', 'Entro CLI / git-clone scanning; not an Add New Account tile.'),
    _waiver('code-and-ci-cd/entro-command-line-interface-cli/entro-cli-pre-commit-hook.md', 'Entro CLI / git-clone scanning; not an Add New Account tile.'),
    _waiver('code-and-ci-cd/entro-command-line-interface-cli/entro-cli-scan.md', 'Entro CLI / git-clone scanning; not an Add New Account tile.'),
    _waiver('code-and-ci-cd/entro-command-line-interface-cli.md', 'Entro CLI / git-clone scanning; not an Add New Account tile.'),
    _waiver('code-and-ci-cd/git-clone-scanning-optional.md', 'Entro CLI / git-clone scanning; not an Add New Account tile.'),
    _waiver('code-and-ci-cd/github/github-cloud-onboarding/githubcloud-app-auto-install.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('code-and-ci-cd/github/github-cloud-onboarding.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('code-and-ci-cd/github/github-cloud-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('code-and-ci-cd/github/github-cloud-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('code-and-ci-cd/github.md', 'GitBook section index; not a Documented method.'),
    _waiver('code-and-ci-cd/gitlab/gitlab-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('code-and-ci-cd/gitlab/gitlab-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('code-and-ci-cd/gitlab.md', 'GitBook section index; not a Documented method.'),
    _waiver('code-and-ci-cd/jenkins/jenkins-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('code-and-ci-cd/jenkins/jenkins-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('code-and-ci-cd/jenkins.md', 'GitBook section index; not a Documented method.'),
    _waiver('ai-and-agents/claude-entro-marketplace/mcp-audit.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/claude-entro-marketplace/plugin-installation.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/claude-entro-marketplace/secret-scanner.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/claude-entro-marketplace.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace/mcp-audit.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace/secret-scanner.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace-1/mcp-audit.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace-1/secret-scanner.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace-1.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/cursor-entro-marketplace.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/entro-webguard.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/gemini-mcp-audit/gemini-mcp-audit-onboarding.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/gemini-mcp-audit/gemini-mcp-audit-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('ai-and-agents/gemini-mcp-audit/gemini-mcp-audit-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('ai-and-agents/gemini-mcp-audit.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('ai-and-agents/n8n/n8n-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('ai-and-agents/n8n/n8n-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('ai-and-agents/n8n.md', 'GitBook section index; not a Documented method.'),
    _waiver('ai-and-agents/open-ai-agent-onboarding.md', 'IDE marketplace or agent plugin docs; not an Add New Account tile.'),
    _waiver('security-and-identity/active-directory/active-directory-onboarding-1.md', 'Documented onboarding path not yet carried as a Setup or Authentication method.'),
    _waiver('security-and-identity/active-directory/active-directory-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('security-and-identity/active-directory/active-directory-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('security-and-identity/active-directory.md', 'GitBook section index; not a Documented method.'),
    _waiver('security-and-identity/crowdstrike/crowdstrike-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('security-and-identity/crowdstrike/crowdstrike-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('security-and-identity/crowdstrike.md', 'GitBook section index; not a Documented method.'),
    _waiver('security-and-identity/okta/okta-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('security-and-identity/okta/okta-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('security-and-identity/okta.md', 'GitBook section index; not a Documented method.'),
    _waiver('security-and-identity/sailpoint-isc/sailpoint-identity-security-cloud-isc-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('security-and-identity/sailpoint-isc.md', 'GitBook section index; not a Documented method.'),
    _waiver('security-and-identity/snowflake/snowflake-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('security-and-identity/snowflake/snowflake-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('security-and-identity/snowflake.md', 'GitBook section index; not a Documented method.'),
    _waiver('security-and-identity/wiz/wiz-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('security-and-identity/wiz/wiz-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('security-and-identity/wiz.md', 'GitBook section index; not a Documented method.'),
    _waiver('container-registries/jfrog-artifactory/jfrog-artifactory-permissions-reference.md', 'Permissions reference; not a Documented method.'),
    _waiver('container-registries/jfrog-artifactory/jfrogartifactory-troubleshooting-and-validation.md', 'Troubleshooting companion; not a Documented method.'),
    _waiver('container-registries/jfrog-artifactory.md', 'GitBook section index; not a Documented method.'),
    _waiver('gemini-instructions/gemini.md', 'Gemini install instructions; not an Add New Account onboarding path.'),
    _waiver('gemini-instructions/install.md', 'Gemini install instructions; not an Add New Account onboarding path.'),
)

AZ_PWSH: tuple[ConfigurationTool, ...] = (
    _tool("az", "preferred"),
    _tool("pwsh", "preferred"),
    _mcp("azure-mcp"),
)
GH_CLOUD: tuple[ConfigurationTool, ...] = (
    _tool("gh", "usable"),
    _mcp("github-mcp"),
)
ATLASSIAN_CLOUD: tuple[ConfigurationTool, ...] = (
    _tool("acli", "usable"),
    _mcp("atlassian-rovo-mcp"),
)
PORTAL_ONLY: tuple[ConfigurationTool, ...] = (_none(),)


N8N_ONBOARDING = "ai-and-agents/n8n/n8n-onboarding.md"
COPILOT_ONBOARDING = (
    "ai-and-agents/microsoft-copilot-studio/onboarding-microsoft-copilot-studio.md"
)
AKEYLESS_ONBOARDING = "cloud-and-infrastructure/akeyless-vault/akeyless-onboarding.md"
AWS_CFN = "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps.md"
AWS_MANUAL = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-manual-onboarding/assume-role-link-to-entro.md"
)
AWS_MULTI = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-multiple-account-automation.md"
)
AWS_MANUAL_OVERVIEW = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-manual-onboarding.md"
)
AWS_IAM_POLICY = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-manual-onboarding/iam-policy-creation-steps.md"
)
AWS_IAM_ROLE = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-manual-onboarding/iam-role-creation-steps.md"
)
AWS_CLOUDTRAIL = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-manual-onboarding/aws-cloudtrail-s3-setup.md"
)
AWS_CLOUDTRAIL_CREATE = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-manual-onboarding/aws-cloudtrail-s3-setup/creating-trail-cloudtrail-console.md"
)
AWS_CLOUDTRAIL_CONFIGURE = (
    "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
    "aws-manual-onboarding/aws-cloudtrail-s3-setup/configure-trail-cloudtrail-console.md"
)
AZURE_AUTO = "cloud-and-infrastructure/azure/automated-powershell-onboarding.md"
AZURE_MANUAL = "cloud-and-infrastructure/azure/azure-manual-onboarding.md"
SHAREPOINT_ONBOARDING = "collaboration-and-saas/sharepoint/sharepoint-onboarding.md"
AZURE_DEVOPS = "cloud-and-infrastructure/azure-devops/azure-devops-onboarding.md"
GCP_SA = "cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-new.md"
GCP_WIF = (
    "cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual/"
    "gcp-workload-identity-federation-manual.md"
)
GCP_CONSOLE = (
    "cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual.md"
)
GCP_TERRAFORM = (
    "cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated.md"
)
GCP_TERRAFORM_WIF = (
    "cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated/"
    "gcp-workload-identity-federation-automated.md"
)
GCP_PRECHECK = "cloud-and-infrastructure/google-cloud-platform-1/gcp-pre-onboarding-check.md"
AZURE_POLICY = "cloud-and-infrastructure/azure/manual-policy-creation-overview.md"
AZURE_POLICY_CREATE = (
    "cloud-and-infrastructure/azure/manual-policy-creation-overview/policy-creation-steps.md"
)
AZURE_POLICY_ROLE = (
    "cloud-and-infrastructure/azure/manual-policy-creation-overview/role-creation-steps.md"
)
AZURE_POLICY_LINK = "cloud-and-infrastructure/azure/manual-policy-creation-overview/link-to-entro.md"
AZURE_POLICY_AUDIT = (
    "cloud-and-infrastructure/azure/manual-policy-creation-overview/audit-logs-setup.md"
)
AZURE_CONTINUOUS = "cloud-and-infrastructure/azure/azure-continuous-onboarding.md"
AZURE_PRECHECK = "cloud-and-infrastructure/azure/azure-pre-onboarding-check.md"
OKTA_CUSTOM_ROLE = "security-and-identity/okta/okta-custom-entro-role.md"
ATLASSIAN_LEGACY = (
    "collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/"
    "legacy-atlassian-jira-and-confluence-cloud.md"
)
VAULT = "cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-onboarding.md"
OCI = "cloud-and-infrastructure/oci/oci-onboarding.md"
SMB = "cloud-and-infrastructure/remote-file-system/smb-file-shares-onboarding.md"
SFTP = "cloud-and-infrastructure/remote-file-system/sftp-ssh-onboarding.md"
WINRM = "cloud-and-infrastructure/remote-file-system/winrm-onboarding.md"
BITBUCKET_CLOUD = "code-and-ci-cd/bitbucket/bitbucket-onboarding.md"
BITBUCKET_DC = (
    "code-and-ci-cd/bitbucket/bitbucket-data-center-workload-identity-federation.md"
)
GITHUB_NEW = "code-and-ci-cd/github/github-cloud-onboarding/githubcloud-app-manual-install.md"
GITHUB_FG = (
    "code-and-ci-cd/github/github-cloud-onboarding/github-cloud-finegrained-token-onboarding.md"
)
GITHUB_CLASSIC = (
    "code-and-ci-cd/github/github-cloud-onboarding/github-cloud-classic-token-onboarding.md"
)
GITHUB_ENTERPRISE = (
    "code-and-ci-cd/github/github-cloud-onboarding/github-cloud-classic-token-onboarding-1.md"
)
GITLAB = "code-and-ci-cd/gitlab/gitlab-onboarding.md"
JENKINS = "code-and-ci-cd/jenkins/jenkins-onboarding.md"
BUILDKITE = "code-and-ci-cd/buildkite/buildkite-onboarding.md"
JFROG = "container-registries/jfrog-artifactory/jfrog-artifactory-onboarding.md"
JIRA_CLOUD = (
    "collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/"
    "onboarding-atlassian-jira-cloud.md"
)
CONFLUENCE_CLOUD = (
    "collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/"
    "onboarding-atlassian-confluence-cloud.md"
)
JIRA_SERVER = (
    "collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/jira-server-on-premise.md"
)
CONFLUENCE_SERVER = (
    "collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/"
    "confluence-server-on-premise.md"
)
GDRIVE = "collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-onboarding.md"
TEAMS = "collaboration-and-saas/microsoft-teams/microsoft-teams-onboarding.md"
SERVICENOW = "collaboration-and-saas/servicenow/servicenow-onboarding.md"
SLACK_PRIVATE = "collaboration-and-saas/slack/slack-onboarding.md"
SLACK_GRID = "collaboration-and-saas/slack/slack-onboarding-1.md"
SALESFORCE = "collaboration-and-saas/salesforce/salesforce-onboarding.md"
AD = "security-and-identity/active-directory/active-directory-onboarding.md"
CROWDSTRIKE = "security-and-identity/crowdstrike/crowdstrike-onboarding.md"
OKTA = "security-and-identity/okta/okta-onboarding.md"
SNOWFLAKE = "security-and-identity/snowflake/snowflake-onboarding.md"
WIZ = "security-and-identity/wiz/wiz-onboarding.md"
SAILPOINT = (
    "security-and-identity/sailpoint-isc/sailpoint-identity-security-cloud-isc-onboarding-guide.md"
)
SHAREPOINT_COVERAGE_DOCS = (
    "collaboration-and-saas/sharepoint.md",
    SHAREPOINT_ONBOARDING,
    "collaboration-and-saas/sharepoint/sharepoint-permissions-reference.md",
    "collaboration-and-saas/sharepoint/sharepoint-troubleshooting-and-validation.md",
)
COPILOT_COVERAGE_DOCS = (
    "ai-and-agents/microsoft-copilot-studio.md",
    COPILOT_ONBOARDING,
    "ai-and-agents/microsoft-copilot-studio/microsoft-copilot-studio-permissions-reference.md",
    "ai-and-agents/microsoft-copilot-studio/troubleshooting-and-validation.md",
)
GITHUB_RTS = "code-and-ci-cd/github/github-real-time-scanning.md"
GITHUB_S3 = (
    "code-and-ci-cd/github/github-cloud-onboarding/github-cloud-enterprise-s3-logs-streaming.md"
)
CROWDSTRIKE_RTR_DOCS = (
    "security-and-identity/crowdstrike/falcon-rtr-secrets-scanner.md",
    "security-and-identity/crowdstrike/rtr-scanning.md",
    "security-and-identity/crowdstrike/ai-security-rtr-integration.md",
)
JIRA_RTS = (
    "collaboration-and-saas/atlassian-ecosystem/setting-up-jira-real-time-scanning.md"
)
SAILPOINT_AGGREGATION = (
    "security-and-identity/sailpoint-isc/sailpoint-entro-identities-aggregation.md"
)
GITHUB_RTS_COVERAGE = _coverage("Real-time scanning", GITHUB_RTS)
GITHUB_S3_COVERAGE = _coverage(
    "Enterprise S3 log streaming",
    GITHUB_S3,
    configuration_tools=(_tool("aws", "preferred"),),
    prep_steps=(
        _step(
            "Grant Entro IAM S3 read on the streaming bucket",
            "On the Entro IAM role in the AWS account that hosts the GitHub audit-log bucket, attach s3:ListBucket and s3:GetObject for that bucket.",
            "The Entro IAM role can list and get objects on the streaming bucket",
        ),
        _step(
            "Record the S3 bucket name",
            "After GitHub Enterprise audit log streaming to Amazon S3 is configured, record the bucket name for the Entro form.",
            "The bucket name is recorded and head-bucket succeeds",
        ),
    ),
    typed_actions=S3_COVERAGE_STEPS_ACTIONS,
    operator_inputs=(S3_BUCKET_INPUT,),
)

LABEL = "Operator-chosen label in Entro; not a secret."
ENV_TYPE = "Select Production, Development, or the matching environment type in the form."


def _env_field() -> ConnectionField:
    return _field("Environment", LABEL)


def _display_field() -> ConnectionField:
    return _field("Display Name", LABEL)


def _nickname_field() -> ConnectionField:
    return _field("Nickname", LABEL)


COPILOT_STUDIO_STEPS = (
    _step(
        "Add Copilot Studio Graph permissions",
        "On the same Entra app used for Microsoft Ecosystem, add the Copilot Studio / Power Platform Graph application permissions from Entro's Copilot Studio permissions list, then grant admin consent for the tenant.",
        "API permissions page shows the Copilot Studio scopes with admin consent granted",
    ),
    _step(
        "Provision the app into Dataverse environments",
        "Using the Power Platform CLI as a Global Administrator, add the Entro Entra app as an application user in each Power Platform environment that hosts Copilot Studio agents.",
        "Each target environment lists the Entro app under Application users",
    ),
)


_LEGACY_INTEGRATIONS: tuple[LegacyIntegrationDefinition, ...] = (
    _row(
        "n8n",
        "ai-and-agents",
        N8N_ONBOARDING,
        (_mcp("n8n-mcp"),),
        hosting="operator-selected",
        summary="Connect an n8n Cloud or self-hosted instance so Entro can discover credentials used in workflows.",
        connection_fields=(
            _env_field(),
            _display_field(),
            _field(
                "Instance URL",
                "n8n Cloud uses https://<instance>.app.n8n.cloud; self-hosted uses the instance base URL.",
            ),
            _field(
                "API Key",
                "In n8n, create an API key under Settings → n8n API and copy it once.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create an n8n API key",
                "In the n8n editor, open Settings → n8n API, create a key with access to the instance, and store it in the operator vault. Do not paste it into chat.",
                "n8n Settings shows an API key entry (value stored outside the session)",
            ),
        ),
        method_waivers=CATALOG_GAP_WAIVERS,
    ),
    _row(
        "Akeyless",
        "cloud-and-infrastructure",
        AKEYLESS_ONBOARDING,
        (_tool("akeyless", "preferred"),),
        hosting="public",
        summary="Connect Akeyless Vault so Entro can discover secrets through a read-only Universal Identity or API key.",
        connection_fields=(
            _field("Environment nickname", LABEL),
            _field(
                "Access ID",
                "From the Akeyless auth method (Universal Identity or API Key) created for Entro.",
            ),
            _field(
                "Access Key",
                "The matching Akeyless credential for that Access ID; store it in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create an Entro auth method in Akeyless",
                "In Akeyless, create a Universal Identity or API Key auth method named for Entro and note Access ID (and UID if Universal Identity).",
                "Akeyless lists the Entro auth method with an Access ID",
            ),
        ),
        typed_actions=AKEYLESS_ACTIONS,
        operator_inputs=(ENV_NICK,),
        authentication_methods=(
            _method("Universal Identity", AKEYLESS_ONBOARDING),
            _method("API Key", AKEYLESS_ONBOARDING),
        ),
        fork_census=(
            _census(
                AKEYLESS_ONBOARDING,
                "Universal Identity",
                "## Universal Identity Onboarding",
                bound_method="Universal Identity",
            ),
            _census(
                AKEYLESS_ONBOARDING,
                "API Key",
                "## API Key Onboarding",
                bound_method="API Key",
            ),
        ),
    ),
    _row(
        "AWS",
        "cloud-and-infrastructure",
        (
            AWS_CFN,
            AWS_MANUAL,
            AWS_MULTI,
            AWS_MANUAL_OVERVIEW,
            AWS_IAM_POLICY,
            AWS_IAM_ROLE,
        ),
        (_tool("aws", "preferred"), _tool("terraform", "usable"), _mcp("aws-mcp")),
        hosting="public",
        summary="Connect AWS accounts so Entro can discover secrets and NHIs via a read-only IAM role (CloudFormation, Terraform, or manual assume-role).",
        connection_fields=(
            _field("Environment", ENV_TYPE),
            _field(
                "AWS Role ARN",
                "IAM console → Roles → Entro role → copy Role ARN. CloudFormation creates this role; paste it for Assume Role.",
            ),
        ),
        setup_methods=(
            _method(
                "CloudFormation",
                AWS_CFN,
                prep_steps=(
                    _step(
                        "Launch CloudFormation from the Entro wizard",
                        "In Entro, open Add New Account → AWS, choose CloudFormation, and launch the stack from that wizard. Stay in the Entro UI until the stack finishes and the account shows Active. Do not create the stack from the AWS CLI.",
                        "Integrations → AWS lists the account as Active",
                        operator_only=OperatorOnly(
                            reason="Entro launches the CloudFormation stack from the Add New Account wizard; there is no CLI create-stack step on this path",
                            evidence="Integrations → AWS lists the account as Active",
                        ),
                    ),
                ),
            ),
            _method(
                "Manual Assume Role",
                AWS_MANUAL,
                prep_steps=(
                    _step(
                        "Create the read-only IAM policy and role",
                        "In IAM, create Entro's read-only policy, create a role trusted by Entro's AWS account with the wizard External ID, and attach the policy.",
                        "IAM shows the Entro role with the read-only policy and a matching trust policy",
                    ),
                    _step(
                        "Copy the Role ARN",
                        "Open the role and copy its ARN for the Entro form.",
                        "The Role ARN is recorded in the operator vault (not in chat)",
                    ),
                ),
                typed_actions=AWS_MANUAL_ACTIONS,
            ),
            _method(
                "Terraform",
                AWS_MULTI,
                prep_steps=(
                    _step(
                        "Initialize the Entro Terraform module",
                        "Copy Terraform-Entro.tf into the workspace and run terraform init.",
                        "terraform init completes and providers are installed",
                    ),
                    _step(
                        "Plan and apply the Entro IAM roles",
                        "Set external_id, remote_agent, and optional sns_topic_arn_suffix, then terraform apply so member accounts get EntroAWSIntegrationRole.",
                        "EntroAWSIntegrationRole and EntroReadOnlyAccess exist in member accounts",
                    ),
                    _step(
                        "Copy the Role ARN",
                        "Copy EntroAWSIntegrationRole ARN from a member account for the Entro form.",
                        "The Role ARN is recorded in the operator vault (not in chat)",
                    ),
                ),
                typed_actions=AWS_TERRAFORM_ACTIONS,
            ),
        ),
        coverages=(
            _coverage(
                "CloudTrail S3",
                (AWS_CLOUDTRAIL, AWS_CLOUDTRAIL_CREATE, AWS_CLOUDTRAIL_CONFIGURE),
            ),
        ),
        operator_inputs=(
            ENV_FIELD,
            EXTERNAL_ID,
            ROLE_NAME,
            REMOTE_AGENT,
            SNS_TOPIC_ARN_SUFFIX,
            TERRAFORM_DIR,
        ),
        fork_census=(
            _census(
                AWS_MULTI,
                "AWS CloudFormation StackSets",
                "**AWS CloudFormation StackSets**",
                waiver_reason=(
                    "Not a distinct Entro Add New Account setup choice; org-wide "
                    "StackSets is CloudFormation at organization scale, not a fourth Connect option."
                ),
            ),
            _census(
                AWS_MULTI,
                "Terraform (Infrastructure-as-Code)",
                "**Terraform (Infrastructure-as-Code)**",
                bound_method="Terraform",
            ),
        ),
    ),
    _row(
        "Microsoft Ecosystem",
        "cloud-and-infrastructure",
        (AZURE_AUTO, AZURE_MANUAL, AZURE_POLICY, AZURE_POLICY_CREATE, AZURE_POLICY_ROLE, AZURE_POLICY_LINK, AZURE_POLICY_AUDIT, AZURE_CONTINUOUS, AZURE_PRECHECK, SHAREPOINT_ONBOARDING, COPILOT_ONBOARDING),
        AZ_PWSH,
        hosting="public",
        summary="Connect Microsoft Entra / Azure / M365 so Entro can discover secrets and NHIs through a dedicated app registration.",
        connection_fields=(
            _field("Environment nickname", LABEL),
            _field(
                "Tenant ID",
                "Entra admin center → the app Overview → Directory (tenant) ID.",
            ),
            _field(
                "Azure Client ID",
                "Entra admin center → the app Overview → Application (client) ID.",
            ),
            _field(
                "Client Secret",
                "Certificates & secrets → new client secret; copy Value immediately into the operator vault.",
                secret=True,
            ),
        ),
        setup_methods=(
            _method(
                "Automated PowerShell",
                AZURE_AUTO,
                prep_steps=(
                    _step(
                        "Run Entro's Azure onboarding script",
                        "On a workstation with PowerShell 7 and Az modules, run Entro's automated onboarding script as a Global Administrator so it creates the app, secret, and required Graph / Azure permissions.",
                        "The script reports success and Entra shows the Entro app registration",
                    ),
                    _step(
                        "Record tenant, client ID, and secret",
                        "Copy Tenant ID, Application (client) ID, and the generated secret Value into the operator vault. Do not paste the secret into chat.",
                        "Tenant ID and Client ID are visible on the app Overview; secret Value is stored outside the session",
                    ),
                ),
                typed_actions=MS_AUTO_ACTIONS,
            ),
            _method(
                "Manual App Registration",
                AZURE_MANUAL,
                prep_steps=(
                    _step(
                        "Register the Entro app in Entra",
                        "In entra.microsoft.com, register a single-tenant app for Entro, create a client secret, and add the Graph / Azure application permissions from Entro's permissions reference, then grant admin consent.",
                        "App Overview shows Tenant ID and Client ID; API permissions show admin consent",
                    ),
                ),
                typed_actions=MS_MANUAL_ACTIONS,
            ),
            _method(
                "Manual Policy Creation",
                AZURE_POLICY,
                prep_steps=(
                    _step(
                        "Create the Entro Azure policy and custom role",
                        "Follow Entro's Manual Policy Creation flow: create the policy, define the custom role, then link Tenant ID, Client ID, and secret in Entro.",
                        "Azure shows the Entro policy and custom role; Entro form has Tenant ID and Client ID",
                        operator_only=OperatorOnly(
                            reason="Azure Portal policy and custom-role blades have no complete CLI equivalent in Entro's guide",
                            evidence="The Manual Policy Creation flow is divided into Azure Portal pages",
                        ),
                    ),
                ),
            ),
            _method(
                "Azure Continuous Onboarding",
                AZURE_CONTINUOUS,
                prep_steps=(
                    _step(
                        "Enable continuous onboarding of subscriptions",
                        "Deploy Entro's Azure Function App against the Tenant Root management group so new subscriptions and Key Vaults onboard without repeating the wizard.",
                        "The Function App is running and new subscriptions appear in Entro without a second wizard run",
                        operator_only=OperatorOnly(
                            reason="Function App and management-group wiring is documented as Azure Portal / ARM, not a preferred CLI plan",
                            evidence="The setup leverages Microsoft Azure Functions to periodically invoke Entro's onboarding API",
                        ),
                    ),
                ),
            ),
        ),
        coverages=(
            _coverage("SharePoint / OneDrive", SHAREPOINT_COVERAGE_DOCS),
            _coverage(
                "Copilot Studio",
                COPILOT_COVERAGE_DOCS,
                configuration_tools=(_tool("pac", "preferred"),),
                prep_steps=COPILOT_STUDIO_STEPS,
                typed_actions=COPILOT_ACTIONS,
                operator_inputs=(DATAVERSE_ENV_ID,),
            ),
        ),
        operator_inputs=(ENV_NICK, ENTRA_APP_NAME),
    ),
    _row(
        "Azure DevOps",
        "cloud-and-infrastructure",
        AZURE_DEVOPS,
        AZ_PWSH,
        hosting="public",
        summary="Connect Azure DevOps organizations through an Entra app so Entro can discover secrets in pipelines and repos.",
        connection_fields=(
            _field("Environment Nickname", LABEL),
            _field("Tenant ID", "Entra app Overview → Directory (tenant) ID."),
            _field("Client ID", "Entra app Overview → Application (client) ID."),
            _field(
                "Client Secret",
                "Certificates & secrets Value for the Entro DevOps app; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create or reuse the Entro Entra app",
                "Register (or reuse) an Entra app with Azure DevOps permissions from Entro's onboarding guide and grant admin consent.",
                "Entra shows the app with Azure DevOps permissions consented",
            ),
        ),
        operator_inputs=(ENV_NICK_ADO, ENTRA_APP_NAME),
        typed_actions=ADO_ACTIONS,
    ),
    _row(
        "Google Cloud Platform",
        "cloud-and-infrastructure",
        (GCP_SA, GCP_WIF, GCP_CONSOLE, GCP_TERRAFORM, GCP_TERRAFORM_WIF, GCP_PRECHECK),
        (_tool("gcloud", "preferred"), _tool("terraform", "usable")),
        hosting="public",
        summary="Connect a GCP organization so Entro can discover secrets and NHIs using Private Key Integration or Workload Identity Federation.",
        connection_fields=(
            _field(
                "Organization Domain",
                "The primary domain attached to the GCP organization, such as example.com.",
            ),
        ),
        setup_methods=(
            _method(
                "Console manual",
                GCP_CONSOLE,
                prep_steps=(
                    _step(
                        "Run the GCP pre-onboarding check",
                        "Save and run Entro's GCP pre-onboarding check so report.txt shows project access and logging before creating the reader identity.",
                        "report.txt lists organization projects with role and logging results",
                    ),
                    _step(
                        "Enable Terraform-default GCP APIs",
                        "Run the generated, checksummed API artifact. It enables the pinned Terraform defaults on the host project and on active organization projects discovered from the cataloged organization ID; billing-dependent defaults follow the pinned Terraform condition without an API-selection prompt.",
                        "APIs & Services shows 8 host-project defaults, 3 organization-project defaults, and the 2 billing-dependent defaults where the Terraform condition applies",
                    ),
                    _step(
                        "Create the Entro reader identity",
                        "Describe the requested service-account email first. Stop before grants if it already exists; otherwise create only the service account in the host project.",
                        "IAM & Admin → Service Accounts shows the newly created Entro reader account",
                    ),
                    _step(
                        "Grant the Terraform-derived Entro IAM roles",
                        "Run the generated, checksummed IAM artifact after service-account creation. It creates an unused Terraform-compatible Entro Logging Role and grants that role plus the 12 pinned predefined organization roles.",
                        "Organization IAM shows the service account with the custom Entro Logging Role and 12 predefined role bindings",
                    ),
                    _step(
                        "Configure organization audit logs",
                        "In the Google Cloud console, open https://console.cloud.google.com/iam-admin/audit for the organization. Configure Data Read and Data Write audit logging for Secret Manager API, Cloud Functions API, and Identity and Access Management (IAM) API, preserving existing exempted principals and settings.",
                        "The organization Audit Logs page visibly shows Data Read and Data Write enabled for the three required services",
                        operator_only=OperatorOnly(
                            reason="The documented command route replaces the organization IAM policy; Connect keeps this organization-wide merge-sensitive change in the Google Cloud console",
                            evidence="The organization Audit Logs page shows Data Read and Data Write enabled for Secret Manager API, Cloud Functions API, and Identity and Access Management (IAM) API",
                        ),
                    ),
                ),
                typed_actions=GCP_ACTIONS,
            ),
            _method(
                "Terraform automated",
                GCP_TERRAFORM,
                prep_steps=(
                    _step(
                        "Initialize and apply Entro's GCP Terraform",
                        "Download Entro's GCP Terraform zip. Use the tfvars file named by the locked authentication method, then run terraform init, plan, and apply.",
                        "Terraform apply completes and the service account plus the locked authentication credential exist",
                        operator_only=OperatorOnly(
                            reason="Entro ships a zip of Terraform files the operator applies from their own workspace; not a preferred gcloud typed-action plan",
                            evidence="Download the provided Terraform files, update variables, and execute as instructed",
                        ),
                    ),
                ),
                operator_inputs=(TERRAFORM_DIR,),
            ),
        ),
        authentication_methods=(
            _method(
                "Private Key Integration",
                GCP_SA,
                prep_steps=(
                    _step(
                        "Create the private key credential",
                        "For Console manual, create a JSON key on the Entro service account and vault the downloaded file. For Terraform automated, fill tf-var-files/create-service-account-key.tfvars; it sets service_account_key_create_condition=true and enable_workload_identity_federation=false.",
                        "A service-account private-key JSON file is stored in the operator vault",
                    ),
                ),
                connection_fields=(
                    _field(
                        "Private Key JSON",
                        "Upload the JSON key created for the Entro service account; keep its value in the operator vault.",
                        secret=True,
                    ),
                ),
            ),
            _method(
                "Workload Identity Federation",
                GCP_WIF,
                prep_steps=(
                    _step(
                        "Create the keyless federation credential",
                        "Copy Entro's AWS role ARN from the WIF connection form. For Console manual, create an AWS workload identity pool/provider and grant that principal service-account impersonation. For Terraform automated, fill tf-var-files/wif-setup.tfvars; it sets service_account_key_create_condition=false and enable_workload_identity_federation=true.",
                        "The WIF provider trusts only Entro's AWS role and its configuration JSON is ready for upload",
                    ),
                ),
                connection_fields=(
                    _field(
                        "Workload Identity Federation Configuration JSON",
                        "Upload the external-account configuration downloaded from GCP or emitted by Terraform output wif_config.",
                    ),
                ),
                operator_inputs=(GCP_ENTRO_AWS_ROLE_ARN,),
            ),
        ),
        operator_inputs=(
            GCP_ORGANIZATION_DOMAIN,
            GCP_ORGANIZATION_ID,
            GCP_PROJECT_ID,
            GCP_SERVICE_ACCOUNT,
        ),
        fork_census=(
            _census(
                GCP_TERRAFORM,
                "Terraform automated onboarding",
                "This method allows you to onboard Entro to GCP using Terraform for automated, repeatable configuration.",
                bound_method="Terraform automated",
            ),
            _census(
                GCP_CONSOLE,
                "Console manual onboarding",
                "GCP Console Onboarding (Manual)",
                bound_method="Console manual",
            ),
        ),
    ),
    _row(
        "HashiCorp Vault",
        "cloud-and-infrastructure",
        VAULT,
        (_tool("vault", "preferred"),),
        hosting="self-hosted",
        summary="Connect a HashiCorp Vault cluster using a read-only ACL policy and a renewable token.",
        connection_fields=(
            _env_field(),
            _field(
                "Vault Server URL",
                "Base URL of the Vault API including scheme and port (from the Vault UI or VAULT_ADDR).",
            ),
            _field(
                "Access Token",
                "Token created with the entro-policy; copy once from `vault token create` into the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create the entro-policy ACL",
                "In Vault, add an ACL policy named entro-policy with Entro's documented list/read capabilities (no write on secrets).",
                "Policies list includes entro-policy",
            ),
            _step(
                "Create a renewable token",
                "After local `vault login`, create a token bound to entro-policy and store it in the operator vault. Do not paste the token into chat.",
                "Vault reports a token created with policy entro-policy (value stored outside the session)",
            ),
        ),
        operator_inputs=(ENV_FIELD,),
        typed_actions=VAULT_ACTIONS,
    ),
    _row(
        "Oracle Cloud Infrastructure",
        "cloud-and-infrastructure",
        OCI,
        (_tool("oci", "preferred"),),
        hosting="public",
        summary="Connect an OCI tenancy so Entro can discover secrets in Vault and related services.",
        connection_fields=(
            _field("Environment Nickname", LABEL),
            _field("Tenancy OCID", "OCI Console → Tenancy details → OCID."),
            _field("User OCID", "Identity → Users → the Entro user OCID."),
            _field("Fingerprint", "API keys on that user → fingerprint."),
            _field(
                "Private Key",
                "PEM API signing key downloaded when the API key was added; store in the operator vault.",
                secret=True,
            ),
            _field("Region", "OCI region identifier for the home region (Console region selector)."),
        ),
        prep_steps=(
            _step(
                "Create an Entro OCI user and API key",
                "Create a user with Entro's read-only policies, add an API signing key, and record tenancy OCID, user OCID, fingerprint, and private key in the operator vault.",
                "Identity shows the user, policy, and an API key fingerprint",
            ),
        ),
        operator_inputs=(ENV_NICK_ADO,),
        typed_actions=OCI_ACTIONS,
    ),
    _row(
        "File Shares Scanning",
        "cloud-and-infrastructure",
        SMB,
        PORTAL_ONLY,
        hosting="self-hosted",
        target_selection="SMB",
        summary="Scan SMB file shares from a Connector that can reach the share over port 445.",
        connection_fields=(
            _nickname_field(),
            _field(
                "Username",
                "Domain-qualified service account that can read the share (e.g. DOMAIN\\user).",
            ),
            _field("Password", "Password for that service account; store in the operator vault.", secret=True),
            _field(
                "File Share IP or Hostname",
                "Host:445 of the file server as shown in Entro's SMB form.",
            ),
        ),
        prep_steps=(
            _step(
                "Create a read-only share account",
                "On the file server or AD, create a service account with read access to the target shares and confirm port 445 is reachable from the Connector host.",
                "The account can list the share and the Connector host reaches host:445",
            ),
        ),
        setup_methods=(
            _method(
                "Manual Onboarding",
                SMB,
                prep_steps=(
                    _step(
                        "Create a read-only share account",
                        "On the file server or AD, create a service account with read access to the target shares and confirm port 445 is reachable from the Connector host.",
                        "The account can list the share and the Connector host reaches host:445",
                    ),
                ),
            ),
            _method(
                "JSON Upload",
                SMB,
                prep_steps=(
                    _step(
                        "Prepare the SMB JSON template",
                        "Fill Entro's SMB JSON template for each server and upload it on Add New Account instead of entering one share at a time.",
                        "Entro accepts the JSON upload and lists the shares",
                    ),
                ),
            ),
        ),
        fork_census=(
            _census(
                SMB,
                "Manual Onboarding",
                "**Manual Onboarding**",
                bound_method="Manual Onboarding",
            ),
            _census(
                SMB,
                "JSON Upload",
                "**JSON Upload**",
                bound_method="JSON Upload",
            ),
        ),
    ),
    _row(
        "File Shares Scanning",
        "cloud-and-infrastructure",
        SFTP,
        PORTAL_ONLY,
        hosting="self-hosted",
        target_selection="SFTP (SSH)",
        summary="Scan remote directories over SFTP from a Connector that can reach the SSH host.",
        connection_fields=(
            _nickname_field(),
            _field("Host", "DNS or IP of the SFTP server (optionally with port)."),
            _field("Username", "SFTP user with read access to the target directories."),
            _field(
                "Private Key",
                "SSH private key for that user if not using a password; store in the operator vault.",
                secret=True,
            ),
            _field(
                "Passphrase (optional)",
                "Passphrase for the private key if it is encrypted; omit when unused.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Provision an SFTP reader",
                "Create an SFTP user limited to the directories Entro should scan and confirm SSH reachability from the Connector host.",
                "SFTP login from the Connector host lists the target directories",
            ),
        ),
    ),
    _row(
        "File Shares Scanning",
        "cloud-and-infrastructure",
        WINRM,
        PORTAL_ONLY,
        hosting="self-hosted",
        target_selection="WinRM",
        summary="Scan Windows hosts over WinRM from a Connector on the same network.",
        connection_fields=(
            _nickname_field(),
            _field("Host", "DNS or IP of the Windows host with WinRM enabled."),
            _field("Username", "WinRM user with read access to the target paths."),
            _field(
                "Password",
                "Password for that user when not using a key; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Enable WinRM for the Connector",
                "On each Windows host, enable WinRM, allow the Connector source, and grant a service account read access to the directories to scan.",
                "WinRM responds from the Connector host with the service account",
            ),
        ),
    ),
    _row(
        "BitBucket",
        "code-and-ci-cd",
        BITBUCKET_CLOUD,
        (_mcp("atlassian-rovo-mcp"),),
        hosting="public",
        target_selection="BitBucket Cloud",
        summary="Connect Bitbucket Cloud workspaces so Entro can scan repositories for secrets.",
        connection_fields=(
            _field("Environment", LABEL),
            _field("Environment Type", ENV_TYPE),
            _field(
                "Workspace",
                "Bitbucket workspace slug from the workspace URL or settings.",
            ),
            _field(
                "Access Token",
                "Repository or workspace access token with read scope; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Bitbucket access token",
                "In Bitbucket Cloud, create a workspace or repository access token with read access for Entro and store it in the operator vault.",
                "Bitbucket shows an access token named for Entro (value stored outside the session)",
            ),
        ),
    ),
    _row(
        "BitBucket",
        "code-and-ci-cd",
        BITBUCKET_DC,
        PORTAL_ONLY,
        hosting="self-hosted",
        target_selection="BitBucket Data Center",
        summary="Connect a self-hosted Bitbucket Data Center using workload identity federation as documented by Entro.",
        connection_fields=(
            _field("Environment", LABEL),
            _field(
                "Bitbucket Base URL",
                "HTTPS URL of the Data Center instance reachable from the Connector.",
            ),
        ),
        prep_steps=(
            _step(
                "Configure Data Center federation",
                "Follow Entro's Bitbucket Data Center workload-identity steps so the instance trusts Entro without a long-lived PAT in chat.",
                "Bitbucket Data Center shows the Entro application link or federation entry",
            ),
        ),
    ),
    _row(
        "GitHub",
        "code-and-ci-cd",
        GITHUB_NEW,
        GH_CLOUD,
        hosting="public",
        target_selection="GitHub Cloud - New",
        summary="Connect GitHub Cloud by installing Entro's GitHub App on the organization (no PAT).",
        connection_fields=(
            _display_field(),
            _field("Company Nickname", LABEL),
        ),
        prep_steps=(
            _step(
                "Install the Entro GitHub App",
                "From Entro Add New Account → GitHub Cloud - New, choose Install on GitHub Organization, pick the org or repos, and approve the App permissions. Entro redirects back after install.",
                "GitHub Organization Settings → GitHub Apps lists the Entro app as installed",
            ),
        ),
        coverages=(GITHUB_RTS_COVERAGE, GITHUB_S3_COVERAGE),
        operator_inputs=(DISPLAY, COMPANY_NICK),
    ),
    _row(
        "GitHub",
        "code-and-ci-cd",
        (GITHUB_FG, GITHUB_CLASSIC),
        GH_CLOUD,
        hosting="public",
        target_selection="GitHub Cloud - Legacy",
        summary="Connect GitHub Cloud with a fine-grained or classic personal access token when the GitHub App path is not used.",
        connection_fields=(
            _display_field(),
            _field("Company Nickname", LABEL),
            _field("Environment Type", ENV_TYPE),
            _field(
                "Github access token",
                "Fine-grained or classic PAT created for Entro with repo read access; store in the operator vault. Never paste the token into chat.",
                secret=True,
            ),
        ),
        authentication_methods=(
            _method("Fine-grained Token", GITHUB_FG),
            _method("Classic Token", GITHUB_CLASSIC),
        ),
        prep_steps=(
            _step(
                "Create a GitHub PAT for Entro",
                "In GitHub Settings → Developer settings, create a fine-grained token (preferred) or classic token with Entro's documented read scopes, no expiration if policy allows, and store it in the operator vault.",
                "GitHub lists a PAT named Entro (value stored outside the session)",
            ),
        ),
        coverages=(GITHUB_RTS_COVERAGE, GITHUB_S3_COVERAGE),
        operator_inputs=(DISPLAY, COMPANY_NICK, ENV_TYPE_INPUT),
    ),
    _row(
        "GitHub",
        "code-and-ci-cd",
        GITHUB_ENTERPRISE,
        (_tool("gh", "usable"),),
        hosting="self-hosted",
        target_selection="GitHub Enterprise Server",
        summary="Connect GitHub Enterprise Server with a PAT so the Connector can reach the GHES hostname.",
        connection_fields=(
            _display_field(),
            _field("Environment Type", ENV_TYPE),
            _field(
                "Github server hostname",
                "GHES hostname as operators use it in the browser (no token).",
            ),
            _field(
                "Github access token",
                "Classic PAT generated on the GHES instance; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a GHES PAT",
                "On the GitHub Enterprise Server, create a classic PAT with Entro's documented scopes and confirm the Connector can reach the hostname.",
                "GHES shows a PAT named Entro and the Connector resolves the hostname",
            ),
        ),
        coverages=(GITHUB_RTS_COVERAGE,),
    ),
    _row(
        "GitLab",
        "code-and-ci-cd",
        GITLAB,
        (_tool("glab", "preferred"),),
        hosting="operator-selected",
        summary="Connect GitLab.com or self-managed GitLab so Entro can scan projects for secrets.",
        connection_fields=(
            _nickname_field(),
            _field(
                "GitLab URL",
                "https://gitlab.com or the self-managed base URL.",
            ),
            _field(
                "Access Token",
                "Group or project access token with read_api/read_repository; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a GitLab access token",
                "In GitLab, create a group or project access token with Entro's read scopes and store it in the operator vault.",
                "GitLab shows an access token named for Entro (value stored outside the session)",
            ),
        ),
        operator_inputs=(NICKNAME,),
        typed_actions=GITLAB_ACTIONS,
        authentication_methods=(
            _method("Group Access Token", GITLAB),
            _method("Personal Access Token", GITLAB),
        ),
        fork_census=(
            _census(
                GITLAB,
                "Group Access Token",
                "Option 1: Generate a Group Access Token (Preferred)",
                bound_method="Group Access Token",
            ),
            _census(
                GITLAB,
                "Personal Access Token",
                "Option 2: Generate a Personal Access Token",
                bound_method="Personal Access Token",
            ),
        ),
    ),
    _row(
        "Jenkins",
        "code-and-ci-cd",
        JENKINS,
        (_tool("jenkins-cli", "preferred"),),
        hosting="self-hosted",
        summary="Connect a Jenkins controller so Entro can discover credentials and pipeline secrets.",
        connection_fields=(
            _field("Environment Nickname", LABEL),
            _field("Environment Type", ENV_TYPE),
            _field("Jenkins URL", "Controller base URL reachable from the Connector."),
            _field(
                "API Token",
                "Jenkins user API token generated for Entro; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Jenkins API user",
                "On the Jenkins controller, create a user with read access to jobs and credentials metadata, generate an API token, and confirm the Connector can reach the controller URL.",
                "Jenkins shows the Entro user and the Connector loads the login page",
            ),
        ),
        operator_inputs=(ENV_NICK_ADO, ENV_TYPE_INPUT),
        typed_actions=JENKINS_ACTIONS,
    ),
    _row(
        "BuildKite",
        "code-and-ci-cd",
        BUILDKITE,
        (_tool("bk", "usable"),),
        hosting="public",
        summary="Connect a Buildkite organization so Entro can discover pipeline secrets.",
        connection_fields=(
            _field("Environment Nickname", LABEL),
            _field("Environment Type", ENV_TYPE),
            _field(
                "API Token",
                "Buildkite API access token with Entro's documented read scopes; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Buildkite API token",
                "In Buildkite Personal Settings → API Access Tokens, create a token for Entro with organization read scopes and store it in the operator vault.",
                "Buildkite lists an API token named for Entro (value stored outside the session)",
            ),
        ),
    ),
    _row(
        "JFrog Artifactory",
        "container-registries",
        JFROG,
        (_tool("jf", "preferred"),),
        hosting="self-hosted",
        summary="Connect JFrog Artifactory so Entro can discover tokens and secrets in the instance.",
        connection_fields=(
            _field(
                "Artifactory URL",
                "Base URL of the JFrog instance (https://artifactory.example.com).",
            ),
            _field("Username", "Username of the account that created the access token."),
            _field(
                "Access Token",
                "Scoped read-only access token from JFrog User Profile → Generate Identity Token.",
                secret=True,
            ),
            _field("Environment Nickname", LABEL),
            _field("Environment Type", ENV_TYPE),
        ),
        prep_steps=(
            _step(
                "Create a read-only Artifactory token",
                "In JFrog, create a user or identity token with Entro's read scopes and store the token in the operator vault.",
                "Artifactory shows the Entro token (value stored outside the session)",
            ),
        ),
        operator_inputs=(ENV_NICK_ADO, ENV_TYPE_INPUT),
        typed_actions=JFROG_ACTIONS,
    ),
    _row(
        "Atlassian",
        "collaboration-and-saas",
        (JIRA_CLOUD, ATLASSIAN_LEGACY),

        ATLASSIAN_CLOUD,
        hosting="public",
        target_selection="Jira Cloud",
        summary="Connect Jira Cloud so Entro can discover secrets in issues and attachments.",
        connection_fields=(
            _field("Environment", ENV_TYPE),
            _field("Atlassian URL", "Site URL such as https://<org>.atlassian.net from the browser."),
            _field(
                "Jira Cloud ID",
                "Cloud ID from Atlassian admin or Entro's documented lookup for the Jira site.",
            ),
            _field("Atlassian Username", "Atlassian account email used to create the API token."),
            _field(
                "Atlassian API Token",
                "API token from https://id.atlassian.com/manage-profile/security/api-tokens; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create an Atlassian API token",
                "Sign in as a Jira admin, create an API token, and note the site URL and Jira Cloud ID.",
                "id.atlassian.com lists an API token (value stored outside the session) and the Cloud ID is recorded",
            ),
        ),
        coverages=(_coverage("Jira real-time scanning", JIRA_RTS),),
        fork_census=(
            _census(
                ATLASSIAN_LEGACY,
                "Legacy combined Jira and Confluence Cloud",
                "legacy-atlassian-jira-and-confluence-cloud",
                waiver_reason=(
                    "Legacy combined Cloud page; current rows cite the split Jira Cloud "
                    "and Confluence Cloud onboarding pages."
                ),
            ),
        ),
    ),
    _row(
        "Atlassian",
        "collaboration-and-saas",
        (CONFLUENCE_CLOUD, ATLASSIAN_LEGACY),
        ATLASSIAN_CLOUD,
        hosting="public",
        target_selection="Confluence Cloud",
        summary="Connect Confluence Cloud so Entro can discover secrets in pages and attachments.",
        connection_fields=(
            _field("Environment", ENV_TYPE),
            _field("Atlassian URL", "Site URL such as https://<org>.atlassian.net."),
            _field(
                "Confluence Cloud ID",
                "Cloud ID for the Confluence site from Atlassian admin.",
            ),
            _field("Atlassian Username", "Atlassian account email used to create the API token."),
            _field(
                "Atlassian API Token",
                "API token from id.atlassian.com; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create an Atlassian API token",
                "As a Confluence admin, create an API token and record the site URL and Confluence Cloud ID.",
                "An API token exists (value stored outside the session) and the Cloud ID is recorded",
            ),
        ),
    ),
    _row(
        "Atlassian",
        "collaboration-and-saas",
        (JIRA_SERVER, ATLASSIAN_LEGACY),
        PORTAL_ONLY,
        hosting="self-hosted",
        target_selection="Jira Server",
        summary="Connect Jira Server / Data Center so the Connector can scan issues on-premises.",
        connection_fields=(
            _field("Environment", ENV_TYPE),
            _field("Jira Base URL", "HTTPS URL of the Jira Server reachable from the Connector."),
            _field(
                "Personal Access Token",
                "Jira Server PAT for a service account; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Jira Server PAT",
                "On Jira Server, create a service user with read access and a personal access token; confirm Connector reachability.",
                "Jira shows the PAT user and the Connector loads the base URL",
            ),
        ),
    ),
    _row(
        "Atlassian",
        "collaboration-and-saas",
        (CONFLUENCE_SERVER, ATLASSIAN_LEGACY),
        PORTAL_ONLY,
        hosting="self-hosted",
        target_selection="Confluence Server",
        summary="Connect Confluence Server / Data Center so the Connector can scan pages on-premises.",
        connection_fields=(
            _field("Environment", ENV_TYPE),
            _field(
                "Confluence Base URL",
                "HTTPS URL of Confluence Server reachable from the Connector.",
            ),
            _field(
                "Personal Access Token",
                "Confluence Server PAT; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Confluence Server PAT",
                "Create a read-only service user and PAT on Confluence Server and confirm Connector reachability.",
                "Confluence shows the PAT user and the Connector loads the base URL",
            ),
        ),
    ),
    _row(
        "Google Workspace (GDrive)",
        "collaboration-and-saas",
        GDRIVE,
        (_tool("gcloud", "usable"),),
        hosting="public",
        summary="Connect Google Drive / Workspace so Entro can discover exposed secrets in Drive.",
        connection_fields=(
            _field(
                "Client ID",
                "GCP Console → the Workspace integration service account → Unique ID / Client ID.",
            ),
            _field(
                "Service Account Key JSON",
                "JSON key for that service account when using key auth; store in the operator vault.",
                secret=True,
            ),
        ),
        authentication_methods=(
            _method("Service Account Key", GDRIVE),
            _method("Workload Identity Federation", GDRIVE),
        ),
        prep_steps=(
            _step(
                "Enable Domain-wide Delegation",
                "In Google Workspace Admin, authorize the service account Client ID with Entro's Drive scopes, or complete WIF as documented.",
                "Admin console shows the Client ID with the Drive scopes (or WIF is bound)",
            ),
        ),
    ),
    _row(
        "Microsoft Teams",
        "collaboration-and-saas",
        TEAMS,
        AZ_PWSH,
        hosting="public",
        summary="Connect Microsoft Teams so Entro can discover secrets in Teams content using an Entra app.",
        connection_fields=(
            _field("Tenant ID", "Entra app Overview → Directory (tenant) ID."),
            _field("Client ID", "Entra app Overview → Application (client) ID."),
            _field(
                "Client Secret",
                "Client secret Value for the Teams-capable Entro app; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Grant Teams Graph permissions",
                "On the Entro Entra app, add Teams-related application permissions from Entro's Teams onboarding guide and grant admin consent.",
                "API permissions show Teams scopes with admin consent",
            ),
        ),
        typed_actions=TEAMS_ACTIONS,
    ),
    _row(
        "ServiceNow",
        "collaboration-and-saas",
        SERVICENOW,
        PORTAL_ONLY,
        hosting="public",
        summary="Connect a ServiceNow instance using a dedicated integration user and REST API key.",
        connection_fields=(
            _env_field(),
            _display_field(),
            _field(
                "ServiceNow URL",
                "Instance URL https://<yourDomain>.service-now.com.",
            ),
            _field(
                "Access Token",
                "REST API key token from System Web Services → REST API Key; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create the integration user and API key",
                "In ServiceNow, create the Entro integration user, auth scope, and REST API key; copy the token Value once into the operator vault.",
                "ServiceNow lists the Entro user and an API key (value stored outside the session)",
            ),
        ),
    ),
    _row(
        "Slack",
        "collaboration-and-saas",
        SLACK_PRIVATE,
        PORTAL_ONLY,
        hosting="public",
        target_selection="Slack Private App",
        summary="Connect a standard Slack workspace via an Entro Slack app installed from a manifest.",
        connection_fields=(
            _field(
                "Bot User OAuth Token",
                "From the Slack app OAuth & Permissions page after install (xoxb- prefix). Store in the operator vault.",
                secret=True,
            ),
            _field(
                "User OAuth Token",
                "User OAuth token from the same page (xoxp- prefix). Store in the operator vault.",
                secret=True,
            ),
            _field(
                "App-Level Token",
                "Socket-mode app-level token (xapp- prefix) generated on Basic Information → App-Level Tokens.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create the Slack app from Entro's manifest",
                "At api.slack.com/apps, create an app from manifest, paste Entro's manifest, install it to the workspace, and generate the socket-mode app-level token.",
                "The workspace Apps list includes Entro Security",
            ),
            _step(
                "Copy OAuth tokens into the vault",
                "On OAuth & Permissions, copy Bot and User tokens into the operator vault. Do not paste them into chat.",
                "OAuth & Permissions shows installed tokens (values stored outside the session)",
            ),
        ),
    ),
    _row(
        "Slack",
        "collaboration-and-saas",
        SLACK_GRID,
        PORTAL_ONLY,
        hosting="public",
        target_selection="Slack Enterprise Grid App",
        summary="Connect Slack Enterprise Grid by installing Entro's org-level app and picking the workspace in Entro.",
        connection_fields=(
            _field(
                "Workspace",
                "Target workspace name selected in Entro after the Grid org install.",
            ),
        ),
        prep_steps=(
            _step(
                "Install the Entro Grid app",
                "As an org admin, install Entro's Enterprise Grid Slack app at the org, then in Entro pick Worker Group and the target workspace.",
                "Slack org apps lists Entro and Entro shows the workspace selectable",
            ),
        ),
    ),
    _row(
        "Salesforce",
        "collaboration-and-saas",
        SALESFORCE,
        (_tool("sf", "usable"), _mcp("salesforce-mcp")),
        hosting="public",
        summary="Connect a Salesforce org so Entro can discover secrets in metadata and connected apps.",
        connection_fields=(
            _field("Environment", LABEL),
            _field(
                "Instance URL",
                "My Domain URL from Salesforce Setup → Company Settings → My Domain.",
            ),
            _field(
                "Access Token or refresh credentials",
                "Connected-app client credentials or CLI-authenticated org alias; store secrets in the operator vault, not chat.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Connected App for Entro",
                "In Salesforce Setup, create a Connected App (or External Client App) with Entro's documented OAuth scopes and record the consumer key in the operator vault.",
                "Setup → App Manager lists the Entro Connected App",
            ),
        ),
    ),
    _row(
        "Active Directory",
        "security-and-identity",
        AD,
        (_tool("pwsh", "usable"),),
        hosting="self-hosted",
        summary="Connect on-premises Active Directory from a Connector that can reach a domain controller.",
        connection_fields=(
            _nickname_field(),
            _field("Domain Controller (DC)", "IP or hostname of a DC reachable from the Connector."),
            _field("DC Name (FQDN)", "FQDN of that domain controller."),
            _field("Domain", "AD DNS domain name."),
            _field("Username", "UPN of the read-only service account (e.g. svc_entro@domain)."),
            _field(
                "Password",
                "Password for that service account; store in the operator vault.",
                secret=True,
            ),
            _field(
                "Root CA (PEM)",
                "PEM of the AD CS root CA if LDAPS is required; paste the certificate, not a private key.",
            ),
            _field("Environment Nickname", LABEL),
            _field("Environment Type", ENV_TYPE),
        ),
        prep_steps=(
            _step(
                "Create a read-only AD service account",
                "Create svc_entro (or equivalent) with Entro's documented read rights and confirm LDAPS from the Connector host to a DC.",
                "The account exists in AD and the Connector host can reach the DC on LDAPS",
            ),
        ),
    ),
    _row(
        "CrowdStrike",
        "security-and-identity",
        CROWDSTRIKE,
        PORTAL_ONLY,
        hosting="public",
        summary="Connect CrowdStrike Falcon via an API client so Entro can discover related secrets and NHIs.",
        connection_fields=(
            _nickname_field(),
            _field(
                "Client ID",
                "Falcon console → Support → API clients → Entro client ID.",
            ),
            _field(
                "Client Secret",
                "Secret shown once when the API client is created; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Falcon API client",
                "In CrowdStrike Falcon, create an API client with Entro's documented scopes and copy Client ID and Client Secret into the operator vault.",
                "API clients lists the Entro client (secret stored outside the session)",
            ),
        ),
        coverages=(_coverage("Falcon RTR", CROWDSTRIKE_RTR_DOCS),),
        fork_census=(
            _census(
                "security-and-identity/crowdstrike/falcon-rtr-secrets-scanner.md",
                "Falcon RTR Terraform EC2 deployment",
                "AWS deployment (Terraform → EC2)",
                waiver_reason=(
                    "Deploys the Falcon RTR scanner host, not an Add New Account "
                    "setup path for the CrowdStrike tile; censused on the Falcon RTR Coverage."
                ),
            ),
        ),
    ),
    _row(
        "Okta",
        "security-and-identity",
        OKTA,
        (_tool("okta", "preferred"),),
        hosting="public",
        summary="Connect Okta via an API Services app that uses Entro's public key (no client secret in the form).",
        connection_fields=(
            _env_field(),
            _display_field(),
            _field(
                "Okta Domain",
                "Okta org URL from the Admin Console address bar, e.g. https://<org>.okta.com.",
            ),
            _field(
                "Client Id",
                "API Services app → General tab → Client ID after you paste Entro's public key into the app.",
            ),
        ),
        prep_steps=(
            _step(
                "Copy Entro's public key from the Okta form",
                "In Entro Add New Account → Okta, copy the Public Key from the bottom of the form and keep the tab open.",
                "The Entro Okta form still shows a Public Key",
            ),
            _step(
                "Create an Okta API Services app",
                "In Okta Admin, create an API Services app, set public-key authentication, paste Entro's public key, disable DPoP, grant Entro's documented Okta API scopes, and assign Super Administrator (or the documented custom role).",
                "The app General tab shows a Client ID and the public key; scopes are granted",
            ),
        ),
        authentication_methods=(
            _method("Super Administrator", OKTA),
            _method("Custom Entro Role", OKTA_CUSTOM_ROLE),
        ),
        operator_inputs=(ENV_FIELD, DISPLAY),
        typed_actions=OKTA_ACTIONS,
        fork_census=(
            _census(
                OKTA,
                "Super Administrator",
                "Select **Super Administrator** and click **Save Changes**.",
                bound_method="Super Administrator",
            ),
            _census(
                OKTA_CUSTOM_ROLE,
                "Custom Entro Role",
                "Okta Custom Entro Role",
                bound_method="Custom Entro Role",
            ),
        ),
    ),
    _row(
        "Snowflake",
        "security-and-identity",
        SNOWFLAKE,
        (_tool("snow", "preferred"),),
        hosting="public",
        summary="Connect a Snowflake account so Entro can discover secrets and NHIs with a key-pair user.",
        connection_fields=(
            _field("Environment", LABEL),
            _display_field(),
            _field(
                "Account URL",
                "https://<account>.snowflakecomputing.com from Profile → Account → View Account Details.",
            ),
        ),
        prep_steps=(
            _step(
                "Create the Entro Snowflake user",
                "In Snowflake, create the Entro user with key-pair auth and Entro's documented grants; store the private key in the operator vault, not in chat.",
                "Snowflake shows the Entro user with the documented role",
            ),
        ),
        operator_inputs=(ENV_FIELD, DISPLAY, SNOWFLAKE_USER),
        typed_actions=SNOWFLAKE_ACTIONS,
    ),
    _row(
        "Wiz",
        "security-and-identity",
        WIZ,
        PORTAL_ONLY,
        hosting="public",
        summary="Connect Wiz via a service account so Entro can read DSPM findings.",
        connection_fields=(
            _nickname_field(),
            _field(
                "Wiz Service Account Client ID",
                "From Wiz Settings → Service Accounts after creating the Entro account.",
            ),
            _field(
                "Wiz Service Account Client Secret",
                "Secret shown when the service account is created; store in the operator vault.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create a Wiz service account",
                "In Wiz, create a service account with read:data_findings, create:reports, and read:reports, then copy Client ID and Client Secret into the operator vault.",
                "Wiz lists the Entro service account (secret stored outside the session)",
            ),
        ),
    ),
    _row(
        "SailPoint ISC",
        "security-and-identity",
        SAILPOINT,
        PORTAL_ONLY,
        hosting="public",
        summary="Connect SailPoint Identity Security Cloud so Entro can exchange NHI inventory via an API client.",
        connection_fields=(
            _field("Environment Nickname", LABEL),
            _field(
                "Tenant URL",
                "ISC tenant API URL retained when the API client is created.",
            ),
            _field(
                "Client ID",
                "One-time Client ID from ISC API Management after creating the Entro client.",
            ),
            _field(
                "Client Secret",
                "One-time Client Secret from that dialog; store in the operator vault immediately.",
                secret=True,
            ),
        ),
        prep_steps=(
            _step(
                "Create an ISC API client",
                "In SailPoint ISC, create an API client for Entro, copy Tenant URL, Client ID, and Client Secret into the operator vault, and confirm outbound HTTPS from the Connector.",
                "ISC shows the Entro API client (secret stored outside the session)",
            ),
        ),
        coverages=(_coverage("Aggregating Entro NHIs & AI agents", SAILPOINT_AGGREGATION),),
    ),
)

from integration_catalog_migration import consolidate_tile_catalog

INTEGRATIONS: tuple[IntegrationDefinition, ...] = consolidate_tile_catalog(
    _LEGACY_INTEGRATIONS
)

EXCLUDED_DOC_PREFIXES: tuple[str, ...] = (
    "ai-and-agents/claude-entro-marketplace",
    "ai-and-agents/cursor-entro-marketplace",
    "ai-and-agents/gemini-mcp-audit",
    "ai-and-agents/entro-webguard",
    "ai-and-agents/open-ai-agent-onboarding",
    "entro-connector/",
    "code-and-ci-cd/entro-command-line-interface-cli",
    "code-and-ci-cd/git-clone-scanning-optional",
    "sso/",
)

_CLI_CACHE = "vendor CLI token cache"

AWS_AUTH_ROUTES = (
    AuthenticationRoute(
        name="IAM user access keys",
        when_to_pick=(
            "Your organization does not use IAM Identity Center, or you already hold an IAM "
            "user access key. Needs nothing configured at the organization level and works in "
            "any AWS account. The keys are long-lived, so rotate or delete them once "
            "onboarding is done."
        ),
        command="aws configure",
        check=CatalogCheck(
            command=(
                'CREDS="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"; '
                'test -f "$CREDS" && grep -q "aws_access_key_id" "$CREDS"'
            ),
            source_url=AWS_ACCESS_KEY_DOCS,
            retrieved_at=AWS_CONFIGURE_ONCE_RETRIEVED,
        ),
        suitable_when="Shared credentials file already holds an access key ID",
        prompts=AWS_ACCESS_KEY_PROMPTS,
        auth_once=None,
        credential_boundary="shared credentials file holding long-lived keys",
        docs_url=AWS_ACCESS_KEY_DOCS,
        source_url=AWS_ACCESS_KEY_DOCS,
        retrieved_at=AWS_CONFIGURE_ONCE_RETRIEVED,
    ),
    AuthenticationRoute(
        name="IAM Identity Center",
        when_to_pick=(
            "Your organization has IAM Identity Center — the AWS access portal — enabled and "
            "you sign in through it. Credentials are short-lived and refresh with a browser "
            "sign-in."
        ),
        command="aws configure sso",
        check=CatalogCheck(
            command=(
                'CONFIG="${AWS_CONFIG_FILE:-$HOME/.aws/config}"; '
                'test -f "$CONFIG" && grep -qE "sso_session|sso_start_url" "$CONFIG"'
            ),
            source_url=AWS_SSO_PROFILE_DOCS,
            retrieved_at=AWS_CONFIGURE_ONCE_RETRIEVED,
        ),
        suitable_when=(
            "AWS config file already has an IAM Identity Center session or start URL"
        ),
        prompts=AWS_IDC_PROMPTS,
        auth_once="aws sso login",
        credential_boundary=_CLI_CACHE,
        docs_url=AWS_IAM_IDC_AUTH_DOCS,
        source_url=AWS_SSO_PROFILE_DOCS,
        retrieved_at=AWS_CONFIGURE_ONCE_RETRIEVED,
    ),
)

TOOL_INSTALL: dict[str, ToolInstall] = {
    "az": _install(
        docs_url="https://learn.microsoft.com/cli/azure/install-azure-cli",
        auth_once="az login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://learn.microsoft.com/cli/azure/install-azure-cli-windows",
            "winget install --exact --id Microsoft.AzureCLI",
        ),
        macos=_os(
            "homebrew",
            "https://learn.microsoft.com/cli/azure/install-azure-cli-macos",
            "brew update && brew install azure-cli",
        ),
        linux=_os(
            "docs",
            "https://learn.microsoft.com/cli/azure/install-azure-cli-linux",
            None,
        ),
        tool_key="az",
    ),
    "pwsh": _install(
        docs_url="https://learn.microsoft.com/powershell/scripting/install/installing-powershell",
        auth_once="pwsh (then Connect-AzAccount when using Azure modules)",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows",
            "winget install --id Microsoft.PowerShell --source winget",
        ),
        macos=_os(
            "homebrew",
            "https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-macos",
            "brew install --cask powershell",
        ),
        linux=_os(
            "docs",
            "https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux",
            None,
        ),
        tool_key="pwsh",
    ),
    "pac": _install(
        docs_url="https://learn.microsoft.com/power-platform/developer/cli/introduction",
        auth_once="pac auth create",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "dotnet-tool",
            "https://learn.microsoft.com/power-platform/developer/howto/install-cli-net-tool",
            "dotnet tool install --global Microsoft.PowerApps.CLI.Tool",
        ),
        macos=_os(
            "dotnet-tool",
            "https://learn.microsoft.com/power-platform/developer/howto/install-cli-net-tool",
            "dotnet tool install --global Microsoft.PowerApps.CLI.Tool",
        ),
        linux=_os(
            "dotnet-tool",
            "https://learn.microsoft.com/power-platform/developer/howto/install-cli-net-tool",
            "dotnet tool install --global Microsoft.PowerApps.CLI.Tool",
        ),
        tool_key="pac",
    ),
    "aws": _install(
        docs_url="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html",
        auth_once="aws sso login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html",
            "winget install --id Amazon.AWSCLI",
        ),
        macos=_os(
            "homebrew",
            "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html",
            "brew install awscli",
        ),
        linux=_os(
            "docs",
            "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html",
            None,
        ),
        tool_key="aws",
        configure_once=ConfigureOnce(methods=AWS_AUTH_ROUTES),
    ),
    "terraform": _install(
        docs_url="https://developer.hashicorp.com/terraform/install",
        auth_once="aws sso login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://developer.hashicorp.com/terraform/install",
            "winget install --id Hashicorp.Terraform",
        ),
        macos=_os(
            "homebrew",
            "https://developer.hashicorp.com/terraform/install",
            "brew tap hashicorp/tap && brew install hashicorp/tap/terraform",
        ),
        linux=_os("docs", "https://developer.hashicorp.com/terraform/install", None),
        tool_key="terraform",
    ),
    "gcloud": _install(
        docs_url="https://cloud.google.com/sdk/docs/install",
        auth_once="gcloud auth login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://cloud.google.com/sdk/docs/install-sdk",
            "winget install --id Google.CloudSDK",
        ),
        macos=_os(
            "homebrew",
            "https://cloud.google.com/sdk/docs/install-sdk",
            "brew install --cask google-cloud-sdk",
        ),
        linux=_os("docs", "https://cloud.google.com/sdk/docs/install-sdk", None),
        tool_key="gcloud",
    ),
    "gh": _install(
        docs_url="https://cli.github.com/",
        auth_once="gh auth login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://github.com/cli/cli#installation",
            "winget install --id GitHub.cli --source winget",
        ),
        macos=_os(
            "homebrew",
            "https://github.com/cli/cli#installation",
            "brew install gh",
        ),
        linux=_os("docs", "https://github.com/cli/cli#installation", None),
        tool_key="gh",
    ),
    "glab": _install(
        docs_url="https://gitlab.com/gitlab-org/cli#installation",
        auth_once="glab auth login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://gitlab.com/gitlab-org/cli#windows",
            "winget install --id GLab.GLab",
        ),
        macos=_os(
            "homebrew",
            "https://gitlab.com/gitlab-org/cli#macos",
            "brew install glab",
        ),
        linux=_os("docs", "https://gitlab.com/gitlab-org/cli#linux", None),
        tool_key="glab",
    ),
    "vault": _install(
        docs_url="https://developer.hashicorp.com/vault/install",
        auth_once="vault login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://developer.hashicorp.com/vault/install",
            "winget install --id Hashicorp.Vault",
        ),
        macos=_os(
            "homebrew",
            "https://developer.hashicorp.com/vault/install",
            "brew tap hashicorp/tap && brew install hashicorp/tap/vault",
        ),
        linux=_os("docs", "https://developer.hashicorp.com/vault/install", None),
        tool_key="vault",
    ),
    "oci": _install(
        docs_url="https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm",
        auth_once="oci session authenticate",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm",
            "winget install --id Oracle.OCI-CLI",
        ),
        macos=_os(
            "homebrew",
            "https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm",
            "brew install oci-cli",
        ),
        linux=_os(
            "docs",
            "https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm",
            None,
        ),
        tool_key="oci",
    ),
    "jf": _install(
        docs_url="https://jfrog.com/help/r/jfrog-cli/install-jfrog-cli",
        auth_once="jf login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://jfrog.com/help/r/jfrog-cli/install-jfrog-cli",
            "winget install --id JFrog.JFrogCLI",
        ),
        macos=_os(
            "homebrew",
            "https://jfrog.com/help/r/jfrog-cli/install-jfrog-cli",
            "brew install jfrog-cli",
        ),
        linux=_os("docs", "https://jfrog.com/help/r/jfrog-cli/install-jfrog-cli", None),
        tool_key="jf",
    ),
    "sf": _install(
        docs_url="https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm",
        auth_once="sf org login web",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://developer.salesforce.com/tools/salesforcecli",
            "winget install --id Salesforce.SalesforceCLI",
        ),
        macos=_os(
            "homebrew",
            "https://developer.salesforce.com/tools/salesforcecli",
            "brew install --cask sf",
        ),
        linux=_os("docs", "https://developer.salesforce.com/tools/salesforcecli", None),
        tool_key="sf",
    ),
    "snow": _install(
        docs_url="https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation",
        auth_once="snow connection add",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation",
            "winget install --id Snowflake.SnowflakeCLI",
        ),
        macos=_os(
            "homebrew",
            "https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation",
            "brew tap snowflake-cli && brew install snowflake-cli",
        ),
        linux=_os(
            "docs",
            "https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation",
            None,
        ),
        tool_key="snow",
    ),
    "jenkins-cli": _install(
        docs_url="https://www.jenkins.io/doc/book/managing/cli/",
        auth_once="java -jar jenkins-cli.jar -s https://<controller> help",
        credential_boundary=(
            "Jenkins controller session; download jenkins-cli.jar from the controller"
        ),
        windows=_os(
            "controller-jar",
            "https://www.jenkins.io/doc/book/managing/cli/",
            None,
        ),
        macos=_os(
            "controller-jar",
            "https://www.jenkins.io/doc/book/managing/cli/",
            None,
        ),
        linux=_os(
            "controller-jar",
            "https://www.jenkins.io/doc/book/managing/cli/",
            None,
        ),
        tool_key="jenkins-cli",
    ),
    "akeyless": _install(
        docs_url="https://docs.akeyless.io/docs/cli",
        auth_once="akeyless login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://docs.akeyless.io/docs/cli",
            "winget install --id Akeyless.CLI",
        ),
        macos=_os(
            "homebrew",
            "https://docs.akeyless.io/docs/cli",
            "brew install akeyless",
        ),
        linux=_os("docs", "https://docs.akeyless.io/docs/cli", None),
        tool_key="akeyless",
    ),
    "okta": _install(
        docs_url="https://cli.okta.com/",
        auth_once="okta login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://cli.okta.com/",
            "winget install --id Okta.OktaCLI",
        ),
        macos=_os("homebrew", "https://cli.okta.com/", "brew install okta"),
        linux=_os("docs", "https://cli.okta.com/", None),
        tool_key="okta",
    ),
    "bk": _install(
        docs_url="https://buildkite.com/docs/pipelines/cli",
        auth_once="bk login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://github.com/buildkite/cli#installation",
            "winget install --id Buildkite.CLI",
        ),
        macos=_os(
            "homebrew",
            "https://github.com/buildkite/cli#installation",
            "brew install buildkite/buildkite/bk",
        ),
        linux=_os("docs", "https://github.com/buildkite/cli#installation", None),
        tool_key="bk",
    ),
    "acli": _install(
        docs_url="https://developer.atlassian.com/cloud/acli/guides/install-acli/",
        auth_once="acli auth login",
        credential_boundary=_CLI_CACHE,
        windows=_os(
            "winget",
            "https://developer.atlassian.com/cloud/acli/guides/install-acli/",
            "winget install --id Atlassian.ACLI",
        ),
        macos=_os(
            "homebrew",
            "https://developer.atlassian.com/cloud/acli/guides/install-acli/",
            "brew tap atlassian/homebrew-acli && brew install acli",
        ),
        linux=_os(
            "docs",
            "https://developer.atlassian.com/cloud/acli/guides/install-acli/",
            None,
        ),
        tool_key="acli",
    ),
    "n8n-mcp": _mcp_install(
        "https://docs.n8n.io/advanced-ai/accessing-n8n-mcp-server/",
        "Enable instance MCP in n8n Settings and authorize the MCP client",
        tool_key="n8n-mcp",
    ),
    "azure-mcp": _mcp_install(
        "https://learn.microsoft.com/azure/developer/azure-mcp-server/",
        "Sign in through the Azure MCP client (uses Azure CLI or Entra login)",
        tool_key="azure-mcp",
    ),
    "aws-mcp": _mcp_install(
        "https://awslabs.github.io/mcp/",
        "Configure the AWS MCP client to use a local AWS CLI profile",
        tool_key="aws-mcp",
    ),
    "github-mcp": _mcp_install(
        "https://github.com/github/github-mcp-server",
        "Authorize the GitHub MCP client (OAuth)",
        tool_key="github-mcp",
    ),
    "atlassian-rovo-mcp": _mcp_install(
        "https://github.com/atlassian/atlassian-mcp-server",
        "Authorize the Atlassian Rovo MCP client (OAuth 2.1)",
        tool_key="atlassian-rovo-mcp",
    ),
    "salesforce-mcp": _mcp_install(
        "https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/client-connection-overview.html",
        "Register an External Client App and authorize the MCP client",
        tool_key="salesforce-mcp",
    ),
}


def _fields_to_list(fields: tuple[ConnectionField, ...]) -> list[dict[str, object]]:
    return [
        {"name": field.name, "secret": field.secret, "obtainedHow": field.obtained_how}
        for field in fields
    ]


def _steps_to_list(
    steps: tuple[PrepStep, ...],
    typed_actions: tuple[TypedAction, ...] = (),
) -> list[dict[str, object]]:
    covered = {action.prep_step_title for action in typed_actions}
    payload: list[dict[str, object]] = []
    for step in steps:
        item: dict[str, object] = {
            "title": step.title,
            "instruction": step.instruction,
            "evidence": step.evidence,
        }
        if step.title not in covered:
            if step.operator_only:
                item["operatorOnly"] = {
                    "reason": step.operator_only.reason,
                    "evidence": step.operator_only.evidence,
                }
            else:
                item["uncataloged"] = {"evidence": step.evidence}
        payload.append(item)
    return payload


def _method_to_dict(method: DocumentedMethod) -> dict[str, object]:
    payload: dict[str, object] = {
        "name": method.name,
        "documentation": method.documentation,
    }
    if method.prep_steps:
        payload["prepSteps"] = _steps_to_list(method.prep_steps, method.typed_actions)
    if method.typed_actions:
        payload["typedActions"] = actions_to_list(method.typed_actions)
    if method.connection_fields:
        payload["connectionFields"] = _fields_to_list(method.connection_fields)
    if method.operator_inputs:
        payload["operatorInputs"] = inputs_to_list(method.operator_inputs)
    return payload


def _tool_to_dict(tool: ConfigurationTool) -> dict[str, str]:
    payload: dict[str, str] = {"fit": tool.fit}
    if tool.kind != "cli":
        payload["kind"] = tool.kind
    if tool.binary:
        payload["binary"] = tool.binary
    if tool.id:
        payload["id"] = tool.id
    if tool.name:
        payload["name"] = tool.name
    return payload


def _os_install_to_dict(install: OsInstall) -> dict[str, object]:
    return {
        "method": install.method,
        "command": install.command,
        "docsUrl": install.docs_url,
    }


def _tool_install_to_dict(entry: ToolInstall) -> dict[str, object]:
    payload: dict[str, object] = {
        "authOnce": entry.auth_once,
        "credentialBoundary": entry.credential_boundary,
        "docsUrl": entry.docs_url,
        "presenceCheck": check_to_dict(entry.presence),
        "capabilityProbe": check_to_dict(entry.capability),
        "authCheck": check_to_dict(entry.auth_check),
        "platformIdentity": identity_to_dict(entry.platform_identity),
        "install": {
            "windows": _os_install_to_dict(entry.windows),
            "macos": _os_install_to_dict(entry.macos),
            "linux": _os_install_to_dict(entry.linux),
        },
    }
    if entry.configure_once is not None:
        payload["configureOnce"] = configure_once_to_dict(entry.configure_once)
    return payload


def integration_to_dict(defn: IntegrationDefinition) -> dict[str, object]:
    optional_capabilities: list[dict[str, object]] = []
    for capability in defn.optional_capabilities:
        item: dict[str, object] = {
            "name": capability.name,
            "documentation": list(capability.documentation),
            "configurationTools": [
                _tool_to_dict(tool) for tool in capability.configuration_tools
            ],
        }
        if capability.prep_steps:
            item["prepSteps"] = _steps_to_list(
                capability.prep_steps, capability.typed_actions
            )
        if capability.typed_actions:
            item["typedActions"] = actions_to_list(capability.typed_actions)
        if capability.operator_inputs:
            item["operatorInputs"] = inputs_to_list(capability.operator_inputs)
        optional_capabilities.append(item)

    integration_paths: list[dict[str, object]] = []
    for path in defn.integration_paths:
        path_item: dict[str, object] = {
            "name": path.name,
            "documentation": list(path.documentation),
            "pathEvidence": path.path_evidence,
            "implicit": path.implicit,
            "configurationTools": [
                _tool_to_dict(tool) for tool in path.configuration_tools
            ],
            "connectionFields": _fields_to_list(path.connection_fields),
            "operatorInputs": inputs_to_list(path.operator_inputs),
        }
        if path.hosting is not None:
            path_item["hosting"] = path.hosting
        if path.prep_steps:
            path_item["prepSteps"] = _steps_to_list(path.prep_steps, path.typed_actions)
        if path.typed_actions:
            path_item["typedActions"] = actions_to_list(path.typed_actions)
        integration_paths.append(path_item)

    payload: dict[str, object] = {
        "tile": defn.tile,
        "category": defn.category,
        "documentation": list(defn.documentation),
        "integrationPaths": integration_paths,
        "optionalCapabilities": optional_capabilities,
        "configurationTools": [_tool_to_dict(tool) for tool in defn.configuration_tools],
        "hosting": defn.hosting,
        "summary": defn.summary,
        "connectionFields": _fields_to_list(defn.connection_fields),
        "captureRequired": defn.capture_required,
        "pathEvidence": defn.path_evidence,
        "methodWaivers": [method_waiver_to_dict(item) for item in defn.method_waivers],
        "forkCensus": [census_entry_to_dict(item) for item in defn.fork_census],
    }
    return payload


def tool_install_payload() -> dict[str, dict[str, object]]:
    return {binary: _tool_install_to_dict(entry) for binary, entry in TOOL_INSTALL.items()}


def integration_index_payload() -> dict[str, object]:
    return {
        "integrations": [integration_to_dict(defn) for defn in INTEGRATIONS],
        "toolInstall": tool_install_payload(),
        "skillHeldArtifacts": skill_held.build_skill_held_pins(),
    }


def skill_catalog_payload() -> dict[str, object]:
    return {"integrations": skill_catalog_index_entries()}


def skill_row_catalogs() -> list[dict[str, object]]:
    ingest = integration_index_payload()
    rows: list[dict[str, object]] = []
    for row in ingest["integrations"]:
        assert isinstance(row, dict)
        rows.append(_strip_documentation_paths(row))
    return rows


def skill_catalog_index_entries() -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    for row in skill_row_catalogs():
        entries.append(_index_entry(row))
    return entries


def _index_entry(row: dict[str, object]) -> dict[str, object]:
    paths = row.get("integrationPaths") or []
    optional = row.get("optionalCapabilities") or []
    path_names: list[str] = []
    if isinstance(paths, list):
        for path in paths:
            if not isinstance(path, dict):
                continue
            if path.get("implicit") is True:
                continue
            name = path.get("name")
            if isinstance(name, str) and name.strip():
                path_names.append(name)
    return {
        "tile": row["tile"],
        "summary": row["summary"],
        "integrationPathNames": path_names,
        "optionalCapabilityNames": [
            capability["name"]
            for capability in optional
            if isinstance(capability, dict) and capability.get("name")
        ],
        "catalogPath": catalog_path_for(str(row["tile"])),
        "captureRequired": bool(row.get("captureRequired")),
    }


def _strip_documentation_paths(row: dict[str, object]) -> dict[str, object]:
    skill = {
        key: value
        for key, value in row.items()
        if key not in ("documentation", "methodWaivers", "forkCensus")
    }
    for collection_key in ("integrationPaths", "optionalCapabilities"):
        items = skill.get(collection_key, [])
        if isinstance(items, list):
            skill[collection_key] = [
                {key: value for key, value in item.items() if key != "documentation"}
                if isinstance(item, dict)
                else item
                for item in items
            ]
    return skill


def _row_label(row: dict[str, object]) -> str:
    return str(row.get("tile"))


def _validate_tool_entries(label: str, tools: object, *, required: bool) -> list[str]:
    errors: list[str] = []
    if tools is None:
        tools = []
    if not isinstance(tools, list):
        errors.append(f"{label}: configurationTools must be a list")
        return errors
    if required and not tools:
        errors.append(f"{label}: configurationTools must be a non-empty list")
        return errors
    for entry in tools:
        if not isinstance(entry, dict):
            errors.append(f"{label}: Configuration tool must be an object")
            continue
        fit = entry.get("fit")
        if fit not in FITS:
            errors.append(f"{label}: unknown Fit {fit!r}")
        kind = entry.get("kind", "cli")
        if kind not in KINDS:
            errors.append(f"{label}: unknown kind {kind!r}")
            continue
        if fit == "none" or fit not in FITS:
            continue
        if kind == "mcp":
            tool_id = entry.get("id")
            if not isinstance(tool_id, str) or not tool_id.strip():
                errors.append(f"{label}: MCP Configuration tool must name an id")
        else:
            binary = entry.get("binary")
            if not isinstance(binary, str) or not binary.strip():
                errors.append(
                    f"{label}: Configuration tool with Fit {fit!r} must name a binary"
                )
    return errors


def _validate_optional_capabilities(row: dict[str, object]) -> list[str]:
    errors: list[str] = []
    label = _row_label(row)
    capabilities = row.get("optionalCapabilities", [])
    if capabilities is None:
        capabilities = []
    if not isinstance(capabilities, list):
        errors.append(f"{label}: optionalCapabilities must be a list")
        return errors
    seen: set[str] = set()
    for capability in capabilities:
        if not isinstance(capability, dict):
            errors.append(f"{label}: Optional capability must be an object")
            continue
        name = capability.get("name")
        display = name if isinstance(name, str) else None
        if not isinstance(name, str) or not name.strip():
            errors.append(f"{label}: Optional capability name must be non-empty")
        elif name in seen:
            errors.append(f"{label}: duplicate Optional capability name {name!r}")
        else:
            seen.add(name)
        docs = capability.get("documentation")
        if "documentation" in capability and docs:
            if not isinstance(docs, list) or not docs:
                errors.append(
                    f"{label}: Optional capability {display!r} must cite documentation"
                )
        cap_label = f"{label} Optional capability {display!r}"
        errors.extend(
            _validate_tool_entries(
                cap_label, capability.get("configurationTools", []), required=False
            )
        )
        if "connectionFields" in capability:
            errors.append(f"{cap_label}: Optional capabilities must not list connectionFields")
        errors.extend(
            _validate_prep_steps(cap_label, capability.get("prepSteps"), required=False)
        )
    return errors


def _validate_integration_paths_row(row: dict[str, object]) -> list[str]:
    errors: list[str] = []
    label = _row_label(row)
    paths = row.get("integrationPaths", [])
    if paths is None:
        paths = []
    if not isinstance(paths, list):
        errors.append(f"{label}: integrationPaths must be a list")
        return errors
    if row.get("captureRequired") and paths:
        errors.append(f"{label}: capture-required rows must not declare integrationPaths")
    seen: set[str] = set()
    for path in paths:
        if not isinstance(path, dict):
            errors.append(f"{label}: Integration path must be an object")
            continue
        name = path.get("name")
        display = name if isinstance(name, str) else None
        if not isinstance(name, str) or not name.strip():
            errors.append(f"{label}: Integration path name must be non-empty")
        elif name in seen:
            errors.append(f"{label}: duplicate Integration path name {name!r}")
        else:
            seen.add(name)
        path_label = f"{label} Integration path {display!r}"
        tools = path.get("configurationTools") or row.get("configurationTools")
        errors.extend(_validate_tool_entries(path_label, tools, required=False))
        errors.extend(
            _validate_connection_fields(path_label, path.get("connectionFields"))
            if path.get("connectionFields")
            else []
        )
        errors.extend(_validate_operator_inputs(path_label, path.get("operatorInputs")))
        errors.extend(
            _validate_prep_steps(path_label, path.get("prepSteps"), required=False)
        )
    return errors


def _blob_has_secret_shaped_value(payload: object) -> bool:
    return bool(_SECRET_SHAPED.search(json.dumps(payload)))


def _validate_connection_fields(label: str, fields: object) -> list[str]:
    errors: list[str] = []
    if fields is None:
        fields = []
    if not isinstance(fields, list):
        errors.append(f"{label}: connectionFields must be a list")
        return errors
    if not fields:
        return errors
    for item in fields:
        if not isinstance(item, dict):
            errors.append(f"{label}: connectionFields item must be an object")
            continue
        name = item.get("name")
        if not isinstance(name, str) or not name.strip():
            errors.append(f"{label}: connectionFields item must have name")
        elif name.strip().lower() in WORKER_GROUP_NAMES:
            errors.append(f"{label}: connectionFields must not include Worker Group")
        obtained = item.get("obtainedHow")
        if not isinstance(obtained, str) or not obtained.strip():
            errors.append(f"{label}: connectionFields item {name!r} must have obtainedHow")
        if "secret" not in item or not isinstance(item.get("secret"), bool):
            errors.append(f"{label}: connectionFields item {name!r} must have boolean secret")
        if _blob_has_secret_shaped_value(item):
            errors.append(f"{label}: connectionFields item {name!r} contains a secret-shaped value")
    return errors


def _validate_prep_steps(label: str, steps: object, *, required: bool) -> list[str]:
    errors: list[str] = []
    if steps is None:
        if required:
            errors.append(f"{label}: prepSteps must be a non-empty list")
        return errors
    if not isinstance(steps, list):
        errors.append(f"{label}: prepSteps must be a list")
        return errors
    if required and not steps:
        errors.append(f"{label}: prepSteps must be a non-empty list")
        return errors
    for step in steps:
        if not isinstance(step, dict):
            errors.append(f"{label}: Prep step must be an object")
            continue
        if "command" in step:
            errors.append(f"{label}: Prep step must not contain a command field")
        title = step.get("title")
        instruction = step.get("instruction")
        evidence = step.get("evidence")
        if not isinstance(title, str) or not title.strip():
            errors.append(f"{label}: Prep step must have title")
        if not isinstance(instruction, str) or not instruction.strip():
            errors.append(f"{label}: Prep step must have instruction")
        if not isinstance(evidence, str) or not evidence.strip():
            errors.append(f"{label}: Prep step must have evidence")
        if _blob_has_secret_shaped_value(step):
            errors.append(f"{label}: Prep step {title!r} contains a secret-shaped value")
    return errors


def _has_preferred(tools: object) -> bool:
    if not isinstance(tools, list):
        return False
    return any(
        isinstance(entry, dict) and entry.get("fit") == "preferred" for entry in tools
    )


def _validate_operator_inputs(label: str, inputs: object) -> list[str]:
    errors: list[str] = []
    if inputs is None:
        return errors
    if not isinstance(inputs, list):
        errors.append(f"{label}: operatorInputs must be a list")
        return errors
    seen: set[str] = set()
    for item in inputs:
        if not isinstance(item, dict):
            errors.append(f"{label}: Operator input must be an object")
            continue
        key = item.get("key")
        if not isinstance(key, str) or not key.strip():
            errors.append(f"{label}: Operator input must have key")
        elif key in seen:
            errors.append(f"{label}: duplicate Operator input key {key!r}")
        else:
            seen.add(key)
        for field in ("prompt", "purpose", "validation"):
            if not isinstance(item.get(field), str) or not str(item.get(field)).strip():
                errors.append(f"{label}: Operator input {key!r} must have {field}")
        if item.get("secret") is True:
            errors.append(f"{label}: Operator input {key!r} must not be secret")
        if _blob_has_secret_shaped_value(item):
            errors.append(f"{label}: Operator input {key!r} contains a secret-shaped value")
    return errors


_INPUT_PLACEHOLDER = re.compile(r"<([a-z][a-z0-9]*(?:_[a-z0-9]+)*)>")
_PLACEHOLDER_FIELDS = ("preview", "mutation", "verification", "rollbackOrImpact")


def _operator_input_keys(inputs: object) -> set[str]:
    keys: set[str] = set()
    if not isinstance(inputs, list):
        return keys
    for item in inputs:
        if isinstance(item, dict) and isinstance(item.get("key"), str):
            keys.add(item["key"])
    return keys


def _validate_action_placeholders(
    label: str,
    actions: object,
    keys: set[str],
) -> list[str]:
    errors: list[str] = []
    if not isinstance(actions, list):
        return errors
    for item in actions:
        if not isinstance(item, dict):
            continue
        title = item.get("prepStepTitle")
        text = " ".join(str(item.get(field, "")) for field in _PLACEHOLDER_FIELDS)
        for name in sorted(set(_INPUT_PLACEHOLDER.findall(text)) - keys):
            errors.append(
                f"{label}: Typed action {title!r} names <{name}> "
                "with no matching Operator input key"
            )
    return errors


def _validate_row_placeholders(row: dict[str, object]) -> list[str]:
    label = _row_label(row)
    errors: list[str] = []
    paths = row.get("integrationPaths") or []
    if isinstance(paths, list):
        for path in paths:
            if not isinstance(path, dict):
                continue
            path_label = f"{label} Integration path {path.get('name')!r}"
            keys = _operator_input_keys(path.get("operatorInputs"))
            errors.extend(
                _validate_action_placeholders(path_label, path.get("typedActions"), keys)
            )
    optional = row.get("optionalCapabilities") or []
    if isinstance(optional, list):
        for capability in optional:
            if not isinstance(capability, dict):
                continue
            cap_label = f"{label} Optional capability {capability.get('name')!r}"
            keys = _operator_input_keys(capability.get("operatorInputs"))
            errors.extend(
                _validate_action_placeholders(
                    cap_label, capability.get("typedActions"), keys
                )
            )
    return errors


def _validate_typed_actions(label: str, actions: object, step_titles: set[str]) -> list[str]:
    errors: list[str] = []
    if actions is None:
        actions = []
    if not isinstance(actions, list):
        errors.append(f"{label}: typedActions must be a list")
        return errors
    covered: set[str] = set()
    for item in actions:
        if not isinstance(item, dict):
            errors.append(f"{label}: Typed action must be an object")
            continue
        title = item.get("prepStepTitle")
        if not isinstance(title, str) or not title.strip():
            errors.append(f"{label}: Typed action must have prepStepTitle")
        else:
            covered.add(title)
        for field in (
            "preview",
            "mutation",
            "target",
            "expectedChange",
            "verification",
            "rollbackOrImpact",
            "sourceUrl",
            "retrievedAt",
        ):
            if not isinstance(item.get(field), str) or not str(item.get(field)).strip():
                errors.append(f"{label}: Typed action {title!r} must have {field}")
        if "secretProducing" not in item or not isinstance(item.get("secretProducing"), bool):
            errors.append(f"{label}: Typed action {title!r} must have boolean secretProducing")
        if "command" in item:
            errors.append(f"{label}: Typed action must not put command on a Prep step")
        script = item.get("script")
        if script is not None:
            errors.extend(validate_script_pin(f"{label}: Typed action {title!r}", script))
        if _blob_has_secret_shaped_value(item):
            errors.append(f"{label}: Typed action {title!r} contains a secret-shaped value")
    return errors


def _validate_step_ownership(
    label: str,
    steps: object,
    actions: object,
    *,
    preferred: bool,
) -> list[str]:
    errors = _validate_typed_actions(label, actions, _step_titles(steps))
    covered: set[str] = set()
    if isinstance(actions, list):
        for item in actions:
            if isinstance(item, dict) and isinstance(item.get("prepStepTitle"), str):
                covered.add(item["prepStepTitle"])
    errors.extend(
        validate_prep_step_coverage(label, steps, covered, preferred=preferred)
    )
    extra = covered - _step_titles(steps)
    for title in sorted(extra):
        errors.append(f"{label}: Typed action {title!r} does not match a Prep step")
    return errors


def _step_titles(steps: object) -> set[str]:
    titles: set[str] = set()
    if not isinstance(steps, list):
        return titles
    for step in steps:
        if isinstance(step, dict) and isinstance(step.get("title"), str):
            titles.add(step["title"])
    return titles


def _naming_fields(fields: object) -> list[str]:
    names: list[str] = []
    if not isinstance(fields, list):
        return names
    for item in fields:
        if not isinstance(item, dict):
            continue
        name = item.get("name")
        if not isinstance(name, str):
            continue
        if item.get("secret") is True:
            continue
        if name.strip().lower() in NAMING_FIELD_NAMES:
            names.append(name)
    return names


def _bound_field_names(inputs: object) -> set[str]:
    bound: set[str] = set()
    if not isinstance(inputs, list):
        return bound
    for item in inputs:
        if isinstance(item, dict) and isinstance(item.get("bindsTo"), str):
            bound.add(item["bindsTo"])
    return bound


def _validate_preferred_plan(row: dict[str, object]) -> list[str]:
    errors: list[str] = []
    label = _row_label(row)
    paths = row.get("integrationPaths") or []
    if isinstance(paths, list):
        for path in paths:
            if not isinstance(path, dict):
                continue
            tools = path.get("configurationTools") or row.get("configurationTools")
            path_label = f"{label} Integration path {path.get('name')!r}"
            if not _has_preferred(tools):
                errors.extend(
                    _validate_step_ownership(
                        path_label,
                        path.get("prepSteps"),
                        path.get("typedActions"),
                        preferred=False,
                    )
                )
                continue
            inputs = path.get("operatorInputs") or row.get("operatorInputs") or []
            errors.extend(_validate_operator_inputs(path_label, inputs))
            fields = path.get("connectionFields") or row.get("connectionFields")
            for name in _naming_fields(fields):
                if name not in _bound_field_names(inputs):
                    errors.append(
                        f"{path_label}: Fit preferred path needs Operator input bound to {name!r}"
                    )
            errors.extend(
                _validate_step_ownership(
                    path_label,
                    path.get("prepSteps"),
                    path.get("typedActions"),
                    preferred=True,
                )
            )
    optional = row.get("optionalCapabilities") or []
    if isinstance(optional, list):
        for capability in optional:
            if not isinstance(capability, dict):
                continue
            if not _has_preferred(capability.get("configurationTools")):
                continue
            cap_label = f"{label} Optional capability {capability.get('name')!r}"
            errors.extend(
                _validate_step_ownership(
                    cap_label,
                    capability.get("prepSteps"),
                    capability.get("typedActions"),
                    preferred=True,
                )
            )
            errors.extend(
                _validate_operator_inputs(cap_label, capability.get("operatorInputs"))
            )
    return errors


def _validate_nonpreferred_optional_capabilities(row: dict[str, object]) -> list[str]:
    errors: list[str] = []
    label = _row_label(row)
    optional = row.get("optionalCapabilities") or []
    if isinstance(optional, list):
        for capability in optional:
            if not isinstance(capability, dict):
                continue
            if _has_preferred(capability.get("configurationTools")):
                continue
            extra_steps = capability.get("prepSteps") or []
            if not extra_steps:
                continue
            cap_label = f"{label} Optional capability {capability.get('name')!r}"
            errors.extend(
                _validate_step_ownership(
                    cap_label,
                    extra_steps,
                    capability.get("typedActions"),
                    preferred=False,
                )
            )
    return errors


def validate_integration_row(row: dict[str, object]) -> list[str]:
    errors: list[str] = []
    label = _row_label(row)
    capture_required = bool(row.get("captureRequired"))
    errors.extend(_validate_optional_capabilities(row))
    errors.extend(_validate_integration_paths_row(row))
    errors.extend(
        _validate_tool_entries(label, row.get("configurationTools"), required=True)
    )

    if "connectorRequirement" in row or "connectorEvidence" in row:
        errors.append(f"{label}: rows must not carry connector requirement fields")

    if any(key in row for key in _TOPOLOGY_LIST_KEYS):
        errors.append(f"{label}: rows must not carry connector deployment fields")

    forbidden = {
        "targetSelection",
        "setupMethods",
        "authenticationMethods",
        "coverages",
        "prepSteps",
        "typedActions",
        "operatorInputs",
    }
    for key in forbidden:
        if key in row:
            errors.append(f"{label}: rows must not carry legacy field {key!r}")

    hosting = row.get("hosting", None)
    if hosting is None:
        errors.append(f"{label}: missing hosting")
    elif hosting not in HOSTINGS:
        errors.append(f"{label}: unknown hosting {hosting!r}")

    summary = row.get("summary")
    if not isinstance(summary, str) or not summary.strip():
        errors.append(f"{label}: missing summary")
    if not capture_required:
        errors.extend(_validate_connection_fields(label, row.get("connectionFields")))

    if not capture_required:
        errors.extend(_validate_preferred_plan(row))
        errors.extend(_validate_nonpreferred_optional_capabilities(row))
        errors.extend(_validate_row_placeholders(row))

    return errors


def _documentation_paths(row: dict[str, object]) -> list[str]:
    paths: list[str] = []
    documentation = row.get("documentation", [])
    if isinstance(documentation, str):
        paths.append(documentation)
    elif isinstance(documentation, list):
        paths.extend(str(item) for item in documentation)
    for key in ("integrationPaths", "optionalCapabilities"):
        items = row.get(key, [])
        if isinstance(items, list):
            for item in items:
                if not isinstance(item, dict):
                    continue
                docs = item.get("documentation", [])
                if isinstance(docs, list):
                    paths.extend(str(page) for page in docs)
                elif isinstance(docs, str) and docs:
                    paths.append(docs)
    return paths


def integration_documentation_pages(output_dir: Path) -> list[str]:
    pages: list[str] = []
    for folder in INTEGRATION_DOCUMENTATION_FOLDERS:
        root = output_dir / folder
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.md")):
            if path.is_file():
                pages.append(path.relative_to(output_dir).as_posix())
    return pages


def _cited_pages(rows: list[dict[str, object]]) -> set[str]:
    cited: set[str] = set()
    for row in rows:
        cited.update(_documentation_paths(row))
    return cited


def _waiver_pages(rows: list[dict[str, object]]) -> set[str]:
    pages: set[str] = set()
    for row in rows:
        for waiver in row.get("methodWaivers") or []:
            if isinstance(waiver, dict) and waiver.get("page"):
                pages.add(str(waiver["page"]))
    return pages


def validate_page_citation(
    output_dir: Path,
    rows: list[dict[str, object]],
) -> list[str]:
    cited = _cited_pages(rows)
    waived = _waiver_pages(rows)
    errors: list[str] = []
    for page in integration_documentation_pages(output_dir):
        if page not in cited and page not in waived:
            errors.append(f"uncited integration documentation page {page}")
    return errors


def _method_bound(bound: str, method_names: set[str]) -> bool:
    if bound in method_names:
        return True
    return any(name.startswith(f"{bound} —") for name in method_names)


def validate_fork_census(
    output_dir: Path,
    rows: list[dict[str, object]],
) -> list[str]:
    errors: list[str] = []
    for row in rows:
        label = _row_label(row)
        method_names: set[str] = set()
        for path in row.get("integrationPaths") or []:
            if isinstance(path, dict) and path.get("name"):
                method_names.add(str(path["name"]))
        for entry in row.get("forkCensus") or []:
            if not isinstance(entry, dict):
                errors.append(f"{label}: fork census entry must be an object")
                continue
            page = entry.get("page")
            if not isinstance(page, str) or not page:
                errors.append(f"{label}: fork census entry missing page")
                continue
            path = output_dir / page
            if not path.is_file():
                errors.append(f"{label}: fork census page missing {page}")
                continue
            evidence = entry.get("evidence")
            quote = evidence if isinstance(evidence, str) else ""
            if not quote:
                errors.append(f"{label}: fork census entry missing evidence on {page}")
            elif quote.encode("utf-8") not in path.read_bytes():
                errors.append(f"{label}: missing census evidence on {page}: {quote}")
            bound = entry.get("boundMethod")
            reason = entry.get("waiverReason")
            bound_ok = isinstance(bound, str) and _method_bound(bound, method_names)
            reason_ok = isinstance(reason, str) and bool(reason.strip())
            if isinstance(bound, str) and bound and not _method_bound(bound, method_names):
                errors.append(f"{label}: census binds to absent method {bound!r}")
            elif not bound_ok and not reason_ok:
                errors.append(
                    f"{label}: census entry on {page} needs a method binding or waiver reason"
                )
    return errors


def validate_method_waivers(
    output_dir: Path,
    rows: list[dict[str, object]],
) -> list[str]:
    allowed = set(integration_documentation_pages(output_dir))
    errors: list[str] = []
    for row in rows:
        label = _row_label(row)
        for waiver in row.get("methodWaivers") or []:
            if not isinstance(waiver, dict):
                errors.append(f"{label}: Method waiver must be an object")
                continue
            reason = waiver.get("reason")
            if not isinstance(reason, str) or not reason.strip():
                errors.append(f"{label}: Method waiver without a reason")
            page = waiver.get("page")
            if not isinstance(page, str) or page not in allowed:
                errors.append(f"{label}: Method waiver for missing page {page!r}")
    return errors


def _validate_catalog_completeness(
    output_dir: Path,
    rows: list[dict[str, object]],
) -> list[str]:
    errors = validate_page_citation(output_dir, rows)
    errors.extend(validate_fork_census(output_dir, rows))
    errors.extend(validate_method_waivers(output_dir, rows))
    return errors


def validate_duplicate_targets(rows: list[dict[str, object]]) -> list[str]:
    errors: list[str] = []
    seen: dict[str, str] = {}
    for row in rows:
        tile = row.get("tile")
        label = _row_label(row)
        if not isinstance(tile, str):
            errors.append(f"{label}: missing tile")
            continue
        if tile in seen:
            errors.append(f"{label}: duplicate tile {tile!r}")
        else:
            seen[tile] = label
    return errors


def _referenced_binaries(rows: list[dict[str, object]]) -> set[str]:
    referenced: set[str] = set()
    for row in rows:
        groups: list[object] = [row.get("configurationTools", [])]
        for collection_key in ("integrationPaths", "optionalCapabilities"):
            items = row.get(collection_key, [])
            if isinstance(items, list):
                for item in items:
                    if isinstance(item, dict):
                        groups.append(item.get("configurationTools", []))
        for tools in groups:
            if not isinstance(tools, list):
                continue
            for entry in tools:
                if not isinstance(entry, dict):
                    continue
                if entry.get("fit") == "none":
                    continue
                kind = entry.get("kind", "cli")
                if kind == "mcp":
                    tool_id = entry.get("id")
                    if isinstance(tool_id, str) and tool_id.strip():
                        referenced.add(tool_id)
                    continue
                binary = entry.get("binary")
                if isinstance(binary, str) and binary.strip():
                    referenced.add(binary)
    return referenced


def _validate_os_install(binary: str, os_name: str, payload: object) -> list[str]:
    if not isinstance(payload, dict):
        return [f"toolInstall {binary!r}: install.{os_name} must be an object"]
    errors: list[str] = []
    if not payload.get("method"):
        errors.append(f"toolInstall {binary!r}: install.{os_name} must have method")
    if not payload.get("docsUrl"):
        errors.append(f"toolInstall {binary!r}: install.{os_name} must have docsUrl")
    return errors


def validate_tool_install(
    tool_install: dict[str, object],
    rows: list[dict[str, object]],
) -> list[str]:
    errors: list[str] = []
    if not isinstance(tool_install, dict):
        return ["toolInstall must be an object"]
    referenced = _referenced_binaries(rows)
    for binary, entry in tool_install.items():
        if binary not in referenced:
            errors.append(f"toolInstall {binary!r}: orphan install key")
        if not isinstance(entry, dict):
            errors.append(f"toolInstall {binary!r}: entry must be an object")
            continue
        if not entry.get("docsUrl"):
            errors.append(f"toolInstall {binary!r}: missing docsUrl")
        if not entry.get("authOnce"):
            errors.append(f"toolInstall {binary!r}: missing authOnce")
        if not entry.get("credentialBoundary"):
            errors.append(f"toolInstall {binary!r}: missing credentialBoundary")
        errors.extend(
            f"toolInstall {binary!r}: {message}"
            for message in probe_fields_present(entry)
        )
        once = entry.get("configureOnce")
        if once is not None and _blob_has_secret_shaped_value(once):
            errors.append(f"toolInstall {binary!r}: configureOnce contains a secret-shaped value")
        install = entry.get("install")
        if not isinstance(install, dict):
            errors.append(f"toolInstall {binary!r}: install must be an object")
            continue
        for os_name in ("windows", "macos", "linux"):
            if os_name not in install:
                errors.append(f"toolInstall {binary!r}: missing {os_name} install")
            else:
                errors.extend(_validate_os_install(binary, os_name, install[os_name]))
    for binary in sorted(referenced - set(tool_install)):
        errors.append(f"missing toolInstall key {binary}")
    return errors


def validate_integration_paths(
    output_dir: Path,
    rows: list[dict[str, object]] | None = None,
) -> list[str]:
    errors: list[str] = []
    payload_rows = rows if rows is not None else integration_index_payload()["integrations"]
    for row in payload_rows:
        label = _row_label(row)
        for rel in _documentation_paths(row):
            if not (output_dir / rel).is_file():
                errors.append(f"{label}: missing documentation {rel}")
    return errors


def write_integrations_index(
    output_dir: Path,
    skill_catalog: Path | None | bool = None,
) -> list[str]:
    payload = integration_index_payload()
    rows = payload["integrations"]
    skill_index = skill_catalog_payload()
    skill_rows = skill_row_catalogs()
    errors = validate_integration_definitions(
        tool_install=payload["toolInstall"],
    )
    destinations = _skill_catalog_destinations(output_dir, skill_catalog)
    writing_docs = False
    try:
        writing_docs = output_dir.resolve() == (REPO_ROOT / "documentation").resolve()
    except OSError:
        writing_docs = False
    if writing_docs:
        migrate_vendor_into_row_folders()
        skill_held.migrate_skill_row_folders()
        remove_vendor_trees()
        errors.extend(_validate_gcp_source_archives())
    try:
        generated_gcp = gcp_generated_artifacts()
    except ValueError as exc:
        errors.append(str(exc))
        generated_gcp = ()
    if destinations:
        errors.extend(validate_skill_catalog(skill_index, ingest_rows=rows, row_catalogs=skill_rows))
        for skill_path in destinations:
            errors.extend(
                validate_skill_catalog_tree_plan(skill_path.parent, skill_index, skill_rows)
            )
    if writing_docs:
        # Stale generated files are repairable output, so only source/harvest
        # inputs are a pre-write gate. Full generated validation runs below.
        errors.extend(validate_skill_held(validate_generated=False))
    if errors:
        return errors
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "integrations.json").write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )
    for skill_path in destinations:
        _write_skill_catalog_tree(
            skill_path.parent,
            index_path=skill_path,
            index=skill_index,
            rows=skill_rows,
            tool_install=payload["toolInstall"],
            generated_artifacts=generated_gcp,
        )
    if writing_docs:
        copy_skill_held_tree()
        for extra in ("integrations.json", TOOL_INSTALL_FILE):
            src = SKILL_ROOTS[0] / extra
            dest = SKILL_ROOTS[1] / extra
            dest.write_bytes(src.read_bytes())
        post = _validate_skill_roots_generated()
        if post:
            return post
    return []


def _write_skill_catalog_tree(
    skill_root: Path,
    *,
    index_path: Path,
    index: dict[str, object],
    rows: list[dict[str, object]],
    tool_install: dict[str, object],
    generated_artifacts: tuple[GeneratedSkillArtifact, ...] = (),
) -> None:
    skill_root.mkdir(parents=True, exist_ok=True)
    integrations_dir = skill_root / INTEGRATIONS_DIR
    integrations_dir.mkdir(parents=True, exist_ok=True)
    index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    (skill_root / TOOL_INSTALL_FILE).write_text(
        json.dumps({"toolInstall": tool_install}, indent=2) + "\n",
        encoding="utf-8",
    )
    keep: set[Path] = set()
    for row in rows:
        rel = catalog_path_for(str(row["tile"]))
        dest = skill_root / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(row, indent=2) + "\n", encoding="utf-8")
        keep.add(dest.parent.resolve())
    for artifact in generated_artifacts:
        dest = skill_root / artifact.skill_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(artifact.content)
        if artifact.executable:
            dest.chmod(0o755)
    if integrations_dir.is_dir():
        for child in list(integrations_dir.iterdir()):
            if not child.is_dir():
                continue
            if child.resolve() in keep:
                continue
            leftovers = [path for path in child.rglob("*") if path.is_file() and path.name != ROW_CATALOG_NAME]
            if leftovers:
                continue
            shutil.rmtree(child)


def validate_skill_catalog_tree_plan(
    skill_root: Path,
    index: dict[str, object],
    rows: list[dict[str, object]],
) -> list[str]:
    errors: list[str] = []
    by_tile = {row.get("tile"): row for row in rows}
    for entry in index.get("integrations") or []:
        if not isinstance(entry, dict):
            continue
        catalog_path = entry.get("catalogPath")
        if not isinstance(catalog_path, str) or not catalog_path:
            errors.append(f"{_row_label(entry)}: catalogPath missing")
            continue
        expected = catalog_path_for(str(entry.get("tile")))
        if catalog_path != expected:
            errors.append(
                f"{_row_label(entry)}: catalogPath {catalog_path!r} does not match {expected!r}"
            )
        row = by_tile.get(entry.get("tile"))
        if row is None:
            errors.append(f"{_row_label(entry)}: no Row catalog object")
    return errors


def _skill_catalog_destinations(
    output_dir: Path,
    skill_catalog: Path | None | bool,
) -> list[Path]:
    if skill_catalog is False:
        return []
    if isinstance(skill_catalog, Path):
        return [skill_catalog]
    try:
        if output_dir.resolve() == (REPO_ROOT / "documentation").resolve():
            return list(SKILL_CATALOG_PATHS)
    except OSError:
        return []
    return []


def _resolve_skill_catalog_path(
    output_dir: Path,
    skill_catalog: Path | None | bool,
) -> Path | None:
    destinations = _skill_catalog_destinations(output_dir, skill_catalog)
    return destinations[0] if destinations else None


def validate_skill_held(
    documentation_dir: Path | None = None,
    *,
    fetch_origin: bool = False,
    opener=None,
    notices: list[str] | None = None,
    validate_generated: bool = True,
) -> list[str]:
    docs = documentation_dir or (REPO_ROOT / "documentation")
    pins = payload_pins()
    errors: list[str] = []
    dumped = json.dumps(integration_index_payload())
    if "verify-after-download" in dumped:
        errors.append("catalog must not record sha256:verify-after-download")
    for pin in pins:
        errors.extend(validate_script_pin("skillHeldArtifacts", pin))
    errors.extend(
        validate_harvest_coverage(
            docs, pins, fetch_origin=fetch_origin, opener=opener, notices=notices
        )
    )
    if validate_generated:
        errors.extend(_validate_generated_gcp_documentation_index(docs))
        errors.extend(_validate_generated_gcp_publication())
    return errors


def payload_pins() -> list[dict[str, object]]:
    pins = list(skill_held.build_skill_held_pins())
    seen = {pin.get("skillPath") for pin in pins}
    for row in integration_index_payload()["integrations"]:
        for action in _iter_typed_actions(row):
            script = action.get("script")
            if isinstance(script, dict) and script.get("skillPath") not in seen:
                pins.append(script)
                seen.add(script.get("skillPath"))
    return pins


def _iter_typed_actions(row: dict[str, object]) -> list[dict[str, object]]:
    actions: list[dict[str, object]] = []
    for collection_key in ("integrationPaths", "optionalCapabilities"):
        for item in row.get(collection_key) or []:
            if not isinstance(item, dict):
                continue
            for action in item.get("typedActions") or []:
                if isinstance(action, dict):
                    actions.append(action)
    return actions


def _validate_generated_gcp_documentation_index(documentation_dir: Path) -> list[str]:
    """Compare the selected ingest Integration index's GCP row to memory."""

    index_path = documentation_dir / "integrations.json"
    if not index_path.is_file():
        return []
    try:
        payload = json.loads(index_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"Integration index GCP row drift: {index_path} is not JSON: {exc}"]
    if not isinstance(payload, dict) or not isinstance(payload.get("integrations"), list):
        return [f"Integration index GCP row drift: {index_path} has no integrations list"]

    expected_row = next(
        row
        for row in integration_index_payload()["integrations"]
        if row.get("tile") == "Google GCP"
    )
    committed_row = next(
        (
            row
            for row in payload["integrations"]
            if isinstance(row, dict) and row.get("tile") == "Google GCP"
        ),
        None,
    )
    if committed_row is None:
        return ["Integration index GCP row drift: Google GCP row is missing"]

    errors: list[str] = []
    if committed_row != expected_row:
        errors.append(
            f"Integration index GCP row drift: {index_path} is stale versus "
            "the in-memory generated row"
        )

    generated_paths = {
        GCP_IAM_ARTIFACT_SKILL_PATH,
        GCP_API_ARTIFACT_SKILL_PATH,
    }
    expected_actions: dict[object, list[dict[str, object]]] = {}
    for action in _iter_typed_actions(expected_row):
        script = action.get("script")
        if isinstance(script, dict) and script.get("skillPath") in generated_paths:
            expected_actions.setdefault(action.get("prepStepTitle"), []).append(action)
    committed_actions = _iter_typed_actions(committed_row)
    for title, expected_for_title in expected_actions.items():
        actions = [
            action
            for action in committed_actions
            if action.get("prepStepTitle") == title
        ]
        if not actions:
            errors.append(f"Integration index GCP action drift: missing {title}")
            continue
        expected_action = expected_for_title[0]
        expected_script = expected_action["script"]
        if len(actions) != len(expected_for_title) or any(
            action != expected_action for action in actions
        ):
            errors.append(f"Integration index GCP action drift: stale {title}")
        actual_scripts = [action.get("script") for action in actions]
        if any(
            not isinstance(script, dict)
            or script.get("skillPath") != expected_script.get("skillPath")
            for script in actual_scripts
        ):
            errors.append(f"Integration index GCP path drift: stale {title}")
        if any(
            not isinstance(script, dict)
            or script.get("checksum") != expected_script.get("checksum")
            for script in actual_scripts
        ):
            errors.append(f"Integration index GCP checksum drift: stale {title}")
    return errors


def validate_skill_catalog(
    skill_payload: dict[str, object],
    ingest_rows: list[dict[str, object]] | None = None,
    row_catalogs: list[dict[str, object]] | None = None,
) -> list[str]:
    errors: list[str] = []
    skill_rows = skill_payload.get("integrations")
    if not isinstance(skill_rows, list):
        return ["Skill catalog integrations must be a list"]
    if skill_payload.get("toolInstall") is not None:
        errors.append("Skill catalog index must not include toolInstall")
    ingest = ingest_rows if ingest_rows is not None else integration_index_payload()["integrations"]
    full_rows = row_catalogs if row_catalogs is not None else skill_row_catalogs()
    full_by_tile = {row.get("tile"): row for row in full_rows}
    ingest_tiles = {row.get("tile") for row in ingest}
    skill_tiles = set()
    for row in skill_rows:
        if not isinstance(row, dict):
            errors.append("Skill catalog row must be an object")
            continue
        tile = row.get("tile")
        skill_tiles.add(tile)
        dumped = json.dumps(row)
        if "documentation/" in dumped:
            errors.append(f"{_row_label(row)}: Skill catalog must not include documentation/ paths")
        for forbidden in INDEX_FORBIDDEN_KEYS:
            if forbidden in row:
                errors.append(f"{_row_label(row)}: index is fat ({forbidden})")
        for bookkeeping in ("methodWaivers", "forkCensus", "documentation"):
            if bookkeeping in row:
                errors.append(
                    f"{_row_label(row)}: Skill catalog index must not include {bookkeeping}"
                )
        for required in INDEX_ENTRY_KEYS:
            if required not in row:
                errors.append(f"{_row_label(row)}: missing {required}")
        catalog_path = row.get("catalogPath")
        expected = catalog_path_for(str(row.get("tile")))
        if catalog_path != expected:
            errors.append(
                f"{_row_label(row)}: catalogPath {catalog_path!r} does not match Row catalog identity"
            )
        full = full_by_tile.get(tile)
        if full is None:
            errors.append(f"{_row_label(row)}: missing Row catalog")
        else:
            if full.get("tile") != row.get("tile"):
                errors.append(f"{_row_label(row)}: catalogPath identity mismatch")
            if "documentation/" in json.dumps(full):
                errors.append(f"{_row_label(row)}: Row catalog must not include documentation/ paths")
            for bookkeeping in ("methodWaivers", "forkCensus", "documentation"):
                if bookkeeping in full:
                    errors.append(
                        f"{_row_label(row)}: Row catalog must not include {bookkeeping}"
                    )
            if not full.get("summary"):
                errors.append(f"{_row_label(row)}: Skill catalog row missing summary")
            if not full.get("captureRequired") and not full.get("connectionFields"):
                errors.append(f"{_row_label(row)}: Skill catalog row missing connectionFields")
            errors.extend(validate_integration_row(full))
    missing = ingest_tiles - skill_tiles
    for tile in sorted(missing, key=str):
        errors.append(f"Skill catalog missing tile {tile!r}")
    return errors


def _validate_generated_gcp_skill_root(skill_root: Path) -> list[str]:
    """Compare one committed GCP row and its generated files to memory."""

    archive_path = skill_root / GCP_TERRAFORM_ARCHIVE_SKILL_PATH
    row_path = skill_root / catalog_path_for("Google GCP")
    # Custom writer fixtures intentionally contain catalogs without the
    # complete Skill-held source tree. Configured roots (including monkeypatch
    # isolates) always receive the full publication validation.
    if skill_root not in SKILL_ROOTS and not archive_path.exists():
        return []

    errors = _validate_gcp_source_archive(archive_path)
    try:
        artifacts = gcp_generated_artifacts(archive_path)
    except ValueError as exc:
        errors.append(f"{archive_path}: cannot regenerate GCP artifacts: {exc}")
        return errors

    expected_row = next(
        row for row in skill_row_catalogs() if row.get("tile") == "Google GCP"
    )
    committed_row: dict[str, object] | None = None
    if not row_path.is_file():
        errors.append(f"generated GCP Row catalog missing at {row_path}")
    else:
        try:
            loaded = json.loads(row_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{row_path}: generated GCP Row catalog is not JSON: {exc}")
        else:
            if not isinstance(loaded, dict):
                errors.append(f"{row_path}: generated GCP Row catalog must be an object")
            else:
                committed_row = loaded
                if committed_row != expected_row:
                    errors.append(
                        f"{row_path}: generated GCP Row catalog is stale versus "
                        "the in-memory catalog"
                    )

    expected_actions = {
        action["prepStepTitle"]: action
        for action in _iter_typed_actions(expected_row)
        if isinstance(action.get("script"), dict)
        and action["script"].get("skillPath")
        in {artifact.skill_path for artifact in artifacts}
    }
    committed_actions = (
        {
            action.get("prepStepTitle"): action
            for action in _iter_typed_actions(committed_row)
        }
        if committed_row is not None
        else {}
    )
    for title, expected_action in expected_actions.items():
        action = committed_actions.get(title)
        if action is None:
            errors.append(f"{row_path}: generated GCP Typed action removed: {title}")
            continue
        if action.get("script") != expected_action.get("script"):
            errors.append(
                f"{row_path}: generated GCP Typed action script metadata drift: {title}"
            )

    for artifact in artifacts:
        path = skill_root / artifact.skill_path
        if not path.is_file():
            errors.append(f"generated GCP artifact missing at {path}")
            continue
        body = path.read_bytes()
        if body != artifact.content:
            errors.append(f"{path}: generated bytes drift from pinned Terraform source")
        actual_checksum = "sha256:" + sha256(body).hexdigest()
        if actual_checksum != artifact.checksum:
            errors.append(
                f"{path}: generated checksum {actual_checksum} does not match "
                f"expected {artifact.checksum}"
            )
        if artifact.executable and path.stat().st_mode & 0o111 == 0:
            errors.append(f"{path}: generated GCP artifact is not executable")
        matching = [
            action
            for action in committed_actions.values()
            if isinstance(action.get("script"), dict)
            and action["script"].get("skillPath") == artifact.skill_path
        ]
        if len(matching) != 1:
            errors.append(
                f"{row_path}: expected exactly one Typed action reference to "
                f"{artifact.skill_path}"
            )
        elif matching[0]["script"].get("checksum") != artifact.checksum:
            errors.append(
                f"{row_path}: Typed action checksum drift for {artifact.skill_path}"
            )
    return errors


def _validate_generated_gcp_publication() -> list[str]:
    """Validate generated GCP publication and dual-Skill-tree identity."""

    errors: list[str] = []
    for root in SKILL_ROOTS:
        errors.extend(_validate_generated_gcp_skill_root(root))
    left, right = SKILL_ROOTS
    for rel in (
        GCP_TERRAFORM_ARCHIVE_SKILL_PATH,
        catalog_path_for("Google GCP"),
        GCP_IAM_ARTIFACT_SKILL_PATH,
        GCP_API_ARTIFACT_SKILL_PATH,
    ):
        a = left / rel
        b = right / rel
        if a.is_file() != b.is_file():
            errors.append(f"{rel}: generated GCP file exists in only one Skill tree")
        elif a.is_file() and a.read_bytes() != b.read_bytes():
            errors.append(f"{rel}: GCP Skill trees are not byte-identical")
    return errors


def _validate_skill_roots_generated() -> list[str]:
    errors: list[str] = []
    left, right = SKILL_ROOTS
    for root in SKILL_ROOTS:
        if (root / "vendor").exists():
            errors.append(f"vendor/ remains under {root}")
        index = root / "integrations.json"
        tools = root / TOOL_INSTALL_FILE
        if not index.is_file():
            errors.append(f"Skill catalog index missing at {index}")
        if not tools.is_file():
            errors.append(f"Tool install file missing at {tools}")
        else:
            try:
                payload = json.loads(tools.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                errors.append(f"Tool install file is not JSON: {exc}")
            else:
                install = payload.get("toolInstall") if isinstance(payload, dict) else None
                if not isinstance(install, dict):
                    errors.append(f"{tools}: must contain toolInstall")
                else:
                    for binary, entry in install.items():
                        if not isinstance(entry, dict):
                            continue
                        missing_keys = [key for key in TOOL_INSTALL_OBJECT_KEYS if key not in entry]
                        if missing_keys:
                            errors.append(f"toolInstall {binary!r} missing {missing_keys}")
        for catalog in (root / INTEGRATIONS_DIR).rglob(ROW_CATALOG_NAME):
            if (catalog.parent / "SKILL.md").exists():
                errors.append(f"row folder must not contain SKILL.md: {catalog.parent}")
    generated = ("integrations.json", TOOL_INSTALL_FILE)
    for name in generated:
        a = left / name
        b = right / name
        if a.is_file() and b.is_file() and a.read_bytes() != b.read_bytes():
            errors.append(f"skill trees differ at {name}")
    left_rows = left / INTEGRATIONS_DIR
    right_rows = right / INTEGRATIONS_DIR
    if left_rows.is_dir() and right_rows.is_dir():
        left_files = {path.relative_to(left_rows) for path in left_rows.rglob("*") if path.is_file()}
        right_files = {path.relative_to(right_rows) for path in right_rows.rglob("*") if path.is_file()}
        if left_files != right_files:
            errors.append("skill trees differ: row folder file set")
        else:
            for rel in sorted(left_files):
                if (left_rows / rel).read_bytes() != (right_rows / rel).read_bytes():
                    errors.append(f"skill trees differ at {INTEGRATIONS_DIR}/{rel}")
    errors.extend(_validate_generated_gcp_publication())
    return errors


def validate_skill_catalog_file(path: Path | None = None) -> list[str]:
    catalog = path if path is not None else SKILL_CATALOG_PATH
    skill_root = catalog.parent if catalog.suffix == ".json" else catalog
    index_path = catalog if catalog.suffix == ".json" else catalog / "integrations.json"
    if not index_path.is_file():
        return [f"Skill catalog missing at {index_path}"]
    try:
        payload = json.loads(index_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"Skill catalog is not JSON: {exc}"]
    if not isinstance(payload, dict):
        return ["Skill catalog must be an object"]
    expected = skill_catalog_payload()
    rows = skill_row_catalogs()
    errors = validate_skill_catalog(payload, row_catalogs=rows)
    if payload.get("integrations") != expected.get("integrations"):
        errors.append("Skill catalog is stale versus the catalog module")
    tools_path = skill_root / TOOL_INSTALL_FILE
    if tools_path.is_file():
        try:
            tools = json.loads(tools_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"Tool install file is not JSON: {exc}")
        else:
            if tools.get("toolInstall") != tool_install_payload():
                errors.append("Skill catalog toolInstall is stale versus the catalog module")
            if payload.get("toolInstall") is not None:
                errors.append("toolInstall must live only in the Tool install file")
    else:
        errors.append(f"Tool install file missing at {tools_path}")
    for entry in payload.get("integrations") or []:
        if not isinstance(entry, dict):
            continue
        rel = entry.get("catalogPath")
        if not isinstance(rel, str):
            continue
        row_file = skill_root / rel
        if not row_file.is_file():
            errors.append(f"Row catalog missing at {rel}")
            continue
        try:
            row = json.loads(row_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{rel} is not JSON: {exc}")
            continue
        if row.get("tile") != entry.get("tile"):
            errors.append(f"{rel}: identity does not match index catalogPath")
        if "documentation/" in json.dumps(row):
            errors.append(f"{rel}: Row catalog must not include documentation/ paths")
        for bookkeeping in ("methodWaivers", "forkCensus", "documentation"):
            if bookkeeping in row:
                errors.append(f"{rel}: Row catalog must not include {bookkeeping}")
    if (skill_root / "vendor").exists():
        errors.append(f"vendor/ remains under {skill_root}")
    errors.extend(_validate_generated_gcp_skill_root(skill_root))
    return errors


def validate_integration_definitions(
    output_dir: Path | None = None,
    rows: list[dict[str, object]] | None = None,
    tool_install: dict[str, object] | None = None,
) -> list[str]:
    payload = integration_index_payload()
    payload_rows = rows if rows is not None else payload["integrations"]
    errors: list[str] = []
    for row in payload_rows:
        errors.extend(validate_integration_row(row))
    errors.extend(validate_duplicate_targets(payload_rows))
    if rows is None and tool_install is None:
        tool_install = payload["toolInstall"]
    if tool_install is not None:
        errors.extend(validate_tool_install(tool_install, payload_rows))
    if output_dir is not None:
        errors.extend(validate_integration_paths(output_dir, rows=payload_rows))
    if rows is None:
        docs = output_dir if output_dir is not None else (REPO_ROOT / "documentation")
        if docs.is_dir():
            errors.extend(_validate_catalog_completeness(docs, payload_rows))
    return errors

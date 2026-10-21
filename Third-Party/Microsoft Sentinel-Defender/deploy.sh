#!/usr/bin/env bash
# Headless cheap Sentinel + SailPoint IdentityNow RestApiPoller install.
# Secrets never go to the repo, stdout, or chat. Only the PAT id is persisted.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT}/.out"
mkdir -p "${OUT_DIR}"

# Defaults (overridable via env / justfile)
: "${SUBSCRIPTION_ID:=180aa0bd-2861-4b9e-9593-eba6a027c2c5}"
: "${SUBSCRIPTION_NAME:=PAYG - Fernando}"
: "${RESOURCE_GROUP:=rg-sentinel-emea-tes-team}"
: "${LOCATION:=northeurope}"
: "${WORKSPACE_NAME:=law-emea-tes-sentinel}"
: "${SAIL_ENV:=emea-tes-team}"
: "${SAIL_TENANT:=company24509-poc}"
: "${SAIL_DOMAIN:=identitynow-demo}"
: "${SAIL_CONFIG:=${HOME}/.sailpoint/config.yaml}"
: "${PAT_NAME:=sentinel-ccf}"
: "${MIN_SOLUTION_VERSION:=3.0.1}"
: "${CONNECTOR_TEMPLATE:=${ROOT}/connector.json}"
: "${CONTENT_DIR:=${ROOT}/content}"
: "${PLAYBOOK_TEMPLATE:=${CONTENT_DIR}/response/playbook.json}"
: "${PLAYBOOK_NAME:=sailpoint-isc-response}"
: "${RESPONSE_DRY_RUN:=true}"
: "${KEY_VAULT_NAME:=}"
# Opt-in response credentials (never persisted). Prefer env vars over files.
: "${RESPONSE_CLIENT_ID:=}"
: "${RESPONSE_CLIENT_SECRET:=}"

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

ensure_log_analytics_ext() {
  if ! az extension show -n log-analytics >/dev/null 2>&1; then
    log "Installing az log-analytics extension"
    az extension add -n log-analytics -y >/dev/null
  fi
}

default_key_vault_name() {
  # Key Vault names: 3-24 chars, alphanumeric. Derive a stable unique-ish name.
  local suffix
  suffix="$(printf '%s' "${SUBSCRIPTION_ID}${RESOURCE_GROUP}" | shasum -a 256 | cut -c1-8)"
  printf 'kvsp%s' "${suffix}"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

version_ge() {
  # Return 0 if $1 >= $2 (semver x.y.z)
  printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1 | grep -qx "$2"
}

workspace_id() {
  az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query id -o tsv
}

workspace_customer_id() {
  az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query customerId -o tsv
}

sentinel_path() {
  local ws
  ws="$(workspace_id)"
  printf '%s/providers/Microsoft.SecurityInsights' "${ws}"
}

# ---------------------------------------------------------------------------
# preflight
# ---------------------------------------------------------------------------
cmd_preflight() {
  require_cmd az
  require_cmd jq
  require_cmd sail
  require_cmd curl
  require_cmd python3

  log "Checking Azure login and subscription"
  local acct_json acct_id acct_name
  acct_json="$(az account show -o json)" \
    || die "az is not logged in. Run: az login"
  acct_id="$(jq -r '.id' <<<"${acct_json}")"
  acct_name="$(jq -r '.name' <<<"${acct_json}")"
  if [[ "${acct_id}" != "${SUBSCRIPTION_ID}" ]]; then
    die "Expected subscription ${SUBSCRIPTION_ID} (${SUBSCRIPTION_NAME}), got ${acct_id} (${acct_name}). Run: az account set --subscription ${SUBSCRIPTION_ID}"
  fi
  log "Subscription OK: ${acct_name} (${acct_id})"
  printf '%s\n' "${acct_id}" >"${OUT_DIR}/subscription-id.txt"

  log "Ensuring West Europe is available"
  az account list-locations --query "[?name=='${LOCATION}'].name" -o tsv \
    | grep -qx "${LOCATION}" \
    || die "Location ${LOCATION} is not available on this subscription"

  log "Registering Microsoft.SecurityInsights and related providers"
  for ns in Microsoft.OperationalInsights Microsoft.SecurityInsights Microsoft.Insights Microsoft.OperationsManagement Microsoft.Logic Microsoft.KeyVault Microsoft.Authorization; do
    az provider register -n "${ns}" --wait >/dev/null
    local st
    st="$(az provider show -n "${ns}" --query registrationState -o tsv)"
    [[ "${st}" == "Registered" ]] || die "${ns} state is ${st}"
    log "  ${ns}: ${st}"
  done

  log "Checking sail env ${SAIL_ENV} via config (sail env list hangs when piped)"
  [[ -f "${SAIL_CONFIG}" ]] || die "Sail config not found at ${SAIL_CONFIG}"
  python3 - "${SAIL_CONFIG}" "${SAIL_ENV}" <<'PY'
import re, sys
cfg_path, env = sys.argv[1], sys.argv[2]
text = open(cfg_path).read()
# Match "    emea-tes-team:" under environments without requiring PyYAML
pat = re.compile(rf'(?m)^(?P<indent>\s*){re.escape(env)}:\s*$')
m = pat.search(text)
if not m:
    raise SystemExit(f"env {env} not found in {cfg_path}")
indent = m.group("indent")
# Collect immediate child keys (baseurl etc.) at indent+4 spaces
block_start = m.end()
child_indent = indent + "    "
baseurl = ""
for line in text[block_start:].splitlines():
    if line.strip() == "":
        continue
    if not line.startswith(child_indent):
        # Dedented or sibling env
        if re.match(r"^\s+\S", line) and not line.startswith(child_indent):
            break
        if re.match(r"^\S", line):
            break
        break
    km = re.match(rf"^{re.escape(child_indent)}([A-Za-z0-9_]+):\s*(.*)$", line)
    if km and km.group(1) == "baseurl":
        baseurl = km.group(2).strip().strip('"').strip("'")
print(f"sail env OK: {env} -> {baseurl or '(baseurl not parsed)'}")
PY

  log "Preflight OK"
}

# ---------------------------------------------------------------------------
# workspace
# ---------------------------------------------------------------------------
cmd_workspace() {
  log "Creating resource group ${RESOURCE_GROUP} in ${LOCATION}"
  az group create \
    --name "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --tags purpose=sentinel-sailpoint tenant="${SAIL_TENANT}" \
    -o none

  if az monitor log-analytics workspace show \
      --resource-group "${RESOURCE_GROUP}" \
      --workspace-name "${WORKSPACE_NAME}" \
      -o none 2>/dev/null; then
    log "Log Analytics workspace ${WORKSPACE_NAME} already exists"
  else
    log "Creating Log Analytics workspace ${WORKSPACE_NAME} (PerGB2018, 90-day retention)"
    az monitor log-analytics workspace create \
      --resource-group "${RESOURCE_GROUP}" \
      --workspace-name "${WORKSPACE_NAME}" \
      --location "${LOCATION}" \
      --sku PerGB2018 \
      --retention-time 90 \
      -o none
  fi

  local sku retention
  sku="$(az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query sku.name -o tsv)"
  retention="$(az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query retentionInDays -o tsv)"
  [[ "${sku}" == "PerGB2018" ]] || die "Workspace sku is ${sku}, expected PerGB2018 (pay-as-you-go)"
  log "Workspace sku=${sku} retentionInDays=${retention}"

  local ws_id onboard_url
  ws_id="$(workspace_id)"
  onboard_url="${ws_id}/providers/Microsoft.SecurityInsights/onboardingStates/default?api-version=2024-03-01"
  log "Enabling Microsoft Sentinel on ${WORKSPACE_NAME}"
  az rest --method put --url "${onboard_url}" --body "{}" -o none

  printf '%s\n' "${ws_id}" >"${OUT_DIR}/workspace-id.txt"
  printf '%s\n' "${WORKSPACE_NAME}" >"${OUT_DIR}/workspace-name.txt"
  printf '%s\n' "$(workspace_customer_id)" >"${OUT_DIR}/workspace-customer-id.txt"
  log "Workspace + Sentinel OK"
}

# ---------------------------------------------------------------------------
# solution
# ---------------------------------------------------------------------------
cmd_solution() {
  local base packages_url package_json content_id content_product_id package_version display_name
  base="$(sentinel_path)"
  packages_url="${base}/contentProductPackages?api-version=2024-03-01"

  log "Resolving SailPoint IdentityNow Content Hub package"
  package_json="$(az rest --method get --url "${packages_url}" -o json)"
  printf '%s\n' "${package_json}" >"${OUT_DIR}/contentProductPackages.json"

  python3 - "${OUT_DIR}" <<'PY2'
import json, sys
from pathlib import Path
out = Path(sys.argv[1])
pkgs = json.load(open(out / "contentProductPackages.json"))
cands = []
for v in pkgs.get("value", []):
    props = v.get("properties") or {}
    blob = " ".join([
        str(props.get("contentId") or ""),
        str(props.get("displayName") or ""),
        str((props.get("source") or {}).get("name") or ""),
        str(v.get("name") or ""),
    ])
    if "sailpoint" in blob.lower():
        cands.append(v)
if not cands:
    raise SystemExit("Could not find SailPoint IdentityNow in contentProductPackages")
cands.sort(key=lambda v: (v.get("properties") or {}).get("version") or "0.0.0")
best = cands[-1]
props = best["properties"]
meta = {
    "contentId": props["contentId"],
    "contentProductId": props.get("contentProductId") or best["name"],
    "version": props.get("version") or "0.0.0",
    "displayName": props.get("displayName") or "SailPoint",
    "contentKind": props.get("contentKind") or "Solution",
    "contentSchemaVersion": props.get("contentSchemaVersion"),
    "source": props.get("source"),
    "author": props.get("author"),
    "support": props.get("support"),
    "dependencies": props.get("dependencies"),
    "firstPublishDate": props.get("firstPublishDate"),
    "lastPublishDate": props.get("lastPublishDate"),
    "publisherDisplayName": props.get("publisherDisplayName"),
    "descriptionHtml": props.get("descriptionHtml"),
    "icon": props.get("icon"),
    "categories": props.get("categories"),
}
json.dump(meta, open(out / "package-meta.json", "w"), indent=2)
body = {"properties": {k: v for k, v in meta.items() if v is not None}}
json.dump(body, open(out / "package-install-body.json", "w"))
print(meta["contentId"], meta["version"], meta["contentProductId"])
PY2

  read -r content_id package_version content_product_id < <(
    jq -r '[.contentId, .version, .contentProductId] | @tsv' "${OUT_DIR}/package-meta.json"
  )

  version_ge "${package_version}" "${MIN_SOLUTION_VERSION}" \
    || die "SailPoint package version ${package_version} is below required ${MIN_SOLUTION_VERSION}"

  log "Installing content package ${content_id} version ${package_version}"
  local install_url
  install_url="${base}/contentPackages/${content_id}?api-version=2024-03-01"
  az rest --method put --url "${install_url}" --body @"${OUT_DIR}/package-install-body.json" -o json \
    >"${OUT_DIR}/contentPackage-install.json" \
    || die "Failed to install content package ${content_id}"

  printf '%s\n' "${content_id}" >"${OUT_DIR}/package-id.txt"
  printf '%s\n' "${package_version}" >"${OUT_DIR}/package-version.txt"
  log "Solution package registered: id=${content_id} version=${package_version}"

  # Content Hub package install registers metadata; the CCF connector definition
  # is ensured explicitly so RestApiPoller can reference it (and analytic rules /
  # playbooks stay uncreated).
  local def_url
  def_url="${base}/dataConnectorDefinitions/SailPointIdentityNowConnector?api-version=2024-09-01"
  if az rest --method get --url "${def_url}" -o none 2>/dev/null; then
    log "Connector definition SailPointIdentityNowConnector present"
  else
    log "Creating dataConnectorDefinitions/SailPointIdentityNowConnector from upstream CCF definition"
    curl -fsSL 'https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Solutions/SailPointIdentityNow/Data%20Connectors/SearchEvent_CCF/SailPointIdentityNow_ConnectorDefinition.json' \
      -o "${OUT_DIR}/connector-definition-upstream.json"
    python3 - "${OUT_DIR}" "${LOCATION}" <<'PY3'
import json, sys
from pathlib import Path
out, loc = Path(sys.argv[1]), sys.argv[2]
src = json.load(open(out / "connector-definition-upstream.json"))
body = {"kind": src["kind"], "properties": src["properties"]}
# location is optional on some api versions; include for consistency
body["location"] = loc
json.dump(body, open(out / "connector-definition-body.json", "w"))
PY3
    az rest --method put --url "${def_url}" --body @"${OUT_DIR}/connector-definition-body.json" -o json \
      >"${OUT_DIR}/connector-definition.json" \
      || die "Failed to create dataConnectorDefinitions/SailPointIdentityNowConnector"
    log "Connector definition created"
  fi
}

# Temporarily force sail config debug:false so Authorization headers are not dumped.
# Restores the previous debug value on RETURN.
sail_quiet_begin() {
  SAIL_DEBUG_BACKUP="$(python3 - "${SAIL_CONFIG}" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path).read()
m = re.search(r'(?m)^debug:\s*(\S+)', text)
print(m.group(1) if m else "")
PY
)"
  python3 - "${SAIL_CONFIG}" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path).read()
new, n = re.subn(r'(?m)^debug:\s*\S+', 'debug: false', text, count=1)
if n == 0:
    new = 'debug: false\n' + text
open(path, 'w').write(new)
PY
}

sail_quiet_end() {
  python3 - "${SAIL_CONFIG}" "${SAIL_DEBUG_BACKUP:-}" <<'PY'
import re, sys
path, prev = sys.argv[1], sys.argv[2]
text = open(path).read()
if prev == "":
    new = re.sub(r'(?m)^debug:\s*\S+\n?', '', text, count=1)
else:
    new = re.sub(r'(?m)^debug:\s*\S+', f'debug: {prev}', text, count=1)
open(path, 'w').write(new)
PY
}

# ---------------------------------------------------------------------------
# connect
# ---------------------------------------------------------------------------
cmd_connect() {
  [[ -f "${CONNECTOR_TEMPLATE}" ]] || die "Missing ARM template: ${CONNECTOR_TEMPLATE}"

  local pat_id_file="${OUT_DIR}/pat-id.txt"
  local client_id secret tmpdir params_file expiration_date body_file response_file http_code
  local sail_err

  # Skip only when all three RestApiPollers (events, accountactivities, workflowsummaries) exist.
  local required_types='["SailPointISC_Events_CL","SailPointISC_AccountActivities_CL","SailPointISC_WorkflowHistory_CL","SailPointISC_Identities_CL"]'
  if [[ "${FORCE_RECONNECT:-}" != "1" ]] && az rest --method get \
      --url "$(sentinel_path)/dataConnectors?api-version=2024-09-01" \
      -o json 2>/dev/null \
      | jq -e --arg t "${SAIL_TENANT}" --argjson need "${required_types}" '
          ($need) as $need
          | [
              .value[]
              | select(.kind=="RestApiPoller")
              | select((.properties.addOnAttributes.tenantId // "") == $t)
              | .properties.dataType
            ]
          | unique
          | contains($need)
        ' >/dev/null 2>&1; then
    log "All RestApiPollers for ${SAIL_TENANT} already present; skipping PAT create + redeploy (FORCE_RECONNECT=1 to redo)"
    return 0
  fi
  log "Deploying/updating RestApiPollers for events + accountactivities + workflowsummaries"

  expiration_date="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(days=365)).strftime("%Y-%m-%dT%H:%M:%S.000Z"))
PY
)"

  log "Creating SailPoint PAT ${PAT_NAME} (scope sp:search:read only)"
  body_file="$(mktemp)"
  response_file="$(mktemp)"
  sail_err="$(mktemp)"
  tmpdir="$(mktemp -d)"
  trap 'sail_quiet_end; rm -rf "${tmpdir:-}"; rm -f "${body_file:-}" "${response_file:-}" "${sail_err:-}"; trap - RETURN' RETURN
  sail_quiet_begin
  umask 077

  # Revoke any prior PAT with the same name so create is idempotent (secret is unrecoverable).
  local list_out
  list_out="$(mktemp)"
  sail api get /personal-access-tokens/v1 --env "${SAIL_ENV}" -q 'owner-id=me' -q limit=250 \
    >"${list_out}.out" 2>"${list_out}.err" || true
  cat "${list_out}.out" "${list_out}.err" >"${list_out}"
  python3 - "${list_out}" "${PAT_NAME}" "${SAIL_ENV}" <<'PY'
import json, re, subprocess, sys
text = open(sys.argv[1]).read()
name, env = sys.argv[2], sys.argv[3]
arr = None
for i, ch in enumerate(text):
    if ch != '[':
        continue
    try:
        candidate, _ = json.JSONDecoder().raw_decode(text[i:])
    except Exception:
        continue
    if isinstance(candidate, list):
        arr = candidate
        break
if not arr:
    sys.exit(0)
for pat in arr:
    if pat.get("name") == name and pat.get("id"):
        subprocess.run(
            ["sail", "api", "delete", f"/personal-access-tokens/v1/{pat['id']}", "--env", env],
            check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        print(f"revoked prior PAT id={pat['id']}")
PY
  rm -f "${list_out}" "${list_out}.out" "${list_out}.err"

  cat >"${body_file}" <<EOF
{"name":"${PAT_NAME}","scope":["sp:search:read"],"expirationDate":"${expiration_date}","userAwareTokenNeverExpires":false}
EOF

  # sail api prints Status on stdout and the JSON body on stderr (even with debug:false).
  # Merge both into response_file, then extract the JSON object. Never print it.
  local status_file
  status_file="$(mktemp)"
  if ! sail api post /personal-access-tokens/v1 --env "${SAIL_ENV}" --body-file "${body_file}" \
      >"${status_file}" 2>"${sail_err}"; then
    sail api post /personal-access-tokens/v1 --env "${SAIL_ENV}" \
      --body "$(cat "${body_file}")" \
      >"${status_file}" 2>"${sail_err}" \
      || die "Failed to create PAT (HTTP/CLI error; secret not printed)"
  fi
  cat "${status_file}" "${sail_err}" >"${response_file}"
  : >"${sail_err}"
  rm -f "${status_file}"

  python3 - "${response_file}" <<'PY'
import sys, re, json
path = sys.argv[1]
text = open(path).read()
# Prefer an object that includes a secret (create response)
obj = None
for m in re.finditer(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', text, re.S):
    # Broaden: find from each '{' to matching end via raw decode attempts
    pass
# Robust scan: try every '{' as a start offset
for i, ch in enumerate(text):
    if ch != '{':
        continue
    try:
        candidate, _ = json.JSONDecoder().raw_decode(text[i:])
    except Exception:
        continue
    if isinstance(candidate, dict) and candidate.get('secret') and candidate.get('id'):
        obj = candidate
        break
if obj is None:
    # Surface non-secret error detail if present
    err = None
    for i, ch in enumerate(text):
        if ch != '{':
            continue
        try:
            candidate, _ = json.JSONDecoder().raw_decode(text[i:])
        except Exception:
            continue
        if isinstance(candidate, dict) and (candidate.get('detailCode') or candidate.get('messages')):
            err = candidate.get('detailCode') or candidate
            break
    raise SystemExit(f'PAT create response missing id/secret ({err})')
json.dump(
    {"id": obj["id"], "clientId": obj.get("clientId") or obj["id"], "secret": obj["secret"]},
    open(path, 'w'),
)
PY

  pat_id="$(jq -r '.id' <"${response_file}")"
  client_id="$(jq -r '.clientId' <"${response_file}")"
  secret="$(jq -r '.secret' <"${response_file}")"
  # Scrub the response file immediately after loading into memory
  : >"${response_file}"
  printf '%s\n' "${pat_id}" >"${pat_id_file}"
  log "PAT created id=${pat_id} (secret held in memory only)"

  log "Smoke-testing OAuth token endpoint (printing HTTP status only)"
  http_code="$(
    curl -sS -o /dev/null -w '%{http_code}' \
      -u "${client_id}:${secret}" \
      -X POST "https://${SAIL_TENANT}.api.${SAIL_DOMAIN}.com/oauth/token" \
      -d 'grant_type=client_credentials' \
      -d 'scope=sp:search:read'
  )"
  log "Token endpoint HTTP ${http_code}"
  [[ "${http_code}" == "200" ]] \
    || die "OAuth token smoke test failed with HTTP ${http_code}. Not deploying connector."

  params_file="${tmpdir}/params.json"
  umask 077
  jq -n \
    --arg ws "${WORKSPACE_NAME}" \
    --arg loc "${LOCATION}" \
    --arg tenant "${SAIL_TENANT}" \
    --arg domain "${SAIL_DOMAIN}" \
    --arg cid "${client_id}" \
    --arg sec "${secret}" \
    '{
      workspaceName: {value: $ws},
      location: {value: $loc},
      tenantId: {value: $tenant},
      identityNowDomain: {value: $domain},
      clientId: {value: $cid},
      clientSecret: {value: $sec}
    }' >"${params_file}"

  secret=''
  unset secret
  client_id=''
  unset client_id

  log "Deploying DCE + table + DCR + RestApiPoller"
  # Redact secure params from deployment stdout before saving
  if ! az deployment group create \
      --resource-group "${RESOURCE_GROUP}" \
      --name "sailpoint-ccf-$(date +%Y%m%d%H%M%S)" \
      --template-file "${CONNECTOR_TEMPLATE}" \
      --parameters "@${params_file}" \
      -o json >"${tmpdir}/deployment-raw.json"; then
    die "ARM deployment failed. Temp params were shredded; see Azure activity log."
  fi
  jq 'walk(if type=="object" then with_entries(if .key=="clientSecret" or .key=="ClientSecret" then .value="***" else . end) else . end)' \
    "${tmpdir}/deployment-raw.json" >"${OUT_DIR}/connector-deployment.json" \
    || cp "${tmpdir}/deployment-raw.json" "${OUT_DIR}/connector-deployment.json"

  rm -rf "${tmpdir}"
  tmpdir="$(mktemp -d)"  # empty placeholder so RETURN trap rm is a no-op
  log "Connector deployed"
}

# ---------------------------------------------------------------------------
# content — KQL functions, analytics rules, workbook
# ---------------------------------------------------------------------------
cmd_content() {
  require_cmd az
  require_cmd jq
  require_cmd python3
  [[ -d "${CONTENT_DIR}" ]] || die "Content directory missing: ${CONTENT_DIR}"

  local ws_id customer_id
  ws_id="$(workspace_id)"
  customer_id="$(workspace_customer_id)"
  ensure_log_analytics_ext

  log "Deploying KQL functions and shared saved searches"
  local search_template
  search_template="$(mktemp)"
  python3 "${CONTENT_DIR}/kql/build_saved_searches.py" template "${search_template}"
  az deployment group create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "sailpoint-kql-$(date +%Y%m%d%H%M%S)" \
    --template-file "${search_template}" \
    --parameters workspaceName="${WORKSPACE_NAME}" \
    -o none
  rm -f "${search_template}"
  log "KQL functions and shared saved searches OK"

  log "Deploying analytics rules"
  local rule_file rule_id body_file
  for rule_file in "${CONTENT_DIR}"/analytics/*.json; do
    [[ -f "${rule_file}" ]] || continue
    rule_id="$(jq -r '.id' "${rule_file}")"
    [[ -n "${rule_id}" && "${rule_id}" != "null" ]] || die "Rule missing id: ${rule_file}"
    body_file="$(mktemp)"
    jq '{
      kind: .kind,
      etag: null,
      properties: ({
        displayName: .displayName,
        description: .description,
        severity: .severity,
        enabled: .enabled,
        query: .query,
        queryFrequency: .queryFrequency,
        queryPeriod: .queryPeriod,
        triggerOperator: .triggerOperator,
        triggerThreshold: .triggerThreshold,
        suppressionEnabled: .suppressionEnabled,
        suppressionDuration: .suppressionDuration,
        tactics: .tactics,
        techniques: (.techniques // []),
        entityMappings: .entityMappings,
        customDetails: (.customDetails // {}),
        eventGroupingSettings: .eventGroupingSettings,
        incidentConfiguration: .incidentConfiguration
      } + (if .alertDetailsOverride then {alertDetailsOverride: .alertDetailsOverride} else {} end))
    }' "${rule_file}" >"${body_file}"
    az rest --method put \
      --url "${ws_id}/providers/Microsoft.SecurityInsights/alertRules/${rule_id}?api-version=2023-02-01" \
      --body @"${body_file}" \
      -o none
    rm -f "${body_file}"
    log "  rule $(jq -r '.displayName' "${rule_file}")"
  done
  jq -n --argjson rules "$(jq -s '[.[] | {id, displayName, severity, enabled}]' "${CONTENT_DIR}"/analytics/*.json)" \
    '{deployedAt: (now|todate), rules: $rules}' >"${OUT_DIR}/analytics-rules.json"

  log "Deploying SailPoint ISC Operations workbook"
  local wb_id wb_body
  wb_id="a1b2c3d4-e5f6-7890-abcd-ef1234567801"
  wb_body="$(python3 - "${CONTENT_DIR}/workbooks/sailpoint-isc-operations.json" "${LOCATION}" "${ws_id}" "${wb_id}" <<'PY'
import json, sys
src, location, ws_id, wb_id = sys.argv[1:5]
workbook = json.load(open(src))
serialized = json.dumps(workbook, separators=(",", ":"))
resource = {
    "kind": "shared",
    "location": location,
    "properties": {
        "displayName": "SailPoint ISC Operations",
        "serializedData": serialized,
        "category": "sentinel",
        "sourceId": ws_id,
        "description": "Operator workbook for SailPoint ISC telemetry, detections, and ingestion health.",
        "version": "1.0",
    },
    "tags": {
        "hidden-title": "SailPoint ISC Operations",
        "purpose": "sentinel-sailpoint",
    },
}
print(json.dumps(resource))
PY
)"
  az rest --method put \
    --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Insights/workbooks/${wb_id}?api-version=2022-04-01" \
    --body "${wb_body}" \
    -o json >"${OUT_DIR}/workbook-deploy.json"
  log "Workbook OK (id=${wb_id})"

  printf '%s\n' "${wb_id}" >"${OUT_DIR}/workbook-id.txt"
  log "Content deploy complete"
}

# ---------------------------------------------------------------------------
# response — opt-in Logic App + Key Vault (destructive path gated by dryRun)
# ---------------------------------------------------------------------------
cmd_response_capability() {
  require_cmd curl
  require_cmd jq
  local api_base discovery ssf_status="unavailable"
  api_base="https://${SAIL_TENANT}.api.${SAIL_DOMAIN}.com"

  log "Checking SailPoint Shared Signals capability (informational)"
  # ISC SSF transmitter discovery (tenant-side). Microsoft CAEP transmitter is separate.
  if discovery="$(curl -fsS --max-time 15 "${api_base}/.well-known/ssf-configuration" 2>/dev/null)"; then
    printf '%s\n' "${discovery}" >"${OUT_DIR}/ssf-configuration.json"
    ssf_status="isc-transmitter-discovery-ok"
    log "  ISC SSF discovery document reachable"
  else
    warn "  ISC SSF discovery not reachable (expected on many tenants / entitlement tiers)"
    printf '%s\n' '{"available":false}' >"${OUT_DIR}/ssf-configuration.json"
  fi

  # Microsoft does not expose a stable public CAEP/SSF transmitter discovery URL for Sentinel
  # in this subscription context; Response Actions API remains the supported containment path.
  local ms_transmitter="${MICROSOFT_SSF_DISCOVERY_URL:-}"
  if [[ -n "${ms_transmitter}" ]]; then
    if curl -fsS --max-time 15 "${ms_transmitter}" >/dev/null 2>&1; then
      log "  Microsoft SSF discovery URL reachable: ${ms_transmitter}"
      ssf_status="microsoft-transmitter-ok"
    else
      warn "  MICROSOFT_SSF_DISCOVERY_URL set but not reachable; falling back to Response Actions"
    fi
  else
    log "  No MICROSOFT_SSF_DISCOVERY_URL set — using Response Actions API path"
  fi

  jq -n \
    --arg status "${ssf_status}" \
    --arg path "response-actions" \
    --arg tenant "${SAIL_TENANT}" \
    '{ssfStatus:$status, selectedPath:$path, tenant:$tenant, note:"Prefer SSF only when a Microsoft CAEP/SSF transmitter discovery URL is available; otherwise POST /intelligence/v1/response-actions."}' \
    >"${OUT_DIR}/response-capability.json"
  cat "${OUT_DIR}/response-capability.json"
}

cmd_response() {
  require_cmd az
  require_cmd jq
  [[ -f "${PLAYBOOK_TEMPLATE}" ]] || die "Playbook template missing: ${PLAYBOOK_TEMPLATE}"

  cmd_response_capability

  if [[ -z "${RESPONSE_CLIENT_ID}" || -z "${RESPONSE_CLIENT_SECRET}" ]]; then
    die "RESPONSE_CLIENT_ID and RESPONSE_CLIENT_SECRET are required (PAT/OAuth with sp:identity-sec-intel:read/write). Do not reuse the sp:search:read ingestion PAT."
  fi

  local kv_name dry_run_bool
  kv_name="${KEY_VAULT_NAME:-$(default_key_vault_name)}"
  dry_run_bool="${RESPONSE_DRY_RUN}"
  case "${dry_run_bool}" in
    true|false) ;;
    1) dry_run_bool=true ;;
    0) dry_run_bool=false ;;
    *) die "RESPONSE_DRY_RUN must be true|false (got ${RESPONSE_DRY_RUN})" ;;
  esac

  log "Deploying response playbook ${PLAYBOOK_NAME} (dryRun=${dry_run_bool}, keyVault=${kv_name})"
  local tmpdir params_file
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' RETURN
  umask 077
  params_file="${tmpdir}/params.json"
  jq -n \
    --arg playbook "${PLAYBOOK_NAME}" \
    --arg kv "${kv_name}" \
    --arg loc "${LOCATION}" \
    --arg tenant "${SAIL_TENANT}" \
    --arg domain "${SAIL_DOMAIN}" \
    --arg cid "${RESPONSE_CLIENT_ID}" \
    --arg csec "${RESPONSE_CLIENT_SECRET}" \
    --argjson dry "${dry_run_bool}" \
    '{
      playbookName: {value: $playbook},
      keyVaultName: {value: $kv},
      location: {value: $loc},
      sailTenant: {value: $tenant},
      sailDomain: {value: $domain},
      defaultActionType: {value: "DISABLE_ACCOUNT"},
      clientId: {value: $cid},
      clientSecret: {value: $csec},
      dryRun: {value: $dry}
    }' >"${params_file}"

  if ! az deployment group create \
      --resource-group "${RESOURCE_GROUP}" \
      --name "sailpoint-response-$(date +%Y%m%d%H%M%S)" \
      --template-file "${PLAYBOOK_TEMPLATE}" \
      --parameters "@${params_file}" \
      -o json >"${tmpdir}/deployment-raw.json"; then
    die "Response playbook deployment failed. Secrets were not persisted."
  fi

  jq 'walk(if type=="object" then with_entries(
        if (.key|test("(?i)secret|password|clientSecret|clientId")) then .value="***" else . end
      ) else . end)' \
    "${tmpdir}/deployment-raw.json" >"${OUT_DIR}/response-deployment.json" \
    || printf '{"status":"deployed","secretsRedacted":true}\n' >"${OUT_DIR}/response-deployment.json"

  printf '%s\n' "${kv_name}" >"${OUT_DIR}/keyvault-name.txt"
  printf '%s\n' "${PLAYBOOK_NAME}" >"${OUT_DIR}/playbook-name.txt"
  printf '%s\n' "${dry_run_bool}" >"${OUT_DIR}/response-dry-run.txt"
  rm -rf "${tmpdir}"
  tmpdir="$(mktemp -d)"
  log "Response playbook deployed (credentials only in Key Vault; dryRun=${dry_run_bool})"
  log "Configure ISC SecOps Identity Intelligence Response Action workflow with approval before setting RESPONSE_DRY_RUN=false"
}

cmd_verify_content() {
  require_cmd az
  require_cmd jq
  ensure_log_analytics_ext
  local ws_id customer_id
  ws_id="$(workspace_id)"
  customer_id="$(workspace_customer_id)"

  log "Verifying saved-search functions and shared queries"
  az monitor log-analytics workspace saved-search list \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    -o json 2>/dev/null \
    | jq '[.[] | select(.category=="SailPointISC" or (.category|tostring|startswith("SailPoint -")) or (.name|tostring|contains("SailPointISC"))) | {name, displayName, functionAlias, category}]' \
    >"${OUT_DIR}/saved-searches.json" || warn "Could not list saved searches"

  local shared_count
  shared_count="$(jq '[.[] | select(.category|tostring|startswith("SailPoint -"))] | length' "${OUT_DIR}/saved-searches.json")"
  [[ "${shared_count}" -ge 27 ]] || die "Expected >=27 shared SailPoint saved searches, found ${shared_count}"
  log "Shared saved searches: ${shared_count}"

  log "Verifying analytics rules"
  az rest --method get \
    --url "${ws_id}/providers/Microsoft.SecurityInsights/alertRules?api-version=2023-02-01" -o json \
    | jq '[.value[] | select(.properties.displayName|startswith("SailPoint ISC")) | {name, displayName: .properties.displayName, enabled: .properties.enabled, severity: .properties.severity}]' \
    >"${OUT_DIR}/analytics-rules-live.json"

  local rule_count
  rule_count="$(jq 'length' "${OUT_DIR}/analytics-rules-live.json")"
  [[ "${rule_count}" -ge 3 ]] || warn "Expected >=3 SailPoint ISC analytics rules, found ${rule_count}"

  log "Smoke-testing KQL against SailPointISC_Events_CL"
  az monitor log-analytics query \
    --workspace "${customer_id}" \
    --analytics-query '
      SailPointISC_Events_CL
      | where TimeGenerated > ago(30d)
      | summarize RowCount=count(), Actors=dcount(ActorName), Failures=countif(toupper(Status) in ("FAILED","FAILURE","ERROR"))
    ' -o json >"${OUT_DIR}/content-smoke.json"
  jq -r 'if type=="array" then .[0] else . end | "Events RowCount=\(.RowCount // 0) Actors=\(.Actors // 0) Failures=\(.Failures // 0)"' \
    "${OUT_DIR}/content-smoke.json"

  log "Smoke-testing shared saved searches"
  python3 "${CONTENT_DIR}/kql/build_saved_searches.py" smoke "${customer_id}"

  if [[ -f "${OUT_DIR}/workbook-id.txt" ]]; then
    log "Workbook id: $(cat "${OUT_DIR}/workbook-id.txt")"
  fi
  if [[ -f "${OUT_DIR}/playbook-name.txt" ]]; then
    log "Playbook: $(cat "${OUT_DIR}/playbook-name.txt") dryRun=$(cat "${OUT_DIR}/response-dry-run.txt" 2>/dev/null || echo unknown)"
  fi
  log "Content verify complete"
}

# ---------------------------------------------------------------------------
# verify
# ---------------------------------------------------------------------------
cmd_verify() {
  local sku reservation connectors_json connector_count rows_json usage_json
  log "Asserting pay-as-you-go workspace sku"
  sku="$(az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query sku.name -o tsv)"
  reservation="$(az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query sku.capacityReservationLevel -o tsv 2>/dev/null || echo '')"
  [[ "${sku}" == "PerGB2018" ]] || die "sku=${sku}, expected PerGB2018"
  if [[ -n "${reservation}" && "${reservation}" != "None" && "${reservation}" != "null" ]]; then
    die "capacityReservationLevel=${reservation}; commitment tier must not be set"
  fi
  log "sku=${sku} capacityReservationLevel=${reservation:-none}"

  log "Checking RestApiPoller connector"
  connectors_json="$(az rest --method get \
    --url "$(sentinel_path)/dataConnectors?api-version=2024-09-01" -o json)"
  printf '%s\n' "${connectors_json}" >"${OUT_DIR}/dataConnectors.json"
  connector_count="$(jq --arg t "${SAIL_TENANT}" '
    [.value[]
      | select(.kind=="RestApiPoller")
      | select((.properties.addOnAttributes.tenantId // "") == $t)
    ] | length
  ' <<<"${connectors_json}")"
  [[ "${connector_count}" -ge 1 ]] || die "No RestApiPoller found for tenant ${SAIL_TENANT}"
  jq --arg t "${SAIL_TENANT}" '
    .value[]
    | select(.kind=="RestApiPoller")
    | select((.properties.addOnAttributes.tenantId // "") == $t)
    | {name, kind, dataType: .properties.dataType, tenantId: .properties.addOnAttributes.tenantId, domain: .properties.addOnAttributes.identityNowDomain}
  ' <<<"${connectors_json}"

  ensure_log_analytics_ext

  local customer_id
  customer_id="$(workspace_customer_id)"

  log "Querying SailPoint custom tables (first rows can take ~15 minutes per poller)"
  local table
  for table in SailPointISC_Events_CL SailPointISC_AccountActivities_CL SailPointISC_WorkflowHistory_CL SailPointISC_Identities_CL; do
    if rows_json="$(az monitor log-analytics query \
        --workspace "${customer_id}" \
        --analytics-query "${table} | summarize RowCount=count(), LastSeen=max(TimeGenerated)" \
        -o json 2>"${OUT_DIR}/${table}-query.stderr")"; then
      printf '%s\n' "${rows_json}" >"${OUT_DIR}/${table}-summary.json"
      jq -r --arg t "${table}" \
        'if type=="array" then .[0] else . end | "\($t) RowCount=\(.RowCount // .rowCount // 0) LastSeen=\(.LastSeen // .lastSeen // "none")"' \
        <<<"${rows_json}" || log "${table}: ${rows_json}"
    else
      warn "${table} not queryable yet. See ${OUT_DIR}/${table}-query.stderr"
    fi
  done

  log "Checking Usage by DataType (SailPoint-only expectation)"
  if usage_json="$(az monitor log-analytics query \
      --workspace "${customer_id}" \
      --analytics-query 'Usage | where TimeGenerated > ago(7d) | summarize IngestedMB=sum(Quantity) by DataType | order by IngestedMB desc' \
      -o json 2>"${OUT_DIR}/usage-query.stderr")"; then
    printf '%s\n' "${usage_json}" >"${OUT_DIR}/usage.json"
    jq -r '.[]? | "\(.DataType // .dataType)\t\(.IngestedMB // .ingestedMB)"' <<<"${usage_json}" \
      || printf '%s\n' "${usage_json}"
  else
    warn "Usage query unavailable yet. See ${OUT_DIR}/usage-query.stderr"
  fi

  log "Verify complete"
}

# ---------------------------------------------------------------------------
# status / events / cost helpers
# ---------------------------------------------------------------------------
cmd_status() {
  log "Resource group"
  az group show -n "${RESOURCE_GROUP}" --query "{name:name,location:location,provisioningState:properties.provisioningState}" -o jsonc 2>/dev/null \
    || warn "Resource group ${RESOURCE_GROUP} not found"
  log "Workspace"
  az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query "{name:name,sku:sku.name,retention:retentionInDays,customerId:customerId}" -o jsonc 2>/dev/null \
    || warn "Workspace not found"
  log "Connectors"
  az rest --method get \
    --url "$(sentinel_path)/dataConnectors?api-version=2024-09-01" -o json 2>/dev/null \
    | jq '[.value[] | {name, kind, dataType: .properties.dataType, tenant: .properties.addOnAttributes.tenantId}]' \
    || warn "No connectors"
  [[ -f "${OUT_DIR}/pat-id.txt" ]] && log "Stored PAT id: $(cat "${OUT_DIR}/pat-id.txt")"
  [[ -f "${OUT_DIR}/package-version.txt" ]] && log "Solution version: $(cat "${OUT_DIR}/package-version.txt")"
}

cmd_events() {
  ensure_log_analytics_ext
  local customer_id
  customer_id="$(workspace_customer_id)"
  az monitor log-analytics query \
    --workspace "${customer_id}" \
    --analytics-query '
      union isfuzzy=true
        (SailPointISC_Events_CL | extend Table="Events" | summarize RowCount=count(), LastSeen=max(TimeGenerated) by Table),
        (SailPointISC_AccountActivities_CL | extend Table="AccountActivities" | summarize RowCount=count(), LastSeen=max(TimeGenerated) by Table),
        (SailPointISC_WorkflowHistory_CL | extend Table="WorkflowHistory" | summarize RowCount=count(), LastSeen=max(TimeGenerated) by Table),
        (SailPointISC_Identities_CL | extend Table="Identities" | summarize RowCount=count(), LastSeen=max(TimeGenerated) by Table)
      | project Table, RowCount, LastSeen
    ' \
    -o jsonc
}

cmd_cost() {
  log "Workspace billing surface (sku + recent Usage)"
  az monitor log-analytics workspace show \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${WORKSPACE_NAME}" \
    --query "{sku:sku,retentionInDays:retentionInDays}" -o jsonc
  ensure_log_analytics_ext
  az monitor log-analytics query \
    --workspace "$(workspace_customer_id)" \
    --analytics-query 'Usage | where TimeGenerated > ago(30d) | summarize IngestedGB=sum(Quantity)/1024.0 by bin(TimeGenerated, 1d), DataType | order by TimeGenerated desc' \
    -o jsonc 2>/dev/null || warn "Usage table empty or unavailable"
}

# ---------------------------------------------------------------------------
# down
# ---------------------------------------------------------------------------
cmd_down() {
  local confirm="${1:-}"
  if [[ "${confirm}" != "yes" ]]; then
    die "Refusing to destroy. Re-run: $0 down yes"
  fi

  if [[ -f "${OUT_DIR}/pat-id.txt" ]]; then
    local pat_id
    pat_id="$(tr -d '[:space:]' <"${OUT_DIR}/pat-id.txt")"
    if [[ -n "${pat_id}" ]]; then
      log "Revoking SailPoint PAT ${pat_id}"
      sail api delete "/personal-access-tokens/v1/${pat_id}" --env "${SAIL_ENV}" \
        || warn "PAT delete failed (may already be gone)"
      rm -f "${OUT_DIR}/pat-id.txt"
    fi
  else
    warn "No stored PAT id at ${OUT_DIR}/pat-id.txt"
  fi

  if az group show -n "${RESOURCE_GROUP}" -o none 2>/dev/null; then
    log "Deleting resource group ${RESOURCE_GROUP}"
    az group delete -n "${RESOURCE_GROUP}" --yes --no-wait
    log "Delete accepted (running asynchronously)"
  else
    warn "Resource group ${RESOURCE_GROUP} already gone"
  fi
}

# ---------------------------------------------------------------------------
# up
# ---------------------------------------------------------------------------
cmd_up() {
  cmd_preflight
  cmd_workspace
  cmd_solution
  cmd_connect
  cmd_content
  cmd_verify
  cmd_verify_content
}

usage() {
  cat <<EOF
Usage: $0 <command>

Commands:
  preflight        Check az login, providers, location, sail env
  workspace        Create RG + PerGB2018 LAW + enable Sentinel
  solution         Install SailPoint IdentityNow Content Hub package (>= ${MIN_SOLUTION_VERSION})
  connect          Create PAT, smoke-test token, deploy RestApiPoller
  content          Deploy KQL functions, shared saved searches, analytics rules, and workbook
  verify           Assert connector, sku, events/usage queries
  verify-content   Assert content pack + KQL smoke queries
  response-capability  Check Shared Signals vs Response Actions path
  response         Opt-in: deploy Key Vault + Logic App response playbook
                   Requires RESPONSE_CLIENT_ID / RESPONSE_CLIENT_SECRET
                   Default RESPONSE_DRY_RUN=true (no disable submitted)
  status           Show current resource state
  events           Query recent SailPointISC_* table summaries
  cost             Show sku + Usage summary
  down yes         Revoke PAT and delete the resource group
  up               preflight + workspace + solution + connect + content + verify
EOF
}

main() {
  local cmd="${1:-}"
  shift || true
  case "${cmd}" in
    preflight|workspace|solution|connect|content|verify|status|events|cost|up|response) "cmd_${cmd}" "$@" ;;
    verify-content) cmd_verify_content "$@" ;;
    response-capability) cmd_response_capability "$@" ;;
    down) cmd_down "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "Unknown command: ${cmd}" ;;
  esac
}

main "$@"

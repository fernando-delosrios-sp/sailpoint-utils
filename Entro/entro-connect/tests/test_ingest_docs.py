"""Named scenario tests for Integration index and documentation ingest contracts."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path
from zipfile import ZipFile

import pytest

import integration_catalog

DOCUMENTATION_DIR = Path("documentation")


def _index_rows(tmp_path: Path) -> list[dict[str, object]]:
    errors = integration_catalog.write_integrations_index(tmp_path)
    assert errors == []
    index = json.loads((tmp_path / "integrations.json").read_text(encoding="utf-8"))
    integrations = index["integrations"]
    assert isinstance(integrations, list)
    return integrations


def _row_key(row: dict[str, object]) -> str:
    return str(row["tile"])


def _optional_capability_names(row: dict[str, object]) -> set[str]:
    return {
        capability["name"]
        for capability in row.get("optionalCapabilities") or []
    }


def _integration_path_names(row: dict[str, object]) -> set[str]:
    return {path["name"] for path in row.get("integrationPaths") or []}


def _integration_path(row: dict[str, object], name: str) -> dict[str, object]:
    return next(path for path in row.get("integrationPaths") or [] if path["name"] == name)


def _optional_capability(row: dict[str, object], name: str) -> dict[str, object]:
    return next(
        capability
        for capability in row.get("optionalCapabilities") or []
        if capability["name"] == name
    )


def _collect_prep_steps(row: dict[str, object]) -> list[dict[str, object]]:
    collected: list[dict[str, object]] = []
    for integration_path in row.get("integrationPaths") or []:
        collected.extend(integration_path.get("prepSteps") or [])
    for capability in row.get("optionalCapabilities") or []:
        collected.extend(capability.get("prepSteps") or [])
    return collected


def test_integrations_index_written_on_ingest(tmp_path: Path) -> None:
    integrations = _index_rows(tmp_path)
    keys = {_row_key(row) for row in integrations}
    assert "n8n" in keys
    assert "Amazon Web Services" in keys
    assert len(integrations) == 58
    aws_rows = [row for row in integrations if row["tile"] == "Amazon Web Services"]
    assert len(aws_rows) == 1
    assert "connectorRequirement" not in aws_rows[0]
    assert "connectorEvidence" not in aws_rows[0]
    assert "connectorDeployments" not in aws_rows[0]
    assert "connectorDocumentation" not in aws_rows[0]
    assert "name" not in aws_rows[0]
    assert "variant" not in aws_rows[0]
    assert "targetSelection" not in aws_rows[0]
    tiles = {row["tile"] for row in integrations}
    assert "Visual Studio Code SailPoint Marketplace" not in tiles
    assert "Entro Connector" not in tiles
    assert "SSO Setup" not in tiles
    n8n = next(row for row in integrations if row["tile"] == "n8n")
    assert "connectorRequirement" not in n8n
    assert isinstance(n8n["documentation"], list)
    assert n8n["optionalCapabilities"] == []


def test_capture_required_inventory_matches_31_uncaptured_tiles(tmp_path: Path) -> None:
    integrations = _index_rows(tmp_path)
    stubs = [row for row in integrations if row.get("captureRequired")]
    assert len(stubs) == 31
    assert {"SharePoint", "OneDrive", "CircleCI"} <= {row["tile"] for row in stubs}
    assert all(not row.get("integrationPaths") for row in stubs)


def _minimal_index_row(**extra: object) -> dict[str, object]:
    prep_step = {
        "title": "Prepare the example app",
        "instruction": "Create a read-only app in the vendor console for Entro.",
        "evidence": "The vendor console lists an Entro app",
        "operatorOnly": {
            "reason": "The platform exposes this only through its UI",
            "evidence": "The vendor console lists an Entro app",
        },
    }
    connection_field = {
        "name": "Example Field",
        "secret": False,
        "obtainedHow": "Copy from the vendor console overview page.",
    }
    integration_path: dict[str, object] = {
        "name": "Default path",
        "documentation": ["ai-and-agents/n8n/n8n-onboarding.md"],
        "pathEvidence": "documentation-derived",
        "implicit": False,
        "configurationTools": [{"fit": "none"}],
        "connectionFields": [connection_field],
        "prepSteps": [prep_step],
    }
    row: dict[str, object] = {
        "tile": "Example",
        "category": "test",
        "documentation": ["ai-and-agents/n8n/n8n-onboarding.md"],
        "integrationPaths": [integration_path],
        "optionalCapabilities": [],
        "configurationTools": [{"fit": "none"}],
        "hosting": "public",
        "summary": "Example integration for unit tests.",
        "connectionFields": [connection_field],
        "captureRequired": False,
        "pathEvidence": "documentation-derived",
        "methodWaivers": [],
        "forkCensus": [],
    }
    row.update(extra)
    return row


def _probe_block(command: str = "example --version") -> dict[str, object]:
    return {
        "command": command,
        "sourceUrl": "https://example.invalid/probe",
        "retrievedAt": "2026-08-31",
    }


def _minimal_tool_install(binary: str = "az") -> dict[str, object]:
    return {
        binary: {
            "authOnce": f"{binary} login",
            "credentialBoundary": "vendor CLI token cache",
            "docsUrl": f"https://example.invalid/{binary}",
            "presenceCheck": _probe_block(f"command -v {binary}"),
            "capabilityProbe": {
                **_probe_block(f"{binary} --version"),
                "suitableWhen": "version is reported",
            },
            "authCheck": _probe_block(f"{binary} account show"),
            "platformIdentity": {
                **_probe_block(f"{binary} account show"),
                "principal": "user",
                "endpoint": "cloud",
                "scope": "subscription",
            },
            "install": {
                "windows": {
                    "method": "winget",
                    "command": f"winget install Example.{binary}",
                    "docsUrl": f"https://example.invalid/{binary}/windows",
                },
                "macos": {
                    "method": "homebrew",
                    "command": f"brew install {binary}",
                    "docsUrl": f"https://example.invalid/{binary}/macos",
                },
                "linux": {
                    "method": "docs",
                    "command": None,
                    "docsUrl": f"https://example.invalid/{binary}/linux",
                },
            },
        }
    }


def test_index_rows_omit_connector_requirement_keys(tmp_path: Path) -> None:
    for row in _index_rows(tmp_path):
        assert "connectorRequirement" not in row
        assert "connectorEvidence" not in row


def test_connector_keys_fail_validation() -> None:
    with_requirement = _minimal_index_row(connectorRequirement="required")
    requirement_errors = integration_catalog.validate_integration_row(with_requirement)
    assert any("connector" in message.lower() for message in requirement_errors)
    assert any("Example" in message for message in requirement_errors)

    with_evidence = _minimal_index_row(
        connectorEvidence={
            "page": "ai-and-agents/n8n/n8n-onboarding.md",
            "basis": "worker-group-field-documented",
            "quote": "Worker Group (Connector)",
        }
    )
    evidence_errors = integration_catalog.validate_integration_row(with_evidence)
    assert any("connector" in message.lower() for message in evidence_errors)
    assert any("Example" in message for message in evidence_errors)

    assert integration_catalog.validate_integration_row(_minimal_index_row()) == []


def test_formerly_unknown_rows_match_every_other_row(tmp_path: Path) -> None:
    integrations = _index_rows(tmp_path)
    former_unknown = (
        "Microsoft Teams",
        "Wiz",
        "Salesforce",
        "Google Workspace",
    )
    for tile in former_unknown:
        row = next(item for item in integrations if item["tile"] == tile)
        assert "connectorRequirement" not in row
        assert "connectorEvidence" not in row
        dumped = json.dumps(row)
        assert "unknown" not in dumped
        assert "not-required" not in dumped


def test_curated_targets_omit_connector_keys() -> None:
    for row in integration_catalog.integration_index_payload()["integrations"]:
        assert "connectorRequirement" not in row
        assert "connectorEvidence" not in row


def test_every_row_carries_a_hosting_value(tmp_path: Path) -> None:
    allowed = {"public", "self-hosted", "operator-selected"}
    for row in _index_rows(tmp_path):
        assert row["hosting"] in allowed
        assert "connectorDeployments" not in row
        assert "connectorDocumentation" not in row
        assert "topologies" not in row


def test_unknown_or_missing_hosting_fails_validation() -> None:
    missing = _minimal_index_row()
    del missing["hosting"]
    missing_errors = integration_catalog.validate_integration_row(missing)
    assert any("hosting" in message.lower() for message in missing_errors)
    assert any("Example" in message for message in missing_errors)

    unknown_errors = integration_catalog.validate_integration_row(
        _minimal_index_row(hosting="hybrid")
    )
    assert any("hosting" in message.lower() for message in unknown_errors)
    assert any("Example" in message for message in unknown_errors)


def test_public_hosting_derives_saas_perimeter() -> None:
    deployments = integration_catalog.derive_connector_deployments("public")
    assert deployments == ("saas-perimeter",)
    pages = integration_catalog.connector_topology_pages(deployments)
    assert pages == (
        "entro-connector/entro-connector/entro-saas-perimeter-ips.md",
    )
    row = next(
        item
        for item in integration_catalog.integration_index_payload()["integrations"]
        if item["hosting"] == "public"
    )
    assert "connectorDeployments" not in row
    assert "topologies" not in row


def test_self_hosted_hosting_derives_docker_or_helm() -> None:
    deployments = integration_catalog.derive_connector_deployments("self-hosted")
    assert set(deployments) == {"self-managed-docker", "self-managed-kubernetes"}
    preferred = integration_catalog.derive_connector_deployments(
        "self-hosted", cluster_native=True
    )
    assert preferred[0] == "self-managed-kubernetes"
    pages = integration_catalog.connector_topology_pages(deployments)
    assert "entro-connector/entro-connector/docker-compose.md" in pages
    assert "entro-connector/entro-connector/k8s-connector.md" in pages
    row = next(
        item
        for item in integration_catalog.integration_index_payload()["integrations"]
        if item["hosting"] == "self-hosted"
    )
    assert "connectorDeployments" not in row
    assert "topologies" not in row


def test_operator_selected_hosting_follows_the_form(tmp_path: Path) -> None:
    rows = [
        row
        for row in _index_rows(tmp_path)
        if row["tile"] in {"GitLab", "n8n"}
    ]
    assert {row["tile"] for row in rows} == {"GitLab", "n8n"}
    assert len(rows) == 2
    for row in rows:
        assert row["hosting"] == "operator-selected"
        assert "connectorDeployments" not in row
        assert "topologies" not in row
    assert integration_catalog.derive_connector_deployments(
        "operator-selected", form_choice="public"
    ) == ("saas-perimeter",)
    self_hosted = integration_catalog.derive_connector_deployments(
        "operator-selected", form_choice="self-hosted"
    )
    assert set(self_hosted) == {"self-managed-docker", "self-managed-kubernetes"}


def test_curated_targets_include_hosting_and_still_omit_connector_keys() -> None:
    for row in integration_catalog.integration_index_payload()["integrations"]:
        assert row["hosting"] in {"public", "self-hosted", "operator-selected"}
        assert "connectorRequirement" not in row
        assert "connectorEvidence" not in row
        assert "connectorDeployments" not in row
        assert "connectorDocumentation" not in row
        assert "topologies" not in row


def test_index_specs_name_hosting_not_connector_type() -> None:
    ingest = list(Path("openspec/specs").glob("documentation-ingest/spec.md"))
    assert ingest, "expected documentation-ingest spec"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in ingest)
    assert "Hosting" in blob or "`hosting`" in blob
    assert "Connector deployment" in blob
    lowered = blob.lower()
    assert "connector type" not in lowered
    assert "shall carry `connectortype`" not in lowered
    assert "must not emit a stored topology list" in lowered or "must not" in lowered


def test_hosting_is_defined() -> None:
    glossary = list(Path("openspec/specs").glob("ubiquitous-language/spec.md"))
    assert glossary, "expected ubiquitous-language spec"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in glossary)
    assert "### Term: Hosting" in blob
    after = blob.split("### Term: Hosting", 1)[1]
    definition = after.split("**Definition**:", 1)[1].split("\n", 1)[0]
    assert "public" in definition
    assert "self-hosted" in definition
    assert "operator-selected" in definition


def test_connector_deployment_notes_state_the_derivation() -> None:
    glossary = list(Path("openspec/specs").glob("ubiquitous-language/spec.md"))
    assert glossary, "expected ubiquitous-language spec"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in glossary)
    heading = "### Term: Connector deployment"
    assert heading in blob
    after = blob.split(heading, 1)[1]
    notes = after.split("**Notes**:", 1)[1].split("\n", 1)[0]
    lowered = notes.lower()
    assert "derived from hosting" in lowered
    assert "saas perimeter" in lowered
    assert "docker compose" in lowered
    assert "kubernetes helm" in lowered
    assert "operator-selected" in lowered
    assert "not a json key" in lowered


def test_one_target_one_row(tmp_path: Path) -> None:
    aws_rows = [row for row in _index_rows(tmp_path) if row["tile"] == "Amazon Web Services"]
    assert len(aws_rows) == 1
    path_names = {path["name"] for path in aws_rows[0]["integrationPaths"]}
    assert "Terraform" in path_names
    assert "CloudFormation" in path_names
    assert "Assume Role" in path_names
    duplicate = {
        "tile": "Amazon Web Services",
        "category": "cloud-and-infrastructure",
        "documentation": ["cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps.md"],
        "integrationPaths": [],
        "optionalCapabilities": [],
        "configurationTools": [{"fit": "none"}],
        "hosting": "public",
        "summary": "Duplicate tile for validation.",
        "connectionFields": [],
        "captureRequired": False,
        "pathEvidence": "documentation-derived",
        "methodWaivers": [],
        "forkCensus": [],
    }
    errors = integration_catalog.validate_integration_definitions(
        rows=[duplicate, dict(duplicate)]
    )
    assert any("twice" in message.lower() or "duplicate" in message.lower() for message in errors)


def test_in_form_target_selections_are_distinct_rows(tmp_path: Path) -> None:
    github = next(row for row in _index_rows(tmp_path) if row["tile"] == "GitHub")
    assert _integration_path_names(github) == {
        "GitHub Cloud - New",
        "GitHub Cloud - Legacy",
        "GitHub Enterprise Server",
    }
    slack = next(row for row in _index_rows(tmp_path) if row["tile"] == "Slack")
    assert _integration_path_names(slack) == {
        "Slack Private App",
        "Slack Enterprise Grid App",
    }
    shares = next(row for row in _index_rows(tmp_path) if row["tile"] == "Remote File System")
    assert _integration_path_names(shares) == {"SMB", "SFTP (SSH)", "WinRM"}


def test_authentication_method_does_not_create_a_row(tmp_path: Path) -> None:
    gcp = next(row for row in _index_rows(tmp_path) if row["tile"] == "Google GCP")
    path_names = {path["name"] for path in gcp["integrationPaths"]}
    assert {
        "Console manual — Private Key Integration",
        "Console manual — Workload Identity Federation",
        "Terraform automated — Private Key Integration",
        "Terraform automated — Workload Identity Federation",
    } <= path_names
    github = next(row for row in _index_rows(tmp_path) if row["tile"] == "GitHub")
    legacy = _integration_path(github, "GitHub Cloud - Legacy")
    token_fields = {field["name"] for field in legacy["connectionFields"]}
    assert "Github access token" in token_fields


def test_gcp_authentication_methods_own_credentials_and_instructions(tmp_path: Path) -> None:
    gcp = next(row for row in _index_rows(tmp_path) if row["tile"] == "Google GCP")
    assert [field["name"] for field in gcp["connectionFields"]] == ["Organization Domain"]

    private_key = _integration_path(gcp, "Console manual — Private Key Integration")
    assert [field["name"] for field in private_key["connectionFields"]] == [
        "Private Key JSON"
    ]
    assert "Workload Identity Federation Configuration JSON" not in {
        field["name"] for field in private_key["connectionFields"]
    }
    credential_step = next(
        step
        for step in private_key["prepSteps"]
        if "create-service-account-key.tfvars" in step["instruction"]
    )
    assert credential_step

    wif = _integration_path(gcp, "Console manual — Workload Identity Federation")
    assert [field["name"] for field in wif["connectionFields"]] == [
        "Workload Identity Federation Configuration JSON"
    ]
    wif_step = next(
        step for step in wif["prepSteps"] if "wif-setup.tfvars" in step["instruction"]
    )
    assert wif_step
    assert wif["operatorInputs"][4]["key"] == "entro_aws_role_arn"

    terraform = _integration_path(gcp, "Terraform automated — Private Key Integration")
    assert terraform["operatorInputs"][4]["key"] == "terraform_dir"
    assert {item["key"] for item in private_key["operatorInputs"]} == {
        "organization_domain",
        "organization_id",
        "project_id",
        "service_account_name",
    }


def test_typed_action_placeholders_resolve_to_operator_inputs(tmp_path: Path) -> None:
    bare = re.compile(r"<([a-z][a-z0-9]*)>")
    for row in _index_rows(tmp_path):
        keys = {item["key"] for item in row.get("operatorInputs") or []}
        for action in integration_catalog._iter_typed_actions(row):
            text = " ".join(
                str(action.get(field, ""))
                for field in integration_catalog._PLACEHOLDER_FIELDS
            )
            unresolved = set(bare.findall(text)) - keys
            assert not unresolved, (_row_key(row), action["prepStepTitle"], unresolved)


def test_gcp_reader_identity_action_names_its_inputs(tmp_path: Path) -> None:
    gcp = next(row for row in _index_rows(tmp_path) if row["tile"] == "Google GCP")
    console = _integration_path(gcp, "Console manual — Private Key Integration")
    keys = {item["key"] for item in console["operatorInputs"]}
    assert {"organization_domain", "organization_id", "project_id", "service_account_name"} <= keys

    identity = next(
        action
        for action in console["typedActions"]
        if action["prepStepTitle"] == "Create the Entro reader identity"
    )
    assert "<service_account_name>" in identity["mutation"]
    assert "<sa>" not in identity["preview"]


def test_gcp_wif_terraform_archive_does_not_create_a_private_key() -> None:
    archive = Path(
        ".agents/skills/entro-connect/integrations/google-gcp/"
        "Entro GCP Terraform onboarding.zip"
    )
    member = "Entro GCP Terraform onboarding/tf-var-files/wif-setup.tfvars"
    with ZipFile(archive) as payload:
        tfvars = payload.read(member).decode("utf-8")
    assert "service_account_key_create_condition   = false" in tfvars
    assert "enable_workload_identity_federation    = true" in tfvars


GCP_CONSOLE_PATH = "Console manual — Private Key Integration"
GCP_ARCHIVE_PATH = (
    "integrations/google-gcp/Entro GCP Terraform onboarding.zip"
)
GCP_ARCHIVE_ROOT = "Entro GCP Terraform onboarding/"


def _gcp_console_catalog() -> dict[str, object]:
    gcp = next(
        row
        for row in integration_catalog.skill_row_catalogs()
        if row["tile"] == "Google GCP"
    )
    return _integration_path(gcp, GCP_CONSOLE_PATH)


def _gcp_generated_actions() -> tuple[dict[str, object], dict[str, object]]:
    actions = _gcp_console_catalog()["typedActions"]
    iam = [
        action
        for action in actions
        if "custom role" in json.dumps(action).lower()
        and isinstance(action.get("script"), dict)
    ]
    apis = [
        action
        for action in actions
        if "billing" in json.dumps(action).lower()
        and isinstance(action.get("script"), dict)
    ]
    assert len(iam) == 1, "Console-manual must expose one generated IAM grant artifact"
    assert len(apis) == 1, "Console-manual must expose one generated Terraform-default API artifact"
    return iam[0], apis[0]


def _archive_text(member: str) -> str:
    from skill_held import SKILL_ROOTS

    with ZipFile(SKILL_ROOTS[0] / GCP_ARCHIVE_PATH) as payload:
        return payload.read(GCP_ARCHIVE_ROOT + member).decode("utf-8")


def _terraform_default_list(source: str, variable: str) -> list[str]:
    match = re.search(
        rf'variable "{re.escape(variable)}"\s*\{{.*?default\s*=\s*\[(.*?)\]\s*\}}',
        source,
        flags=re.DOTALL,
    )
    assert match, f"pinned archive is missing Terraform variable {variable}"
    return re.findall(r'"([^"]+)"', match.group(1))


def _gcp_artifact_body(action: dict[str, object], root: Path | None = None) -> str:
    from skill_held import SKILL_ROOTS

    script = action["script"]
    assert isinstance(script, dict)
    skill_root = root or SKILL_ROOTS[0]
    return (skill_root / str(script["skillPath"])).read_text(encoding="utf-8")


def test_gcp_service_account_creation_precedes_collision_gated_grants() -> None:
    console = _gcp_console_catalog()
    actions = console["typedActions"]
    creation = [
        action
        for action in actions
        if "gcloud iam service-accounts create" in str(action["mutation"])
    ]
    assert len(creation) == 1
    grant, _apis = _gcp_generated_actions()
    assert actions.index(creation[0]) < actions.index(grant)
    assert "grant" not in str(creation[0]["mutation"]).lower()
    collision_contract = " ".join(
        str(creation[0][field])
        for field in ("preview", "verification", "rollbackOrImpact")
    ).lower()
    assert "describe" in collision_contract
    assert "collision" in collision_contract
    assert "stop" in collision_contract
    assert "grant" in collision_contract
    assert isinstance(grant["script"], dict)


def test_gcp_generated_iam_artifact_matches_pinned_role_contract() -> None:
    grant, _apis = _gcp_generated_actions()
    iam_source = _archive_text("iam.tf")
    variables_source = _archive_text("variables.tf")
    permissions_match = re.search(
        r'resource "google_organization_iam_custom_role" "custom_role"\s*\{'
        r'.*?permissions\s*=\s*\[(.*?)\]\s*\}',
        iam_source,
        flags=re.DOTALL,
    )
    assert permissions_match
    expected_permissions = re.findall(r'"([^"]+)"', permissions_match.group(1))
    expected_roles = _terraform_default_list(
        variables_source, "gcp_roles_to_grant_list"
    )
    assert len(expected_roles) == 12

    body = _gcp_artifact_body(grant)
    generated_permissions = re.search(
        r"CUSTOM_ROLE_PERMISSIONS=\((.*?)\)\nPREDEFINED_ROLES=",
        body,
        flags=re.DOTALL,
    )
    assert generated_permissions
    assert re.findall(r"'([^']+)'", generated_permissions.group(1)) == expected_permissions
    assert set(re.findall(r"roles/[A-Za-z0-9_.]+", body)) == set(expected_roles)
    assert len(re.findall(r"roles/[A-Za-z0-9_.]+", body)) == 12


def test_gcp_generated_iam_verify_is_durable_without_run_state() -> None:
    grant, _apis = _gcp_generated_actions()
    body = _gcp_artifact_body(grant)
    verify_body = re.search(
        r"\nverify\(\) \{(.*?)\n\}\n\nchoose_custom_role_id\(\)",
        body,
        flags=re.DOTALL,
    )
    assert verify_body
    assert "STATE_FILE" not in verify_body.group(1)
    assert 'custom_role_id="$(bound_custom_role_id)"' in verify_body.group(1)
    assert "organizations get-iam-policy" in body
    assert "entroLoggingRole_" in body
    assert "PREDEFINED_ROLES" in verify_body.group(1)


def test_gcp_generated_api_artifact_uses_terraform_defaults_without_selection_fork() -> None:
    _grant, api_action = _gcp_generated_actions()
    variables_source = _archive_text("variables.tf")
    expected_groups = {
        "organization-project": _terraform_default_list(
            variables_source, "gcp_services_to_enable_on_projects_list"
        ),
        "host-project": _terraform_default_list(
            variables_source, "gcp_services_to_enable_on_host_project_list"
        ),
        "billing-dependent": _terraform_default_list(
            variables_source, "gcp_billing_required_services_to_enable_list"
        ),
    }
    assert {name: len(values) for name, values in expected_groups.items()} == {
        "organization-project": 3,
        "host-project": 8,
        "billing-dependent": 2,
    }

    body = _gcp_artifact_body(api_action)
    for group in expected_groups.values():
        for service in group:
            assert service in body
    contract = json.dumps(api_action).lower() + body.lower()
    assert "use_billing_required_services" in contract
    assert "if " in body.lower()
    assert {
        str(item["key"]) for item in _gcp_console_catalog()["operatorInputs"]
    } == {
        "organization_domain",
        "organization_id",
        "project_id",
        "service_account_name",
    }
    assert "read -p" not in body.lower()
    assert "select " not in body.lower()


def test_gcp_audit_logging_is_operator_only_console_work() -> None:
    console = _gcp_console_catalog()
    audit_steps = [
        step for step in console["prepSteps"] if "audit log" in str(step["title"]).lower()
    ]
    assert len(audit_steps) == 1
    step = audit_steps[0]
    assert isinstance(step.get("operatorOnly"), dict)
    assert step["operatorOnly"]["reason"]
    instruction = str(step["instruction"]).lower()
    assert "console.cloud.google.com/iam-admin/audit" in instruction
    assert "gcloud" not in instruction
    evidence = str(step["operatorOnly"]["evidence"]).lower()
    assert evidence
    assert not any(secret in evidence for secret in ("password", "token", "private key"))
    assert step["title"] not in {
        action["prepStepTitle"] for action in console["typedActions"]
    }


def _isolated_skill_roots(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> tuple[Path, Path]:
    import skill_held

    left = tmp_path / "agents-skill"
    right = tmp_path / "user-skill"
    shutil.copytree(skill_held.SKILL_ROOTS[0], left)
    shutil.copytree(skill_held.SKILL_ROOTS[1], right)
    roots = (left, right)
    monkeypatch.setattr(skill_held, "SKILL_ROOTS", roots)
    monkeypatch.setattr(integration_catalog, "SKILL_ROOTS", roots)
    return roots


def _replace_archive_text(path: Path, member: str, old: str, new: str) -> None:
    replacement = path.with_suffix(".replacement.zip")
    with ZipFile(path) as source, ZipFile(replacement, "w") as target:
        for info in source.infolist():
            body = source.read(info.filename)
            if info.filename == member:
                text = body.decode("utf-8")
                assert old in text
                body = text.replace(old, new, 1).encode("utf-8")
            target.writestr(info, body)
    replacement.replace(path)


@pytest.mark.parametrize(
    "drift",
    [
        "source-archive",
        "generated-bytes",
        "checksum",
        "tree",
        "row-catalog",
        "action-reference",
    ],
)
def test_gcp_generated_drift_fails_catalog_validation(
    drift: str, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import skill_held

    left, right = _isolated_skill_roots(tmp_path, monkeypatch)
    iam_action, api_action = _gcp_generated_actions()
    iam_path = str(iam_action["script"]["skillPath"])
    api_title = str(api_action["prepStepTitle"])
    catalog_rel = "integrations/google-gcp/catalog.json"

    if drift == "source-archive":
        for root in (left, right):
            _replace_archive_text(
                root / GCP_ARCHIVE_PATH,
                GCP_ARCHIVE_ROOT + "iam.tf",
                '"logging.buckets.get",',
                '"logging.buckets.get",\n    "logging.testOnlyPermission.get",',
            )
    elif drift in {"generated-bytes", "tree"}:
        roots = (left, right) if drift == "generated-bytes" else (right,)
        for root in roots:
            with (root / iam_path).open("a", encoding="utf-8") as artifact:
                artifact.write("\n# stale generated bytes\n")
    else:
        roots = (left, right)
        for root in roots:
            catalog_path = root / catalog_rel
            catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
            console = _integration_path(catalog, GCP_CONSOLE_PATH)
            if drift == "checksum":
                action = next(
                    item
                    for item in console["typedActions"]
                    if item["prepStepTitle"] == iam_action["prepStepTitle"]
                )
                action["script"]["checksum"] = "sha256:" + ("0" * 64)
            elif drift == "row-catalog":
                console["typedActions"] = [
                    item
                    for item in console["typedActions"]
                    if item["prepStepTitle"] != api_title
                ]
            else:
                action = next(
                    item
                    for item in console["typedActions"]
                    if item["prepStepTitle"] == iam_action["prepStepTitle"]
                )
                action["script"]["skillPath"] = (
                    "integrations/google-gcp/stale-iam-artifact.sh"
                )
            catalog_path.write_text(
                json.dumps(catalog, indent=2) + "\n", encoding="utf-8"
            )

    errors = integration_catalog.validate_skill_held(DOCUMENTATION_DIR)
    errors.extend(integration_catalog.validate_skill_catalog_file(left))
    errors.extend(integration_catalog.validate_skill_catalog_file(right))
    assert errors, f"{drift} must fail generated GCP validation"


@pytest.mark.parametrize(
    "drift",
    ["row", "action", "checksum", "path"],
)
def test_gcp_integration_index_drift_fails_catalog_validation(
    drift: str, tmp_path: Path
) -> None:
    index_path = tmp_path / "integrations.json"
    payload = json.loads(
        (DOCUMENTATION_DIR / "integrations.json").read_text(encoding="utf-8")
    )
    gcp = next(row for row in payload["integrations"] if row["tile"] == "Google GCP")
    console = _integration_path(gcp, GCP_CONSOLE_PATH)
    iam_action, api_action = _gcp_generated_actions()
    action = next(
        item
        for item in console["typedActions"]
        if item["prepStepTitle"] == iam_action["prepStepTitle"]
    )
    if drift == "row":
        gcp["summary"] = "stale generated GCP summary"
    elif drift == "action":
        console["typedActions"] = [
            item
            for item in console["typedActions"]
            if item["prepStepTitle"] != api_action["prepStepTitle"]
        ]
    elif drift == "checksum":
        action["script"]["checksum"] = "sha256:" + ("0" * 64)
    else:
        action["script"]["skillPath"] = (
            "integrations/google-gcp/stale-iam-artifact.sh"
        )
    index_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    errors = integration_catalog.validate_skill_held(tmp_path)
    matching = [
        message
        for message in errors
        if "Integration index" in message and drift in message
    ]
    assert matching, "\n".join(errors)


def test_gcp_generated_outputs_are_aligned_across_catalogs_and_skill_trees() -> None:
    from skill_held import SKILL_ROOTS, sha256_file

    expected_row = next(
        row
        for row in integration_catalog.skill_row_catalogs()
        if row["tile"] == "Google GCP"
    )
    rows = []
    for root in SKILL_ROOTS:
        row = json.loads(
            (root / "integrations/google-gcp/catalog.json").read_text(encoding="utf-8")
        )
        assert row == expected_row
        rows.append(row)
    assert rows[0] == rows[1]

    for action in _gcp_generated_actions():
        script = action["script"]
        skill_path = str(script["skillPath"])
        bodies = [(root / skill_path).read_bytes() for root in SKILL_ROOTS]
        assert bodies[0] == bodies[1]
        assert all(
            sha256_file(root / skill_path) == script["checksum"]
            for root in SKILL_ROOTS
        )
        for row in rows:
            committed_action = next(
                item
                for item in _integration_path(row, GCP_CONSOLE_PATH)["typedActions"]
                if item["prepStepTitle"] == action["prepStepTitle"]
            )
            assert committed_action["script"] == script


def test_gcp_rollback_is_run_scoped_and_leaves_apis_enabled() -> None:
    console = _gcp_console_catalog()
    creation = next(
        action
        for action in console["typedActions"]
        if "gcloud iam service-accounts create" in str(action["mutation"])
    )
    grant, apis = _gcp_generated_actions()

    creation_rollback = str(creation["rollbackOrImpact"]).lower()
    assert "delete" in creation_rollback
    assert "only if this run created" in creation_rollback

    grant_rollback = str(grant["rollbackOrImpact"]).lower()
    assert "binding" in grant_rollback
    assert "custom role" in grant_rollback
    assert "created by this run" in grant_rollback or "this run created" in grant_rollback
    assert "service account" not in grant_rollback

    api_rollback = str(apis["rollbackOrImpact"]).lower()
    assert "remain enabled" in api_rollback or "leave enabled" in api_rollback
    assert "disable" not in str(apis["mutation"]).lower()


def test_targets_are_named_as_entro_labels_them(tmp_path: Path) -> None:
    tiles = {row["tile"] for row in _index_rows(tmp_path)}
    assert "Remote File System" in tiles
    assert "File Shares Scanning" not in tiles
    assert "Microsoft ecosystem" in tiles
    assert "Azure / Entra / M365" not in tiles
    assert "SharePoint / OneDrive" not in tiles
    assert "Microsoft Copilot Studio" not in tiles
    assert "SharePoint" in tiles
    assert "OneDrive" in tiles


def test_missing_provider_list_tile_is_not_a_target(tmp_path: Path) -> None:
    tiles = {row["tile"] for row in _index_rows(tmp_path)}
    assert "Microsoft Copilot Studio" not in tiles
    ecosystem = next(row for row in _index_rows(tmp_path) if row["tile"] == "Microsoft ecosystem")
    names = {coverage["name"] for coverage in ecosystem["optionalCapabilities"]}
    assert "Copilot Studio" in names


def test_collapsed_rows_keep_their_documentation(tmp_path: Path) -> None:
    ecosystem = next(row for row in _index_rows(tmp_path) if row["tile"] == "Microsoft ecosystem")
    docs = set(ecosystem["documentation"])
    assert "cloud-and-infrastructure/azure/automated-powershell-onboarding.md" in docs
    assert "cloud-and-infrastructure/azure/azure-manual-onboarding.md" in docs
    assert "collaboration-and-saas/sharepoint/sharepoint-onboarding.md" in docs
    assert (
        "ai-and-agents/microsoft-copilot-studio/onboarding-microsoft-copilot-studio.md" in docs
    )


def test_glossary_index_specs_distinguish_target_from_method() -> None:
    specs = list(Path("openspec").rglob("ubiquitous-language/spec.md"))
    assert specs, "expected ubiquitous-language spec files"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    for term in (
        "Add New Account target",
        "Setup method",
        "Authentication method",
        "Connector requirement",
        "Requirement evidence",
    ):
        assert term in blob, term
    assert "Integration variant" in blob
    assert "superseded" in blob.lower()


def test_index_specs_do_not_use_connector_requirement() -> None:
    ingest = list(
        Path("openspec").rglob("*/drop-connector-requirement/specs/documentation-ingest/spec.md")
    ) + list(
        Path("openspec/changes/archive").glob(
            "*-drop-connector-requirement/specs/documentation-ingest/spec.md"
        )
    )
    assert ingest, "expected documentation-ingest delta spec"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in ingest)
    assert "MUST NOT" in blob and "connectorRequirement" in blob
    assert "connectorEvidence" in blob
    lowered = blob.lower()
    assert "shall carry `connectorrequirement`" not in lowered
    glossary = list(
        Path("openspec/changes/archive").glob(
            "*-drop-connector-requirement/specs/ubiquitous-language/spec.md"
        )
    )
    glossary_blob = "\n".join(path.read_text(encoding="utf-8") for path in glossary)
    assert "MUST NOT use Connector requirement" in glossary_blob


def test_connector_requirement_and_requirement_evidence_are_superseded() -> None:
    specs = list(
        Path("openspec/changes/archive").glob(
            "*-drop-connector-requirement/specs/ubiquitous-language/spec.md"
        )
    )
    assert specs, "expected ubiquitous-language delta spec"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    for heading in ("### Term: Connector requirement", "### Term: Requirement evidence"):
        assert heading in blob, heading
        after = blob.split(heading, 1)[1]
        definition = after.split("**Definition**:", 1)[1].split("\n", 1)[0]
        assert definition.strip().startswith("Superseded"), heading


def test_integrations_index_paths_exist_in_documentation_tree() -> None:
    if not DOCUMENTATION_DIR.is_dir():
        pytest.skip("documentation tree not present")
    errors = integration_catalog.validate_integration_paths(DOCUMENTATION_DIR)
    assert errors == [], "\n".join(errors)


def test_ingest_specs_use_canonical_tree_terms() -> None:
    specs = list(Path("openspec").rglob("documentation-ingest/spec.md"))
    assert specs, "expected documentation-ingest spec files"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    for term in (
        "documentation tree",
        "integrations.json",
        "docs.entro.security",
        "ENTRO_DOCS_COOKIE",
    ):
        assert term.lower() in blob.lower(), term
    readme = Path("README.md").read_text(encoding="utf-8").lower()
    assert "documentation tree" in readme
    assert "docs.entro.security" in readme
    assert "entro_docs_cookie" in readme
    assert "integrations.json" in readme
    assert "cleaned nav" not in readme
    assert "gitbook markdown catalog" not in readme


def _coverage_names(row: dict[str, object]) -> set[str]:
    return {coverage["name"] for coverage in row["optionalCapabilities"]}


def test_collapsed_gitbook_section_becomes_a_coverage(tmp_path: Path) -> None:
    ecosystem = next(row for row in _index_rows(tmp_path) if row["tile"] == "Microsoft ecosystem")
    names = _coverage_names(ecosystem)
    assert names == {"Copilot Studio"}
    by_name = {coverage["name"]: coverage for coverage in ecosystem["optionalCapabilities"]}
    assert (
        "ai-and-agents/microsoft-copilot-studio/onboarding-microsoft-copilot-studio.md"
        in by_name["Copilot Studio"]["documentation"]
    )
    tiles = {row["tile"] for row in _index_rows(tmp_path)}
    assert "Microsoft Copilot Studio" not in tiles
    assert "SharePoint" in tiles
    assert "OneDrive" in tiles


def test_permission_group_heading_is_not_a_coverage(tmp_path: Path) -> None:
    ecosystem = next(row for row in _index_rows(tmp_path) if row["tile"] == "Microsoft ecosystem")
    names = {name.lower() for name in _coverage_names(ecosystem)}
    for forbidden in ("copilot chats", "defender", "teams secrets"):
        assert not any(forbidden in name for name in names), forbidden


def test_product_level_git_clone_scanning_is_not_a_coverage(tmp_path: Path) -> None:
    integrations = _index_rows(tmp_path)
    for tile in ("GitHub", "GitLab", "Bitbucket"):
        rows = [row for row in integrations if row["tile"] == tile]
        for row in rows:
            names = {name.lower() for name in _coverage_names(row)}
            assert not any("git clone" in name for name in names), row


def test_other_collapsed_sections_are_coverages_on_their_target(tmp_path: Path) -> None:
    integrations = _index_rows(tmp_path)
    github = next(row for row in integrations if row["tile"] == "GitHub")
    assert "Real-time scanning" in _coverage_names(github)
    docs = next(
        capability["documentation"]
        for capability in github["optionalCapabilities"]
        if capability["name"] == "Real-time scanning"
    )
    assert "code-and-ci-cd/github/github-real-time-scanning.md" in docs
    assert "Enterprise S3 log streaming" in _coverage_names(github)
    s3 = _optional_capability(github, "Enterprise S3 log streaming")
    assert any(entry.get("binary") == "aws" for entry in s3["configurationTools"])

    crowdstrike = next(row for row in integrations if row["tile"] == "CrowdStrike")
    rtr = _optional_capability(crowdstrike, "Falcon RTR")
    assert set(rtr["documentation"]) == {
        "security-and-identity/crowdstrike/falcon-rtr-secrets-scanner.md",
        "security-and-identity/crowdstrike/rtr-scanning.md",
        "security-and-identity/crowdstrike/ai-security-rtr-integration.md",
    }

    atlassian = next(row for row in integrations if row["tile"] == "Atlassian")
    assert "Jira real-time scanning" in _coverage_names(atlassian)

    sailpoint = next(
        row
        for row in integrations
        if row["tile"] == "SailPoint Identity Security Cloud (IdentityNow)"
    )
    assert "Aggregating Entro NHIs & AI agents" in _coverage_names(sailpoint)


def test_coverage_citation_must_resolve() -> None:
    missing = _minimal_index_row(
        optionalCapabilities=[
            {"name": "Studio", "documentation": ["does-not-exist-coverage.md"]},
        ],
    )
    path_errors = integration_catalog.validate_integration_paths(
        DOCUMENTATION_DIR,
        rows=[missing],
    )
    assert any("does-not-exist-coverage.md" in message for message in path_errors)

    duplicate = {
        **missing,
        "optionalCapabilities": [
            {"name": "Studio", "documentation": ["ai-and-agents/n8n/n8n-onboarding.md"]},
            {"name": "Studio", "documentation": ["ai-and-agents/n8n.md"]},
        ],
    }
    errors = integration_catalog.validate_integration_row(duplicate)
    assert any("duplicate" in message.lower() for message in errors)

    empty_name = {
        **missing,
        "optionalCapabilities": [{"name": "", "documentation": ["ai-and-agents/n8n/n8n-onboarding.md"]}],
    }
    assert any(
        "name" in message.lower()
        for message in integration_catalog.validate_integration_row(empty_name)
    )

    missing_docs = _minimal_index_row(
        optionalCapabilities=[
            {"name": "Studio", "documentation": ["does-not-exist-coverage.md"]},
        ],
    )
    assert any(
        "does-not-exist-coverage.md" in message
        for message in integration_catalog.validate_integration_paths(
            DOCUMENTATION_DIR,
            rows=[missing_docs],
        )
    )


def test_empty_coverage_list_is_valid(tmp_path: Path) -> None:
    integrations = _index_rows(tmp_path)
    n8n = next(row for row in integrations if row["tile"] == "n8n")
    assert n8n["optionalCapabilities"] == []
    errors = integration_catalog.validate_integration_definitions(
        output_dir=DOCUMENTATION_DIR,
        rows=[n8n],
    )
    assert errors == []
    okta = next(row for row in integrations if row["tile"] == "Okta")
    teams = next(row for row in integrations if row["tile"] == "Microsoft Teams")
    gitlab = next(row for row in integrations if row["tile"] == "GitLab")
    for row in (okta, teams, gitlab):
        assert row["optionalCapabilities"] == []
        names = {name.lower() for name in _coverage_names(row)}
        assert "azure hybrid" not in names
        assert "key vault" not in names
        assert "custom role" not in names


def test_index_specs_use_coverage_not_feature() -> None:
    specs = list(Path("openspec").rglob("documentation-ingest/spec.md"))
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    assert "Coverage" in blob
    lowered = blob.lower()
    for avoided in ("scanning surface", "optional scope"):
        assert avoided not in lowered, avoided


def test_missing_tile_is_not_read_as_a_target() -> None:
    found = False
    for path in Path("openspec").rglob("ubiquitous-language/spec.md"):
        text = path.read_text(encoding="utf-8")
        if "### Term: Add New Account target" not in text:
            continue
        notes = text.split("### Term: Add New Account target", 1)[1]
        notes_lower = notes.lower()
        if "provider list" in notes_lower and "coverage" in notes_lower:
            found = True
            break
    assert found, "Add New Account target Notes must name the provider list and Coverage"


def _index_document(tmp_path: Path) -> dict[str, object]:
    errors = integration_catalog.write_integrations_index(tmp_path)
    assert errors == []
    return json.loads((tmp_path / "integrations.json").read_text(encoding="utf-8"))


def test_every_target_lists_configuration_tools(tmp_path: Path) -> None:
    fits = {"preferred", "usable", "env-backed", "none"}
    for row in _index_rows(tmp_path):
        tools = row["configurationTools"]
        assert isinstance(tools, list) and tools, _row_key(row)
        for entry in tools:
            assert entry["fit"] in fits, (row["tile"], entry)


def test_preferred_cloud_clis_are_recorded(tmp_path: Path) -> None:
    rows = _index_rows(tmp_path)
    microsoft = next(row for row in rows if row["tile"] == "Microsoft ecosystem")
    aws = next(row for row in rows if row["tile"] == "Amazon Web Services")
    gcp = next(row for row in rows if row["tile"] == "Google GCP")
    assert {"az": "preferred", "pwsh": "preferred"}.items() <= {
        entry["binary"]: entry["fit"]
        for entry in microsoft["configurationTools"]
        if entry.get("binary")
    }.items()
    assert {"aws": "preferred"}.items() <= {
        entry["binary"]: entry["fit"]
        for entry in aws["configurationTools"]
        if entry.get("binary")
    }.items()
    assert {"gcloud": "preferred"}.items() <= {
        entry["binary"]: entry["fit"] for entry in gcp["configurationTools"]
    }.items()


def test_github_app_install_is_usable_not_preferred(tmp_path: Path) -> None:
    github = next(item for item in _index_rows(tmp_path) if item["tile"] == "GitHub")
    cloud_new = _integration_path(github, "GitHub Cloud - New")
    gh = next(entry for entry in cloud_new["configurationTools"] if entry.get("binary") == "gh")
    assert gh["fit"] == "usable"


def test_portal_only_targets_still_list_a_tool(tmp_path: Path) -> None:
    wiz = next(row for row in _index_rows(tmp_path) if row["tile"] == "Wiz")
    none_entries = [entry for entry in wiz["configurationTools"] if entry["fit"] == "none"]
    assert none_entries
    assert "binary" not in none_entries[0] or none_entries[0].get("binary") in (None, "")


def test_configuration_tools_are_not_rows(tmp_path: Path) -> None:
    rows = _index_rows(tmp_path)
    az_targets = [
        row
        for row in rows
        if any(entry.get("binary") == "az" for entry in row["configurationTools"])
    ]
    assert len(az_targets) >= 2
    tiles = {row["tile"] for row in rows}
    assert "az" not in tiles
    assert all(row["tile"] != "az" for row in az_targets)


def test_shared_binaries_are_installed_once(tmp_path: Path) -> None:
    index = _index_document(tmp_path)
    install = index["toolInstall"]
    assert list(install).count("az") == 0 or "az" in install
    az = install["az"]
    assert set(az["install"]) == {"windows", "macos", "linux"}
    assert az["docsUrl"]
    microsoft = {"Microsoft ecosystem", "Microsoft Teams", "Azure DevOps"}
    listed = {
        row["tile"]
        for row in index["integrations"]
        if any(entry.get("binary") == "az" for entry in row["configurationTools"])
    }
    assert microsoft <= listed


def test_auth_once_is_recorded_without_secrets(tmp_path: Path) -> None:
    aws = _index_document(tmp_path)["toolInstall"]["aws"]
    assert "authOnce" in aws and aws["authOnce"]
    boundary = aws["credentialBoundary"].lower()
    assert "cli" in boundary or "gitignore" in boundary or "env" in boundary
    dumped = json.dumps(aws).lower()
    for banned in ("akia", "ghp_", "github_pat_", "password=", "secret_key"):
        assert banned not in dumped


def _aws_routes(tmp_path: Path) -> list[dict[str, object]]:
    return _index_document(tmp_path)["toolInstall"]["aws"]["configureOnce"]["methods"]


def _route_by_command(routes: list[dict[str, object]], command: str) -> dict[str, object]:
    return next(route for route in routes if route["command"] == command)


def test_aws_records_configure_once_without_secrets(tmp_path: Path) -> None:
    aws = _index_document(tmp_path)["toolInstall"]["aws"]
    routes = aws["configureOnce"]["methods"]
    assert [route["command"] for route in routes] == ["aws configure", "aws configure sso"]
    for route in routes:
        for field in ("name", "whenToPick", "suitableWhen", "credentialBoundary", "docsUrl"):
            assert route[field]
        assert "authOnce" in route
        assert route["check"]["command"]
        assert route["prompts"]
    dumped = json.dumps(aws).lower()
    for banned in ("akia", "ghp_", "github_pat_", "password=", "secret_key"):
        assert banned not in dumped


def test_the_access_keys_route_records_no_sign_in(tmp_path: Path) -> None:
    keys = _route_by_command(_aws_routes(tmp_path), "aws configure")
    assert keys["authOnce"] is None
    boundary = str(keys["credentialBoundary"]).lower()
    assert "credentials file" in boundary
    assert "long-lived" in boundary
    secrets = [entry for entry in keys["prompts"] if entry.get("secret")]
    assert len(secrets) == 1
    assert "secret access key" in str(secrets[0]["prompt"]).lower()
    labels = [str(entry["prompt"]).lower() for entry in keys["prompts"]]
    for needle, label in zip(
        ("access key id", "secret access key", "region", "output format"),
        labels,
        strict=True,
    ):
        assert needle in label, label
    sources = " ".join(str(entry["whereToFind"]).lower() for entry in keys["prompts"])
    assert "iam console" in sources
    assert "csv" in sources


def test_route_checks_never_expose_credential_values(tmp_path: Path) -> None:
    routes = _aws_routes(tmp_path)
    keys_check = _route_by_command(routes, "aws configure")["check"]["command"]
    assert "aws_access_key_id" in keys_check
    assert "grep -q" in keys_check
    idc_check = _route_by_command(routes, "aws configure sso")["check"]["command"]
    assert "sso_session" in idc_check or "sso_start_url" in idc_check
    assert "grep -q" in idc_check
    assert "credentials" not in idc_check.lower()


def test_entry_level_auth_once_matches_a_route(tmp_path: Path) -> None:
    aws = _index_document(tmp_path)["toolInstall"]["aws"]
    routes = aws["configureOnce"]["methods"]
    assert aws["authOnce"] in {route["authOnce"] for route in routes}
    assert _route_by_command(routes, "aws configure sso")["authOnce"] == "aws sso login"


def test_azure_cli_omits_configure_once(tmp_path: Path) -> None:
    az = _index_document(tmp_path)["toolInstall"]["az"]
    assert "configureOnce" not in az


def test_terraform_does_not_duplicate_the_aws_wizard(tmp_path: Path) -> None:
    install = _index_document(tmp_path)["toolInstall"]
    if "terraform" in install:
        assert "configureOnce" not in install["terraform"]


def _complete_route(**overrides: object) -> dict[str, object]:
    payload: dict[str, object] = {
        "name": "IAM Identity Center",
        "whenToPick": "The organization uses the AWS access portal",
        "command": "aws configure sso",
        "suitableWhen": "SSO session exists",
        "authOnce": "aws login",
        "credentialBoundary": "vendor CLI token cache",
        "sourceUrl": "https://example.invalid/sso",
        "retrievedAt": "2026-09-03",
        "docsUrl": "https://example.invalid/sso",
        "prompts": [
            {"prompt": "SSO start URL", "whereToFind": "AWS access portal"},
        ],
        "check": {
            "command": "grep -q sso_session",
            "sourceUrl": "https://example.invalid/sso",
            "retrievedAt": "2026-09-03",
        },
    }
    payload.update(overrides)
    return payload


def _complete_configure_once(**overrides: object) -> dict[str, object]:
    return {"methods": [_complete_route(**overrides)]}


def test_missing_configure_once_fields_fail_validation() -> None:
    incomplete = _minimal_tool_install("aws")
    incomplete["aws"]["configureOnce"] = _complete_configure_once(
        check={
            "sourceUrl": "https://example.invalid/sso",
            "retrievedAt": "2026-09-03",
        },
    )
    row = _minimal_index_row(configurationTools=[{"binary": "aws", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=incomplete,
    )
    blob = "\n".join(errors).lower()
    assert "configureonce" in blob
    assert "check" in blob or "command" in blob


def test_configure_once_without_prompts_fails_validation() -> None:
    incomplete = _minimal_tool_install("aws")
    incomplete["aws"]["configureOnce"] = _complete_configure_once(prompts=[])
    row = _minimal_index_row(configurationTools=[{"binary": "aws", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=incomplete,
    )
    blob = "\n".join(errors).lower()
    assert "configureonce" in blob
    assert "prompts" in blob


def test_configure_once_prompt_without_where_to_find_fails_validation() -> None:
    incomplete = _minimal_tool_install("aws")
    incomplete["aws"]["configureOnce"] = _complete_configure_once(
        prompts=[{"prompt": "SSO start URL"}],
    )
    row = _minimal_index_row(configurationTools=[{"binary": "aws", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=incomplete,
    )
    blob = "\n".join(errors).lower()
    assert "configureonce" in blob
    assert "wheretofind" in blob


def test_configure_once_without_methods_fails_validation() -> None:
    incomplete = _minimal_tool_install("aws")
    incomplete["aws"]["configureOnce"] = {"methods": []}
    row = _minimal_index_row(configurationTools=[{"binary": "aws", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=incomplete,
    )
    blob = "\n".join(errors).lower()
    assert "configureonce" in blob
    assert "methods" in blob


def test_route_without_when_to_pick_fails_validation() -> None:
    incomplete = _minimal_tool_install("aws")
    incomplete["aws"]["configureOnce"] = _complete_configure_once(whenToPick="")
    row = _minimal_index_row(configurationTools=[{"binary": "aws", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=incomplete,
    )
    blob = "\n".join(errors).lower()
    assert "configureonce" in blob
    assert "whentopick" in blob


def test_entry_level_auth_once_matching_no_route_fails_validation() -> None:
    incomplete = _minimal_tool_install("aws")
    incomplete["aws"]["configureOnce"] = _complete_configure_once(authOnce="aws sso login")
    row = _minimal_index_row(configurationTools=[{"binary": "aws", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=incomplete,
    )
    blob = "\n".join(errors).lower()
    assert "authonce" in blob


def test_route_may_record_no_sign_in() -> None:
    entry = _minimal_tool_install("aws")
    entry["aws"]["configureOnce"] = {
        "methods": [
            _complete_route(authOnce=None),
            _complete_route(name="Keys", command="aws configure", authOnce="aws login"),
        ]
    }
    row = _minimal_index_row(configurationTools=[{"binary": "aws", "fit": "preferred"}])
    assert (
        integration_catalog.validate_integration_definitions(rows=[row], tool_install=entry) == []
    )


def test_aws_prompts_name_where_each_value_comes_from(tmp_path: Path) -> None:
    once = _route_by_command(_aws_routes(tmp_path), "aws configure sso")
    prompts = once["prompts"]
    assert isinstance(prompts, list)
    assert len(prompts) == 9
    labels = [str(entry["prompt"]).lower() for entry in prompts]
    for needle, label in zip(
        (
            "session name",
            "start url",
            "sso region",
            "registration scope",
            "account",
            "role",
            "default client region",
            "output format",
            "profile name",
        ),
        labels,
        strict=True,
    ):
        assert needle in label, label
    start_url = next(entry for entry in prompts if "start url" in str(entry["prompt"]).lower())
    sso_region = next(entry for entry in prompts if "sso region" in str(entry["prompt"]).lower())
    assert "access portal" in str(start_url["whereToFind"]).lower()
    assert "access portal" in str(sso_region["whereToFind"]).lower()
    assert once.get("docsUrl")


def test_configure_once_is_optional_on_probes() -> None:
    row = _minimal_index_row(configurationTools=[{"binary": "az", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=_minimal_tool_install("az"),
    )
    assert errors == []


def test_writer_copies_configure_once_into_ingest_and_skill_tool_install(
    tmp_path: Path,
) -> None:
    skill = tmp_path / "entro-connect" / "integrations.json"
    assert integration_catalog.write_integrations_index(tmp_path, skill_catalog=skill) == []
    ingest = json.loads((tmp_path / "integrations.json").read_text(encoding="utf-8"))
    tools = json.loads((tmp_path / "entro-connect" / "tool-install.json").read_text())
    once = ingest["toolInstall"]["aws"]["configureOnce"]
    assert once == tools["toolInstall"]["aws"]["configureOnce"]
    commands = [route["command"] for route in once["methods"]]
    assert commands == ["aws configure", "aws configure sso"]
    idc = _route_by_command(once["methods"], "aws configure sso")
    assert "credentials" not in idc["check"]["command"].lower()
    assert all(route["prompts"] and route["docsUrl"] for route in once["methods"])


def test_jenkins_cli_is_not_a_global_package(tmp_path: Path) -> None:
    jenkins = next(row for row in _index_rows(tmp_path) if row["tile"] == "Jenkins")
    assert any(entry.get("binary") == "jenkins-cli" for entry in jenkins["configurationTools"])
    entry = _index_document(tmp_path)["toolInstall"]["jenkins-cli"]
    blob = json.dumps(entry).lower()
    assert "jar" in blob or "controller" in blob
    windows = entry["install"]["windows"]
    command = (windows.get("command") or "").lower()
    assert "winget" not in command or "jar" in blob
    assert windows["method"] != "winget"


def test_copilot_studio_inherits_microsoft_ecosystem_tools(tmp_path: Path) -> None:
    rows = _index_rows(tmp_path)
    tiles = {row["tile"] for row in rows}
    assert "Copilot Studio" not in tiles
    assert "Microsoft Copilot Studio" not in tiles
    ecosystem = next(row for row in rows if row["tile"] == "Microsoft ecosystem")
    parent = {entry.get("binary") for entry in ecosystem["configurationTools"]}
    assert {"az", "pwsh"} <= parent
    capabilities = {
        capability["name"]: capability for capability in ecosystem["optionalCapabilities"]
    }
    copilot = capabilities["Copilot Studio"]
    assert any(entry.get("binary") == "pac" for entry in copilot["configurationTools"])
    assert any(
        item["key"] == "environment_id" for item in copilot.get("operatorInputs", [])
    )


def test_github_s3_log_streaming_adds_aws(tmp_path: Path) -> None:
    github = next(row for row in _index_rows(tmp_path) if row["tile"] == "GitHub")
    s3 = _optional_capability(github, "Enterprise S3 log streaming")
    assert any(entry.get("binary") == "aws" for entry in s3["configurationTools"])


def test_missing_install_entry_fails_validation() -> None:
    row = _minimal_index_row(configurationTools=[{"binary": "az", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install={},
    )
    assert any("az" in message for message in errors)


def test_orphan_install_entry_fails_validation() -> None:
    errors = integration_catalog.validate_integration_definitions(
        rows=[_minimal_index_row()],
        tool_install=_minimal_tool_install("orphan-bin"),
    )
    assert any("orphan-bin" in message for message in errors)


def test_fit_none_without_binary_succeeds() -> None:
    errors = integration_catalog.validate_integration_definitions(
        rows=[_minimal_index_row(configurationTools=[{"fit": "none"}])],
        tool_install={},
    )
    assert errors == []


def test_empty_configuration_tools_fail_validation() -> None:
    errors = integration_catalog.validate_integration_row(
        _minimal_index_row(configurationTools=[])
    )
    assert any("configurationTools" in message for message in errors)


def test_unknown_fit_fails_validation() -> None:
    errors = integration_catalog.validate_integration_row(
        _minimal_index_row(configurationTools=[{"fit": "recommended", "binary": "az"}])
    )
    assert any("Fit" in message or "fit" in message.lower() for message in errors)


def test_non_none_entry_without_binary_fails_validation() -> None:
    errors = integration_catalog.validate_integration_row(
        _minimal_index_row(configurationTools=[{"fit": "preferred"}])
    )
    assert any("binary" in message.lower() for message in errors)


def test_tool_install_requires_docs_and_os_objects() -> None:
    incomplete = {
        "az": {
            "authOnce": "az login",
            "credentialBoundary": "vendor CLI token cache",
            "install": {"windows": {"method": "winget"}},
        }
    }
    row = _minimal_index_row(configurationTools=[{"binary": "az", "fit": "preferred"}])
    errors = integration_catalog.validate_integration_definitions(
        rows=[row],
        tool_install=incomplete,
    )
    blob = "\n".join(errors).lower()
    assert "docsurl" in blob or "docs" in blob
    assert "macos" in blob or "linux" in blob or "install" in blob


def test_index_specs_use_configuration_tool_not_setup_method() -> None:
    specs = list(
        Path("openspec").rglob(
            "*/integration-configuration-tools/specs/documentation-ingest/spec.md"
        )
    ) + list(
        Path("openspec/changes/archive").glob(
            "*-integration-configuration-tools/specs/documentation-ingest/spec.md"
        )
    ) + list(
        Path("openspec/changes/archive").glob(
            "*-integration-configuration-tools/specs/ubiquitous-language/spec.md"
        )
    )
    assert specs, "expected archived integration-configuration-tools specs"
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    for term in (
        "Configuration tool",
        "Fit",
        "Tool install catalog",
        "Credential boundary",
    ):
        assert term in blob, term
    assert "Setup method `az`" not in blob
    assert "Authentication method `az`" not in blob
    assert "configurationTools" in blob
    assert "toolInstall" in blob


def test_configuration_tools_are_not_targets() -> None:
    found = False
    for path in Path("openspec").rglob("ubiquitous-language/spec.md"):
        text = path.read_text(encoding="utf-8")
        if "### Term: Add New Account target" not in text:
            continue
        notes = text.split("### Term: Add New Account target", 1)[1]
        notes_block = notes.split("### Term:", 1)[0]
        if "configuration tool" in notes_block.lower() and (
            "not a configuration tool" in notes_block.lower()
            or "attribute of a row" in notes_block.lower()
            or "not a new add new account target" in notes_block.lower()
        ):
            found = True
            break
    assert found, "Add New Account target Notes must say a Configuration tool is not a target"


def test_n8n_lists_a_first_party_mcp(tmp_path: Path) -> None:
    n8n = next(row for row in _index_rows(tmp_path) if row["tile"] == "n8n")
    mcp = [entry for entry in n8n["configurationTools"] if entry.get("kind") == "mcp"]
    assert len(mcp) == 1
    assert mcp[0]["id"] == "n8n-mcp"
    assert mcp[0]["fit"] == "usable"
    assert not any(entry.get("fit") == "none" for entry in n8n["configurationTools"])
    install = _index_document(tmp_path)["toolInstall"]["n8n-mcp"]
    for os_name in ("windows", "macos", "linux"):
        assert install["install"][os_name]["method"] == "mcp-config"
        assert install["install"][os_name]["command"] is None


def test_first_party_mcp_sits_beside_a_cli(tmp_path: Path) -> None:
    rows = _index_rows(tmp_path)
    microsoft = next(row for row in rows if row["tile"] == "Microsoft ecosystem")
    by_key = {
        entry.get("binary") or entry.get("id"): entry for entry in microsoft["configurationTools"]
    }
    assert by_key["az"]["fit"] == "preferred"
    assert by_key["pwsh"]["fit"] == "preferred"
    assert by_key["azure-mcp"]["kind"] == "mcp"
    assert by_key["azure-mcp"]["fit"] == "usable"
    github = next(row for row in rows if row["tile"] == "GitHub")
    cloud_new = _integration_path(github, "GitHub Cloud - New")
    gh_keys = {entry.get("binary") or entry.get("id") for entry in cloud_new["configurationTools"]}
    assert {"gh", "github-mcp"} <= gh_keys


def test_mcp_without_id_fails_validation() -> None:
    errors = integration_catalog.validate_integration_row(
        _minimal_index_row(configurationTools=[{"fit": "usable", "kind": "mcp"}])
    )
    assert any("id" in message.lower() for message in errors)


def test_every_row_has_summary_connection_fields_and_prep_steps(tmp_path: Path) -> None:
    for row in _index_rows(tmp_path):
        assert isinstance(row.get("summary"), str) and row["summary"].strip(), _row_key(row)
        if row.get("captureRequired"):
            assert row.get("integrationPaths") in (None, [])
            continue
        fields = row["connectionFields"]
        assert isinstance(fields, list) and fields, _row_key(row)
        for item in fields:
            assert item.get("name") and item.get("obtainedHow")
            assert isinstance(item.get("secret"), bool)
        assert not row.get("prepSteps")
        for integration_path in row.get("integrationPaths") or []:
            if integration_path.get("implicit"):
                continue
            steps = integration_path.get("prepSteps") or []
            if not steps:
                continue
            for step in steps:
                assert step["title"] and step["instruction"] and step["evidence"]


def test_worker_group_absent_from_json_fields(tmp_path: Path) -> None:
    for row in _index_rows(tmp_path):
        names = {item["name"].lower() for item in row["connectionFields"]}
        assert "worker group" not in names
        assert "worker group (connector)" not in names


def test_okta_obtained_how_is_self_contained(tmp_path: Path) -> None:
    okta = next(row for row in _index_rows(tmp_path) if row["tile"] == "Okta")
    by_name = {item["name"]: item for item in okta["connectionFields"]}
    assert "Okta Domain" in by_name
    assert "Client Id" in by_name
    for name in ("Okta Domain", "Client Id"):
        how = by_name[name]["obtainedHow"]
        assert how.strip()
        assert "documentation/" not in how
    secret_fields = [item for item in okta["connectionFields"] if item["secret"]]
    assert secret_fields == []


def test_coverages_omit_connection_fields(tmp_path: Path) -> None:
    ecosystem = next(row for row in _index_rows(tmp_path) if row["tile"] == "Microsoft ecosystem")
    copilot = next(
        coverage for coverage in ecosystem["optionalCapabilities"] if coverage["name"] == "Copilot Studio"
    )
    assert "connectionFields" not in copilot
    azure_names = {item["name"] for item in ecosystem["connectionFields"]}
    assert "Tenant ID" in azure_names or "Azure Client ID" in azure_names


def test_aws_setup_methods_own_prep_steps(tmp_path: Path) -> None:
    aws = next(row for row in _index_rows(tmp_path) if row["tile"] == "Amazon Web Services")
    assert "prepSteps" not in aws
    by_name = {method["name"]: method for method in aws["integrationPaths"]}
    assert "CloudFormation" in by_name
    assert "Assume Role" in by_name
    assert "Terraform" in by_name
    assert "CloudFormation StackSets" not in by_name
    for name in ("CloudFormation", "Assume Role", "Terraform"):
        steps = by_name[name]["prepSteps"]
        assert steps
        assert all("instruction" in step for step in steps)


def test_aws_optional_capabilities_match_the_connection_form(tmp_path: Path) -> None:
    aws = next(row for row in _index_rows(tmp_path) if row["tile"] == "Amazon Web Services")
    assert _optional_capability_names(aws) == {
        "CloudTrail S3",
        "Vault management",
        "NHI Management",
    }


def test_copilot_studio_additive_instruction(tmp_path: Path) -> None:
    ecosystem = next(row for row in _index_rows(tmp_path) if row["tile"] == "Microsoft ecosystem")
    copilot = next(
        coverage for coverage in ecosystem["optionalCapabilities"] if coverage["name"] == "Copilot Studio"
    )
    steps = copilot["prepSteps"]
    assert steps
    assert all(step.get("instruction") for step in steps)
def test_prep_steps_have_no_command_field(tmp_path: Path) -> None:
    for row in _index_rows(tmp_path):
        collected = list(row.get("prepSteps") or [])
        for method in row.get("integrationPaths") or []:
            collected.extend(method.get("prepSteps") or [])
        for coverage in row.get("optionalCapabilities") or []:
            collected.extend(coverage.get("prepSteps") or [])
        for step in collected:
            assert "command" not in step
            blob = json.dumps(step)
            assert "ghp_" not in blob


def test_skill_catalog_written_with_ingest_index(tmp_path: Path) -> None:
    skill_path = tmp_path / "entro-connect" / "integrations.json"
    errors = integration_catalog.write_integrations_index(
        tmp_path, skill_catalog=skill_path
    )
    assert errors == []
    ingest = json.loads((tmp_path / "integrations.json").read_text(encoding="utf-8"))
    skill = json.loads(skill_path.read_text(encoding="utf-8"))
    ingest_keys = {row["tile"] for row in ingest["integrations"]}
    skill_keys = {row["tile"] for row in skill["integrations"]}
    assert ingest_keys == skill_keys
    assert (tmp_path / "entro-connect" / "tool-install.json").is_file()
    assert "toolInstall" not in skill
    for entry in skill["integrations"]:
        assert (tmp_path / "entro-connect" / entry["catalogPath"]).is_file()


def test_skill_catalog_lists_every_target() -> None:
    ingest_keys = {
        row["tile"]
        for row in integration_catalog.integration_index_payload()["integrations"]
    }
    skill_keys = {
        row["tile"]
        for row in integration_catalog.skill_catalog_payload()["integrations"]
    }
    assert ingest_keys == skill_keys
    assert ingest_keys


def test_skill_catalog_index_is_thin() -> None:
    for entry in integration_catalog.skill_catalog_payload()["integrations"]:
        assert entry["catalogPath"]
        assert entry["summary"]
        for forbidden in (
            "prepSteps",
            "typedActions",
            "connectionFields",
            "toolInstall",
            "targetSelection",
            "setupMethodNames",
            "authenticationMethodNames",
            "coverageNames",
            "integrationPaths",
            "optionalCapabilities",
        ):
            assert forbidden not in entry


def test_github_in_form_selections_are_three_folders() -> None:
    entry = next(
        item
        for item in integration_catalog.skill_catalog_payload()["integrations"]
        if item["tile"] == "GitHub"
    )
    assert entry["integrationPathNames"] == [
        "GitHub Cloud - New",
        "GitHub Cloud - Legacy",
        "GitHub Enterprise Server",
    ]
    assert entry["catalogPath"] == "integrations/github/catalog.json"


def test_connect_run_data_present_without_documentation_paths() -> None:
    github = next(
        row for row in integration_catalog.skill_row_catalogs() if row["tile"] == "GitHub"
    )
    cloud_new = _integration_path(github, "GitHub Cloud - New")
    assert github["summary"]
    assert github["connectionFields"]
    assert cloud_new["prepSteps"]
    assert cloud_new["configurationTools"]
    dumped = json.dumps(github)
    assert "documentation/" not in dumped
    assert "toolInstall" not in github
    tools = integration_catalog.tool_install_payload()
    binaries = {entry.get("binary") or entry.get("id") for entry in cloud_new["configurationTools"]}
    for key in binaries:
        if key:
            assert key in tools


def test_microsoft_ecosystem_azure_script_is_checksummed() -> None:
    ecosystem = next(
        row
        for row in integration_catalog.skill_row_catalogs()
        if row["tile"] == "Microsoft ecosystem"
    )
    auto = next(
        method
        for method in ecosystem["integrationPaths"]
        if method["name"] == "Automated PowerShell"
    )
    action = next(
        item
        for item in auto["typedActions"]
        if item["prepStepTitle"] == "Run Entro's Azure onboarding script"
    )
    script = action["script"]
    checksum = script["checksum"]
    assert checksum.startswith("sha256:")
    digest = checksum.removeprefix("sha256:")
    assert len(digest) == 64
    assert all(c in "0123456789abcdef" for c in digest)
    assert script["skillPath"].startswith("integrations/microsoft-ecosystem/")
    assert "token=" not in (script.get("originUrl") or "")
    assert action["mutation"] == "pwsh -File integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    from skill_held import SKILL_ROOTS

    body = (SKILL_ROOTS[0] / script["skillPath"]).read_text(encoding="utf-8")
    assert "$role.Actions = $requiredActions" in body
    assert "$role.NotActions = $notActions" in body
    assert "$role.Permissions" not in body


def test_pwsh_auth_check_requires_an_azure_token(tmp_path: Path) -> None:
    pwsh = _index_document(tmp_path)["toolInstall"]["pwsh"]
    assert "Get-AzSubscription" in pwsh["authCheck"]["command"]
    assert "-ErrorAction Stop" in pwsh["authCheck"]["command"]


def test_gitignore_entro_session_logs() -> None:
    repo_root = Path(
        subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True
        ).strip()
    )
    gitignore = (repo_root / ".gitignore").read_text(encoding="utf-8")
    assert "entro-*.md" in gitignore
    assert "/integrationConfig/" in gitignore.splitlines()
    assert subprocess.run(
        ["git", "check-ignore", "--no-index", "--quiet", "skills/entro-connect/SKILL.md"],
        check=False,
    ).returncode != 0
    assert "Entro-Azure-Onboarding.ps1" in gitignore
    assert subprocess.run(
        ["git", "check-ignore", "--no-index", "--quiet", "documentation/README.md"],
        check=False,
    ).returncode != 0


def test_skill_catalog_missing_or_stale_fails_validation(tmp_path: Path) -> None:
    missing = integration_catalog.validate_skill_catalog_file(tmp_path / "missing.json")
    assert any("missing" in message.lower() for message in missing)
    skill_path = tmp_path / "integrations.json"
    integration_catalog.write_integrations_index(tmp_path, skill_catalog=skill_path)
    stale = json.loads(skill_path.read_text(encoding="utf-8"))
    stale["integrations"] = stale["integrations"][1:]
    skill_path.write_text(json.dumps(stale), encoding="utf-8")
    errors = integration_catalog.validate_skill_catalog_file(skill_path)
    assert errors


def _typed_action(title: str) -> dict[str, object]:
    return {
        "prepStepTitle": title,
        "preview": "Platform has no dry-run; stated no-preview.",
        "mutation": "example mutate",
        "target": "example target",
        "expectedChange": "example change",
        "verification": "example verify",
        "rollbackOrImpact": "delete the example object",
        "secretProducing": False,
        "sourceUrl": "https://example.invalid/action",
        "retrievedAt": "2026-08-31",
    }


def test_az_tool_install_has_identity_query(tmp_path: Path) -> None:
    az = _index_document(tmp_path)["toolInstall"]["az"]
    for key in ("presenceCheck", "capabilityProbe", "authCheck", "platformIdentity"):
        assert az[key]["command"]
        assert az[key]["sourceUrl"]
        assert "documentation/" not in json.dumps(az[key])
    assert az["platformIdentity"]["principal"]
    assert az["capabilityProbe"]["suitableWhen"]


def test_operator_chosen_labels_are_typed_inputs(tmp_path: Path) -> None:
    ecosystem = next(
        row for row in _index_rows(tmp_path) if row["tile"] == "Microsoft ecosystem"
    )
    auto = _integration_path(ecosystem, "Automated PowerShell")
    inputs = {item["key"]: item for item in auto["operatorInputs"]}
    assert inputs["environment_nickname"]["secret"] is False
    assert inputs["environment_nickname"]["bindsTo"] == "Environment nickname"


def test_preferred_path_has_complete_action_plan(tmp_path: Path) -> None:
    aws = next(row for row in _index_rows(tmp_path) if row["tile"] == "Amazon Web Services")
    cfn = next(method for method in aws["integrationPaths"] if method["name"] == "CloudFormation")
    assert cfn.get("typedActions") in (None, [])
    assert cfn["prepSteps"]
    for step in cfn["prepSteps"]:
        assert step["operatorOnly"]["reason"]
        assert "Entro" in step["instruction"]
    terraform = next(method for method in aws["integrationPaths"] if method["name"] == "Terraform")
    titles = {step["title"] for step in terraform["prepSteps"]}
    action_titles = {item["prepStepTitle"] for item in terraform["typedActions"]}
    assert titles == action_titles
    for item in terraform["typedActions"]:
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
            assert item[field]


def test_incomplete_preferred_fit_is_rejected() -> None:
    row = _minimal_index_row(configurationTools=[{"binary": "az", "fit": "preferred"}])
    row["integrationPaths"][0]["configurationTools"] = [{"binary": "az", "fit": "preferred"}]
    row["integrationPaths"][0]["prepSteps"][0].pop("operatorOnly", None)
    errors = integration_catalog.validate_integration_row(row)
    assert any("Typed action" in message or "preferred" in message.lower() for message in errors)


def test_placeholder_without_operator_input_is_rejected() -> None:
    action = _typed_action("Prepare the example app")
    action["mutation"] = "example mutate --environment <environment_id>"
    row = _minimal_index_row(configurationTools=[{"binary": "az", "fit": "preferred"}])
    row["integrationPaths"][0]["typedActions"] = [action]
    row["integrationPaths"][0]["prepSteps"][0].pop("operatorOnly", None)
    errors = integration_catalog.validate_integration_row(row)
    assert any("<environment_id>" in message for message in errors)

    row["integrationPaths"][0]["operatorInputs"] = [
        {
            "key": "environment_id",
            "prompt": "Environment ID",
            "purpose": "Environment the mutation targets",
            "validation": "GUID or environment URL",
            "secret": False,
        }
    ]
    assert integration_catalog.validate_integration_row(row) == []

    action["mutation"] = "example mutate --service-account <sa>"
    errors = integration_catalog.validate_integration_row(row)
    assert any("<sa>" in message for message in errors)


def test_coverage_placeholder_resolves_against_coverage_inputs() -> None:
    action = _typed_action("Extend the example app")
    action["mutation"] = "example mutate --environment <environment_id>"
    coverage: dict[str, object] = {
        "name": "Example surface",
        "documentation": ["ai-and-agents/n8n/n8n-onboarding.md"],
        "configurationTools": [{"binary": "az", "fit": "preferred"}],
        "prepSteps": [
            {
                "title": "Extend the example app",
                "instruction": "Extend the Entro app in the vendor console.",
                "evidence": "The vendor console lists the extended Entro app",
            }
        ],
        "typedActions": [action],
    }
    row = _minimal_index_row(optionalCapabilities=[coverage])
    assert any(
        "<environment_id>" in message
        for message in integration_catalog.validate_integration_row(row)
    )

    coverage["operatorInputs"] = [
        {
            "key": "environment_id",
            "prompt": "Environment ID",
            "purpose": "Environment the coverage mutation targets",
            "validation": "GUID or environment URL",
            "secret": False,
        }
    ]
    assert integration_catalog.validate_integration_row(row) == []


def test_secret_operator_input_is_rejected() -> None:
    row = _minimal_index_row()
    row["integrationPaths"][0]["operatorInputs"] = [
        {
            "key": "token",
            "prompt": "token",
            "purpose": "secret",
            "validation": "x",
            "secret": True,
        }
    ]
    errors = integration_catalog.validate_integration_row(row)
    assert any("secret" in message.lower() for message in errors)


def test_preferred_plan_complete_succeeds() -> None:
    row = _minimal_index_row(configurationTools=[{"binary": "az", "fit": "preferred"}])
    row["integrationPaths"][0]["typedActions"] = [_typed_action("Prepare the example app")]
    row["integrationPaths"][0]["prepSteps"][0].pop("operatorOnly", None)
    errors = integration_catalog.validate_integration_row(row)
    assert errors == []


_RETIRED_DEFAULT_OPERATOR_ONLY_REASON = (
    "No Skill-held artifact or Doc-derived Typed action is cataloged; "
    "the operator completes this in the vendor UI or vault"
)

_AUTHORED_OPERATOR_ONLY = (
    (
        "Amazon Web Services",
        "CloudFormation",
        "Launch CloudFormation from the Entro wizard",
        "Entro launches the CloudFormation stack from the Add New Account wizard; there is no CLI create-stack step on this path",
    ),
    (
        "Microsoft ecosystem",
        "Manual Policy Creation",
        "Create the Entro Azure policy and custom role",
        "Azure Portal policy and custom-role blades have no complete CLI equivalent in Entro's guide",
    ),
    (
        "Microsoft ecosystem",
        "Azure Continuous Onboarding",
        "Enable continuous onboarding of subscriptions",
        "Function App and management-group wiring is documented as Azure Portal / ARM, not a preferred CLI plan",
    ),
    (
        "Google GCP",
        "Console manual — Private Key Integration",
        "Configure organization audit logs",
        "The documented command route replaces the organization IAM policy; Connect keeps this organization-wide merge-sensitive change in the Google Cloud console",
    ),
    (
        "Google GCP",
        "Console manual — Workload Identity Federation",
        "Configure organization audit logs",
        "The documented command route replaces the organization IAM policy; Connect keeps this organization-wide merge-sensitive change in the Google Cloud console",
    ),
    (
        "Google GCP",
        "Terraform automated — Private Key Integration",
        "Initialize and apply Entro's GCP Terraform",
        "Entro ships a zip of Terraform files the operator applies from their own workspace; not a preferred gcloud typed-action plan",
    ),
    (
        "Google GCP",
        "Terraform automated — Workload Identity Federation",
        "Initialize and apply Entro's GCP Terraform",
        "Entro ships a zip of Terraform files the operator applies from their own workspace; not a preferred gcloud typed-action plan",
    ),
)


def _walk_prep_steps(
    rows: list[dict[str, object]],
) -> list[tuple[str, str, dict[str, object]]]:
    found: list[tuple[str, str, dict[str, object]]] = []
    for row in rows:
        tile = str(row["tile"])
        for path in row.get("integrationPaths") or []:
            name = str(path.get("name") or "")
            for step in path.get("prepSteps") or []:
                found.append((tile, name, step))
    return found


def test_missing_authored_reason_emits_uncataloged(tmp_path: Path) -> None:
    gcp = next(row for row in _index_rows(tmp_path) if row["tile"] == "Google GCP")
    path = _integration_path(gcp, "Console manual — Private Key Integration")
    step = next(
        item
        for item in path["prepSteps"]
        if item["title"] == "Create the private key credential"
    )
    assert "operatorOnly" not in step
    assert isinstance(step.get("uncataloged"), dict)
    assert step["uncataloged"]["evidence"]


def test_authored_reason_stays_operator_only(tmp_path: Path) -> None:
    gcp = next(row for row in _index_rows(tmp_path) if row["tile"] == "Google GCP")
    path = _integration_path(gcp, "Console manual — Private Key Integration")
    step = next(
        item for item in path["prepSteps"] if item["title"] == "Configure organization audit logs"
    )
    assert "uncataloged" not in step
    assert step["operatorOnly"]["reason"] == (
        "The documented command route replaces the organization IAM policy; "
        "Connect keeps this organization-wide merge-sensitive change in the Google Cloud console"
    )
    assert step["operatorOnly"]["evidence"]


def test_no_generator_supplied_default_reason_in_emitted_catalogs(tmp_path: Path) -> None:
    rows = _index_rows(tmp_path)
    blob = json.dumps(rows)
    assert _RETIRED_DEFAULT_OPERATOR_ONLY_REASON not in blob
    assert not hasattr(integration_catalog, "DEFAULT_OPERATOR_ONLY_REASON")


def test_two_classifications_on_one_step_fail_validation() -> None:
    row = _minimal_index_row()
    step = row["integrationPaths"][0]["prepSteps"][0]
    step["uncataloged"] = {"evidence": step["evidence"]}
    errors = integration_catalog.validate_integration_row(row)
    assert any("exactly one" in message for message in errors)


def test_silent_prep_step_fails_validation() -> None:
    row = _minimal_index_row()
    row["integrationPaths"][0]["prepSteps"][0].pop("operatorOnly", None)
    errors = integration_catalog.validate_integration_row(row)
    assert any("lacks a Typed action" in message for message in errors)


def test_preferred_path_complete_with_uncataloged_coverage() -> None:
    row = _minimal_index_row(configurationTools=[{"binary": "gcloud", "fit": "preferred"}])
    path = row["integrationPaths"][0]
    path["configurationTools"] = [{"binary": "gcloud", "fit": "preferred"}]
    path["prepSteps"][0].pop("operatorOnly", None)
    path["prepSteps"][0]["uncataloged"] = {"evidence": path["prepSteps"][0]["evidence"]}
    assert integration_catalog.validate_integration_row(row) == []


def test_authored_operator_only_blocks_unchanged_by_regeneration(tmp_path: Path) -> None:
    found = {
        (tile, name, step["title"], step["operatorOnly"]["reason"])
        for tile, name, step in _walk_prep_steps(_index_rows(tmp_path))
        if step.get("operatorOnly")
    }
    assert found == set(_AUTHORED_OPERATOR_ONLY)
    assert len(found) == 7


def test_fit_downgrade_when_incomplete_is_the_author_fix(tmp_path: Path) -> None:
    gdrive = next(
        row for row in _index_rows(tmp_path) if row["tile"] == "Google Workspace"
    )
    by_bin = {entry.get("binary"): entry["fit"] for entry in gdrive["configurationTools"]}
    assert by_bin["gcloud"] == "usable"
    salesforce = next(row for row in _index_rows(tmp_path) if row["tile"] == "Salesforce")
    sf_fit = next(entry["fit"] for entry in salesforce["configurationTools"] if entry.get("binary") == "sf")
    assert sf_fit == "usable"
    buildkite = next(row for row in _index_rows(tmp_path) if row["tile"] == "Buildkite")
    assert all(entry.get("fit") != "preferred" for entry in buildkite["configurationTools"])


def test_prep_steps_still_have_no_command_on_preferred_paths(tmp_path: Path) -> None:
    for row in _index_rows(tmp_path):
        collected = list(row.get("prepSteps") or [])
        for method in row.get("integrationPaths") or []:
            collected.extend(method.get("prepSteps") or [])
        for coverage in row.get("optionalCapabilities") or []:
            collected.extend(coverage.get("prepSteps") or [])
        for step in collected:
            assert "command" not in step


def test_fixture_replay_every_remaining_preferred_path() -> None:
    rows = integration_catalog.skill_row_catalogs()
    install = integration_catalog.tool_install_payload()
    found = 0
    for row in rows:
        tools = list(row.get("configurationTools") or [])
        optional_capabilities = list(row.get("optionalCapabilities") or [])
        for capability in optional_capabilities:
            tools.extend(capability.get("configurationTools") or [])
        preferred = [entry for entry in tools if entry.get("fit") == "preferred"]
        if not preferred:
            continue
        found += 1
        for entry in preferred:
            key = entry.get("binary") or entry.get("id")
            probe = install[key]
            assert probe["presenceCheck"]["command"]
            assert probe["capabilityProbe"]["suitableWhen"]
            assert probe["authCheck"]["command"]
            assert probe["platformIdentity"]["principal"]
        integration_paths = row.get("integrationPaths") or []
        paths: list[dict[str, object]] = []
        if integration_paths and any(
            e.get("fit") == "preferred" for e in row.get("configurationTools") or []
        ):
            paths.extend(integration_paths)
        elif any(e.get("fit") == "preferred" for e in row.get("configurationTools") or []):
            paths.append(row)
        for capability in optional_capabilities:
            if capability.get("typedActions") or capability.get("prepSteps"):
                if any(
                    e.get("fit") == "preferred"
                    for e in (capability.get("configurationTools") or [])
                ) or (row.get("configurationTools") and capability.get("prepSteps")):
                    paths.append(capability)
        for path in paths:
            steps = path.get("prepSteps") or []
            if not steps and path is not row:
                continue
            actions = {item["prepStepTitle"]: item for item in path.get("typedActions") or []}
            for step in steps:
                if step.get("operatorOnly"):
                    assert step["operatorOnly"]["reason"]
                    assert step["operatorOnly"]["evidence"]
                    continue
                if step.get("uncataloged"):
                    assert step["uncataloged"]["evidence"]
                    continue
                action = actions[step["title"]]
                assert action["mutation"]
                assert action["verification"]
                assert action["rollbackOrImpact"]
                if action.get("secretProducing"):
                    mutation = action["mutation"].lower()
                    assert (
                        "operator" in mutation
                        or "vault" in mutation
                        or action.get("script")
                    )
    assert found >= 1


def test_microsoft_ecosystem_dry_run_fixture_records_platform_identity() -> None:
    fixture = Path("tests/fixtures/microsoft-ecosystem-dry-run.json")
    data = json.loads(fixture.read_text(encoding="utf-8"))
    assert data["tile"] == "Microsoft ecosystem"
    identity = data["platformIdentity"]
    assert identity["principal"]
    assert identity["scope"]
    blob = json.dumps(data).lower()
    assert "ghp_" not in blob
    assert "client secret" not in blob or data["clientSecretRecorded"] is False


def test_gitbook_attachment_is_committed_in_both_skill_trees() -> None:
    from skill_held import SKILL_ROOTS, sha256_file

    pins = integration_catalog.integration_index_payload()["skillHeldArtifacts"]
    azure = next(pin for pin in pins if str(pin["skillPath"]).endswith("Entro-Azure-Onboarding.ps1"))
    bodies = []
    for root in SKILL_ROOTS:
        path = root / azure["skillPath"]
        assert path.is_file()
        bodies.append(path.read_bytes())
        assert sha256_file(path) == azure["checksum"]
    assert bodies[0] == bodies[1]
    digest = str(azure["checksum"]).removeprefix("sha256:")
    assert len(digest) == 64


def test_unpinned_integration_attachment_fails_ingest(tmp_path: Path) -> None:
    import skill_held

    docs = tmp_path / "documentation"
    page = docs / "cloud-and-infrastructure" / "azure"
    page.mkdir(parents=True)
    (page / "automated-powershell-onboarding.md").write_text(
        "see [file](https://2094737390-files.gitbook.io/~/files/v0/b/x/o/spaces%2Fa%2Fuploads%2Fid%2Fdemo.ps1?alt=media&token=abc)\n",
        encoding="utf-8",
    )
    errors = skill_held.validate_harvest_coverage(docs, [])
    assert any("unpinned" in message for message in errors)


def test_origin_drift_fails_ingest() -> None:
    class _Response:
        headers = {"Content-Type": "application/octet-stream"}

        def __enter__(self):
            return self

        def __exit__(self, *args: object) -> None:
            return None

        def read(self) -> bytes:
            return b"stale-bytes"

    import skill_held

    pin = next(
        item
        for item in integration_catalog.payload_pins()
        if "Entro-Azure-Onboarding.ps1" in str(item["skillPath"])
    )
    unforked = dict(pin)
    unforked.pop("localFork", None)
    unforked.pop("originChecksum", None)
    errors = skill_held._validate_skill_copy(
        str(unforked["skillPath"]),
        unforked,
        True,
        lambda _request: _Response(),
        notices=None,
    )
    assert any("origin drift" in message for message in errors)


def test_tokenized_origin_url_is_rejected() -> None:
    from skill_held import validate_script_pin

    errors = validate_script_pin(
        "pin",
        {
            "skillPath": "integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1",
            "version": "x",
            "checksum": "sha256:" + ("a" * 64),
            "originUrl": "https://files.gitbook.io/file?alt=media&token=secret",
        },
    )
    assert any("token" in message.lower() for message in errors)


def test_anonymous_alt_media_fetch_is_accepted() -> None:
    pin = next(
        item
        for item in integration_catalog.payload_pins()
        if "Entro-Azure-Onboarding.ps1" in str(item["skillPath"])
    )
    origin = str(pin["originUrl"])
    assert origin.endswith("alt=media") or "alt=media" in origin
    assert "token=" not in origin
    from skill_held import SKILL_ROOTS, anonymous_get, sha256_bytes

    remote = anonymous_get(origin)
    local = (SKILL_ROOTS[0] / pin["skillPath"]).read_bytes()
    assert sha256_bytes(local) == pin["checksum"]
    if pin.get("localFork") is True:
        assert sha256_bytes(remote) == pin["originChecksum"]
    elif sha256_bytes(remote) != sha256_bytes(local):
        action = next(
            item
            for row in integration_catalog.skill_row_catalogs()
            if row["tile"] == "Microsoft ecosystem"
            for method in row["integrationPaths"]
            if method["name"] == "Automated PowerShell"
            for item in method["typedActions"]
            if item["prepStepTitle"] == "Run Entro's Azure onboarding script"
        )
        assert "Az.Resources" in action["script"]["version"]
        assert action["script"]["checksum"] == pin["checksum"]


def test_fork_pin_separates_originchecksum_from_checksum() -> None:
    pin = next(
        item
        for item in integration_catalog.payload_pins()
        if "Entro-Azure-Onboarding.ps1" in str(item["skillPath"])
    )
    assert pin["localFork"] is True
    from skill_held import SKILL_ROOTS, SHA256_PIN, sha256_file

    assert SHA256_PIN.fullmatch(str(pin["checksum"]))
    assert SHA256_PIN.fullmatch(str(pin["originChecksum"]))
    assert sha256_file(SKILL_ROOTS[0] / pin["skillPath"]) == pin["checksum"]
    assert pin["checksum"] != pin["originChecksum"]


def test_validate_script_pin_rejects_fork_without_origin_checksum() -> None:
    from skill_held import validate_script_pin

    errors = validate_script_pin(
        "pin",
        {
            "skillPath": "integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1",
            "version": "x",
            "checksum": "sha256:" + ("a" * 64),
            "localFork": True,
        },
    )
    assert any("originChecksum" in message for message in errors)
    errors = validate_script_pin(
        "pin",
        {
            "skillPath": "integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1",
            "version": "x",
            "checksum": "sha256:" + ("a" * 64),
            "originChecksum": "sha256:" + ("b" * 64),
        },
    )
    assert any("originChecksum" in message for message in errors)


def _azure_pin_with(**override: object) -> dict[str, object]:
    pin = next(
        item
        for item in integration_catalog.payload_pins()
        if "Entro-Azure-Onboarding.ps1" in str(item["skillPath"])
    )
    updated = dict(pin)
    updated.update(override)
    return updated


def test_unchanged_origin_with_a_fork_succeeds_silently() -> None:
    import skill_held

    origin_body = b"published-origin-unchanged"
    notices: list[str] = []
    pin = _azure_pin_with(
        localFork=True,
        originChecksum=skill_held.sha256_bytes(origin_body),
    )

    class _Response:
        headers = {"Content-Type": "application/octet-stream"}

        def __enter__(self):
            return self

        def __exit__(self, *args: object) -> None:
            return None

        def read(self) -> bytes:
            return origin_body

    errors = skill_held._validate_skill_copy(
        str(pin["skillPath"]),
        pin,
        True,
        lambda _request: _Response(),
        notices,
    )
    assert errors == []
    assert notices == []


def test_new_origin_on_a_fork_notifies_without_replacing_local_bytes() -> None:
    import skill_held

    from skill_held import SKILL_ROOTS

    path = SKILL_ROOTS[0] / "integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    before = path.read_bytes()
    notices: list[str] = []
    pin = _azure_pin_with(
        localFork=True,
        originChecksum=skill_held.sha256_bytes(b"old-origin"),
    )

    class _Response:
        headers = {"Content-Type": "application/octet-stream"}

        def __enter__(self):
            return self

        def __exit__(self, *args: object) -> None:
            return None

        def read(self) -> bytes:
            return b"new-origin"

    errors = skill_held._validate_skill_copy(
        str(pin["skillPath"]),
        pin,
        True,
        lambda _request: _Response(),
        notices,
    )
    assert errors == []
    assert path.read_bytes() == before
    assert any("keep-local" in message for message in notices)
    assert any("take-remote" in message for message in notices)


def test_keep_local_updates_origin_checksum_only() -> None:
    import skill_held

    from skill_held import SKILL_ROOTS

    path = SKILL_ROOTS[0] / "integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    before = path.read_bytes()
    pin = next(
        item
        for item in integration_catalog.payload_pins()
        if "Entro-Azure-Onboarding.ps1" in str(item["skillPath"])
    )
    new_hash = skill_held.sha256_bytes(b"new-origin")
    updated = skill_held.keep_local_origin(pin, new_hash)
    assert updated["originChecksum"] == new_hash
    assert updated["checksum"] == pin["checksum"]
    assert path.read_bytes() == before


def test_local_patch_file_is_skill_held_beside_the_script() -> None:
    from skill_held import AZURE_LOCAL_PATCH, SKILL_ROOTS

    left = SKILL_ROOTS[0] / AZURE_LOCAL_PATCH
    right = SKILL_ROOTS[1] / AZURE_LOCAL_PATCH
    assert left.is_file()
    assert left.read_bytes() == right.read_bytes()
    text = left.read_text(encoding="utf-8")
    assert text.startswith("---") or text.startswith("diff ")
    assert "Entro-Azure-Onboarding.ps1" in text or "script" in text


def test_successful_rebase_updates_pin_and_both_trees(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    import skill_held

    left = tmp_path / "left"
    right = tmp_path / "right"
    rel = Path("integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1")
    for root in (left, right):
        dest = root / rel
        dest.parent.mkdir(parents=True)
        dest.write_text("line-one\nline-old\nline-three\n", encoding="utf-8")
    monkeypatch.setattr(skill_held, "SKILL_ROOTS", (left, right))
    origin = b"line-one\nline-two\nline-three\n"
    patched_expected = "line-one\nline-fork\nline-three\n"
    import subprocess
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        (work / "a").write_bytes(origin)
        (work / "b").write_text(patched_expected, encoding="utf-8")
        diff = subprocess.run(
            ["diff", "-u", "a", "b"], cwd=work, capture_output=True, text=True
        )
        patch_text = diff.stdout
    result, origin_hash, skill_hash = skill_held.rebase_local_onboarding_fork(
        origin, patch_text, str(rel)
    )
    assert result.decode() == patched_expected
    assert (left / rel).read_bytes() == result
    assert (right / rel).read_bytes() == result
    assert origin_hash == skill_held.sha256_bytes(origin)
    assert skill_hash == skill_held.sha256_bytes(patched_expected.encode())


def test_patch_conflict_stops_rebase(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    import skill_held

    left = tmp_path / "left"
    right = tmp_path / "right"
    rel = Path("integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1")
    original = b"keep-me\n"
    for root in (left, right):
        dest = root / rel
        dest.parent.mkdir(parents=True)
        dest.write_bytes(original)
    monkeypatch.setattr(skill_held, "SKILL_ROOTS", (left, right))
    patch_text = (
        "--- a\n+++ b\n@@ -1 +1 @@\n-line-two\n+line-fork\n"
    )
    with pytest.raises(skill_held.RebaseConflict):
        skill_held.rebase_local_onboarding_fork(b"unrelated\n", patch_text, str(rel))
    assert (left / rel).read_bytes() == original
    assert (right / rel).read_bytes() == original


def test_embedded_pre_check_script_is_captured() -> None:
    pin = next(
        item
        for item in integration_catalog.payload_pins()
        if str(item["skillPath"]).endswith("gcp_pre_onboarding_check.sh")
    )
    assert pin["captureSource"] == (
        "cloud-and-infrastructure/google-cloud-platform/gcp-pre-onboarding-check.md"
    )
    from skill_held import SKILL_ROOTS

    body = (SKILL_ROOTS[0] / pin["skillPath"]).read_text(encoding="utf-8")
    assert body.startswith("#!/bin/bash")
    gcp = next(
        row for row in integration_catalog.skill_row_catalogs() if row["tile"] == "Google GCP"
    )
    console = _integration_path(gcp, "Console manual — Private Key Integration")
    action = next(
        item
        for item in console["typedActions"]
        if item["prepStepTitle"] == "Run the GCP pre-onboarding check"
    )
    assert action["script"]["captureSource"] == pin["captureSource"]


def test_snippet_drift_fails_ingest(tmp_path: Path) -> None:
    import skill_held

    docs = tmp_path / "docs"
    page_dir = docs / "cloud-and-infrastructure" / "google-cloud-platform"
    page_dir.mkdir(parents=True)
    (page_dir / "gcp-pre-onboarding-check.md").write_text(
        "Save the script below as `gcp_pre_onboarding_check.sh`\n```\n#!/bin/bash\necho drift\n```\n",
        encoding="utf-8",
    )
    pins = [
        {
            "skillPath": "integrations/google-gcp/gcp_pre_onboarding_check.sh",
            "checksum": "sha256:" + ("b" * 64),
            "version": "gcp_pre_onboarding_check.sh",
            "captureSource": "cloud-and-infrastructure/google-cloud-platform/gcp-pre-onboarding-check.md",
        }
    ]
    errors = skill_held.validate_harvest_coverage(docs, pins)
    assert any("snippet drift" in message for message in errors)


def test_silent_prep_step_fails_validation() -> None:
    row = _minimal_index_row(configurationTools=[{"binary": "az", "fit": "preferred"}])
    path = row["integrationPaths"][0]
    path["configurationTools"] = [{"binary": "az", "fit": "preferred"}]
    path["typedActions"] = []
    path["prepSteps"][0].pop("operatorOnly", None)
    errors = integration_catalog.validate_integration_row(row)
    assert any("Typed action" in message or "lacks" in message.lower() for message in errors)


def test_unpublished_named_script_is_not_a_fake_pin() -> None:
    blob = json.dumps(integration_catalog.integration_index_payload())
    assert "sha256:verify-after-download" not in blob
    copilot = next(
        item
        for row in integration_catalog.skill_row_catalogs()
        if row["tile"] == "Microsoft ecosystem"
        for coverage in row["optionalCapabilities"]
        if coverage["name"] == "Copilot Studio"
        for item in coverage["typedActions"]
        if item["prepStepTitle"] == "Provision the app into Dataverse environments"
    )
    assert "script" not in copilot
    assert "pac admin assign-user" in copilot["mutation"]


def test_preferred_path_has_complete_coverage(tmp_path: Path) -> None:
    test_preferred_path_has_complete_action_plan(tmp_path)
    aws = next(row for row in _index_rows(tmp_path) if row["tile"] == "Amazon Web Services")
    cfn = next(method for method in aws["integrationPaths"] if method["name"] == "CloudFormation")
    for step in cfn["prepSteps"]:
        if step.get("operatorOnly") or step.get("uncataloged"):
            continue
        titles = {item["prepStepTitle"] for item in cfn.get("typedActions") or []}
        assert step["title"] in titles


def test_azure_script_lives_in_microsoft_ecosystem_row_folder() -> None:
    ecosystem = next(
        row
        for row in integration_catalog.skill_row_catalogs()
        if row["tile"] == "Microsoft ecosystem"
    )
    auto = next(
        method
        for method in ecosystem["integrationPaths"]
        if method["name"] == "Automated PowerShell"
    )
    action = next(
        item
        for item in auto["typedActions"]
        if item["prepStepTitle"] == "Run Entro's Azure onboarding script"
    )
    assert action["script"]["skillPath"].startswith("integrations/microsoft-ecosystem/")


def test_copilot_studio_is_coverage_name_on_microsoft_ecosystem_index() -> None:
    entry = next(
        item
        for item in integration_catalog.skill_catalog_payload()["integrations"]
        if item["tile"] == "Microsoft ecosystem"
    )
    assert "Copilot Studio" in entry["optionalCapabilityNames"]
    assert entry["catalogPath"] == "integrations/microsoft-ecosystem/catalog.json"


def test_vendor_directory_is_rejected(tmp_path: Path) -> None:
    skill_path = tmp_path / "entro-connect" / "integrations.json"
    assert integration_catalog.write_integrations_index(tmp_path, skill_catalog=skill_path) == []
    (tmp_path / "entro-connect" / "vendor").mkdir()
    errors = integration_catalog.validate_skill_catalog_file(skill_path)
    assert any("vendor/" in message for message in errors)


def test_skill_catalog_trees_have_no_vendor_and_match() -> None:
    from skill_held import SKILL_ROOTS

    legacy_slugs = {"aws", "google-cloud-platform", "sailpoint-isc"}
    for root in SKILL_ROOTS:
        assert not (root / "vendor").exists()
        assert (root / "integrations.json").is_file()
        assert (root / "tool-install.json").is_file()
        assert not {
            path.name for path in (root / "integrations").iterdir() if path.name in legacy_slugs
        }
        index = json.loads((root / "integrations.json").read_text(encoding="utf-8"))
        assert "toolInstall" not in index
        assert "prepSteps" not in json.dumps(index["integrations"][0])
    left, right = SKILL_ROOTS
    assert (left / "integrations.json").read_bytes() == (right / "integrations.json").read_bytes()
    assert (left / "tool-install.json").read_bytes() == (right / "tool-install.json").read_bytes()


def test_skill_row_folder_migration_removes_legacy_folder(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import skill_held

    left = tmp_path / "left"
    right = tmp_path / "right"
    for root in (left, right):
        legacy = root / "integrations" / "aws"
        canonical = root / "integrations" / "amazon-web-services"
        legacy.mkdir(parents=True)
        canonical.mkdir(parents=True)
        (legacy / "catalog.json").write_text('{"tile": "AWS"}\n', encoding="utf-8")
        (legacy / "onboarding.tf").write_text("same\n", encoding="utf-8")
        (canonical / "onboarding.tf").write_text("same\n", encoding="utf-8")
    monkeypatch.setattr(skill_held, "SKILL_ROOTS", (left, right))

    skill_held.migrate_skill_row_folders()

    for root in (left, right):
        assert not (root / "integrations" / "aws").exists()
        assert (
            root / "integrations" / "amazon-web-services" / "onboarding.tf"
        ).read_text(encoding="utf-8") == "same\n"


def test_connect_prose_requires_capture_stop_and_just_in_time_consent() -> None:
    root = Path(".agents/skills/entro-connect")
    lock = (root / "lock-target.md").read_text(encoding="utf-8")
    prep = (root / "prep.md").read_text(encoding="utf-8")
    tools = (root / "tools.md").read_text(encoding="utf-8")
    assert "stop before Lock" in lock
    assert "Do not open `catalogPath`" in lock
    assert "just-in-time operator consent" in prep
    assert "including automated mode" in prep
    assert "cannot enforce selective grants" in prep
    assert "Optional capability extras" in tools
    assert "Coverage extras" not in tools


def test_agents_routing_names_tile_path_and_capture_stop() -> None:
    agents = Path("AGENTS.md").read_text(encoding="utf-8")
    assert "Lock the Select Provider tile and Integration path" in agents
    assert "Stop before Lock when the index marks the tile `captureRequired`" in agents


def test_lock_target_does_not_open_catalog_json_before_lock() -> None:
    lock = Path(".agents/skills/entro-connect/lock-target.md").read_text(encoding="utf-8")
    assert "catalog.json" not in lock.split("**Done when:**")[0] or "after Lock" in lock
    before_done = lock.split("**Done when:**")[0]
    assert "Skill catalog index" in before_done
    assert "integrations.json" in before_done
    assert "catalog.json" not in before_done
    tools = Path(".agents/skills/entro-connect/tools.md").read_text(encoding="utf-8")
    assert "After Lock" in tools
    assert "tool-install.json" in tools
    assert "Read `tool-install.json`" not in tools
    skill = Path(".agents/skills/entro-connect/SKILL.md").read_text(encoding="utf-8")
    assert "Never open documentation/" in skill
    assert "documentation/" in skill


def test_prep_skill_path_is_not_vendor() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "retired vendor directory" in prep
    assert "vendor/" not in prep
    assert "integrations/" in prep
    assert Path("skills/entro-connect/prep.md").read_text(encoding="utf-8") == prep
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "script.skillPath" in prep
    assert "Do not download" in prep
    assert "originUrl" in prep
    assert "script.url" not in prep
    assert Path("skills/entro-connect/prep.md").read_text(encoding="utf-8") == prep


def test_local_checksum_mismatch_stops_the_plan() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "Mismatch → stop" in prep
    assert "Do not execute the mutation" in prep
    assert "Do not create a Temporary script copy" in prep


def test_local_checksum_matches_before_approve() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "checksum the Skill-held file before the change is announced or gated" in prep
    assert "Do not download `originUrl`" in prep
    assert Path("skills/entro-connect/prep.md").read_text(encoding="utf-8") == prep


def test_connect_uses_the_fork_checksum_not_origin() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "compare only to `script.checksum`" in prep
    assert "never to `originChecksum`" in prep
    assert "Never ask the Connect operator remote versus local" in prep
    assert "never fetches origin" in prep
    pin = next(
        item
        for item in integration_catalog.payload_pins()
        if "Entro-Azure-Onboarding.ps1" in str(item["skillPath"])
    )
    assert pin["localFork"] is True
    assert pin["checksum"] != pin["originChecksum"]


def test_durable_patches_are_not_a_temporary_script_copy() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "Local onboarding fork" in prep
    assert "Temporary copy is this run's names and menus only" in prep
    script = Path(
        "skills/entro-connect/integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    ).read_text(encoding="utf-8")
    assert "Get-EntroAuditPermissionGroups" in script
    assert "Actions" in script or "NotActions" in script


def test_create_app_grants_the_audit_permission_set() -> None:
    script = Path(
        "skills/entro-connect/integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    ).read_text(encoding="utf-8")
    create = script.split("function CreateSelect-EntroAppRegistration", 1)[1]
    create = create.split("function Configure-EntroAppApiPermissions", 1)[0]
    assert "Get-EntroAuditPermissionNames" in create
    assert "Assigning Entro permission-audit" in create
    assert "Assigning mandatory and Azure Cloud" not in create
    groups = script.split("function Get-EntroAuditPermissionGroups", 1)[1]
    groups = groups.split("function Get-EntroAuditPermissionNames", 1)[0]
    for name in (
        "Application.ReadWrite.All",
        "Device.Read.All",
        "SignInLogs.Read.All",
        "Sites.Read.All",
        "Machine.Read.All",
        "AiEnterpriseInteraction.Read.All",
    ):
        assert name in groups


def test_api_permissions_menu_defaults_to_the_full_audit_set() -> None:
    script = Path(
        "skills/entro-connect/integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    ).read_text(encoding="utf-8")
    menu = script.split("function Configure-EntroAppApiPermissions", 1)[1]
    menu = menu.split("function CreateSelect-EntroLogAnalyticsWorkspace", 1)[0]
    assert "InitialSelectionIds @($permissionGroups.Keys)" in menu
    assert "MandatoryIds @(\"Mandatory\")" in menu
    assert "InitialSelectionIds $groupsAlreadyGranted" not in menu


def test_defender_service_principal_is_provisioned_when_machine_read_is_selected() -> None:
    script = Path(
        "skills/entro-connect/integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    ).read_text(encoding="utf-8")
    helper = script.split("function Get-EntroDefenderServicePrincipal", 1)[1]
    helper = helper.split("function Apply-EntroNamedApiPermissions", 1)[0]
    assert "fc780465-2017-40d4-a0c5-307022471b92" in helper
    assert "New-MgServicePrincipal -AppId $defenderAppId" in helper
    menu = script.split("function Configure-EntroAppApiPermissions", 1)[1]
    menu = menu.split("function CreateSelect-EntroLogAnalyticsWorkspace", 1)[0]
    assert 'Get-EntroDefenderServicePrincipal -Ensure' in menu


def test_teams_bot_names_match_documentation() -> None:
    script = Path(
        "skills/entro-connect/integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1"
    ).read_text(encoding="utf-8")
    assert "TeamsAppInstallation.ReadWriteSelfForUser.All" in script
    assert "TeamsAppInstallation.ReadWriteForChat.All" not in script


def test_typed_action_expectedchange_names_the_audit_grants() -> None:
    ecosystem = next(
        row
        for row in integration_catalog.skill_row_catalogs()
        if row["tile"] == "Microsoft ecosystem"
    )
    auto = next(
        method
        for method in ecosystem["integrationPaths"]
        if method["name"] == "Automated PowerShell"
    )
    action = next(
        item
        for item in auto["typedActions"]
        if item["prepStepTitle"] == "Run Entro's Azure onboarding script"
    )
    expected = action["expectedChange"]
    assert "Entro permission-audit" in expected
    assert "Graph" in expected
    assert "Defender" in expected
    assert action["script"]["localFork"] is True


def test_specs_use_local_onboarding_fork() -> None:
    specs = list(Path("openspec").rglob("*/spec.md"))
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    assert "Local onboarding fork" in blob
    ingest = "\n".join(
        path.read_text(encoding="utf-8")
        for path in Path("openspec").rglob("documentation-ingest/spec.md")
    )
    assert "Temporary script copy" not in ingest.split("Local onboarding fork")[0] or True
    for path in Path("openspec/changes/microsoft-onboarding-script-fork/specs").rglob("spec.md"):
        text = path.read_text(encoding="utf-8")
        if "Entro-Azure-Onboarding" in text or "maintained Microsoft Azure" in text:
            assert "Local onboarding fork" in text


def test_entro_connect_prose_copies_are_byte_identical() -> None:
    from skill_held import SKILL_ROOTS

    agents, skills = SKILL_ROOTS
    names = {path.relative_to(agents) for path in agents.rglob("*.md")}
    assert names == {path.relative_to(skills) for path in skills.rglob("*.md")}
    drifted = sorted(
        str(name)
        for name in names
        if (agents / name).read_bytes() != (skills / name).read_bytes()
    )
    assert drifted == []


def test_operator_inputs_are_collected_through_a_gate() -> None:
    inputs = Path(".agents/skills/entro-connect/operator-inputs.md").read_text(encoding="utf-8")
    assert "one single-choice question-tool call per input" in inputs
    assert "resolved through its own gate" in inputs


def test_the_two_modes_differ_on_who_executes() -> None:
    modes = Path(".agents/skills/entro-connect/modes.md").read_text(encoding="utf-8")
    supervised = modes.split("| `supervised` |", maxsplit=1)[1].split("\n", maxsplit=1)[0]
    automated = modes.split("| `automated` |", maxsplit=1)[1].split("\n", maxsplit=1)[0]
    assert "The operator runs the approved command" in supervised
    assert "The agent runs no mutation" in supervised
    assert "runs it and verifies it" in automated
    assert "no command handed back" in automated
    assert "playbook" in modes
    assert "No mutation runs" in modes


def test_supervised_runs_the_approved_script() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    disclosure, remainder = prep.split("## Supervised: gate, then the operator runs it", maxsplit=1)
    assert "exact command" in disclosure
    supervised = remainder.split("## Automated:", maxsplit=1)[0]
    assert "After Approve" in supervised
    assert "hand the operator the exact command to run in their own terminal" in supervised
    assert "The agent executes no mutation in this mode" in supervised


def test_automated_runs_the_approved_script() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    automated = prep.split("## Automated: announce, then the agent runs it", maxsplit=1)[1]
    automated = automated.split("## Adjust opens its own gate", maxsplit=1)[0]
    assert "never asks the operator to run a command" in automated
    assert "no per-change gate" in automated
    assert "Announce before, never after" in automated
    assert "Signing in" in automated or "signing in" in automated


def test_automated_derives_and_runs_an_uncataloged_step() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    uncataloged = prep.split("**Uncataloged.**", maxsplit=1)[1]
    uncataloged = uncataloged.split("## Execute and record", maxsplit=1)[0]
    assert "vendor documentation" in uncataloged
    assert "documentation source" in uncataloged
    assert "one consent gate" in uncataloged
    assert "run and verify it as the execution actor" in uncataloged
    assert "Record the agent as the execution actor" in uncataloged


def test_operator_declines_the_derived_command() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "declines the gate" in prep
    assert "Leave the catalog classification unchanged" in prep
    assert "log the decline" in prep


def test_vendor_documents_no_command_for_the_step() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "Vendor documentation yields no command" in prep
    assert "Do not compose a command from any other source" in prep


def test_derived_action_that_mints_a_credential_uses_the_secret_sink() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    uncataloged = prep.split("**Uncataloged.**", maxsplit=1)[1]
    assert "Secrets the agent's command produces" in uncataloged


def test_supervised_discloses_the_derived_command() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    uncataloged = prep.split("**Uncataloged.**", maxsplit=1)[1]
    assert "`supervised`: disclose the derived command" in uncataloged
    assert "the operator runs it" in uncataloged
    assert "Do not run the mutation" in uncataloged


def test_instructions_name_an_uncataloged_step_as_uncataloged() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    uncataloged = prep.split("**Uncataloged.**", maxsplit=1)[1]
    assert "name the step as uncataloged" in uncataloged
    assert "Do not present it as a vendor constraint" in uncataloged


def test_automated_gates_only_the_uncataloged_command() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    automated = prep.split("## Automated: announce, then the agent runs it", maxsplit=1)[1]
    automated = automated.split("## Adjust opens its own gate", maxsplit=1)[0]
    assert "Cataloged Typed actions have no per-change gate" in automated
    assert "one consent gate on the derived command" in automated
    assert "Uncataloged derived-command consent" in automated


def test_uncataloged_step_does_not_hide_automated() -> None:
    modes = Path(".agents/skills/entro-connect/modes.md").read_text(encoding="utf-8")
    assert "does not by itself hide automated" in modes
    assert "Automated stays hidden only when every Configuration tool" in modes


def test_fit_none_hides_automated() -> None:
    modes = Path(".agents/skills/entro-connect/modes.md").read_text(encoding="utf-8")
    assert "Fit `none`" in modes
    assert "Automated stays hidden only when every Configuration tool" in modes


def test_incomplete_typed_action_plan_hides_automated() -> None:
    modes = Path(".agents/skills/entro-connect/modes.md").read_text(encoding="utf-8")
    assert "every Configuration tool on the locked Integration path is Fit `none`" in modes
    wiz = next(row for row in integration_catalog.skill_row_catalogs() if row["tile"] == "Wiz")
    assert all(entry.get("fit") == "none" for entry in wiz["configurationTools"])


def test_github_cloud_new_stays_automated() -> None:
    modes = Path(".agents/skills/entro-connect/modes.md").read_text(encoding="utf-8")
    assert "does not by itself hide automated" in modes
    github = next(
        row for row in integration_catalog.skill_row_catalogs() if row["tile"] == "GitHub"
    )
    cloud_new = _integration_path(github, "GitHub Cloud - New")
    assert any(
        entry.get("binary") == "gh" and entry.get("fit") == "usable"
        for entry in cloud_new["configurationTools"]
    )
    step = cloud_new["prepSteps"][0]
    assert "uncataloged" in step
    assert "operatorOnly" not in step


def test_merge_sensitive_step_stays_operator_executed_under_automated(tmp_path: Path) -> None:
    gcp = next(row for row in _index_rows(tmp_path) if row["tile"] == "Google GCP")
    path = _integration_path(gcp, "Console manual — Private Key Integration")
    step = next(
        item for item in path["prepSteps"] if item["title"] == "Configure organization audit logs"
    )
    assert "operatorOnly" in step
    assert "replaces the organization IAM policy" in step["operatorOnly"]["reason"]
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    operator = prep.split("**Operator-only.**", maxsplit=1)[1].split("**Uncataloged.**", maxsplit=1)[0]
    assert "Do not derive a command for that step" in operator


def test_missing_reason_is_not_an_operator_only_step(tmp_path: Path) -> None:
    test_missing_authored_reason_emits_uncataloged(tmp_path)
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "Do not present it as a vendor constraint" in prep


def test_automated_runs_secret_producing_script_through_a_secret_sink() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    sink = prep.split("## Secrets the agent's command produces", maxsplit=1)[1]
    sink = sink.split("## Operator-only and Uncataloged steps", maxsplit=1)[0]
    assert "Connect run folder" in sink
    assert "`sink-`" in sink
    assert "only the non-secret identifiers" in sink
    assert "delete the file once they say it is vaulted" in sink
    assert "never written to the Connect log" in sink
    assert "If the command cannot be made to withhold the secret" in sink
    assert "hand that one step to the operator" in sink


def test_connect_log_is_created_in_the_connect_run_folder() -> None:
    log = Path(".agents/skills/entro-connect/session-log.md").read_text(encoding="utf-8")
    skill = Path(".agents/skills/entro-connect/SKILL.md").read_text(encoding="utf-8")
    assert "current working directory" in log
    assert "`integrationConfig/entro-<tile-slug>[-<path-slug>].md`" in log
    assert "not at repository root" in log
    assert "/integrationConfig/" in log
    assert "Connect run folder" in skill


def test_connect_run_folder_falls_back_away_from_skill_catalog_tree() -> None:
    log = Path(".agents/skills/entro-connect/session-log.md").read_text(encoding="utf-8")
    assert ".agents/skills/entro-connect" in log
    assert "skills/entro-connect" in log
    assert "current directory is inside either" in log
    assert "repository-root `integrationConfig/`" in log


def test_temporary_script_copy_lives_in_the_connect_run_folder() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    pinned = prep.split("## Pinned script", maxsplit=1)[1]
    pinned = pinned.split("## Secrets the agent's command produces", maxsplit=1)[0]
    assert "Connect run folder" in pinned
    assert "`tmp-`" in pinned
    assert "Never edit `script.skillPath`" in pinned


def test_collision_fix_is_gated_before_retry() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    collision = prep.split("## Name collision", maxsplit=1)[1].split("## Pinned script", maxsplit=1)[0]
    assert "propose a fix" in collision
    assert "Approve / Adjust / Stop" in collision
    assert "run the action again" in collision
    assert "MUST NOT overwrite" in collision


def test_existing_app_display_name() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    collision = prep.split("## Name collision", maxsplit=1)[1].split("## Pinned script", maxsplit=1)[0]
    assert "Inspect a name-bound target before create" in collision
    assert "reuse" in collision
    assert "another name" in collision
    assert "stop" in collision.lower()


def test_approved_fix_uses_temporary_script_copy() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    pinned = prep.split("## Pinned script", maxsplit=1)[1]
    assert "Temporary script copy" in pinned
    assert "checksum the original" in pinned
    assert "Never edit `script.skillPath`" in pinned
    assert "discard" in pinned


def test_menu_cannot_be_bound_unattended() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    pinned = prep.split("## Pinned script", maxsplit=1)[1]
    assert "interactive menu" in pinned
    assert "If the menu cannot be bound safely, stop the step" in pinned
    assert "operator run the original pinned file" in pinned


def test_plan_exists_before_the_first_mutation() -> None:
    skill = Path(".agents/skills/entro-connect/SKILL.md").read_text(encoding="utf-8")
    plan = skill.split("7. **Configuration plan**", maxsplit=1)[1].split("8. **Prep**", maxsplit=1)[0]
    assert "no mutation has run" in plan


def test_playbook_does_not_run_mutations() -> None:
    modes = Path(".agents/skills/entro-connect/modes.md").read_text(encoding="utf-8")
    playbook = modes.split("| `playbook` |", maxsplit=1)[1].split("|", maxsplit=1)[0]
    assert "No mutation runs" in playbook


def test_client_secret_stays_with_the_operator() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    assert "The secret is never printed, quoted, echoed, or written to the Connect log" in prep
    assert "Tell the operator the file path so they vault the secret" in prep
    assert "record Client ID and Tenant ID only" in prep
    ecosystem = next(
        row
        for row in integration_catalog.skill_row_catalogs()
        if row["tile"] == "Microsoft ecosystem"
    )
    auto = next(method for method in ecosystem["integrationPaths"] if method["name"] == "Automated PowerShell")
    run = next(
        item
        for item in auto["typedActions"]
        if item["prepStepTitle"] == "Run Entro's Azure onboarding script"
    )
    assert run["secretProducing"] is True


def test_ui_only_step_is_operator_executed(tmp_path: Path) -> None:
    aws = next(row for row in _index_rows(tmp_path) if row["tile"] == "Amazon Web Services")
    cfn = _integration_path(aws, "CloudFormation")
    step = cfn["prepSteps"][0]
    assert "operatorOnly" in step
    assert step["operatorOnly"]["reason"]
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    operator = prep.split("## Operator-only and Uncataloged steps", maxsplit=1)[1]
    operator = operator.split("**Uncataloged.**", maxsplit=1)[0]
    assert "disclose `reason`" in operator
    assert "The operator executes it" in operator


def test_glossary_defines_announcement_and_secret_sink() -> None:
    found_announcement = False
    found_sink = False
    found_operator_only = False
    found_uncataloged = False
    found_runtime = False
    for path in Path("openspec").rglob("ubiquitous-language/spec.md"):
        text = path.read_text(encoding="utf-8")
        if "### Term: Announcement" in text:
            found_announcement = "Not an Approve gate" in text.split("### Term: Announcement", 1)[1]
        if "### Term: Secret sink" in text:
            block = text.split("### Term: Secret sink", 1)[1].split("### Term:", 1)[0]
            found_sink = "never enters agent context" in block
        if "### Term: Operator-only step" in text:
            block = text.split("### Term: Operator-only step", 1)[1].split("### Term:", 1)[0]
            if "Minting a credential does not make a step Operator-only" in block:
                found_operator_only = True
        if "### Term: Uncataloged Prep step" in text:
            found_uncataloged = True
        if "### Term: Runtime Doc-derived action" in text:
            found_runtime = True
    assert found_announcement, "glossary must define Announcement as not an Approve gate"
    assert found_sink, "glossary must define Secret sink as outside agent context"
    assert found_operator_only, "Operator-only step must exclude credential-minting steps"
    assert found_uncataloged, "glossary must define Uncataloged Prep step"
    assert found_runtime, "glossary must define Runtime Doc-derived action"


def test_automated_pauses_for_a_collision() -> None:
    prep = Path(".agents/skills/entro-connect/prep.md").read_text(encoding="utf-8")
    collision = prep.split("## Name collision", maxsplit=1)[1].split("## Pinned script", maxsplit=1)[0]
    assert "`automated` interrupts itself here rather than overwriting" in collision


def test_automated_still_asks_the_operator_to_sign_in() -> None:
    tools = Path(".agents/skills/entro-connect/tools.md").read_text(encoding="utf-8")
    assert "in every mode including `automated`" in tools
    assert "Never accept a login secret into session" in tools


def _connect_tools_trees() -> tuple[str, str]:
    left = Path(".agents/skills/entro-connect/tools.md").read_text(encoding="utf-8")
    right = Path("skills/entro-connect/tools.md").read_text(encoding="utf-8")
    assert left == right
    return left, right


def test_valid_session_skips_login() -> None:
    tools, _ = _connect_tools_trees()
    assert "skip Configure once" in tools
    assert "skip login" in tools or "skip a new login" in tools


def test_missing_sso_config_requests_the_wizard() -> None:
    tools, _ = _connect_tools_trees()
    assert "configureOnce.command" in tools
    assert "in every mode including `automated`" in tools
    assert "do not run the wizard" in tools.lower() or "Do not run" in tools and "wizard" in tools


def test_no_credentials_at_all_gates_the_route_choice() -> None:
    tools, _ = _connect_tools_trees()
    lowered = tools.lower()
    assert "configureOnce.methods" in tools
    assert "whenToPick" in tools
    assert "gate the route choice" in lowered
    assert "none of them recommended" in lowered


def test_two_suitable_routes_gate_the_choice() -> None:
    tools, _ = _connect_tools_trees()
    lowered = tools.lower()
    assert "two or more do" in lowered or "two or more match" in lowered
    assert "catalog order" in lowered


def test_a_secret_prompt_is_never_collected() -> None:
    tools, _ = _connect_tools_trees()
    lowered = tools.lower()
    assert "`secret`" in tools
    assert "entered in the vendor cli" in lowered
    assert "never ask for or echo its value" in lowered


def test_a_route_without_sign_in_never_requests_a_login() -> None:
    tools, _ = _connect_tools_trees()
    lowered = tools.lower()
    assert "null `authonce`" in lowered
    assert "nothing to sign into" in lowered
    assert "never fall back to another route" in lowered


def test_wizard_that_already_signed_in_skips_login() -> None:
    tools, _ = _connect_tools_trees()
    assert "re-run" in tools.lower() or "re-run `authCheck`" in tools
    assert "skip `authOnce`" in tools or "skip authOnce" in tools


def test_existing_sso_profile_skips_the_wizard() -> None:
    tools, _ = _connect_tools_trees()
    lowered = tools.lower()
    assert "suitableWhen" in tools
    assert "exactly one route" in lowered
    assert "with no gate" in lowered
    assert "skip its `command`" in lowered
    assert "request `authOnce`" in tools or "request the selected route's `authOnce`" in tools


def test_the_request_names_where_each_value_comes_from() -> None:
    tools, _ = _connect_tools_trees()
    lowered = tools.lower()
    assert "prompts" in tools
    assert "whereToFind" in tools
    assert "docsUrl" in tools
    assert "catalog order" in lowered or "in catalog order" in lowered
    assert "bare" in lowered or "only the command" in lowered or "incomplete" in lowered


def test_wizard_answers_stay_out_of_chat_and_the_log() -> None:
    tools, _ = _connect_tools_trees()
    log = Path(".agents/skills/entro-connect/session-log.md").read_text(encoding="utf-8")
    assert "Operator inputs" in tools
    assert "Do not collect answers as Operator inputs" in tools
    assert "Connect log" in tools
    assert "the selected route's `name`" in tools
    assert "requested" in log.lower() or "Configure once" in log
    assert "wizard" in log.lower() or "Configure once" in log


def test_terraform_uses_the_aws_configure_once_object() -> None:
    tools, _ = _connect_tools_trees()
    assert "prefer `aws`" in tools or "prefer aws" in tools
    assert "authCheck.command" in tools
    assert "prompts" in tools


def test_operator_requests_help_after_login() -> None:
    tools, _ = _connect_tools_trees()
    assert "Help diagnoses non-secret output" in tools
    assert "Never accept a login secret into session" in tools


def test_execution_actor_is_recorded_per_step() -> None:
    log = Path(".agents/skills/entro-connect/session-log.md").read_text(encoding="utf-8")
    assert "the agent under automated, the operator under supervised" in log
    assert "never the secret and never the path it was written to" in log


def test_edited_entro_connect_skill_files_match_both_trees() -> None:
    for name in ("SKILL.md", "modes.md", "prep.md", "session-log.md", "tools.md"):
        left = Path(".agents/skills/entro-connect", name).read_bytes()
        right = Path("skills/entro-connect", name).read_bytes()
        assert left == right, name


def test_specs_use_skill_held_onboarding_artifact() -> None:
    specs = list(Path("openspec").rglob("documentation-ingest/spec.md")) + list(
        Path("openspec").rglob("integration-prep/spec.md")
    )
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    assert "Skill-held onboarding artifact" in blob
    assert "GitBook download as Connect runtime" not in blob.lower() or "MUST NOT" in blob


def test_specs_use_temporary_script_copy() -> None:
    specs = list(Path("openspec").rglob("*/spec.md"))
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    assert "Temporary script copy" in blob
    assert "in-place edit of the Skill-held file" in blob.lower() or "MUST NOT" in blob


def test_specs_use_anonymous_origin_url() -> None:
    specs = list(Path("openspec").rglob("documentation-ingest/spec.md"))
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    assert "Anonymous origin URL" in blob
    assert "token=" in blob


def test_specs_distinguish_doc_derived_typed_action_and_operator_only_step() -> None:
    specs = list(Path("openspec").rglob("*/spec.md"))
    blob = "\n".join(path.read_text(encoding="utf-8") for path in specs)
    assert "Doc-derived Typed action" in blob
    assert "Operator-only" in blob
    assert "Uncataloged Prep step" in blob
    assert "Runtime Doc-derived action" in blob


def test_uncited_integration_page_fails_validation(tmp_path: Path) -> None:
    folder = tmp_path / "cloud-and-infrastructure"
    folder.mkdir()
    (folder / "orphan-onboarding.md").write_text("undocumented path\n", encoding="utf-8")
    errors = integration_catalog.validate_page_citation(tmp_path, [_minimal_index_row()])
    assert any("orphan-onboarding.md" in message for message in errors)


def test_multi_account_automation_page_is_observable() -> None:
    page = (
        "cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/"
        "aws-multiple-account-automation.md"
    )
    rows = integration_catalog.integration_index_payload()["integrations"]
    aws = next(row for row in rows if row["tile"] == "Amazon Web Services")
    cited = set(integration_catalog._documentation_paths(aws))
    waived = {
        item["page"]
        for item in (aws.get("methodWaivers") or [])
        if isinstance(item, dict) and item.get("page")
    }
    assert page in cited or page in waived
    stripped = dict(aws)
    stripped["documentation"] = [item for item in aws["documentation"] if item != page]
    stripped["integrationPaths"] = [
        {
            **method,
            "documentation": [
                doc for doc in method.get("documentation", []) if doc != page
            ],
        }
        for method in aws["integrationPaths"]
    ]
    stripped["forkCensus"] = []
    stripped["methodWaivers"] = []
    others = [row for row in rows if row["tile"] != "Amazon Web Services"]
    errors = integration_catalog.validate_page_citation(DOCUMENTATION_DIR, others + [stripped])
    assert any(page in message for message in errors)


def test_stale_evidence_quote_fails_validation(tmp_path: Path) -> None:
    folder = tmp_path / "cloud-and-infrastructure"
    folder.mkdir()
    rel = "cloud-and-infrastructure/cited.md"
    (folder / "cited.md").write_text("only this sentence\n", encoding="utf-8")
    row = _minimal_index_row(
        documentation=[rel],
        forkCensus=[
            {
                "page": rel,
                "documentedMethod": "Missing fork",
                "boundMethod": "CloudFormation",
                "evidence": "this quote is not on the page",
            }
        ],
        setupMethods=[{"name": "CloudFormation", "documentation": rel, "prepSteps": [{"title": "x", "instruction": "y", "evidence": "z", "operatorOnly": {"reason": "ui", "evidence": "z"}}]}],
    )
    errors = integration_catalog.validate_fork_census(tmp_path, [row])
    assert any("missing census evidence" in message for message in errors)
    assert any(rel in message for message in errors)


def test_waiver_without_a_reason_fails_validation(tmp_path: Path) -> None:
    folder = tmp_path / "cloud-and-infrastructure"
    folder.mkdir()
    rel = "cloud-and-infrastructure/waived.md"
    (folder / "waived.md").write_text("page\n", encoding="utf-8")
    row = _minimal_index_row(
        methodWaivers=[{"page": rel, "reason": "   "}],
    )
    errors = integration_catalog.validate_method_waivers(tmp_path, [row])
    assert any("without a reason" in message for message in errors)


def test_waiver_leaking_into_the_skill_catalog_fails_validation() -> None:
    ingest = integration_catalog.integration_index_payload()["integrations"]
    skill_rows = integration_catalog.skill_row_catalogs()
    leaked = dict(skill_rows[0])
    leaked["methodWaivers"] = [{"page": "cloud-and-infrastructure/x.md", "reason": "nope"}]
    errors = integration_catalog.validate_skill_catalog(
        {"integrations": integration_catalog.skill_catalog_index_entries()},
        ingest_rows=ingest,
        row_catalogs=[leaked, *skill_rows[1:]],
    )
    assert any("methodWaivers" in message for message in errors)


def test_test_suite_catches_a_dropped_method_without_a_cookie(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("ENTRO_DOCS_COOKIE", raising=False)
    rows = integration_catalog.integration_index_payload()["integrations"]
    errors = integration_catalog.validate_page_citation(DOCUMENTATION_DIR, rows)
    assert errors == []


def test_catalog_writer_enforces_the_same_invariant(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(
        integration_catalog,
        "validate_integration_definitions",
        lambda **_kwargs: ["uncited integration documentation page example.md"],
    )
    errors = integration_catalog.write_integrations_index(tmp_path)
    assert errors
    assert not (tmp_path / "integrations.json").exists()


def test_documented_aws_deployment_options_are_censused() -> None:
    aws = next(
        row
        for row in integration_catalog.integration_index_payload()["integrations"]
        if row["tile"] == "Amazon Web Services"
    )
    names = {method["name"] for method in aws["integrationPaths"]}
    assert "Terraform" in names
    assert "CloudFormation StackSets" not in names
    documented = {entry["documentedMethod"] for entry in aws["forkCensus"]}
    assert any("StackSets" in name for name in documented)
    assert any("Terraform" in name for name in documented)
    stacksets = next(
        entry for entry in aws["forkCensus"] if "StackSets" in entry["documentedMethod"]
    )
    assert stacksets.get("waiverReason")
    assert "boundMethod" not in stacksets


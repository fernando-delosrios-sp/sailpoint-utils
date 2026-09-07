"""Consolidate legacy Integration rows into one row per Entro Select Provider tile."""

from __future__ import annotations

from typing import TYPE_CHECKING, Literal

if TYPE_CHECKING:
    from integration_catalog import (
        CensusEntry,
        ConnectionField,
        Coverage,
        DocumentedMethod,
        LegacyIntegrationDefinition,
        MethodWaiver,
        OperatorInput,
        PrepStep,
        TypedAction,
    )

PathEvidence = Literal["ui-verified", "documentation-derived", "capture-required"]

# Exact Select Provider tile labels (2026-09-03 screenshot).
ALL_UI_TILES: tuple[str, ...] = (
    "Atlassian",
    "Amazon Web Services",
    "Microsoft ecosystem",
    "GitHub",
    "Google GCP",
    "HashiCorp Vault",
    "Bitbucket",
    "Slack",
    "Azure DevOps",
    "Okta",
    "GitLab",
    "Remote File System",
    "Akeyless Vault",
    "Buildkite",
    "Microsoft Teams",
    "SharePoint",
    "OneDrive",
    "Snowflake",
    "Google Workspace",
    "Wiz",
    "ServiceNow",
    "Salesforce",
    "Jenkins",
    "JFrog Artifactory",
    "CrowdStrike",
    "On-Prem Active Directory",
    "Oracle Cloud Infrastructure",
    "Azure Pipeline",
    "CircleCI",
    "DroneCI",
    "TeamCity",
    "TravisCI",
    "Octopus",
    "Tines",
    "Torq",
    "n8n",
    "SailPoint Identity Security Cloud (IdentityNow)",
    "CyberArk Conjur",
    "CyberArk",
    "Palo Alto Cortex XDR",
    "BeyondTrust Safe",
    "Datadog",
    "Delinea Secrets Vault",
    "Docker",
    "Elastic",
    "Hybrid Azure AD",
    "JupyterHub",
    "Kubernetes",
    "LastPass",
    "Monday",
    "MongoDB",
    "Notion",
    "1Password",
    "PagerDuty",
    "Splunk",
    "Terraform",
    "Workday",
    "Zendesk",
)

LEGACY_TILE_TO_UI: dict[str, str] = {
    "AWS": "Amazon Web Services",
    "Microsoft Ecosystem": "Microsoft ecosystem",
    "Google Cloud Platform": "Google GCP",
    "BitBucket": "Bitbucket",
    "File Shares Scanning": "Remote File System",
    "Akeyless": "Akeyless Vault",
    "Google Workspace (GDrive)": "Google Workspace",
    "Active Directory": "On-Prem Active Directory",
    "BuildKite": "Buildkite",
    "SailPoint ISC": "SailPoint Identity Security Cloud (IdentityNow)",
}

UI_VERIFIED_TILES: frozenset[str] = frozenset(
    {"Amazon Web Services", "Atlassian", "Microsoft ecosystem"}
)

# Legacy target_selection → UI Integration path name.
TARGET_TO_PATH: dict[str, str] = {
    "Jira Cloud": "Scoped API Token - Jira",
    "Confluence Cloud": "Scoped API Token - Confluence",
    "Jira Server": "Jira Server",
    "Confluence Server": "Confluence Server",
    "SMB": "SMB",
    "SFTP (SSH)": "SFTP (SSH)",
    "WinRM": "WinRM",
    "BitBucket Cloud": "BitBucket Cloud",
    "BitBucket Data Center": "BitBucket Data Center",
    "GitHub Cloud - New": "GitHub Cloud - New",
    "GitHub Cloud - Legacy": "GitHub Cloud - Legacy",
    "GitHub Enterprise Server": "GitHub Enterprise Server",
    "Slack Private App": "Slack Private App",
    "Slack Enterprise Grid App": "Slack Enterprise Grid App",
}

# Legacy setup method → UI Integration path name.
SETUP_TO_PATH: dict[tuple[str, str], str] = {
    ("Amazon Web Services", "Manual Assume Role"): "Assume Role",
}

# Optional capabilities moved off Microsoft ecosystem to standalone tiles.
MICROSOFT_ECOSYSTEM_DROP_COVERAGES: frozenset[str] = frozenset(
    {"SharePoint / OneDrive"}
)

# AWS optional capabilities from Entro connection form (Basic Monitoring is baseline).
AWS_OPTIONAL_CAPABILITIES: tuple[str, ...] = (
    "Vault management",
    "NHI Management",
)

# Map legacy row slug → new tile slug for Skill-held artifact migration.
LEGACY_SLUG_ALIASES: dict[str, str] = {
    "aws": "amazon-web-services",
    "microsoft-ecosystem": "microsoft-ecosystem",
    "google-cloud-platform": "google-gcp",
    "bitbucket-cloud": "bitbucket",
    "bitbucket-data-center": "bitbucket",
    "file-shares-scanning": "remote-file-system",
    "smb": "remote-file-system",
    "sftp-ssh": "remote-file-system",
    "winrm": "remote-file-system",
    "github-cloud-new": "github",
    "github-cloud-legacy": "github",
    "github-enterprise-server": "github",
    "jira-cloud": "atlassian",
    "confluence-cloud": "atlassian",
    "jira-server": "atlassian",
    "confluence-server": "atlassian",
    "slack-private-app": "slack",
    "slack-enterprise-grid-app": "slack",
    "akeyless": "akeyless-vault",
    "google-workspace-gdrive": "google-workspace",
    "active-directory": "on-prem-active-directory",
    "buildkite": "buildkite",
    "sailpoint-isc": "sailpoint-identity-security-cloud-identitynow",
}


def ui_tile_for_legacy(defn: LegacyIntegrationDefinition) -> str:
    return LEGACY_TILE_TO_UI.get(defn.tile, defn.tile)


def path_evidence_for_tile(ui_tile: str, *, capture_required: bool) -> PathEvidence:
    if capture_required:
        return "capture-required"
    if ui_tile in UI_VERIFIED_TILES:
        return "ui-verified"
    return "documentation-derived"


def _path_name(defn: LegacyIntegrationDefinition) -> str | None:
    if defn.target_selection:
        return TARGET_TO_PATH.get(defn.target_selection, defn.target_selection)
    return None


def _setup_path_name(defn: LegacyIntegrationDefinition, setup_name: str) -> str:
    return SETUP_TO_PATH.get((ui_tile_for_legacy(defn), setup_name), setup_name)


def _merge_documentation(
    existing: tuple[str, ...], extra: tuple[str, ...]
) -> tuple[str, ...]:
    seen: set[str] = set()
    merged: list[str] = []
    for page in (*existing, *extra):
        if page not in seen:
            seen.add(page)
            merged.append(page)
    return tuple(merged)


def _legacy_method_to_path(
    defn: LegacyIntegrationDefinition,
    *,
    name: str,
    method: DocumentedMethod | None = None,
    path_evidence: PathEvidence,
    implicit: bool = False,
) -> IntegrationPath:
    from integration_catalog import IntegrationPath

    hosting = defn.hosting
    connection_fields = defn.connection_fields
    prep_steps = defn.prep_steps
    operator_inputs = defn.operator_inputs
    typed_actions = defn.typed_actions
    configuration_tools = defn.configuration_tools
    documentation: tuple[str, ...] = defn.documentation

    if method is not None:
        if method.connection_fields:
            connection_fields = method.connection_fields
        if method.prep_steps:
            prep_steps = method.prep_steps
        if method.operator_inputs:
            operator_inputs = method.operator_inputs
        if method.typed_actions:
            typed_actions = method.typed_actions
        documentation = _merge_documentation(documentation, (method.documentation,))

    return IntegrationPath(
        name=name,
        documentation=documentation,
        path_evidence=path_evidence,
        implicit=implicit,
        hosting=hosting,
        configuration_tools=configuration_tools,
        connection_fields=connection_fields,
        prep_steps=prep_steps,
        operator_inputs=operator_inputs,
        typed_actions=typed_actions,
    )


def paths_from_legacy(defn: LegacyIntegrationDefinition, path_evidence: PathEvidence) -> list:
    from integration_catalog import IntegrationPath

    paths: list[IntegrationPath] = []
    target_name = _path_name(defn)

    if target_name:
        prep_steps = defn.prep_steps
        operator_inputs = defn.operator_inputs
        typed_actions = defn.typed_actions
        if defn.setup_methods:
            for setup in defn.setup_methods:
                prep_steps += setup.prep_steps
                operator_inputs += setup.operator_inputs
                typed_actions += setup.typed_actions
        paths.append(
            IntegrationPath(
                name=target_name,
                documentation=defn.documentation,
                path_evidence=path_evidence,
                hosting=defn.hosting,
                configuration_tools=defn.configuration_tools,
                connection_fields=defn.connection_fields,
                prep_steps=prep_steps,
                operator_inputs=operator_inputs,
                typed_actions=typed_actions,
            )
        )
        return paths

    if defn.setup_methods and defn.authentication_methods:
        for setup in defn.setup_methods:
            for auth in defn.authentication_methods:
                combined = f"{setup.name} — {auth.name}"
                prep_steps = setup.prep_steps + auth.prep_steps
                operator_inputs = (
                    defn.operator_inputs + setup.operator_inputs + auth.operator_inputs
                )
                typed_actions = setup.typed_actions or auth.typed_actions
                connection_fields = (
                    auth.connection_fields
                    if auth.connection_fields
                    else defn.connection_fields
                )
                paths.append(
                    IntegrationPath(
                        name=combined,
                        documentation=_merge_documentation(
                            defn.documentation,
                            (setup.documentation, auth.documentation),
                        ),
                        path_evidence=path_evidence,
                        hosting=defn.hosting,
                        configuration_tools=defn.configuration_tools,
                        connection_fields=connection_fields,
                        prep_steps=prep_steps,
                        operator_inputs=operator_inputs,
                        typed_actions=typed_actions,
                    )
                )
        return paths

    if defn.setup_methods:
        for setup in defn.setup_methods:
            paths.append(
                _legacy_method_to_path(
                    defn,
                    name=_setup_path_name(defn, setup.name),
                    method=setup,
                    path_evidence=path_evidence,
                )
            )
        return paths

    if defn.authentication_methods:
        for auth in defn.authentication_methods:
            paths.append(
                _legacy_method_to_path(
                    defn, name=auth.name, method=auth, path_evidence=path_evidence
                )
            )
        return paths

    paths.append(
        _legacy_method_to_path(
            defn,
            name=ui_tile_for_legacy(defn),
            path_evidence=path_evidence,
            implicit=True,
        )
    )
    return paths


def optional_capabilities_from_legacy(
    defn: LegacyIntegrationDefinition,
    *,
    ui_tile: str,
) -> list:
    from integration_catalog import OptionalCapability

    capabilities: list[OptionalCapability] = []
    for coverage in defn.coverages:
        if (
            ui_tile == "Microsoft ecosystem"
            and coverage.name in MICROSOFT_ECOSYSTEM_DROP_COVERAGES
        ):
            continue
        capabilities.append(
            OptionalCapability(
                name=coverage.name,
                documentation=coverage.documentation,
                configuration_tools=coverage.configuration_tools,
                prep_steps=coverage.prep_steps,
                typed_actions=coverage.typed_actions,
                operator_inputs=coverage.operator_inputs,
            )
        )

    if ui_tile == "Amazon Web Services":
        existing = {cap.name for cap in capabilities}
        for name in AWS_OPTIONAL_CAPABILITIES:
            if name not in existing:
                capabilities.append(
                    OptionalCapability(
                        name=name,
                        documentation=(),
                        configuration_tools=(),
                    )
                )
        cloudtrail = next(
            (cap for cap in capabilities if cap.name == "CloudTrail S3"), None
        )
        if cloudtrail is not None:
            capabilities = [cap for cap in capabilities if cap.name != "CloudTrail S3"]
            capabilities.insert(
                0,
                OptionalCapability(
                    name="CloudTrail S3",
                    documentation=cloudtrail.documentation,
                    configuration_tools=cloudtrail.configuration_tools,
                    prep_steps=cloudtrail.prep_steps,
                    typed_actions=cloudtrail.typed_actions,
                    operator_inputs=cloudtrail.operator_inputs,
                ),
            )
    return capabilities


def _merge_optional_capabilities(capabilities: list) -> list:
    from integration_catalog import OptionalCapability

    by_name: dict[str, OptionalCapability] = {}
    for capability in capabilities:
        if capability.name in by_name:
            existing = by_name[capability.name]
            by_name[capability.name] = OptionalCapability(
                name=capability.name,
                documentation=_merge_documentation(
                    existing.documentation, capability.documentation
                ),
                configuration_tools=capability.configuration_tools
                or existing.configuration_tools,
                prep_steps=capability.prep_steps or existing.prep_steps,
                typed_actions=capability.typed_actions or existing.typed_actions,
                operator_inputs=capability.operator_inputs or existing.operator_inputs,
            )
        else:
            by_name[capability.name] = capability
    return list(by_name.values())


def _rebind_fork_census(
    census: tuple[CensusEntry, ...],
    path_names: list[str],
) -> tuple[CensusEntry, ...]:
    from integration_catalog import CensusEntry

    rebound: list[CensusEntry] = []
    for entry in census:
        bound = entry.bound_method
        if bound and bound not in path_names:
            matches = [name for name in path_names if name.startswith(f"{bound} —")]
            if len(matches) == 1:
                bound = matches[0]
            elif bound in {"Manual Onboarding", "JSON Upload"} and "SMB" in path_names:
                bound = "SMB"
        rebound.append(
            CensusEntry(
                page=entry.page,
                documented_method=entry.documented_method,
                evidence=entry.evidence,
                bound_method=bound,
                waiver_reason=entry.waiver_reason,
            )
        )
    return tuple(rebound)


def _merge_paths(paths: list) -> list:
    from integration_catalog import IntegrationPath

    by_name: dict[str, IntegrationPath] = {}
    for path in paths:
        if path.name in by_name:
            existing = by_name[path.name]
            by_name[path.name] = IntegrationPath(
                name=path.name,
                documentation=_merge_documentation(
                    existing.documentation, path.documentation
                ),
                path_evidence=path.path_evidence,
                implicit=path.implicit,
                hosting=path.hosting,
                configuration_tools=path.configuration_tools or existing.configuration_tools,
                connection_fields=path.connection_fields or existing.connection_fields,
                prep_steps=path.prep_steps or existing.prep_steps,
                operator_inputs=path.operator_inputs or existing.operator_inputs,
                typed_actions=path.typed_actions or existing.typed_actions,
            )
        else:
            by_name[path.name] = path
    return list(by_name.values())


def _stub_tile(name: str) -> IntegrationDefinition:
    from integration_catalog import IntegrationDefinition, MethodWaiver, _none

    waivers: tuple[MethodWaiver, ...] = ()
    if name == "SharePoint":
        waivers = (
            MethodWaiver(
                page="collaboration-and-saas/sharepoint.md",
                reason="Standalone SharePoint tile; pages await connection-form capture.",
            ),
            MethodWaiver(
                page="collaboration-and-saas/sharepoint/sharepoint-permissions-reference.md",
                reason="Standalone SharePoint tile; pages await connection-form capture.",
            ),
            MethodWaiver(
                page="collaboration-and-saas/sharepoint/sharepoint-troubleshooting-and-validation.md",
                reason="Standalone SharePoint tile; pages await connection-form capture.",
            ),
        )
    return IntegrationDefinition(
        tile=name,
        category="uncaptured",
        documentation=(),
        integration_paths=(),
        optional_capabilities=(),
        configuration_tools=(_none(),),
        hosting="public",
        summary=f"Connect {name} — connection form not yet captured for Connect catalog.",
        connection_fields=(),
        capture_required=True,
        path_evidence="capture-required",
        method_waivers=waivers,
    )


def _add_atlassian_classic_path(paths: list, path_evidence: PathEvidence) -> list:
    from integration_catalog import IntegrationPath

    if any(path.name == "Classic API Token" for path in paths):
        return paths
    paths.append(
        IntegrationPath(
            name="Classic API Token",
            documentation=(
                "collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding/"
                "legacy-atlassian-jira-and-confluence-cloud.md",
            ),
            path_evidence=path_evidence,
            hosting="public",
            configuration_tools=(),
            connection_fields=(),
            prep_steps=(),
        )
    )
    return paths


def consolidate_tile_catalog(
    legacy: tuple[LegacyIntegrationDefinition, ...],
) -> tuple[IntegrationDefinition, ...]:
    from integration_catalog import IntegrationDefinition

    grouped: dict[str, list[LegacyIntegrationDefinition]] = {}
    for defn in legacy:
        ui_tile = ui_tile_for_legacy(defn)
        grouped.setdefault(ui_tile, []).append(defn)

    consolidated: list[IntegrationDefinition] = []
    for ui_tile in ALL_UI_TILES:
        if ui_tile in grouped:
            rows = grouped[ui_tile]
            path_evidence = path_evidence_for_tile(ui_tile, capture_required=False)
            all_paths: list = []
            all_optional: list = []
            all_waivers: list[MethodWaiver] = []
            all_census: list[CensusEntry] = []
            documentation: tuple[str, ...] = ()
            category = rows[0].category
            hosting = rows[0].hosting
            summary = rows[0].summary
            configuration_tools = rows[0].configuration_tools

            for row in rows:
                all_paths.extend(paths_from_legacy(row, path_evidence))
                all_optional.extend(
                    optional_capabilities_from_legacy(row, ui_tile=ui_tile)
                )
                all_waivers.extend(row.method_waivers)
                all_census.extend(row.fork_census)
                documentation = _merge_documentation(documentation, row.documentation)
                if len(rows) == 1:
                    summary = row.summary

            all_paths = _merge_paths(all_paths)
            if ui_tile == "Atlassian":
                all_paths = _add_atlassian_classic_path(all_paths, path_evidence)

            all_optional = _merge_optional_capabilities(all_optional)
            path_names = [path.name for path in all_paths]
            rebound_census: list[CensusEntry] = []
            for row in rows:
                rebound_census.extend(_rebind_fork_census(row.fork_census, path_names))

            if ui_tile == "Microsoft ecosystem" and len(rows) == 1:
                summary = rows[0].summary

            if ui_tile == "Amazon Web Services" and len(rows) == 1:
                summary = rows[0].summary

            consolidated.append(
                IntegrationDefinition(
                    tile=ui_tile,
                    category=category,
                    documentation=documentation,
                    integration_paths=tuple(all_paths),
                    optional_capabilities=tuple(all_optional),
                    configuration_tools=configuration_tools,
                    hosting=hosting,
                    summary=summary,
                    connection_fields=rows[0].connection_fields,
                    method_waivers=tuple(all_waivers),
                    fork_census=tuple(rebound_census),
                    capture_required=False,
                    path_evidence=path_evidence,
                )
            )
        else:
            consolidated.append(_stub_tile(ui_tile))

    return tuple(consolidated)

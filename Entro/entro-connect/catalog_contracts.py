"""Operator inputs, Typed actions, and tool probes for the Integration index."""

from __future__ import annotations

import re
from dataclasses import dataclass

RETRIEVED = "2026-08-31"

INDEX_ENTRY_KEYS = (
    "tile",
    "summary",
    "integrationPathNames",
    "optionalCapabilityNames",
    "catalogPath",
    "captureRequired",
)
INDEX_FORBIDDEN_KEYS = frozenset(
    {
        "prepSteps",
        "typedActions",
        "connectionFields",
        "toolInstall",
        "methodWaivers",
        "forkCensus",
    }
)
INTEGRATION_DOCUMENTATION_FOLDERS = (
    "cloud-and-infrastructure",
    "collaboration-and-saas",
    "code-and-ci-cd",
    "ai-and-agents",
    "security-and-identity",
    "container-registries",
    "gemini-instructions",
)
INTEGRATIONS_DIR = "integrations"
ROW_CATALOG_NAME = "catalog.json"
TOOL_INSTALL_FILE = "tool-install.json"
TOOL_INSTALL_OBJECT_KEYS = (
    "authOnce",
    "credentialBoundary",
    "docsUrl",
    "presenceCheck",
    "capabilityProbe",
    "authCheck",
    "platformIdentity",
    "install",
)
AUTH_ROUTE_KEYS = (
    "name",
    "whenToPick",
    "command",
    "check",
    "suitableWhen",
    "prompts",
    "credentialBoundary",
    "docsUrl",
    "sourceUrl",
    "retrievedAt",
)
AWS_SSO_PROFILE_DOCS = (
    "https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html"
)
AWS_IAM_IDC_AUTH_DOCS = AWS_SSO_PROFILE_DOCS
AWS_ACCESS_KEY_DOCS = (
    "https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-user.html"
)
AWS_CONFIGURE_ONCE_RETRIEVED = "2026-09-03"


def kebab_identity(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.casefold()).strip("-")


def row_slug(tile: str, target_selection: str | None = None) -> str:
    del target_selection
    return kebab_identity(tile)


def catalog_path_for(tile: str, target_selection: str | None = None) -> str:
    del target_selection
    return f"{INTEGRATIONS_DIR}/{row_slug(tile)}/{ROW_CATALOG_NAME}"


def skill_held_path(tile: str, target_selection: str | None, filename: str) -> str:
    del target_selection
    return f"{INTEGRATIONS_DIR}/{row_slug(tile)}/{filename}"

NAMING_FIELD_NAMES = frozenset(
    {
        "environment",
        "environment nickname",
        "environment type",
        "display name",
        "nickname",
        "company nickname",
    }
)

ACTION_FIELDS = (
    "prepStepTitle",
    "preview",
    "mutation",
    "target",
    "expectedChange",
    "verification",
    "rollbackOrImpact",
    "secretProducing",
    "sourceUrl",
    "retrievedAt",
)


@dataclass(frozen=True)
class MethodWaiver:
    page: str
    reason: str


@dataclass(frozen=True)
class CensusEntry:
    page: str
    documented_method: str
    evidence: str
    bound_method: str | None = None
    waiver_reason: str | None = None


def method_waiver_to_dict(item: MethodWaiver) -> dict[str, object]:
    return {"page": item.page, "reason": item.reason}


def census_entry_to_dict(item: CensusEntry) -> dict[str, object]:
    payload: dict[str, object] = {
        "page": item.page,
        "documentedMethod": item.documented_method,
        "evidence": item.evidence,
    }
    if item.bound_method:
        payload["boundMethod"] = item.bound_method
    if item.waiver_reason:
        payload["waiverReason"] = item.waiver_reason
    return payload


@dataclass(frozen=True)
class CatalogCheck:
    command: str
    source_url: str
    retrieved_at: str = RETRIEVED
    suitable_when: str | None = None
    min_version: str | None = None


@dataclass(frozen=True)
class ConfigureOncePrompt:
    prompt: str
    where_to_find: str
    secret: bool = False


@dataclass(frozen=True)
class AuthenticationRoute:
    """One way to get a Configuration tool authenticated.

    ``auth_once`` is None when the route has no sign-in step — access keys do
    not expire, so there is nothing to run after the configure command.
    """

    name: str
    when_to_pick: str
    command: str
    check: CatalogCheck
    suitable_when: str
    prompts: tuple[ConfigureOncePrompt, ...]
    credential_boundary: str
    docs_url: str
    source_url: str
    auth_once: str | None = None
    retrieved_at: str = RETRIEVED


@dataclass(frozen=True)
class ConfigureOnce:
    methods: tuple[AuthenticationRoute, ...]


AWS_IDC_PROMPTS = (
    ConfigureOncePrompt(
        "SSO session name (Recommended)",
        "Operator-chosen name for this IAM Identity Center session in the AWS config file.",
    ),
    ConfigureOncePrompt(
        "SSO start URL",
        "AWS access portal → permission set → Access keys → IAM Identity Center credentials "
        "(Start URL). On AWS CLI 2.22.0+, the Issuer URL from the IAM Identity Center console "
        "Dashboard or Settings is an alternative.",
    ),
    ConfigureOncePrompt(
        "SSO region",
        "Same AWS access portal path as the start URL (IAM Identity Center credentials). "
        "The AWS Region that hosts the IAM Identity Center directory.",
    ),
    ConfigureOncePrompt(
        "SSO registration scopes",
        "Press Enter to accept the default sso:account:access unless an administrator named "
        "other OAuth scopes.",
    ),
    ConfigureOncePrompt(
        "AWS account",
        "The target AWS account Entro will scan; pick an account whose permission set can "
        "create the Entro role.",
    ),
    ConfigureOncePrompt(
        "IAM role",
        "A permission set in that account that can create the Entro integration role.",
    ),
    ConfigureOncePrompt(
        "Default client Region",
        "Operator choice: the default AWS Region this CLI profile sends commands to.",
    ),
    ConfigureOncePrompt(
        "CLI default output format",
        "Operator choice: typically json if unspecified.",
    ),
    ConfigureOncePrompt(
        "Profile name",
        "Operator choice: the name this profile is stored under; default makes it the "
        "default profile.",
    ),
)

AWS_ACCESS_KEY_PROMPTS = (
    ConfigureOncePrompt(
        "AWS Access Key ID",
        "IAM console → Users → your user → Security credentials → Access keys → Create "
        "access key, or the credentials CSV downloaded when that key was created. "
        "aws configure import --csv loads the same CSV without retyping.",
    ),
    ConfigureOncePrompt(
        "AWS Secret Access Key",
        "Shown once when the access key is created, and in that same credentials CSV. "
        "Type it straight into the prompt.",
        secret=True,
    ),
    ConfigureOncePrompt(
        "Default region name",
        "Operator choice: the default AWS Region this profile sends commands to.",
    ),
    ConfigureOncePrompt(
        "Default output format",
        "Operator choice: typically json if unspecified.",
    ),
)


@dataclass(frozen=True)
class PlatformIdentityQuery:
    command: str
    principal: str
    endpoint: str
    scope: str
    source_url: str
    retrieved_at: str = RETRIEVED


@dataclass(frozen=True)
class OperatorInput:
    key: str
    prompt: str
    purpose: str
    validation: str
    binds_to: str | None = None
    default: str | None = None
    secret: bool = False


@dataclass(frozen=True)
class PinnedScript:
    """Skill-held onboarding artifact pin.

    ``checksum`` is SHA-256 of the Skill-held bytes Connect runs. A Local
    onboarding fork also sets ``local_fork`` and ``origin_checksum`` (SHA-256 of
    the last recorded anonymous origin GET). Unforked pins omit both extras.
    """

    skill_path: str
    version: str
    checksum: str
    origin_url: str | None = None
    capture_source: str | None = None
    local_fork: bool = False
    origin_checksum: str | None = None


@dataclass(frozen=True)
class TypedAction:
    prep_step_title: str
    preview: str
    mutation: str
    target: str
    expected_change: str
    verification: str
    rollback_or_impact: str
    source_url: str
    secret_producing: bool = False
    retrieved_at: str = RETRIEVED
    script: PinnedScript | None = None


def _check(
    command: str,
    source_url: str,
    *,
    suitable_when: str | None = None,
    min_version: str | None = None,
    retrieved_at: str = RETRIEVED,
) -> CatalogCheck:
    return CatalogCheck(
        command=command,
        source_url=source_url,
        suitable_when=suitable_when,
        min_version=min_version,
        retrieved_at=retrieved_at,
    )


def _identity(
    command: str,
    principal: str,
    endpoint: str,
    scope: str,
    source_url: str,
    retrieved_at: str = RETRIEVED,
) -> PlatformIdentityQuery:
    return PlatformIdentityQuery(
        command=command,
        principal=principal,
        endpoint=endpoint,
        scope=scope,
        source_url=source_url,
        retrieved_at=retrieved_at,
    )


def _input(
    key: str,
    prompt: str,
    purpose: str,
    validation: str,
    binds_to: str | None = None,
    default: str | None = None,
) -> OperatorInput:
    return OperatorInput(
        key=key,
        prompt=prompt,
        purpose=purpose,
        validation=validation,
        binds_to=binds_to,
        default=default,
        secret=False,
    )


def _action(
    title: str,
    preview: str,
    mutation: str,
    target: str,
    expected: str,
    verification: str,
    rollback: str,
    source_url: str,
    *,
    secret_producing: bool = False,
    script: PinnedScript | None = None,
) -> TypedAction:
    return TypedAction(
        prep_step_title=title,
        preview=preview,
        mutation=mutation,
        target=target,
        expected_change=expected,
        verification=verification,
        rollback_or_impact=rollback,
        source_url=source_url,
        secret_producing=secret_producing,
        script=script,
    )


def check_to_dict(check: CatalogCheck) -> dict[str, object]:
    payload: dict[str, object] = {
        "command": check.command,
        "sourceUrl": check.source_url,
        "retrievedAt": check.retrieved_at,
    }
    if check.suitable_when:
        payload["suitableWhen"] = check.suitable_when
    if check.min_version:
        payload["minVersion"] = check.min_version
    return payload


def configure_once_prompt_to_dict(item: ConfigureOncePrompt) -> dict[str, object]:
    payload: dict[str, object] = {"prompt": item.prompt, "whereToFind": item.where_to_find}
    if item.secret:
        payload["secret"] = True
    return payload


def auth_route_to_dict(route: AuthenticationRoute) -> dict[str, object]:
    return {
        "name": route.name,
        "whenToPick": route.when_to_pick,
        "command": route.command,
        "check": check_to_dict(route.check),
        "suitableWhen": route.suitable_when,
        "prompts": [configure_once_prompt_to_dict(entry) for entry in route.prompts],
        "authOnce": route.auth_once,
        "credentialBoundary": route.credential_boundary,
        "docsUrl": route.docs_url,
        "sourceUrl": route.source_url,
        "retrievedAt": route.retrieved_at,
    }


def configure_once_to_dict(item: ConfigureOnce) -> dict[str, object]:
    return {"methods": [auth_route_to_dict(route) for route in item.methods]}


def identity_to_dict(query: PlatformIdentityQuery) -> dict[str, object]:
    return {
        "command": query.command,
        "principal": query.principal,
        "endpoint": query.endpoint,
        "scope": query.scope,
        "sourceUrl": query.source_url,
        "retrievedAt": query.retrieved_at,
    }


def input_to_dict(item: OperatorInput) -> dict[str, object]:
    payload: dict[str, object] = {
        "key": item.key,
        "prompt": item.prompt,
        "purpose": item.purpose,
        "validation": item.validation,
        "secret": item.secret,
    }
    if item.binds_to:
        payload["bindsTo"] = item.binds_to
    if item.default is not None:
        payload["default"] = item.default
    return payload


def action_to_dict(action: TypedAction) -> dict[str, object]:
    payload: dict[str, object] = {
        "prepStepTitle": action.prep_step_title,
        "preview": action.preview,
        "mutation": action.mutation,
        "target": action.target,
        "expectedChange": action.expected_change,
        "verification": action.verification,
        "rollbackOrImpact": action.rollback_or_impact,
        "secretProducing": action.secret_producing,
        "sourceUrl": action.source_url,
        "retrievedAt": action.retrieved_at,
    }
    if action.script is not None:
        script: dict[str, object] = {
            "skillPath": action.script.skill_path,
            "version": action.script.version,
            "checksum": action.script.checksum,
        }
        if action.script.origin_url:
            script["originUrl"] = action.script.origin_url
        if action.script.capture_source:
            script["captureSource"] = action.script.capture_source
        if action.script.local_fork:
            script["localFork"] = True
        if action.script.origin_checksum:
            script["originChecksum"] = action.script.origin_checksum
        payload["script"] = script
    return payload


def inputs_to_list(items: tuple[OperatorInput, ...]) -> list[dict[str, object]]:
    return [input_to_dict(item) for item in items]


def actions_to_list(items: tuple[TypedAction, ...]) -> list[dict[str, object]]:
    return [action_to_dict(item) for item in items]


MS_LEARN_AZ_INSTALL = "https://learn.microsoft.com/cli/azure/install-azure-cli"
MS_LEARN_AZ_ACCOUNT = "https://learn.microsoft.com/cli/azure/account"
MS_LEARN_PWSH = "https://learn.microsoft.com/powershell/module/az.accounts/get-azcontext"
PAC_CLI_DOCS = "https://learn.microsoft.com/power-platform/developer/cli/introduction"
PAC_CLI_NET_TOOL = "https://learn.microsoft.com/power-platform/developer/howto/install-cli-net-tool"
PAC_CLI_AUTH = "https://learn.microsoft.com/power-platform/developer/cli/reference/auth"
PAC_RETRIEVED = "2026-09-02"
AWS_STS = "https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html"
GCLOUD_AUTH = "https://cloud.google.com/sdk/gcloud/reference/auth/list"
GH_AUTH = "https://cli.github.com/manual/gh_auth_status"
GLAB_AUTH = "https://gitlab.com/gitlab-org/cli"
VAULT_TOKEN = "https://developer.hashicorp.com/vault/docs/commands/token/lookup"
OCI_SESSION = "https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm"
JF_CLI = "https://jfrog.com/help/r/jfrog-cli/getting-started-with-the-jfrog-cli"
SF_ORG = "https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_org_commands_unified.htm"
SNOW_CONN = "https://docs.snowflake.com/en/developer-guide/snowflake-cli/connecting/configure-connections"
JENKINS_CLI = "https://www.jenkins.io/doc/book/managing/cli/"
AKEYLESS_CLI = "https://docs.akeyless.io/docs/cli"
OKTA_CLI = "https://cli.okta.com/"
BK_CLI = "https://buildkite.com/docs/apis/cli"
ACLI = "https://developer.atlassian.com/cloud/acli/guides/install/"
AZURE_AUTO_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/azure/"
    "automated-powershell-onboarding.md"
)
AZURE_MANUAL_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/azure/"
    "azure-manual-onboarding.md"
)
COPILOT_PAGE = (
    "https://entro.gitbook.io/integrations/ai-and-agents/microsoft-copilot-studio/"
    "onboarding-microsoft-copilot-studio.md"
)
TEAMS_PAGE = (
    "https://entro.gitbook.io/integrations/collaboration-and-saas/microsoft-teams/"
    "microsoft-teams-onboarding.md"
)
ADO_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/azure-devops/"
    "azure-devops-onboarding.md"
)
AWS_CFN_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/amazon-web-services/"
    "aws-onboarding-steps.md"
)
AWS_MANUAL_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/amazon-web-services/"
    "aws-onboarding-steps/aws-manual-onboarding/assume-role-link-to-entro.md"
)
AWS_MULTI_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/amazon-web-services/"
    "aws-onboarding-steps/aws-multiple-account-automation.md"
)
GITHUB_S3_PAGE = (
    "https://entro.gitbook.io/integrations/code-and-ci-cd/github/"
    "github-cloud-onboarding/github-cloud-enterprise-s3-logs-streaming.md"
)
GCP_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/"
    "google-cloud-platform-1/gcp-console-onboarding-new.md"
)
VAULT_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/"
    "hashicorp-vault/hashicorp-vault-onboarding.md"
)
OCI_PAGE = "https://entro.gitbook.io/integrations/cloud-and-infrastructure/oci/oci-onboarding.md"
OKTA_PAGE = "https://entro.gitbook.io/integrations/security-and-identity/okta/okta-onboarding.md"
SNOW_PAGE = (
    "https://entro.gitbook.io/integrations/security-and-identity/snowflake/"
    "snowflake-onboarding.md"
)
AKEYLESS_PAGE = (
    "https://entro.gitbook.io/integrations/cloud-and-infrastructure/akeyless-vault/"
    "akeyless-onboarding.md"
)
GITLAB_PAGE = "https://entro.gitbook.io/integrations/code-and-ci-cd/gitlab/gitlab-onboarding.md"
JENKINS_PAGE = "https://entro.gitbook.io/integrations/code-and-ci-cd/jenkins/jenkins-onboarding.md"
JFROG_PAGE = (
    "https://entro.gitbook.io/integrations/container-registries/jfrog-artifactory/"
    "jfrog-artifactory-onboarding.md"
)

NO_PREVIEW = "Platform has no dry-run for this change; disclosed as no-preview."

ENTRO_AZURE_ORIGIN = (
    "https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/"
    "spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F7pmnww8A099dTyQLXKT0%2F"
    "Entro-Azure-Onboarding.ps1?alt=media"
)
ENTRO_AZURE_ORIGIN_CHECKSUM = (
    "sha256:af42cb707a3edce614ba23eed7aa14add8ee336142061dc775edb3d4409666d1"
)
ENTRO_AZURE_SCRIPT = PinnedScript(
    skill_path="integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1",
    version=(
        "Entro-Azure-Onboarding.ps1 Local onboarding fork (origin upload 7pmnww8A099dTyQLXKT0; "
        "Entro permission-audit set; Az.Resources 9 PSRoleDefinition Actions/NotActions; "
        "TeamsAppInstallation.ReadWriteSelfForUser.All; ordered permission-group lookup; "
        "lazy WindowsDefenderATP service-principal provisioning)"
    ),
    checksum="sha256:edcb8bb6dbf8a782a9d663df6598515b39126852347415eede36b509d36237fd",
    origin_url=ENTRO_AZURE_ORIGIN,
    local_fork=True,
    origin_checksum=ENTRO_AZURE_ORIGIN_CHECKSUM,
)
GCP_PRECHECK_SCRIPT = PinnedScript(
    skill_path="integrations/google-gcp/gcp_pre_onboarding_check.sh",
    version="gcp_pre_onboarding_check.sh",
    checksum="sha256:8400acb5be426c81c63c7bfec97bc65639b3913d8da9dc8763725e29553e390f",
    capture_source=(
        "cloud-and-infrastructure/google-cloud-platform/gcp-pre-onboarding-check.md"
    ),
)

LABEL_VALIDATION = "Non-empty label; letters, digits, spaces, and hyphens."

ENV_NICK = _input(
    "environment_nickname",
    "Environment nickname for Entro",
    "Operator-chosen Entro label for this connection",
    LABEL_VALIDATION,
    "Environment nickname",
    default="nonprod",
)
ENV_NICK_ADO = _input(
    "environment_nickname",
    "Environment Nickname for Entro",
    "Operator-chosen Entro label for this connection",
    LABEL_VALIDATION,
    "Environment Nickname",
    default="nonprod",
)
ENV_FIELD = _input(
    "environment",
    "Environment label for Entro",
    "Operator-chosen Entro environment label",
    LABEL_VALIDATION,
    "Environment",
    default="Development",
)
ENV_TYPE_INPUT = _input(
    "environment_type",
    "Environment type in Entro",
    "Production, Development, or the matching form value",
    "One of Production, Development, or the form's listed types",
    "Environment Type",
    default="Development",
)
DISPLAY = _input(
    "display_name",
    "Display Name in Entro",
    "Operator-chosen Entro display name",
    LABEL_VALIDATION,
    "Display Name",
)
NICKNAME = _input(
    "nickname",
    "Nickname in Entro",
    "Operator-chosen Entro nickname",
    LABEL_VALIDATION,
    "Nickname",
)
COMPANY_NICK = _input(
    "company_nickname",
    "Company Nickname in Entro",
    "Operator-chosen Entro company nickname",
    LABEL_VALIDATION,
    "Company Nickname",
)
ENTRA_APP_NAME = _input(
    "display_name",
    "Display name for the Entra app registration",
    "Names the Entra app object this run creates in the tenant",
    LABEL_VALIDATION,
    default="EntroSecurityApp",
)
GCP_PROJECT_ID = _input(
    "project_id",
    "GCP project ID for Entro onboarding",
    "Project the required APIs are enabled in and the Entro reader identity lives in",
    "GCP project ID: 6-30 characters, lowercase letters, digits, and hyphens",
)
GCP_ORGANIZATION_DOMAIN = _input(
    "organization_domain",
    "GCP organization domain",
    "Identifies the organization in the Entro form and in Entro's Terraform variables",
    "Domain attached to the GCP organization, such as example.com",
    "Organization Domain",
)
GCP_ORGANIZATION_ID = _input(
    "organization_id",
    "GCP organization ID",
    "Organization whose IAM policy carries Entro's read-only role bindings",
    "Numeric GCP organization ID as `gcloud organizations list` reports it",
)
GCP_SERVICE_ACCOUNT = _input(
    "service_account_name",
    "Name for the Entro reader service account",
    "Names the service account this run creates and grants Entro's read-only roles",
    "Service account ID: 6-30 characters, lowercase letters, digits, and hyphens",
    default="entro-automatic-onboard",
)
GCP_ENTRO_AWS_ROLE_ARN = _input(
    "entro_aws_role_arn",
    "Entro AWS role ARN shown by the GCP connection form",
    "Limits Workload Identity Federation impersonation to Entro's dedicated AWS role",
    "ARN beginning arn:aws:sts::937217723901:assumed-role/EntroTrustRole-",
)
SNOWFLAKE_USER = _input(
    "entro_user",
    "Snowflake username for Entro",
    "Names the Snowflake user this run creates and verifies with DESC USER",
    "Snowflake identifier; unquoted names are stored uppercase",
    default="ENTRO",
)
DATAVERSE_ENV_ID = _input(
    "environment_id",
    "Power Platform environments that host Copilot Studio agents",
    "Dataverse environments the Entro app is added to as an application user",
    "Environment ID (GUID) or environment URL as pac admin list reports it; "
    "separate several environments with commas",
)

PROBES: dict[str, dict[str, CatalogCheck | PlatformIdentityQuery]] = {
    "az": {
        "presence": _check("command -v az", MS_LEARN_AZ_INSTALL),
        "capability": _check(
            "az version",
            MS_LEARN_AZ_INSTALL,
            suitable_when="JSON includes azure-cli",
        ),
        "auth": _check("az account show", MS_LEARN_AZ_ACCOUNT),
        "identity": _identity(
            "az account show --output json",
            "user.name",
            "environmentName",
            "id (subscription) and tenantId",
            MS_LEARN_AZ_ACCOUNT,
        ),
    },
    "pwsh": {
        "presence": _check(
            "command -v pwsh",
            "https://learn.microsoft.com/powershell/scripting/install/installing-powershell",
        ),
        "capability": _check(
            'pwsh -NoProfile -Command "Get-Module -ListAvailable Az, Microsoft.Graph | Select-Object Name, Version"',
            "https://learn.microsoft.com/powershell/azure/install-azure-powershell",
            suitable_when="Az and Microsoft.Graph modules are listed",
            min_version="7.0",
        ),
        "auth": _check(
            'pwsh -NoProfile -Command "Get-AzSubscription -ErrorAction Stop | Select-Object -First 1 | Out-Null"',
            MS_LEARN_PWSH,
        ),
        "identity": _identity(
            'pwsh -NoProfile -Command "Get-AzContext | Select-Object Account, Environment, Tenant, Subscription | ConvertTo-Json"',
            "Account",
            "Environment",
            "Tenant and Subscription",
            MS_LEARN_PWSH,
        ),
    },
    "pac": {
        "presence": _check("command -v pac", PAC_CLI_DOCS, retrieved_at=PAC_RETRIEVED),
        "capability": _check(
            "pac",
            PAC_CLI_DOCS,
            suitable_when="banner prints Microsoft PowerPlatform CLI with a Version line",
            retrieved_at=PAC_RETRIEVED,
        ),
        "auth": _check("pac auth list", PAC_CLI_AUTH, retrieved_at=PAC_RETRIEVED),
        "identity": _identity(
            "pac auth list",
            "User of the active (*) authentication profile",
            "Cloud of the active profile",
            "Url of the active profile (Dataverse environment)",
            PAC_CLI_AUTH,
            retrieved_at=PAC_RETRIEVED,
        ),
    },
    "aws": {
        "presence": _check(
            "command -v aws",
            "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html",
        ),
        "capability": _check(
            "aws --version",
            "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html",
            suitable_when="aws-cli/2 is reported",
        ),
        "auth": _check("aws sts get-caller-identity", AWS_STS),
        "identity": _identity(
            "aws sts get-caller-identity --output json",
            "Arn",
            "sts regional endpoint in use",
            "Account",
            AWS_STS,
        ),
    },
    "terraform": {
        "presence": _check(
            "command -v terraform",
            "https://developer.hashicorp.com/terraform/install",
        ),
        "capability": _check(
            "terraform version",
            "https://developer.hashicorp.com/terraform/install",
            suitable_when="Terraform v1 is reported",
        ),
        "auth": _check("aws sts get-caller-identity", AWS_STS),
        "identity": _identity(
            "aws sts get-caller-identity --output json",
            "Arn",
            "sts regional endpoint in use",
            "Account",
            AWS_STS,
        ),
    },
    "gcloud": {
        "presence": _check("command -v gcloud", "https://cloud.google.com/sdk/docs/install"),
        "capability": _check(
            "gcloud version",
            "https://cloud.google.com/sdk/docs/install",
            suitable_when="Google Cloud SDK is reported",
        ),
        "auth": _check("gcloud auth list --filter=status:ACTIVE --format=value(account)", GCLOUD_AUTH),
        "identity": _identity(
            "gcloud config list --format=json",
            "core.account",
            "core.universe_domain or default cloud endpoint",
            "core.project",
            "https://cloud.google.com/sdk/gcloud/reference/config/list",
        ),
    },
    "gh": {
        "presence": _check("command -v gh", "https://cli.github.com/"),
        "capability": _check("gh --version", "https://cli.github.com/", suitable_when="gh version is reported"),
        "auth": _check("gh auth status", GH_AUTH),
        "identity": _identity(
            "gh api user --jq '{login, html_url}'",
            "login",
            "github.com or GH_HOST",
            "gh api user.html_url",
            GH_AUTH,
        ),
    },
    "glab": {
        "presence": _check("command -v glab", GLAB_AUTH),
        "capability": _check("glab version", GLAB_AUTH, suitable_when="glab version is reported"),
        "auth": _check("glab auth status", "https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/auth/status.md"),
        "identity": _identity(
            "glab auth status",
            "Logged in as",
            "GitLab hostname",
            "API endpoint host",
            "https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/auth/status.md",
        ),
    },
    "vault": {
        "presence": _check(
            "command -v vault",
            "https://developer.hashicorp.com/vault/docs/install",
        ),
        "capability": _check(
            "vault version",
            "https://developer.hashicorp.com/vault/docs/install",
            suitable_when="Vault CLI version is reported",
        ),
        "auth": _check("vault token lookup", VAULT_TOKEN),
        "identity": _identity(
            "vault token lookup -format=json",
            "meta.username or display_name",
            "VAULT_ADDR",
            "policies",
            VAULT_TOKEN,
        ),
    },
    "oci": {
        "presence": _check("command -v oci", "https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm"),
        "capability": _check(
            "oci --version",
            "https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm",
            suitable_when="oci version is reported",
        ),
        "auth": _check("oci iam region list --output json", OCI_SESSION),
        "identity": _identity(
            "oci iam region list --query 'data[0].key' --output json; oci os ns get --output json",
            "config user OCID",
            "OCI regional API",
            "tenancy OCID from config",
            OCI_SESSION,
        ),
    },
    "jf": {
        "presence": _check("command -v jf", JF_CLI),
        "capability": _check("jf --version", JF_CLI, suitable_when="jf version is reported"),
        "auth": _check("jf rt ping", "https://jfrog.com/help/r/jfrog-cli/pinging-artifactory"),
        "identity": _identity(
            "jf config show",
            "User",
            "Url",
            "Server ID / platform URL",
            JF_CLI,
        ),
    },
    "sf": {
        "presence": _check("command -v sf", SF_ORG),
        "capability": _check("sf --version", SF_ORG, suitable_when="sf version is reported"),
        "auth": _check("sf org display --json", SF_ORG),
        "identity": _identity(
            "sf org display --json",
            "username",
            "instanceUrl",
            "orgId",
            SF_ORG,
        ),
    },
    "snow": {
        "presence": _check("command -v snow", SNOW_CONN),
        "capability": _check("snow --version", SNOW_CONN, suitable_when="Snowflake CLI version is reported"),
        "auth": _check("snow connection test", SNOW_CONN),
        "identity": _identity(
            'snow sql -q "SELECT CURRENT_USER(), CURRENT_ACCOUNT(), CURRENT_REGION()"',
            "CURRENT_USER()",
            "Snowflake account URL",
            "CURRENT_ACCOUNT() and CURRENT_REGION()",
            SNOW_CONN,
        ),
    },
    "jenkins-cli": {
        "presence": _check("test -f jenkins-cli.jar", JENKINS_CLI),
        "capability": _check(
            "java -jar jenkins-cli.jar -s \"$JENKINS_URL\" help",
            JENKINS_CLI,
            suitable_when="help lists Jenkins CLI commands",
        ),
        "auth": _check(
            "java -jar jenkins-cli.jar -s \"$JENKINS_URL\" who-am-i",
            JENKINS_CLI,
        ),
        "identity": _identity(
            "java -jar jenkins-cli.jar -s \"$JENKINS_URL\" who-am-i",
            "authenticated user id",
            "JENKINS_URL",
            "controller URL",
            JENKINS_CLI,
        ),
    },
    "akeyless": {
        "presence": _check("command -v akeyless", AKEYLESS_CLI),
        "capability": _check("akeyless --version", AKEYLESS_CLI, suitable_when="akeyless version is reported"),
        "auth": _check("akeyless list-auth-methods", AKEYLESS_CLI),
        "identity": _identity(
            "akeyless profile-list",
            "profile name / Access ID",
            "Akeyless API gateway",
            "account / Access ID",
            AKEYLESS_CLI,
        ),
    },
    "okta": {
        "presence": _check("command -v okta", OKTA_CLI),
        "capability": _check("okta --version", OKTA_CLI, suitable_when="okta CLI version is reported"),
        "auth": _check("okta login --help && okta orgs", OKTA_CLI),
        "identity": _identity(
            "okta orgs",
            "logged-in admin",
            "Okta org URL",
            "Okta org",
            OKTA_CLI,
        ),
    },
    "bk": {
        "presence": _check("command -v bk", BK_CLI),
        "capability": _check("bk --version", BK_CLI, suitable_when="bk version is reported"),
        "auth": _check("bk api user", "https://buildkite.com/docs/apis/rest-api/user"),
        "identity": _identity(
            "bk api user",
            "user name/email",
            "api.buildkite.com",
            "organization slugs",
            "https://buildkite.com/docs/apis/rest-api/user",
        ),
    },
    "acli": {
        "presence": _check("command -v acli", ACLI),
        "capability": _check("acli --version", ACLI, suitable_when="acli version is reported"),
        "auth": _check("acli auth status", ACLI),
        "identity": _identity(
            "acli auth status",
            "Atlassian account",
            "Atlassian cloud",
            "org/site",
            ACLI,
        ),
    },
}


def _mcp_probes(server_id: str, docs_url: str) -> dict[str, CatalogCheck | PlatformIdentityQuery]:
    return {
        "presence": _check(
            f"MCP client configuration lists server id {server_id}",
            docs_url,
        ),
        "capability": _check(
            f"MCP tools/list for {server_id} returns vendor tools",
            docs_url,
            suitable_when="tools/list is non-empty",
        ),
        "auth": _check(
            f"MCP session for {server_id} reports authenticated",
            docs_url,
        ),
        "identity": _identity(
            f"MCP whoami or equivalent resource on {server_id}",
            "non-secret principal from MCP",
            "MCP server endpoint",
            "tenant/org/account from MCP",
            docs_url,
        ),
    }


MCP_PROBES = {
    "n8n-mcp": _mcp_probes(
        "n8n-mcp",
        "https://docs.n8n.io/advanced-ai/accessing-n8n-mcp-server/",
    ),
    "azure-mcp": _mcp_probes(
        "azure-mcp",
        "https://learn.microsoft.com/azure/developer/azure-mcp-server/",
    ),
    "aws-mcp": _mcp_probes(
        "aws-mcp",
        "https://awslabs.github.io/mcp/",
    ),
    "github-mcp": _mcp_probes(
        "github-mcp",
        "https://github.com/github/github-mcp-server",
    ),
    "atlassian-rovo-mcp": _mcp_probes(
        "atlassian-rovo-mcp",
        "https://github.com/atlassian/atlassian-mcp-server",
    ),
    "salesforce-mcp": _mcp_probes(
        "salesforce-mcp",
        "https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/client-connection-overview.html",
    ),
}


def probes_for(key: str) -> dict[str, CatalogCheck | PlatformIdentityQuery]:
    if key in PROBES:
        return PROBES[key]
    return MCP_PROBES[key]


MS_AUTO_ACTIONS = (
    _action(
        "Run Entro's Azure onboarding script",
        "Script has no vendor dry-run; checksum the Skill-held file, review path/size/checksum, then Approve. Entro docs describe a local run only.",
        "pwsh -File integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1",
        "Entra tenant and selected Azure subscriptions / management groups",
        "Entro app registration EntroSecurityApp exists with Entro permission-audit Graph and Defender grants on the Identity object",
        "sha256 of integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1 matches script.checksum; script prints Azure Client ID, Tenant ID, and Client Secret; az ad app list --display-name EntroSecurityApp --query [].appId",
        "Script does not declare automatic rollback; residual Entra app, custom role, and Log Analytics resources must be deleted manually if the operator stops",
        AZURE_AUTO_PAGE,
        secret_producing=True,
        script=ENTRO_AZURE_SCRIPT,
    ),
    _action(
        "Record tenant, client ID, and secret",
        NO_PREVIEW,
        "Operator copies Tenant ID and Application (client) ID from app Overview; creates or copies client secret Value only in the operator vault",
        "Entra app Overview and Certificates & secrets",
        "Tenant ID and Client ID recorded; secret Value stored outside the session",
        "az ad app show --id <appId> --query '{appId:appId,publisherDomain:publisherDomain}' ; secret Value is never printed",
        "Irreversible for a revealed secret Value; rotate by creating a new secret and deleting the old one in Entra",
        AZURE_AUTO_PAGE,
        secret_producing=True,
    ),
)

MS_MANUAL_ACTIONS = (
    _action(
        "Register the Entro app in Entra",
        "az ad app create has no dry-run; disclose display name and permissions then Approve",
        "az ad app create --display-name <display_name> --sign-in-audience AzureADMyOrg ; then add Graph/Azure application permissions from Entro's permissions reference and az ad app permission admin-consent",
        "Entra tenant",
        "Single-tenant app exists with admin-consented application permissions",
        "az ad app list --display-name <display_name> --query [].appId",
        "Delete the app registration if the operator stops (az ad app delete --id <appId>); admin consent is not fully reversed by delete alone for issued tokens",
        AZURE_MANUAL_PAGE,
    ),
)

COPILOT_ACTIONS = (
    _action(
        "Add Copilot Studio Graph permissions",
        NO_PREVIEW,
        "az ad app permission add --id <appId> with Copilot Studio / Power Platform application permission IDs from Entro's Copilot Studio permissions list, then az ad app permission admin-consent --id <appId>",
        "Same Entra app as Microsoft Ecosystem",
        "API permissions include Copilot Studio scopes with admin consent",
        "az ad app permission list --id <appId>",
        "Remove the added Graph permissions (az ad app permission delete) then re-consent; tokens already issued remain until expiry",
        COPILOT_PAGE,
    ),
    _action(
        "Provision the app into Dataverse environments",
        "pac admin list shows target environments; assign-user has no dry-run beyond listing application users first",
        "pac admin assign-user --environment <environment_id> --user <appId> --role \"System Customizer\" --application-user",
        "Power Platform / Dataverse environments that host Copilot Studio agents",
        "Each locked environment lists the Entro app as an application user",
        "pac admin list-application-users --environment <environment_id> (or Power Platform admin → Application users)",
        "Remove the application user from Dataverse environments; no automatic rollback command is cataloged",
        COPILOT_PAGE,
    ),
)

TEAMS_ACTIONS = (
    _action(
        "Grant Teams Graph permissions",
        NO_PREVIEW,
        "az ad app permission add --id <appId> with Teams application permissions from Entro's Teams onboarding guide, then admin-consent",
        "Entro Entra app",
        "API permissions show Teams scopes with admin consent",
        "az ad app permission list --id <appId>",
        "Delete the added permission entries; existing tokens remain until expiry",
        TEAMS_PAGE,
    ),
)

ADO_ACTIONS = (
    _action(
        "Create or reuse the Entro Entra app",
        "Inspect existing apps with az ad app list --display-name <display_name> before create",
        "Reuse the Microsoft Ecosystem app or az ad app create, then add Azure DevOps application permissions from Entro's guide and admin-consent",
        "Entra tenant / Azure DevOps organization",
        "Entra shows the app with Azure DevOps permissions consented",
        "az ad app permission list --id <appId>",
        "Stop and reuse an existing matching app when the name collides; otherwise az ad app delete only if this run created it",
        ADO_PAGE,
    ),
)

AWS_TERRAFORM_ACTIONS = (
    _action(
        "Initialize the Entro Terraform module",
        "terraform init -backend=false",
        "terraform init in <terraform_dir> after copying Entro's Terraform-Entro.tf module into that workspace",
        "Operator Terraform workspace for AWS Organizations",
        "terraform init completes and providers are installed",
        "terraform -chdir=<terraform_dir> version ; .terraform.lock.hcl exists",
        "Remove .terraform/ created this run if stopping before apply",
        AWS_MULTI_PAGE,
    ),
    _action(
        "Plan and apply the Entro IAM roles",
        "terraform plan -var external_id=<external_id> -var remote_agent=<remote_agent> -var sns_topic_arn_suffix=<sns_topic_arn_suffix>",
        "terraform apply -var external_id=<external_id> -var remote_agent=<remote_agent> -var sns_topic_arn_suffix=<sns_topic_arn_suffix> after Approve",
        "AWS Organizations member accounts",
        "EntroAWSIntegrationRole and EntroReadOnlyAccess exist in member accounts",
        "terraform show ; aws iam get-role --role-name EntroAWSIntegrationRole",
        "terraform destroy of this workspace's state after Approve if rolling back this run",
        AWS_MULTI_PAGE,
    ),
    _action(
        "Copy the Role ARN",
        NO_PREVIEW,
        "aws iam get-role --role-name EntroAWSIntegrationRole --query Role.Arn --output text (record in operator vault, not chat)",
        "Member-account IAM role EntroAWSIntegrationRole",
        "Role ARN recorded for the Entro form",
        "ARN matches arn:aws:iam::<accountId>:role/EntroAWSIntegrationRole",
        "No mutation; stop has no residual change",
        AWS_MULTI_PAGE,
    ),
)

AWS_MANUAL_ACTIONS = (
    _action(
        "Create the read-only IAM policy and role",
        "aws iam get-role --role-name <role_name> (inspect collision); no create dry-run",
        "aws iam create-policy then aws iam create-role with Entro account trust and ExternalId condition, then aws iam attach-role-policy",
        "Target AWS account IAM",
        "IAM shows the Entro role with the read-only policy and matching trust policy",
        "aws iam get-role --role-name <role_name> ; aws iam list-attached-role-policies --role-name <role_name>",
        "Detach policy, delete role, delete policy version if this run created them",
        AWS_MANUAL_PAGE,
    ),
    _action(
        "Copy the Role ARN",
        NO_PREVIEW,
        "aws iam get-role --role-name <role_name> --query Role.Arn --output text (record in operator vault, not chat)",
        "IAM role",
        "Role ARN recorded for the Entro form",
        "ARN matches arn:aws:iam::<accountId>:role/<role_name>",
        "No mutation; stop has no residual change",
        AWS_MANUAL_PAGE,
    ),
)

S3_COVERAGE_STEPS_ACTIONS = (
    _action(
        "Grant Entro IAM S3 read on the streaming bucket",
        "aws iam simulate-principal-policy or get-role-policy inspect",
        "aws iam put-role-policy or attach the Entro-documented inline policy with s3:ListBucket and s3:GetObject on the streaming bucket",
        "AWS account that hosts the GitHub audit-log S3 bucket",
        "Entro IAM role can list and get objects on that bucket",
        "aws iam get-role-policy / simulate-principal-policy for s3:ListBucket and s3:GetObject",
        "Delete the inline policy statement added this run",
        GITHUB_S3_PAGE,
    ),
    _action(
        "Record the S3 bucket name",
        "aws s3api head-bucket --bucket <s3_bucket_name>",
        "Operator records the GitHub audit-log streaming bucket name as an Operator input",
        "GitHub Enterprise audit log streaming + AWS S3",
        "Bucket name persisted for the Entro form",
        "aws s3api head-bucket --bucket <s3_bucket_name> exits 0",
        "No mutation beyond IAM already gated",
        GITHUB_S3_PAGE,
    ),
)

def gcp_actions(
    iam_script: PinnedScript,
    api_script: PinnedScript,
) -> tuple[TypedAction, ...]:
    """Build the source-complete Console-manual GCP Configuration plan."""

    return (
    _action(
        "Run the GCP pre-onboarding check",
        "The shell script has no vendor dry-run; checksum the Skill-held file then Approve",
        "bash integrations/google-gcp/gcp_pre_onboarding_check.sh",
        "GCP organization projects the operator can list",
        "report.txt lists projects with role and logging checks",
        "report.txt exists and records Organization ID plus per-project results",
        "No GCP mutation; delete local report.txt if stopping",
        GCP_PAGE,
        script=GCP_PRECHECK_SCRIPT,
    ),
    _action(
        "Enable Terraform-default GCP APIs",
        "The generated artifact has no vendor dry-run; checksum and review the Skill-held file. It will derive active organization projects from <organization_id>, enable 8 host-project defaults on <project_id>, 3 organization-project defaults, and the 2 billing-required defaults when the pinned Terraform billing condition is true.",
        "ORGANIZATION_ID=<organization_id> PROJECT_ID=<project_id> bash integrations/google-gcp/entro-gcp-enable-apis.sh apply",
        "Host project <project_id> and active projects under GCP organization <organization_id>",
        "The host project has all 8 Terraform-default host services; active organization projects have all 3 organization-project services and, when billing-required defaults are enabled, both billing-dependent services",
        "ORGANIZATION_ID=<organization_id> PROJECT_ID=<project_id> bash integrations/google-gcp/entro-gcp-enable-apis.sh verify",
        "Enabled APIs remain enabled; rollback intentionally does not disable shared services because other workloads may depend on them",
        GCP_PAGE,
        script=api_script,
    ),
    _action(
        "Create the Entro reader identity",
        "Run gcloud iam service-accounts describe <service_account_name>@<project_id>.iam.gserviceaccount.com --project <project_id>. If it exists, treat the name as a collision and stop before any IAM grants; do not reuse or modify it.",
        "gcloud iam service-accounts create <service_account_name> --project <project_id> --display-name \"A service account for Entro Automatic Onboard\"",
        "GCP project <project_id>",
        "One Entro reader service account exists; this action creates no key and grants no role",
        "gcloud iam service-accounts describe <service_account_name>@<project_id>.iam.gserviceaccount.com --project <project_id>",
        "Delete the service account only if this run created it: gcloud iam service-accounts delete <service_account_name>@<project_id>.iam.gserviceaccount.com --project <project_id>",
        GCP_PAGE,
    ),
    _action(
        "Grant the Terraform-derived Entro IAM roles",
        "Checksum and review the generated Skill-held artifact. It will select an unused entroLoggingRole_<1-1000> role ID, create the pinned Entro Logging Role, and add its binding plus exactly 12 predefined organization bindings; existing predefined bindings are left untouched.",
        "ORGANIZATION_ID=<organization_id> PROJECT_ID=<project_id> SERVICE_ACCOUNT_NAME=<service_account_name> bash integrations/google-gcp/entro-gcp-iam-grants.sh apply",
        "IAM policy for GCP organization <organization_id> and the Entro reader service account in project <project_id>",
        "An Entro Logging Role with the pinned Terraform permission set and exactly 12 predefined roles grants organization read access to the Entro reader service account",
        "ORGANIZATION_ID=<organization_id> PROJECT_ID=<project_id> SERVICE_ACCOUNT_NAME=<service_account_name> bash integrations/google-gcp/entro-gcp-iam-grants.sh verify",
        "Run ORGANIZATION_ID=<organization_id> PROJECT_ID=<project_id> SERVICE_ACCOUNT_NAME=<service_account_name> bash integrations/google-gcp/entro-gcp-iam-grants.sh rollback; it removes only IAM bindings and the custom role created by this run",
        GCP_PAGE,
        script=iam_script,
    ),
    )

VAULT_ACTIONS = (
    _action(
        "Create the entro-policy ACL",
        "vault policy read entro-policy (inspect collision)",
        "vault policy write entro-policy <entro-acl.hcl> with list/read capabilities from Entro's guide",
        "Vault cluster at VAULT_ADDR",
        "Policies list includes entro-policy",
        "vault policy read entro-policy",
        "vault policy delete entro-policy if this run created it",
        VAULT_PAGE,
    ),
    _action(
        "Create a renewable token",
        NO_PREVIEW,
        "vault token create -policy=entro-policy -renewable (operator copies token into the operator vault; not into chat)",
        "Vault cluster",
        "Vault reports a token created with policy entro-policy (value stored outside the session)",
        "vault token lookup (metadata only; do not print the token)",
        "vault token revoke <tokenAccessor> using the accessor, not the secret token in session",
        VAULT_PAGE,
        secret_producing=True,
    ),
)

OCI_ACTIONS = (
    _action(
        "Create an Entro OCI user and API key",
        "oci iam user get --user-id (inspect collision by name via list)",
        "oci iam user create, group/policy attach from Entro's read-only set, then oci iam user api-key upload; operator stores the PEM outside the session",
        "OCI tenancy",
        "Identity shows the user, policy, and an API key fingerprint",
        "oci iam user list --compartment-id <tenancyOcid> ; oci iam user api-key list --user-id <userOcid>",
        "Delete the API key and user created this run after Approve",
        OCI_PAGE,
        secret_producing=True,
    ),
)

OKTA_ACTIONS = (
    _action(
        "Copy Entro's public key from the Okta form",
        NO_PREVIEW,
        "Operator copies the Public Key from Entro Add New Account → Okta (non-secret PEM) and keeps the tab open",
        "Entro Okta wizard",
        "The Entro Okta form still shows a Public Key",
        "Public key PEM is recorded as non-secret Operator input material for the next step",
        "No Okta mutation",
        OKTA_PAGE,
    ),
    _action(
        "Create an Okta API Services app",
        NO_PREVIEW,
        "okta apps create (API Services) with public-key authentication, paste Entro's public key, disable DPoP, grant Entro's documented Okta API scopes, assign Super Administrator or the documented custom role",
        "Okta org",
        "The app General tab shows a Client ID and the public key; scopes are granted",
        "okta apps list / apps show for the Entro app",
        "Deactivate then delete the API Services app created this run",
        OKTA_PAGE,
    ),
)

SNOWFLAKE_ACTIONS = (
    _action(
        "Create the Entro Snowflake user",
        'snow sql -q "SHOW USERS LIKE \'ENTRO%\'" (inspect collision)',
        'snow sql -q "CREATE USER ... RSA_PUBLIC_KEY=...; GRANT ROLE ..." per Entro\'s documented grants; operator stores the private key in the vault',
        "Snowflake account",
        "Snowflake shows the Entro user with the documented role",
        'snow sql -q "DESC USER <entro_user>"',
        "DROP USER created this run after Approve",
        SNOW_PAGE,
        secret_producing=True,
    ),
)

AKEYLESS_ACTIONS = (
    _action(
        "Create an Entro auth method in Akeyless",
        "akeyless list-auth-methods (inspect name collision)",
        "akeyless create-auth-method or create-auth-method-universal-identity named for Entro; operator stores Access Key / UID outside the session",
        "Akeyless account",
        "Akeyless lists the Entro auth method with an Access ID",
        "akeyless list-auth-methods",
        "Delete the auth method created this run",
        AKEYLESS_PAGE,
        secret_producing=True,
    ),
)

GITLAB_ACTIONS = (
    _action(
        "Create a GitLab access token",
        NO_PREVIEW,
        "glab token create --name entro --scopes read_api,read_repository (group or project as locked); operator stores the token in the vault",
        "GitLab.com or self-managed GitLab",
        "GitLab shows an access token named for Entro (value stored outside the session)",
        "glab token list",
        "Revoke the token created this run (glab token revoke)",
        GITLAB_PAGE,
        secret_producing=True,
    ),
)

JENKINS_ACTIONS = (
    _action(
        "Create a Jenkins API user",
        "java -jar jenkins-cli.jar -s \"$JENKINS_URL\" list-users or who-am-i inspect",
        "Create a Jenkins user with read access to jobs and credentials metadata and generate an API token (operator copies token in Jenkins UI or CLI groovy); confirm Connector reachability",
        "Jenkins controller",
        "Jenkins shows the Entro user and the Connector loads the login page",
        "java -jar jenkins-cli.jar -s \"$JENKINS_URL\" who-am-i ; curl -I \"$JENKINS_URL\"",
        "Delete the Jenkins user created this run; token revoke in the user configure page",
        JENKINS_PAGE,
        secret_producing=True,
    ),
)

JFROG_ACTIONS = (
    _action(
        "Create a read-only Artifactory token",
        NO_PREVIEW,
        "jf access-token-create --groups <read-group> --expiry 0 (or identity token per Entro scopes); operator stores the token in the vault",
        "JFrog Artifactory instance",
        "Artifactory shows the Entro token (value stored outside the session)",
        "jf rt ping ; jf config show",
        "Revoke the access token created this run from JFrog User Management",
        JFROG_PAGE,
        secret_producing=True,
    ),
)

S3_BUCKET_INPUT = _input(
    "s3_bucket_name",
    "S3 bucket name for GitHub Enterprise audit log streaming",
    "Bucket GitHub streams audit logs into; Entro form needs the name",
    "Valid S3 bucket name",
)
EXTERNAL_ID = _input(
    "external_id",
    "Entro External ID from the wizard",
    "CloudFormation / IAM trust ExternalId condition",
    "Non-empty External ID from the Entro wizard",
)
ROLE_NAME = _input(
    "role_name",
    "IAM role name for Entro",
    "Name of the assume-role in the target account",
    "IAM role name",
    default="EntroReadOnly",
)
REMOTE_AGENT = _input(
    "remote_agent",
    "Remote Agent value from Entro",
    "StackSet / Terraform parameter Entro supplies for multi-account automation",
    "Non-empty Remote Agent string from the Entro team",
)
SNS_TOPIC_ARN_SUFFIX = _input(
    "sns_topic_arn_suffix",
    "SNS topic ARN suffix from Entro (optional)",
    "Optional StackSet / Terraform sns_topic_arn_suffix parameter",
    "Empty or Entro-supplied SNS topic ARN suffix",
    default="",
)
TERRAFORM_DIR = _input(
    "terraform_dir",
    "Terraform working directory for the Entro module",
    "Directory holding Terraform-Entro.tf where terraform init/apply run",
    "Existing writable directory path",
    default=".",
)


def probe_fields_present(entry: dict[str, object]) -> list[str]:
    errors: list[str] = []
    for key, json_key in (
        ("presenceCheck", "presenceCheck"),
        ("capabilityProbe", "capabilityProbe"),
        ("authCheck", "authCheck"),
        ("platformIdentity", "platformIdentity"),
    ):
        block = entry.get(json_key)
        if not isinstance(block, dict):
            errors.append(f"missing {json_key}")
            continue
        if not block.get("command") or not block.get("sourceUrl") or not block.get("retrievedAt"):
            errors.append(f"{json_key} must have command, sourceUrl, retrievedAt")
        if json_key == "capabilityProbe" and not block.get("suitableWhen"):
            errors.append("capabilityProbe must have suitableWhen")
        if json_key == "platformIdentity":
            for field in ("principal", "endpoint", "scope"):
                if not block.get(field):
                    errors.append(f"platformIdentity must have {field}")
    errors.extend(configure_once_fields_present(entry))
    return errors


def configure_once_fields_present(entry: dict[str, object]) -> list[str]:
    if "configureOnce" not in entry:
        return []
    block = entry.get("configureOnce")
    if not isinstance(block, dict):
        return ["configureOnce must be an object"]
    routes = block.get("methods")
    if not isinstance(routes, list) or not routes:
        return ["configureOnce must have a non-empty methods list"]
    errors: list[str] = []
    for route in routes:
        if not isinstance(route, dict):
            errors.append("configureOnce methods must hold objects")
            break
        errors.extend(auth_route_fields_present(route))
    logins = {
        route.get("authOnce") for route in routes if isinstance(route, dict)
    }
    if entry.get("authOnce") not in logins:
        errors.append("configureOnce methods must include the entry authOnce")
    return errors


def auth_route_fields_present(route: dict[str, object]) -> list[str]:
    errors: list[str] = []
    for key in AUTH_ROUTE_KEYS:
        if key in ("check", "prompts"):
            continue
        if not route.get(key):
            errors.append(f"configureOnce route must have {key}")
    if "authOnce" not in route:
        errors.append("configureOnce route must have authOnce")
    check = route.get("check")
    if not isinstance(check, dict):
        errors.append("configureOnce route must have check")
    elif not check.get("command") or not check.get("sourceUrl") or not check.get("retrievedAt"):
        errors.append("configureOnce route check must have command, sourceUrl, retrievedAt")
    prompts = route.get("prompts")
    if not isinstance(prompts, list) or not prompts:
        errors.append("configureOnce route must have a non-empty prompts list")
    else:
        for item in prompts:
            if (
                not isinstance(item, dict)
                or not item.get("prompt")
                or not item.get("whereToFind")
            ):
                errors.append("configureOnce route prompts must have prompt and whereToFind")
                break
    return errors


def operator_only_complete(step: dict[str, object]) -> bool:
    operator = step.get("operatorOnly")
    return (
        isinstance(operator, dict)
        and isinstance(operator.get("reason"), str)
        and bool(str(operator.get("reason")).strip())
        and isinstance(operator.get("evidence"), str)
        and bool(str(operator.get("evidence")).strip())
    )


def uncataloged_complete(step: dict[str, object]) -> bool:
    block = step.get("uncataloged")
    return (
        isinstance(block, dict)
        and isinstance(block.get("evidence"), str)
        and bool(str(block.get("evidence")).strip())
    )


def validate_prep_step_coverage(
    label: str,
    steps: object,
    covered: set[str],
    *,
    preferred: bool,
) -> list[str]:
    """A Prep step binds exactly one of Typed action, authored operatorOnly, or uncataloged."""
    errors: list[str] = []
    if not isinstance(steps, list):
        return errors
    for step in steps:
        if not isinstance(step, dict):
            continue
        title = step.get("title")
        if not isinstance(title, str) or not title.strip():
            continue
        has_action = title in covered
        has_operator = operator_only_complete(step)
        has_uncataloged = uncataloged_complete(step)
        kinds = int(has_action) + int(has_operator) + int(has_uncataloged)
        if kinds > 1:
            errors.append(
                f"{label}: Prep step {title!r} must bind exactly one of "
                "Typed action, Operator-only, or Uncataloged"
            )
        elif kinds == 0:
            errors.append(f"{label}: Prep step {title!r} lacks a Typed action")
            if preferred:
                errors.append(
                    f"{label}: Fit preferred is incomplete; correct Fit to usable or none with rationale"
                )
    return errors

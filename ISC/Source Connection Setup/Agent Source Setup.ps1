#Requires -Version 5.1
<#
.SYNOPSIS
    JSON-driven agent facade for ISC Source Connection Setup.

.DESCRIPTION
    Headless entry point for AI agents. Supports Catalog, Plan, and Apply operations
    across Entra ID, AWS SaaS, AWS CIEM, Google Workspace, and IQService connectors.

    Secrets are never written to stdout. Generated secrets are stored in restricted files
    under sourceConfig/<connector>/agent-runs/<run-id>/.

.PARAMETER Operation
    Catalog - static connector metadata.
    Plan    - validate request and perform read-only discovery.
    Apply   - execute a ready plan (requires matching request and plan files).

.PARAMETER Connector
    entra-id | aws-saas | aws-ciem | google-workspace | iqservice

.PARAMETER RequestPath
    Path to agent request JSON (required for Plan and Apply).

.PARAMETER PlanPath
    Path to plan JSON envelope or body (required for Apply).

.PARAMETER OutputPath
    Optional path to write the JSON envelope.

.EXAMPLE
    .\Agent Source Setup.ps1 -Operation Catalog -Connector entra-id

.EXAMPLE
    .\Agent Source Setup.ps1 -Operation Plan -Connector aws-saas -RequestPath .\agent-schema\examples\aws-saas.request.json -OutputPath .\plan.json

.EXAMPLE
    .\Agent Source Setup.ps1 -Operation Apply -Connector entra-id -RequestPath .\request.json -PlanPath .\plan.json -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Catalog', 'Plan', 'Apply')]
    [string]$Operation,

    [Parameter(Mandatory)]
    [ValidateSet('entra-id', 'aws-saas', 'aws-ciem', 'google-workspace', 'iqservice')]
    [string]$Connector,

    [string]$RequestPath,
    [string]$PlanPath,
    [string]$OutputPath,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $script:ModuleRoot 'ISC.AgentAdapter.psm1') -Force -Global -WarningAction SilentlyContinue
Import-AgentConnectorModule -ModuleRoot $script:ModuleRoot -Connector $Connector

try {
    $envelope = Invoke-AgentAdapter -Operation $Operation -Connector $Connector `
        -RequestPath $RequestPath -PlanPath $PlanPath -OutputPath $OutputPath -WhatIf:$WhatIf

    if (-not $OutputPath) {
        $envelope | ConvertTo-Json -Depth 20
    }
}
catch {
    Write-Error $_
    exit 1
}

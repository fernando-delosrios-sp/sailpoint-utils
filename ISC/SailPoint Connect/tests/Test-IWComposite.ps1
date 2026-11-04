#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'AWS' -Title 'AWS' -CoreOptions @('SaaSConnector', 'Entro') -CliName 'aws' `
    -EntroCompanions @{ SaaSConnector = @{ EntroSwitch = 'Entro' } }
Register-AwsConnectorDefinitions
Register-AwsEntroDefinitions

$ctx = @{
    SaaSConnector   = $true
    Entro           = $true
    IscExternalId   = '11111111-2222-3333-4444-555555555555'
    EntroExternalId = '22222222-3333-4444-5555-666666666666'
    Method          = 'AssumeRole'
    Action          = 'BuildRequirements'
    NonInteractive  = $true
}
$plan = Resolve-IntegrationWizardPlan -Platform 'AWS' -Context $ctx
Assert-True ($plan.IsComposite) 'composite plan for AWS SaaS + Entro'
Assert-True ($plan.Title -match '\+') 'composite title joins member titles'

$tempRoot = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
$outDir = Join-Path $tempRoot "iw-composite-test-$(Get-Random)"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$ctx.OutputDirectory = $outDir
try {
    New-IntegrationWizardRequirementsDoc -Definition $plan -Context $ctx -OutputPath (Join-Path $outDir 'aws-composite-requirements.md')
    $md = Get-Content (Join-Path $outDir 'aws-composite-requirements.md') -Raw
    Assert-True ($md -match 'Entro AWS integration') 'requirements doc includes Entro section heading'
    Assert-True ($md -match 'SaaS') 'requirements doc includes SaaS connector section'
    $stepHeadings = ([regex]::Matches($md, '^#### \d+\.', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    Assert-True ($stepHeadings -ge 2) 'requirements doc lists steps from both members'
}
finally {
    Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'PASS (6 assertions)'

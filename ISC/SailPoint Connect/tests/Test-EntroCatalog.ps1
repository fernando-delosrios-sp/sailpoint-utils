#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$connectRoot = Split-Path $PSScriptRoot -Parent
$entroCatalogModule = Join-Path $connectRoot 'modules/IW.EntroCatalog.psm1'
$azureEntroModule = Join-Path $connectRoot 'modules/Definitions/Azure.Entro.psm1'
$awsEntroModule = Join-Path $connectRoot 'modules/Definitions/Aws.Entro.psm1'

Import-IscModule $entroCatalogModule -Force -Global
Import-IscModule $azureEntroModule -Force -Global
Import-IscModule $awsEntroModule -Force -Global

# 1) Get-EntroConnectSkillRoot finds the skill tree
$root = Get-EntroConnectSkillRoot
Assert-True (-not [string]::IsNullOrWhiteSpace($root)) 'Get-EntroConnectSkillRoot returns a path'
Assert-True (Test-Path -LiteralPath $root) "Get-EntroConnectSkillRoot path exists: $root"
Assert-True (Test-Path -LiteralPath (Join-Path $root 'integrations')) 'Skill root contains integrations directory'

# 2) Entro-Azure-Onboarding.ps1 is assimilated natively; Get-EntroAzureOnboardingScriptPath is removed
Assert-True ($null -eq (Get-Command Get-EntroAzureOnboardingScriptPath -ErrorAction SilentlyContinue)) 'Get-EntroAzureOnboardingScriptPath is removed after native Azure assimilation'
$roPerms = Get-EntroAzureGraphPermissions -Access ReadOnly
$rwPerms = Get-EntroAzureGraphPermissions -Access ReadWrite
Assert-True (@($roPerms.AppRoles) -contains 'User.Read.All') 'ReadOnly Azure Entro Graph permissions include User.Read.All'
Assert-True (@($roPerms.AppRoles) -notcontains 'Application.ReadWrite.All') 'ReadOnly Azure Entro Graph permissions exclude Application.ReadWrite.All'
Assert-True (@($rwPerms.AppRoles) -contains 'Application.ReadWrite.All') 'ReadWrite Azure Entro Graph permissions include Application.ReadWrite.All'

# 3) Get-EntroAwsTemplatePath resolves AWS templates
$awsDefault = Get-EntroAwsTemplatePath -Region Default
Assert-True (Test-Path -LiteralPath $awsDefault) "AWS default template exists: $awsDefault"
$awsEurope = Get-EntroAwsTemplatePath -Region Europe
Assert-True (Test-Path -LiteralPath $awsEurope) "AWS Europe template exists: $awsEurope"

# 4) Environment variable override
$savedEnv = $env:ENTRO_CONNECT_SKILL_ROOT
try {
    $env:ENTRO_CONNECT_SKILL_ROOT = $root
    $overridden = Get-EntroConnectSkillRoot
    Assert-Equal $root $overridden 'Get-EntroConnectSkillRoot respects ENTRO_CONNECT_SKILL_ROOT'
}
finally {
    if ($savedEnv) {
        $env:ENTRO_CONNECT_SKILL_ROOT = $savedEnv
    }
    else {
        Remove-Item env:ENTRO_CONNECT_SKILL_ROOT -ErrorAction SilentlyContinue
    }
}

# 5) Resolution from an external/installed module path
$externalResolved = & pwsh -NoProfile -Command {
    param($moduleFile)
    Import-Module $moduleFile -Force
    Get-EntroConnectSkillRoot
} -Args $entroCatalogModule
Assert-True (-not [string]::IsNullOrWhiteSpace($externalResolved)) 'Get-EntroConnectSkillRoot works in fresh subshell'
Assert-True (Test-Path -LiteralPath $externalResolved) 'Fresh subshell resolved path exists'

# 6) Azure.Entro.psm1 resolves native Graph permissions even when imported from an external directory
$tmpModuleDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
try {
    $tmpModulesSubdir = Join-Path $tmpModuleDir 'modules'
    New-Item -ItemType Directory -Path $tmpModulesSubdir -Force | Out-Null
    Copy-Item -LiteralPath $entroCatalogModule -Destination (Join-Path $tmpModulesSubdir 'IW.EntroCatalog.psm1')
    $azDefDir = Join-Path $tmpModulesSubdir 'Definitions'
    New-Item -ItemType Directory -Path $azDefDir -Force | Out-Null
    Copy-Item -LiteralPath $azureEntroModule -Destination (Join-Path $azDefDir 'Azure.Entro.psm1')

    $externalPerms = & pwsh -NoProfile -Command {
        param($tmpDefPath)
        Import-Module $tmpDefPath -Force
        (Get-EntroAzureGraphPermissions -Access ReadOnly).AppRoles -join ','
    } -Args (Join-Path $azDefDir 'Azure.Entro.psm1')
    Assert-True ($externalPerms -match 'Directory\.Read\.All') 'Azure.Entro.psm1 returns Graph permissions from external directory without external script dependencies'
}
finally {
    if (Test-Path -LiteralPath $tmpModuleDir) {
        Remove-Item -LiteralPath $tmpModuleDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS ($script:AssertionCount assertions)"

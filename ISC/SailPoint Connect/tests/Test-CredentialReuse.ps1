#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Project.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Catalog.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.CatalogMenu.psm1') -Force -Global

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("credential-reuse-test-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$env:SAILPOINT_CONNECT_ROOT = Join-Path $tmp 'projects'
$env:SAILPOINT_CONNECT_TEST_LAUNCH_CAPTURE = Join-Path $tmp 'launch.json'

$definition = @{
    Id         = 'azure-connector'
    Title      = 'Microsoft Entra ID connector application'
    FolderName = 'Microsoft-Entra-ID'
    Platform   = 'Azure'
    Inputs     = @(
        @{ Name = 'TenantId'; Required = $false }
        @{ Name = 'ApplicationName'; Required = $true }
        @{ Name = 'Feature'; Required = $false }
        @{ Name = 'ClientSecret'; Required = $false; Secret = $true }
        @{ Name = 'RotateSecret'; Required = $false }
        @{ Name = 'OutputDirectory'; Required = $false }
    )
    CheckInputs = @(
        @{ Name = 'TenantId'; Required = $true }
        @{ Name = 'ClientId'; Required = $true }
        @{ Name = 'ClientSecret'; Required = $true; Secret = $true }
        @{ Name = 'OutputDirectory'; Required = $false }
    )
}

function New-TestCredentialContext {
    param(
        [string]$Project = 'demo',
        [string]$Action = 'Check',
        [string]$Product = 'fabric',
        [string]$VariantId = 'entra',
        [string]$ClientId = 'client-1',
        [string]$CredentialId,
        [string]$ReuseMode = 'CreateNew'
    )
    return @{
        IntegrationProjectName   = $Project
        IntegrationFolderPath    = (Join-Path $tmp $Project)
        IntegrationOutputOverride = $false
        Action                   = $Action
        Access                   = 'ReadOnly'
        CatalogIntegrationId     = 'azure'
        CatalogProduct           = $Product
        CatalogVariantId         = $VariantId
        CatalogCredentialKind    = 'entra.appClientSecret'
        CatalogReuseMode         = $ReuseMode
        CatalogCredentialId      = $CredentialId
        TenantId                 = 'tenant-1'
        ClientId                 = $ClientId
        ClientSecret             = 'super-secret'
        ApplicationName          = 'Demo Entra app'
        Feature                  = 'Ciem'
        RotateSecret             = $true
        OutputDirectory          = (Join-Path $tmp 'old-output')
    }
}

try {
    $ctx = New-TestCredentialContext
    $snapshot = Get-IntegrationProjectSelectionSnapshot -Context $ctx -Definition $definition -Platform 'Azure' -ScriptName 'Azure.ps1'
    Assert-Equal 'client-1' $snapshot.inputs.ClientId 'CheckInputs are included in catalog selection snapshots'
    Assert-Equal '***' $snapshot.inputs.ClientSecret 'Check secret is masked in selection snapshot'
    Assert-Equal 'azure' $snapshot.catalogIntegrationId 'snapshot records catalog integration'
    Assert-Equal 'client-1' $snapshot.discriminators.ClientId 'snapshot records credential discriminators'

    $entry = Save-IntegrationProjectCredential -Context $ctx -Definition $definition -Platform 'Azure' -ScriptName 'Azure.ps1'
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$entry.id)) 'saved credential gets a stable id'
    $indexPath = Get-IntegrationProjectCredentialIndexPath -ProjectName 'demo'
    Assert-True (Test-Path -LiteralPath $indexPath) 'credential-index.json is written'
    $raw = Get-Content -LiteralPath $indexPath -Raw
    Assert-True ($raw -notmatch 'super-secret') 'credential index contains no supplied secret'
    Assert-True ($raw -notmatch '\*\*\*') 'credential index stores no masked secret placeholders'
    Assert-True (-not $entry.inputs.Contains('ClientSecret')) 'secret input is omitted from reusable inputs'
    Assert-True (-not $entry.inputs.Contains('OutputDirectory')) 'old output directory is not reusable credential configuration'
    Assert-Equal 'client-1' $entry.inputs.ClientId 'non-secret Check input is reusable'
    Assert-Equal 1 @($entry.uses).Count 'initial credential has one product use'

    $update = New-TestCredentialContext -Action 'Run' -Product 'ciem' -VariantId 'entra-ciem' -CredentialId $entry.id -ReuseMode 'UpdateExisting'
    $updated = Save-IntegrationProjectCredential -Context $update -Definition $definition -Platform 'Azure' -ScriptName 'Azure.ps1'
    Assert-Equal $entry.id $updated.id 'explicit update keeps the credential id'
    Assert-Equal 1 @(Read-IntegrationProjectCredentialIndex -ProjectName 'demo').Count 'explicit update does not duplicate the credential'
    Assert-Equal 2 @($updated.uses).Count 'Fabric and CIEM uses are retained on the same credential'
    Assert-Equal 'client-1' $updated.inputs.ClientId 'update preserves prior non-secret inputs'
    Assert-Equal 'Ciem' $updated.inputs.Feature 'new additive configuration is recorded'
    Assert-True (-not $updated.inputs.Contains('RotateSecret')) 'rotation preference is never persisted for reuse'
    Assert-Equal 'ciem' $updated.lastProduct 'last product use is recorded'

    $automatic = Save-IntegrationProjectCredential -Context (New-TestCredentialContext) -Definition $definition -Platform 'Azure' -ScriptName 'Azure.ps1'
    Assert-Equal $entry.id $automatic.id 'complete matching discriminators upsert instead of duplicating'

    $second = Save-IntegrationProjectCredential -Context (New-TestCredentialContext -ClientId 'client-2') -Definition $definition -Platform 'Azure' -ScriptName 'Azure.ps1'
    Assert-True ($second.id -ne $entry.id) 'different discriminators create a separate credential'
    Assert-Equal 2 @(Read-IntegrationProjectCredentialIndex -ProjectName 'demo').Count 'index retains both credentials'

    $crossProduct = @(Find-IntegrationProjectCredential -ProjectName 'demo' -IntegrationId 'azure' -CredentialKind 'entra.appClientSecret' -Product 'ciem')
    Assert-Equal 1 $crossProduct.Count 'credential lookup can find an existing credential through another product use'
    Assert-Equal $entry.id $crossProduct[0].id 'CIEM finds the credential originally saved by Fabric'

    $conflict = New-TestCredentialContext -CredentialId $entry.id -ReuseMode 'UpdateExisting'
    $conflict.TenantId = 'different-tenant'
    $conflictThrew = $false
    try {
        Save-IntegrationProjectCredential -Context $conflict -Definition $definition -Platform 'Azure' -ScriptName 'Azure.ps1' | Out-Null
    }
    catch {
        $conflictThrew = $_.Exception.Message -match 'Choose Create new'
    }
    Assert-True $conflictThrew 'an update cannot silently change saved credential identity'

    $ephemeral = New-TestCredentialContext -Project 'ephemeral'
    $ephemeralResult = Save-IntegrationProjectCredential -Context $ephemeral -Definition $definition -Platform 'Azure' -ScriptName 'Azure.ps1'
    Assert-True ($null -eq $ephemeralResult) 'ephemeral output runs are not indexed as project credentials'

    $selectionContext = @{
        IntegrationProjectName = 'demo'
        Action                 = 'Run'
        CatalogIntegrationId   = 'azure'
        CatalogProduct         = 'ciem'
        CatalogVariantId       = 'entra-ciem'
        CatalogCredentialKind  = 'entra.appClientSecret'
        CatalogReuseMode       = 'UpdateExisting'
        CatalogCredentialId    = $entry.id
    }
    $selection = Resolve-IntegrationCatalogInteractiveSelection -Context $selectionContext -NonInteractive
    Assert-Equal $entry.id $selection.Credential.id 'headless update resolves the explicitly selected credential'
    Assert-Equal 'UpdateExisting' $selection.Context.CatalogReuseMode 'headless update mode is preserved'
    Assert-Equal 'entra.appClientSecret' $selection.Context.CatalogCredentialKind 'single credential kind is copied to context'

    $createContext = @{
        IntegrationProjectName = 'demo'
        Action                 = 'Run'
        CatalogIntegrationId   = 'azure'
        CatalogProduct         = 'fabric'
        CatalogVariantId       = 'entra'
        CatalogCredentialKind  = 'entra.appClientSecret'
    }
    $createSelection = Resolve-IntegrationCatalogInteractiveSelection -Context $createContext -NonInteractive
    Assert-Equal 'CreateNew' $createSelection.Context.CatalogReuseMode 'headless runs default to Create new'
    Assert-True ($null -eq $createSelection.Credential) 'headless runs never implicitly reuse the newest credential'

    $missingIdThrew = $false
    try {
        Resolve-IntegrationCatalogInteractiveSelection -Context (@{
            IntegrationProjectName = 'demo'
            Action                 = 'Run'
            CatalogIntegrationId   = 'azure'
            CatalogProduct         = 'fabric'
            CatalogVariantId       = 'entra'
            CatalogCredentialKind  = 'entra.appClientSecret'
            CatalogReuseMode       = 'UpdateExisting'
        }) -NonInteractive | Out-Null
    }
    catch {
        $missingIdThrew = $_.Exception.Message -match 'requires CatalogCredentialId'
    }
    Assert-True $missingIdThrew 'headless Update existing requires an explicit credential id'

    $interactiveContext = @{
        IntegrationProjectName = 'demo'
        Action                 = 'Run'
        CatalogIntegrationId   = 'azure'
        CatalogProduct         = 'ciem'
        CatalogVariantId       = 'entra-ciem'
        CatalogCredentialKind  = 'entra.appClientSecret'
    }
    $catalogModule = Get-Module -Name 'IW.CatalogMenu'
    & $catalogModule {
        $script:OriginalCatalogReadChoice = (Get-Command Invoke-IntegrationCatalogReadChoice).ScriptBlock
        $script:TestCatalogChoices = [System.Collections.Generic.Queue[object]]::new()
    }
    & $catalogModule { param($id)
        $script:TestCatalogChoices.Enqueue('UpdateExisting')
        $script:TestCatalogChoices.Enqueue($id)
        Set-Item -Path Function:Invoke-IntegrationCatalogReadChoice -Value {
            param($Prompt, $Options, $Labels, $Default, $EscapeMeansDefault)
            if ($script:TestCatalogChoices.Count -eq 0) { throw "Unexpected prompt: $Prompt" }
            return $script:TestCatalogChoices.Dequeue()
        }
    } $entry.id
    try {
        $interactiveSelection = Resolve-IntegrationCatalogInteractiveSelection -Context $interactiveContext
        Assert-Equal $entry.id $interactiveSelection.Credential.id 'interactive flow offers and selects a saved credential'
        Assert-Equal 'UpdateExisting' $interactiveSelection.Context.CatalogReuseMode 'interactive update mode is recorded'
        Assert-Equal 0 (& $catalogModule { $script:TestCatalogChoices.Count }) 'interactive flow prompts for reuse mode and credential'
    }
    finally {
        & $catalogModule { Set-Item -Path Function:Invoke-IntegrationCatalogReadChoice -Value $script:OriginalCatalogReadChoice }
    }

    $fakeLauncher = Join-Path $tmp 'FakeLauncher.ps1'
    @'
[CmdletBinding()]
param(
    [switch]$Wizard,
    [switch]$Connector,
    [string]$Project,
    [string]$Action,
    [switch]$NonInteractive,
    [string]$TenantId,
    [string]$ClientId,
    [string]$ApplicationName,
    [string]$ClientSecret,
    [string[]]$Feature,
    [switch]$RotateSecret,
    [string]$OutputDirectory,
    [string]$CatalogIntegrationId,
    [string]$CatalogProduct,
    [string]$CatalogVariantId,
    [string]$CatalogCredentialKind,
    [string]$CatalogReuseMode,
    [string]$CatalogCredentialId
)
$capture = @{}
foreach ($k in $PSBoundParameters.Keys) {
    $v = $PSBoundParameters[$k]
    if ($v -is [System.Management.Automation.SwitchParameter]) { $v = [bool]$v.IsPresent }
    $capture[$k] = $v
}
$capture | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $env:SAILPOINT_CONNECT_TEST_LAUNCH_CAPTURE -Encoding utf8
'@ | Set-Content -LiteralPath $fakeLauncher -Encoding utf8
    $launchCredential = @{
        id     = $entry.id
        inputs = @{
            TenantId        = 'tenant-1'
            ClientId        = 'client-1'
            ApplicationName = 'Demo Entra app'
            ClientSecret    = 'must-not-pass'
            RotateSecret    = $true
            OutputDirectory = 'old-output'
            UnknownValue    = 'must-not-pass'
        }
    }
    Invoke-IntegrationCatalogLauncher -WizardRoot $tmp -Integration @{ launcher = 'FakeLauncher.ps1' } `
        -Binding $selection.Binding -Product 'ciem' `
        -BaseParameters @{ Project = 'demo'; Action = 'Run'; NonInteractive = $true } `
        -Credential $launchCredential
    $launch = Get-Content -LiteralPath $env:SAILPOINT_CONNECT_TEST_LAUNCH_CAPTURE -Raw | ConvertFrom-Json
    Assert-Equal 'tenant-1' $launch.TenantId 'launcher reuses non-secret tenant input'
    Assert-Equal 'client-1' $launch.ClientId 'launcher reuses non-secret client input'
    Assert-Equal 'Demo Entra app' $launch.ApplicationName 'launcher reuses display configuration'
    Assert-True ($launch.PSObject.Properties.Name -notcontains 'ClientSecret') 'launcher never reuses a stored secret'
    Assert-True ($launch.PSObject.Properties.Name -notcontains 'OutputDirectory') 'launcher does not reuse an old output directory'
    Assert-True ($launch.PSObject.Properties.Name -notcontains 'UnknownValue') 'launcher ignores inputs not accepted by the target script'
    Assert-True (-not [bool]$launch.RotateSecret) 'launcher forces secret rotation off for update existing'
    Assert-True (@($launch.Feature) -contains 'Ciem') 'catalog product defaults still apply during reuse'
    Assert-Equal $entry.id $launch.CatalogCredentialId 'launcher passes selected credential id'
    Assert-Equal 'UpdateExisting' $launch.CatalogReuseMode 'launcher passes update mode'
    Assert-Equal 'Run' $launch.Action 'current action is preserved during reuse'
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_ROOT -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_TEST_LAUNCH_CAPTURE -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "PASS ($script:AssertionCount assertions)"

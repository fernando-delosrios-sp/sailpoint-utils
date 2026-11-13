#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [switch]$Wizard,

    [Parameter(ParameterSetName = 'Smb', Mandatory)]
    [switch]$Smb,

    [Parameter(ParameterSetName = 'Sftp', Mandatory)]
    [switch]$Sftp,

    [Parameter(ParameterSetName = 'WinRm', Mandatory)]
    [switch]$WinRm,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$Nickname,
    [Parameter(ParameterSetName = 'Smb')]
    [ValidateSet('Domain', 'Local')]
    [string]$AccountScope,
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$Username,
    [Parameter(ParameterSetName = 'Smb')]
    [string]$ShareHost,
    [Parameter(ParameterSetName = 'Smb')]
    [string]$ShareNames,
    [Parameter(ParameterSetName = 'Smb')]
    [string]$IgnoreShares,
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [Alias('TargetHostName')]
    [string]$FileHost,
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$TargetDirectories,
    [Parameter(ParameterSetName = 'Sftp')]
    [string]$PublicKeyPath,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$WorkerGroup,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$OutpostId,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$OutpostPublicKeyPath,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$OutpostDeploymentMode,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [switch]$NonInteractive,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Smb')]
    [Parameter(ParameterSetName = 'Sftp')]
    [Parameter(ParameterSetName = 'WinRm')]
    [string]$Project,
    [string]$CatalogIntegrationId,
    [string]$CatalogProduct,
    [string]$CatalogVariantId,
    [string]$CatalogCredentialKind,
    [ValidateSet('CreateNew', 'UpdateExisting')]
    [string]$CatalogReuseMode = 'CreateNew',
    [string]$CatalogCredentialId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/RemoteFileSystem.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'RemoteFileSystem' -Title 'Remote File System' -CoreOptions @('Smb', 'Sftp', 'WinRm') -CliName 'pwsh'
Register-RemoteFileSystemEntroDefinitions

$coreHelp = [ordered]@{
    Smb   = @{ Short = 'SMB'; Long = 'Entro SMB file shares (read-only account and JSON upload)' }
    Sftp  = @{ Short = 'SFTP'; Long = 'Entro SFTP reader key and server commands' }
    WinRm = @{ Short = 'WinRM'; Long = 'Entro WinRM reader on a Windows host' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive; Action = $Action
    Smb = [bool]$Smb; Sftp = [bool]$Sftp; WinRm = [bool]$WinRm
    Nickname = $Nickname; AccountScope = $AccountScope; Username = $Username
    ShareHost = $ShareHost; ShareNames = $ShareNames; IgnoreShares = $IgnoreShares
    FileHost = $FileHost; TargetDirectories = $TargetDirectories; PublicKeyPath = $PublicKeyPath
    WorkerGroup = $WorkerGroup
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

$hasCore = $Smb -or $Sftp -or $WinRm
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'RemoteFileSystem' -ScriptName 'Remote File System.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'RemoteFileSystem' -ScriptName 'Remote File System.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'Which file transport?' -Options @('Smb', 'Sftp', 'WinRm') `
            -Labels @('SMB file shares [Requires Outpost]', 'SFTP [Requires Outpost]', 'WinRM [Requires Outpost]') -Default 'Smb'
        $context[$picked] = $true
        switch ($picked) {
            'Smb' { Get-IntegrationWizardDefinition -Id 'remote-file-smb-entro' }
            'Sftp' { Get-IntegrationWizardDefinition -Id 'remote-file-sftp-entro' }
            'WinRm' { Get-IntegrationWizardDefinition -Id 'remote-file-winrm-entro' }
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }

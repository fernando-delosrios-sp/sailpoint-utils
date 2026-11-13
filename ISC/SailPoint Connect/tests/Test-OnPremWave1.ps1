#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$connectRoot = Split-Path $PSScriptRoot -Parent
$env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK = '1'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("onprem-wave1-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$env:SAILPOINT_CONNECT_ROOT = Join-Path $tmp 'projects'

function Assert-GeneratedScript {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label,
        [string[]]$MustContain = @(),
        [string[]]$MustNotContain = @()
    )
    Assert-True (Test-Path -LiteralPath $Path) "$Label file exists ($Path)"
    $text = Get-Content -LiteralPath $Path -Raw
    foreach ($needle in $MustContain) {
        Assert-True ($text.Contains($needle)) "$Label contains $needle"
    }
    foreach ($needle in $MustNotContain) {
        Assert-True (-not $text.Contains($needle)) "$Label omits secret $needle"
    }
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    Assert-Equal 0 @($parseErrors).Count "$Label parses ($($parseErrors -join '; '))"
}

try {
    Import-Module (Join-Path $connectRoot 'modules/IW.Core.psm1') -Force -Global
    Import-Module (Join-Path $connectRoot 'modules/IW.Render.psm1') -Force -Global
    Import-Module (Join-Path $connectRoot 'modules/IW.Catalog.psm1') -Force -Global
    Import-Module (Join-Path $connectRoot 'modules/IW.CatalogMenu.psm1') -Force -Global
    $defRoot = Join-Path $connectRoot 'modules/Definitions'
    Import-Module (Join-Path $defRoot 'HashiCorp.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitLab.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitHub.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'ActiveDirectory.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'RemoteFileSystem.Entro.psm1') -Force
    Import-Module (Join-Path $connectRoot 'SailPoint.Connect.psd1') -Force

    Register-IntegrationWizardPlatform -Name 'HashiCorpVault' -Title 'HashiCorp Vault' -CoreOptions @('Entro') -CliName 'pwsh'
    Register-IntegrationWizardPlatform -Name 'GitLab' -Title 'GitLab' -CoreOptions @('Connector', 'Entro', 'GitLabSelfManaged') -CliName 'glab'
    Register-IntegrationWizardPlatform -Name 'GitHub' -Title 'GitHub' -CoreOptions @('Connector', 'Entro', 'GhesEntro') -CliName 'gh'
    Register-IntegrationWizardPlatform -Name 'OnPremActiveDirectory' -Title 'On-Prem Active Directory' -CoreOptions @('Entro') -CliName 'pwsh'
    Register-IntegrationWizardPlatform -Name 'RemoteFileSystem' -Title 'Remote File System' -CoreOptions @('Smb', 'Sftp', 'WinRm') -CliName 'pwsh'
    Register-HashiCorpEntroDefinitions
    Register-GitLabEntroDefinitions
    Register-GitHubEntroDefinitions
    Register-ActiveDirectoryEntroDefinitions
    Register-RemoteFileSystemEntroDefinitions

    $vaultDef = Get-IntegrationWizardDefinition -Id 'hashicorp-vault-entro'
    $gitLabCloud = Get-IntegrationWizardDefinition -Id 'gitlab-entro'
    $gitLabSm = Get-IntegrationWizardDefinition -Id 'gitlab-selfmanaged-entro'
    $gitHubCloud = Get-IntegrationWizardDefinition -Id 'github-entro'
    $ghesDef = Get-IntegrationWizardDefinition -Id 'github-ghes-entro'
    $adDef = Get-IntegrationWizardDefinition -Id 'on-prem-active-directory-entro'
    $smbDef = Get-IntegrationWizardDefinition -Id 'remote-file-smb-entro'
    $sftpDef = Get-IntegrationWizardDefinition -Id 'remote-file-sftp-entro'
    $winDef = Get-IntegrationWizardDefinition -Id 'remote-file-winrm-entro'

    Assert-Equal 'pwsh' ([string]$vaultDef.CliName) 'Vault Entro uses pwsh'
    Assert-Equal 'pwsh' ([string]$gitLabCloud.CliName) 'GitLab Entro uses pwsh'
    Assert-Equal 'pwsh' ([string]$gitLabSm.CliName) 'GitLab self-managed uses pwsh'
    Assert-Equal 'gh' ([string]$gitHubCloud.CliName) 'GitHub Cloud Entro stays on gh'
    Assert-Equal 'pwsh' ([string]$ghesDef.CliName) 'GHES Entro uses pwsh'
    Assert-Equal 'pwsh' ([string]$adDef.CliName) 'AD Entro uses pwsh'
    Assert-Equal 'pwsh' ([string]$smbDef.CliName) 'SMB Entro uses pwsh'
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$vaultDef.TargetHost.Role)) 'Vault names a target host'
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$ghesDef.TargetHost.Role)) 'GHES names a target host'
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$adDef.TargetHost.Role)) 'AD names a target host'

    $cloudSteps = @(& $gitHubCloud.Steps @{ Organization = 'acme'; Method = 'GitHubApp' })
    Assert-Equal 1 $cloudSteps.Count 'GitHub Cloud Entro still has one step'
    Assert-Equal 'entro-github-onboard' $cloudSteps[0].Id 'GitHub Cloud step id is unchanged'

    $gitLabEntroTargets = @(Get-IntegrationWizardTargets -Platform 'GitLab' -Context @{ Entro = $true })
    Assert-Equal 1 $gitLabEntroTargets.Count 'GitLab Entro resolves one definition'
    Assert-Equal 'gitlab-entro' $gitLabEntroTargets[0].Id 'GitLab Entro stays gitlab.com'
    $gitLabSmTargets = @(Get-IntegrationWizardTargets -Platform 'GitLab' -Context @{ GitLabSelfManaged = $true })
    Assert-Equal 'gitlab-selfmanaged-entro' $gitLabSmTargets[0].Id 'GitLab self-managed uses its own switch'
    $ghesTargets = @(Get-IntegrationWizardTargets -Platform 'GitHub' -Context @{ GhesEntro = $true })
    Assert-Equal 'github-ghes-entro' $ghesTargets[0].Id 'GHES resolves from GhesEntro'
    $gitHubEntroTargets = @(Get-IntegrationWizardTargets -Platform 'GitHub' -Context @{ Entro = $true })
    Assert-Equal 'github-entro' $gitHubEntroTargets[0].Id 'GitHub Cloud Entro does not collide with GHES'

    $hcl = Get-EntroVaultPolicyHcl -Mode Standard
    Assert-True ($hcl.Contains('path "*"')) 'Standard Vault policy lists path *'
    Assert-True ($hcl.Contains('auth/token/renew-self')) 'Standard Vault policy allows renew-self'
    $tokenBody = Get-EntroVaultTokenCreateBody
    Assert-Equal '30d' ([string]$tokenBody.ttl) 'Vault token ttl is 30d'
    Assert-Equal '30d' ([string]$tokenBody.period) 'Vault token period is 30d'
    Assert-True ([bool]$tokenBody.no_default_policy) 'Vault token drops the default policy'

    $groupScopes = @(Get-EntroGitLabGroupScopes)
    Assert-True ($groupScopes -contains 'read_api') 'GitLab group token includes read_api'
    Assert-True (@(Get-EntroGitLabPersonalScopes) -contains 'api') 'GitLab personal token includes api'
    Assert-True (Test-EntroGitLabHostIsCloud -Url 'https://gitlab.com') 'gitlab.com is the cloud host'
    Assert-True (-not (Test-EntroGitLabHostIsCloud -Url 'https://gitlab.corp.local')) 'private GitLab is not cloud'

    $ghesScopes = Get-EntroGhesClassicScopes
    foreach ($scope in @('repo', 'read:org', 'read:repo_hook', 'user', 'read:discussion')) {
        Assert-True (@($ghesScopes.Required) -contains $scope) "GHES required scope $scope"
    }
    Assert-Equal 'https://github.corp.local/api/v3' (Get-EntroGhesApiBase -Hostname 'github.corp.local') 'GHES API base strips no extra port'

    Assert-Equal 4 @(Get-EntroAdLdapsPorts).Count 'AD probe covers four directory ports'
    Assert-Equal 'files.corp.local:445' (ConvertTo-EntroShareUrl -HostOrUrl 'files.corp.local') 'SMB url gains :445'
    $smbJson = New-EntroSmbSharesJson -Nickname 'finance' -User 'CORP\entro' -Password 'secret' -Url 'files.corp.local' -IgnoreShares @('C$')
    Assert-True ($smbJson.TrimStart().StartsWith('[')) 'SMB handoff JSON is an array'
    Assert-True ($smbJson.Contains('ignore_shares')) 'SMB JSON includes ignore_shares'
    Assert-True ($smbJson.Contains('files.corp.local:445')) 'SMB JSON url includes the port'

    $vaultBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'hashicorp-vault' -Product 'entro' -VariantId 'vault'
    $gitLabCloudBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'gitlab' -Product 'entro' -VariantId 'gitlab'
    $gitLabSmBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'gitlab' -Product 'entro' -VariantId 'self-managed'
    $ghesBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'github' -Product 'entro' -VariantId 'ghes'
    $adBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'on-prem-active-directory' -Product 'entro' -VariantId 'ad'
    $smbBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'remote-file-system' -Product 'entro' -VariantId 'smb'
    $sftpBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'remote-file-system' -Product 'entro' -VariantId 'sftp'
    $winBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'remote-file-system' -Product 'entro' -VariantId 'winrm'
    Assert-True ([bool]$vaultBinding.RequiresOutpost) 'Vault requires an Outpost'
    Assert-True (-not [bool]$gitLabCloudBinding.RequiresOutpost) 'gitlab.com does not require an Outpost'
    Assert-True ([bool]$gitLabSmBinding.RequiresOutpost) 'self-managed GitLab requires an Outpost'
    Assert-True ([bool]$ghesBinding.RequiresOutpost) 'GHES requires an Outpost'
    Assert-True ([bool]$adBinding.RequiresOutpost) 'AD requires an Outpost'
    Assert-True ([bool]$smbBinding.RequiresOutpost) 'SMB requires an Outpost'
    Assert-True ([bool]$sftpBinding.RequiresOutpost) 'SFTP requires an Outpost'
    Assert-True ([bool]$winBinding.RequiresOutpost) 'WinRM requires an Outpost'
    Assert-Equal 'pwsh' ([string]$vaultBinding.Cli) 'Vault catalog cli is pwsh'

    $ghesBinding['SelectedCredentialKind'] = 'github.ghesPat'
    $ghesLaunch = Get-IntegrationCatalogLegacyLaunchParameters -Binding $ghesBinding -Product 'entro'
    Assert-True ([bool]$ghesLaunch['GhesEntro']) 'GHES catalog launch uses GhesEntro'
    Assert-True (-not $ghesLaunch.Contains('Entro')) 'GHES catalog launch does not also set Entro'
    Assert-True (-not $ghesLaunch.Contains('Method')) 'GHES catalog launch does not set Method'
    $smLaunch = Get-IntegrationCatalogLegacyLaunchParameters -Binding $gitLabSmBinding -Product 'entro'
    Assert-True ([bool]$smLaunch['GitLabSelfManaged']) 'self-managed GitLab launch uses GitLabSelfManaged'
    $smbLaunch = Get-IntegrationCatalogLegacyLaunchParameters -Binding $smbBinding -Product 'entro'
    Assert-True ([bool]$smbLaunch['Smb']) 'SMB catalog launch uses Smb'
    $sftpLaunch = Get-IntegrationCatalogLegacyLaunchParameters -Binding $sftpBinding -Product 'entro'
    Assert-True ([bool]$sftpLaunch['Sftp']) 'SFTP catalog launch uses Sftp'
    $winLaunch = Get-IntegrationCatalogLegacyLaunchParameters -Binding $winBinding -Product 'entro'
    Assert-True ([bool]$winLaunch['WinRm']) 'WinRM catalog launch uses WinRm'

    $common = @{ NonInteractive = $true; Project = 'wave1' }
    $vaultOut = Join-Path $tmp 'vault'
    $gitLabOut = Join-Path $tmp 'gitlab'
    $gitLabSmOut = Join-Path $tmp 'gitlab-sm'
    $ghesOut = Join-Path $tmp 'ghes'
    $adOut = Join-Path $tmp 'ad'
    $smbOut = Join-Path $tmp 'smb'
    $sftpOut = Join-Path $tmp 'sftp'
    $winOut = Join-Path $tmp 'winrm'
    foreach ($dir in @($vaultOut, $gitLabOut, $gitLabSmOut, $ghesOut, $adOut, $smbOut, $sftpOut, $winOut)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $vaultResult = @(Connect-SailPointHashiCorpVault -Entro -Action BuildScript @common -Environment 'prod' -VaultUrl 'https://vault.corp.local:8200' -PolicyMode Standard -OutputDirectory $vaultOut)
    Assert-Equal 1 $vaultResult.Count 'Vault BuildScript returns one object'
    Assert-GeneratedScript -Path $vaultResult[0].Path -Label 'Vault script' -MustContain @('path "*"', '/v1/auth/token/create', 'entro-policy')

    $gitLabResult = @(Connect-SailPointGitLab -Entro -Action BuildScript @common -Nickname 'cloud' -GitLabUrl 'https://gitlab.com' -OutputDirectory $gitLabOut)
    Assert-Equal 1 $gitLabResult.Count 'GitLab cloud BuildScript returns one object'
    Assert-GeneratedScript -Path $gitLabResult[0].Path -Label 'GitLab cloud script' -MustContain @('/api/v4/groups/', 'access_tokens', 'entro_svc')

    $gitLabSmResult = @(Connect-SailPointGitLab -GitLabSelfManaged -Action BuildScript @common -Nickname 'corp' -GitLabUrl 'https://gitlab.corp.local' -OutputDirectory $gitLabSmOut)
    Assert-Equal 1 $gitLabSmResult.Count 'GitLab self-managed BuildScript returns one object'
    Assert-GeneratedScript -Path $gitLabSmResult[0].Path -Label 'GitLab self-managed script' -MustContain @('gitlab.com belongs on the Entro GitLab cloud variant', 'access_tokens')

    $ghesResult = @(Connect-SailPointGitHub -GhesEntro -Action BuildScript @common -DisplayName 'Corp GHES' -Hostname 'github.corp.local' -EnvironmentType Development -OutputDirectory $ghesOut)
    Assert-Equal 1 $ghesResult.Count 'GHES BuildScript returns one object'
    Assert-GeneratedScript -Path $ghesResult[0].Path -Label 'GHES script' -MustContain @('/api/v3/user', 'repo')

    $adResult = @(Connect-SailPointOnPremActiveDirectory -Entro -Action BuildScript @common -Nickname 'corp-ad' -DomainController 'dc01' -DcFqdn 'dc01.corp.local' -Domain 'corp.local' -EnvironmentNickname 'corp' -OutputDirectory $adOut)
    Assert-Equal 1 $adResult.Count 'AD BuildScript returns one object'
    Assert-GeneratedScript -Path $adResult[0].Path -Label 'AD script' -MustContain @('svc_entro', 'New-ADUser')

    $smbResult = @(Connect-SailPointRemoteFileSystem -Smb -Action BuildScript @common -Nickname 'finance' -Username 'CORP\entro_smb' -ShareHost 'files.corp.local' -OutputDirectory $smbOut)
    Assert-Equal 1 $smbResult.Count 'SMB BuildScript returns one object'
    Assert-GeneratedScript -Path $smbResult[0].Path -Label 'SMB script' -MustContain @('ignore_shares', 'smb-file-shares.json')

    $sftpResult = @(Connect-SailPointRemoteFileSystem -Sftp -Action BuildScript @common -Nickname 'drops' -FileHost 'sftp.corp.local' -OutputDirectory $sftpOut)
    Assert-Equal 1 $sftpResult.Count 'SFTP BuildScript returns one object'
    Assert-GeneratedScript -Path $sftpResult[0].Path -Label 'SFTP script' -MustContain @('ssh-keygen -t ed25519', '-N ''''', 'sftpPort = 22')

    $winResult = @(Connect-SailPointRemoteFileSystem -WinRm -Action BuildScript @common -Nickname 'win' -FileHost 'win.corp.local' -OutputDirectory $winOut)
    Assert-Equal 1 $winResult.Count 'WinRM BuildScript returns one object'
    Assert-GeneratedScript -Path $winResult[0].Path -Label 'WinRM script' -MustContain @('5985', 'Remote Management Users')

    Import-Module (Join-Path $defRoot 'HashiCorp.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitLab.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitHub.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'ActiveDirectory.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'RemoteFileSystem.Entro.psm1') -Force
    Import-Module (Join-Path $connectRoot 'modules/IW.Core.psm1') -Force -Global
    Import-Module (Join-Path $connectRoot 'modules/IW.Render.psm1') -Force -Global
    Register-HashiCorpEntroDefinitions
    Register-GitLabEntroDefinitions
    Register-GitHubEntroDefinitions
    Register-ActiveDirectoryEntroDefinitions
    Register-RemoteFileSystemEntroDefinitions
    $redactDir = Join-Path $tmp 'redact'
    New-Item -ItemType Directory -Path $redactDir -Force | Out-Null
    $vaultSecret = 'plant-vault-admin-9f3a'
    $gitLabSecret = 'plant-gitlab-admin-9f3a'
    $ghesSecret = 'plant-ghes-token-9f3a'
    $adSecret = 'plant-ad-password-9f3a'
    $smbSecret = 'plant-smb-password-9f3a'
    $winSecret = 'plant-winrm-password-9f3a'
    $redactions = @(
        @{ Def = (Get-IntegrationWizardDefinition -Id 'hashicorp-vault-entro'); Name = 'vault'; Context = @{ Environment = 'prod'; VaultUrl = 'https://vault.corp.local:8200'; PolicyMode = 'Standard'; VaultAdminToken = $vaultSecret; OutputDirectory = $redactDir }; Secret = $vaultSecret; Need = @('/v1/auth/token/create') }
        @{ Def = (Get-IntegrationWizardDefinition -Id 'gitlab-selfmanaged-entro'); Name = 'gitlab'; Context = @{ Nickname = 'corp'; GitLabUrl = 'https://gitlab.corp.local'; TokenKind = 'Group'; AdminToken = $gitLabSecret; OutputDirectory = $redactDir }; Secret = $gitLabSecret; Need = @('access_tokens') }
        @{ Def = (Get-IntegrationWizardDefinition -Id 'github-ghes-entro'); Name = 'ghes'; Context = @{ DisplayName = 'Corp'; Hostname = 'github.corp.local'; EnvironmentType = 'Development'; Token = $ghesSecret; OutputDirectory = $redactDir }; Secret = $ghesSecret; Need = @('/api/v3/user') }
        @{ Def = (Get-IntegrationWizardDefinition -Id 'on-prem-active-directory-entro'); Name = 'ad'; Context = @{ Nickname = 'corp-ad'; DomainController = 'dc01'; DcFqdn = 'dc01.corp.local'; Domain = 'corp.local'; EnvironmentNickname = 'corp'; Password = $adSecret; OutputDirectory = $redactDir }; Secret = $adSecret; Need = @('svc_entro') }
        @{ Def = (Get-IntegrationWizardDefinition -Id 'remote-file-smb-entro'); Name = 'smb'; Context = @{ Nickname = 'finance'; Username = 'CORP\entro_smb'; ShareHost = 'files.corp.local'; Password = $smbSecret; OutputDirectory = $redactDir }; Secret = $smbSecret; Need = @('ignore_shares') }
        @{ Def = (Get-IntegrationWizardDefinition -Id 'remote-file-winrm-entro'); Name = 'winrm'; Context = @{ Nickname = 'win'; FileHost = 'win.corp.local'; Password = $winSecret; OutputDirectory = $redactDir }; Secret = $winSecret; Need = @('5985') }
    )
    foreach ($item in $redactions) {
        $path = Join-Path $redactDir "$($item.Name).ps1"
        New-IntegrationWizardBuildScript -Definition $item.Def -Context $item.Context -OutputPath $path | Out-Null
        Assert-GeneratedScript -Path $path -Label "$($item.Name) redaction" -MustContain $item.Need -MustNotContain @($item.Secret)
    }
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_ROOT -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "PASS ($script:AssertionCount assertions)"

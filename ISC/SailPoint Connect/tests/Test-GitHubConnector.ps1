#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/ISC.GitHubConnector.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitHub.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitHub.Entro.psm1') -Force

Initialize-OperatorConsole -NonInteractive
Register-IntegrationWizardPlatform -Name 'GitHub' -Title 'GitHub' -CoreOptions @('Connector', 'Entro') -CliName 'gh'
Register-GitHubConnectorDefinitions
Register-GitHubEntroDefinitions

# 1. Verify connector definition
$def = Get-IntegrationWizardDefinition -Id 'github-connector'
Assert-True ($null -ne $def) 'GitHub connector definition is registered'
Assert-Equal 'GitHub' $def.Platform 'Platform is GitHub'
Assert-Equal 'Connector' $def.CoreSwitch 'Core switch is Connector'
Assert-Equal 'gh' $def.CliName 'CLI is gh'

# 2. Verify feature packs & Copilot/AgentDiscovery
$packs = Get-GitHubFeaturePacks
Assert-True ($packs.ContainsKey('AgentDiscovery')) 'AgentDiscovery feature pack exists'
Assert-True ($packs.ContainsKey('ActivityInsights')) 'ActivityInsights feature pack exists'

$copilot = Get-GitHubAgentDiscoveryFeaturePack
Assert-Equal 'AgentDiscovery' $copilot.Name 'AgentDiscovery name matches'
Assert-True ($copilot.Label -like '*Copilot*') 'AgentDiscovery label highlights Copilot'

# 3. Verify checklist and connection settings
$checklist = Get-GitHubIscFeatureChecklist -FeatureNames @('AgentDiscovery')
Assert-True (($checklist -join ' ') -like '*Copilot*') 'Checklist includes Copilot'
Assert-True (($checklist -join ' ') -like '*Agentic Fabric*') 'Checklist requires Agentic Fabric'

$connSettings = Build-GitHubConnectionSettings -Organization 'acme-corp' -AuthMethod 'PersonalAccessToken' -FeatureNames @('AgentDiscovery')
Assert-True ($connSettings -like '*Organization: acme-corp*') 'Organization in connection settings'
Assert-True ($connSettings -like '*Machine Identity & Agent Discovery*') 'Agent discovery section in settings'

# 4. Verify step generation
$baseCtx = @{ Organization = 'acme-corp'; AuthMethod = 'PersonalAccessToken' }
$stepsBase = @(& $def.Steps $baseCtx)
Assert-Equal 1 $stepsBase.Count 'Base connector has 1 step'
Assert-Equal 'github-auth-check' $stepsBase[0].Id 'Base step is github-auth-check'

$agentCtx = @{ Organization = 'acme-corp'; AuthMethod = 'PersonalAccessToken'; Feature = 'AgentDiscovery' }
$stepsAgent = @(& $def.Steps $agentCtx)
Assert-Equal 2 $stepsAgent.Count 'AgentDiscovery adds copilot/bot step'
Assert-Equal 'github-copilot-bot-discovery' $stepsAgent[1].Id 'Second step is github-copilot-bot-discovery'

# 5. Run steps
$runCtx = $agentCtx.Clone()
foreach ($step in $stepsAgent) {
    $probe = & $step.Probe $runCtx
    Assert-Equal 'Skip' $probe 'Probe skips when required inputs exist'
    & $step.Run $runCtx
}
$record = Get-GitHubRunRecord -Context $runCtx
Assert-Equal 'Verified' $record.AuthResult 'Auth marked verified'
Assert-Equal 'Configured' $record.AgentDiscovery 'AgentDiscovery marked configured'

# 6. Verify Entro GitHub definition
$entroDef = Get-IntegrationWizardDefinition -Id 'github-entro'
Assert-True ($null -ne $entroDef) 'Entro GitHub definition is registered'
Assert-Equal 'Entro' $entroDef.Product 'Entro definition product is Entro'
$entroSteps = @(& $entroDef.Steps @{ Organization = 'acme-corp'; Method = 'GitHubApp' })
Assert-Equal 1 $entroSteps.Count 'Entro GitHub has 1 step'
Assert-Equal 'entro-github-onboard' $entroSteps[0].Id 'Entro step is entro-github-onboard'

# 7. Verify optional Organization
$connOrgInput = @($def.Inputs | Where-Object { $_.Name -eq 'Organization' })[0]
Assert-Equal $false ([bool]$connOrgInput.Required) 'Connector definition Organization is optional'

$entroOrgInput = @($entroDef.Inputs | Where-Object { $_.Name -eq 'Organization' })[0]
Assert-Equal $false ([bool]$entroOrgInput.Required) 'Entro definition Organization is optional'

$connSettingsNoOrg = Build-GitHubConnectionSettings -AuthMethod 'PersonalAccessToken'
Assert-True ($connSettingsNoOrg.Contains('Organization: [Your-GitHub-Organization]')) 'Connection settings placeholder when Organization omitted'

$noOrgCtx = @{ AuthMethod = 'PersonalAccessToken' }
$noOrgSteps = @(& $def.Steps $noOrgCtx)
Assert-Equal 'Skip' (& $noOrgSteps[0].Probe $noOrgCtx) 'Probe succeeds without Organization'
& $noOrgSteps[0].Run $noOrgCtx

Import-Module (Join-Path $wizardRoot 'modules/IW.Check.psm1') -Force
$checkConnNoOrg = Get-IntegrationCheckSubject -Definition $def -Context @{}
Assert-Equal 'GitHub PAT (CLI session / token)' $checkConnNoOrg.Name 'Check subject name handles omitted Organization'

$checkEntroNoOrg = Get-IntegrationCheckSubject -Definition $entroDef -Context @{}
Assert-Equal 'GitHub PAT (CLI session / token)' $checkEntroNoOrg.Name 'Entro check subject name handles omitted Organization'

$checkWithToken = Get-IntegrationCheckSubject -Definition $entroDef -Context @{ Token = 'ghp_1234567890abcdef' }
Assert-Equal 'PAT (ghp_...cdef)' $checkWithToken.Name 'Check subject masks token'
Assert-Equal 'GitHubToken' $checkWithToken.Kind 'Check subject kind is GitHubToken'
Assert-True $checkWithToken.Readable 'GitHubToken subject is marked readable'

# 8. Test Check execution for GitHub PAT
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("gh-check-test-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

# Case 8a: Passing PAT (has repo and read:org)
Set-IntegrationCheckInvoker {
    param($cmd, $args)
    return @{
        ExitCode = 0
        Output = "HTTP/2.0 200 OK`r`nX-OAuth-Scopes: repo, read:org, workflow`r`n`r`n{`"login`": `"testuser`"}"
    }
}
$passReport = Join-Path $tmp 'gh-pass.md'
$passRes = Invoke-IntegrationRequirementCheck -Definition $entroDef -Context @{ Token = 'ghp_valid1234567890' } -OutputPath $passReport
Assert-Equal 'Pass' $passRes.Verdict 'PAT with repo and read:org passes Check'
$passContent = Get-Content -LiteralPath $passReport -Raw
Assert-True ($passContent -match 'Meets the requirements') 'Report states requirements met'
Assert-True ($passContent -match 'testuser') 'Report identifies verified user'

# Case 8b: Gaps in PAT (missing read:org)
Set-IntegrationCheckInvoker {
    param($cmd, $args)
    return @{
        ExitCode = 0
        Output = "HTTP/2.0 200 OK`r`nX-OAuth-Scopes: repo, gist`r`n`r`n{`"login`": `"testuser`"}"
    }
}
$failReport = Join-Path $tmp 'gh-gap.md'
$failRes = Invoke-IntegrationRequirementCheck -Definition $entroDef -Context @{ Token = 'ghp_gap1234567890' } -OutputPath $failReport
Assert-Equal 'Fail' $failRes.Verdict 'PAT missing read:org fails Check'
$failContent = Get-Content -LiteralPath $failReport -Raw
Assert-True ($failContent -match 'Does not meet the requirements') 'Report states does not meet requirements'
Assert-True ($failContent -match 'read:org') 'Report calls out missing read:org scope'

# Case 8c: Invalid/expired PAT (401 Bad credentials)
Set-IntegrationCheckInvoker {
    param($cmd, $args)
    return @{
        ExitCode = 1
        Output = "HTTP/2.0 401 Unauthorized`r`n`r`n{`"message`": `"Bad credentials`"}"
    }
}
$badReport = Join-Path $tmp 'gh-bad.md'
$badRes = Invoke-IntegrationRequirementCheck -Definition $entroDef -Context @{ Token = 'ghp_bad1234567890' } -OutputPath $badReport
Assert-Equal 'Fail' $badRes.Verdict 'Expired/bad PAT fails Check'
$badContent = Get-Content -LiteralPath $badReport -Raw
Assert-True ($badContent -match 'Bad credentials') 'Report notes bad credentials'

# Case 8d: Fine-grained PAT missing organization access
Set-IntegrationCheckInvoker {
    param($cmd, [string[]]$arguments)
    if ($arguments -contains '/user') {
        return @{
            ExitCode = 0
            Output = "HTTP/2.0 200 OK`r`n`r`n{`"login`": `"testuser`"}"
        }
    }
    if ($arguments -contains '/user/orgs?per_page=1') {
        return @{
            ExitCode = 0
            Output = "HTTP/2.0 200 OK`r`n`r`n[]"
        }
    }
    if ($arguments -contains '/user/repos?per_page=1') {
        return @{
            ExitCode = 0
            Output = "HTTP/2.0 200 OK`r`n`r`n[{`"name`": `"my-repo`"}]"
        }
    }
    return @{ ExitCode = 0; Output = "HTTP/2.0 200 OK`r`n`r`n{}" }
}
$fgGapReport = Join-Path $tmp 'gh-fg-gap.md'
$fgGapRes = Invoke-IntegrationRequirementCheck -Definition $entroDef -Context @{ Token = 'github_pat_11AAAABBBBCCCC' } -OutputPath $fgGapReport
Assert-Equal 'Fail' $fgGapRes.Verdict 'Fine-grained PAT missing org fails Check'
$fgGapContent = Get-Content -LiteralPath $fgGapReport -Raw
Assert-True ($fgGapContent -match 'Does not meet the requirements') 'Fine-grained PAT report states does not meet requirements'
Assert-True ($fgGapContent -match 'read:org') 'Report calls out missing read:org'
Assert-True ($fgGapContent -match 'repo') 'Report mentions repo'

# Case 8e: Fine-grained PAT with verified org and repo access
Set-IntegrationCheckInvoker {
    param($cmd, [string[]]$arguments)
    if ($arguments -contains '/user') {
        return @{
            ExitCode = 0
            Output = "HTTP/2.0 200 OK`r`n`r`n{`"login`": `"testuser`"}"
        }
    }
    if ($arguments -contains '/orgs/acme-corp') {
        return @{
            ExitCode = 0
            Output = "HTTP/2.0 200 OK`r`n`r`n{`"login`": `"acme-corp`"}"
        }
    }
    if ($arguments -contains '/orgs/acme-corp/repos?per_page=1') {
        return @{
            ExitCode = 0
            Output = "HTTP/2.0 200 OK`r`n`r`n[{`"name`": `"backend`"}]"
        }
    }
    return @{ ExitCode = 0; Output = "HTTP/2.0 200 OK`r`n`r`n{}" }
}
$fgPassReport = Join-Path $tmp 'gh-fg-pass.md'
$fgPassRes = Invoke-IntegrationRequirementCheck -Definition $entroDef -Context @{ Token = 'github_pat_11AAAABBBBCCCC'; Organization = 'acme-corp' } -OutputPath $fgPassReport
Assert-Equal 'Pass' $fgPassRes.Verdict 'Fine-grained PAT with verified org and repo passes Check'
$fgPassContent = Get-Content -LiteralPath $fgPassReport -Raw
Assert-True ($fgPassContent -match 'Meets the requirements') 'Fine-grained PAT report states meets requirements'
Assert-True ($fgPassContent -match 'read:org') 'Report lists read:org'
Assert-True ($fgPassContent -match 'repo') 'Report lists repo'

# Case 8f: Fine-grained PAT with SAML SSO required
Set-IntegrationCheckInvoker {
    param($cmd, [string[]]$arguments)
    if ($arguments -contains '/user') {
        return @{
            ExitCode = 0
            Output = "HTTP/2.0 200 OK`r`n`r`n{`"login`": `"testuser`"}"
        }
    }
    if ($arguments -contains '/orgs/acme-corp') {
        return @{
            ExitCode = 1
            Output = "HTTP/2.0 403 Forbidden`r`nX-GitHub-SSO: required; url=https://github.com/orgs/acme-corp/sso`r`n`r`n{`"message`": `"Resource protected by organization SAML enforcement`"}"
        }
    }
    if ($arguments -contains '/orgs/acme-corp/repos?per_page=1') {
        return @{
            ExitCode = 1
            Output = "HTTP/2.0 403 Forbidden`r`nX-GitHub-SSO: required; url=https://github.com/orgs/acme-corp/sso`r`n`r`n{`"message`": `"Resource protected by organization SAML enforcement`"}"
        }
    }
    return @{ ExitCode = 0; Output = "HTTP/2.0 200 OK`r`n`r`n{}" }
}
$ssoReport = Join-Path $tmp 'gh-sso.md'
$ssoRes = Invoke-IntegrationRequirementCheck -Definition $entroDef -Context @{ Token = 'github_pat_11AAAABBBBCCCC'; Organization = 'acme-corp' } -OutputPath $ssoReport
Assert-Equal 'Fail' $ssoRes.Verdict 'PAT with SAML SSO required fails Check'
$ssoContent = Get-Content -LiteralPath $ssoReport -Raw
Assert-True ($ssoContent -match 'Does not meet the requirements') 'SSO report states does not meet requirements'
Assert-True ($ssoContent -match 'SAML SSO') 'Report notes SAML SSO requirement'
Assert-True ($ssoContent -match 'read:org') 'Report calls out missing read:org'

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Set-IntegrationCheckInvoker $null

Write-Host "PASS ($script:AssertionCount assertions)"

Set-StrictMode -Version Latest

function Get-EntroAzureOnboardingScriptPath {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue
    Join-Path (Get-EntroConnectSkillRoot) 'integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1'
}

function Register-AzureEntroDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'azure-entro'
        Platform     = 'Azure'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'az'
        Title        = 'Entro Microsoft ecosystem integration'
        FolderName   = 'Entro-Microsoft'
        AccessLevels = @()
        AdminRoles   = @('Global Administrator (Entro onboarding script)')
        OutputsHelp  = 'Paste Environment nickname, Tenant ID, Client ID, and Client Secret at https://app.entro.security/admin/account/add/2'
        Inputs       = @(
            @{ Name = 'EnvironmentNickname'; Source = 'Supply'; Prompt = 'Environment nickname'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'DisplayName'; Source = 'Supply'; Prompt = 'App display name'; Purpose = 'Entra application name'; Required = $false; Default = 'EntroSecurityApp' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-azure-onboard'
                    Title = 'Run Entro Azure onboarding'
                    Kind  = 'Ensure'
                    Run   = {
                        param($c)
                        $scriptPath = Get-EntroAzureOnboardingScriptPath
                        if (-not (Test-Path -LiteralPath $scriptPath)) {
                            throw "Entro Azure onboarding script not found: $scriptPath"
                        }
                        Write-Info "Launching Entro Azure onboarding menu (Global Administrator required)."
                        & pwsh -NoProfile -File $scriptPath
                        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                            throw "Entro-Azure-Onboarding.ps1 exited with code $LASTEXITCODE"
                        }
                    }
                    BuildScript = {
                        param($c)
                        $scriptPath = Get-EntroAzureOnboardingScriptPath
                        @"
# Entro Azure onboarding (interactive menu)
& pwsh -NoProfile -File '$($scriptPath -replace "'", "''")'
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Environment: $($ctx['EnvironmentNickname'])"
            Write-Host '  Tenant ID, Client ID, Client Secret: from onboarding output'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-AzureEntroDefinitions, Get-EntroAzureOnboardingScriptPath

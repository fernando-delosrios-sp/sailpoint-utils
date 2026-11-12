Set-StrictMode -Version Latest

function Register-HashiCorpEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'hashicorp-vault-entro'
        Platform     = 'HashiCorpVault'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'vault'
        Title        = 'Entro HashiCorp Vault integration'
        FolderName   = 'Entro-HashiCorp-Vault'
        AccessLevels = @()
        AdminRoles   = @('Vault operator (policy + token create)')
        OutputsHelp  = 'Paste Environment, Vault server URL, and access token into Entro.'
        Inputs       = @(
            @{ Name = 'Environment'; Source = 'Supply'; Prompt = 'Environment label'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'VaultUrl'; Source = 'Supply'; Prompt = 'Vault server URL'; Purpose = 'https://vault.example.com:8200'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'VaultUrl'; Source = 'Supply'; Prompt = 'Vault server URL'; Purpose = 'Cluster to verify'; Required = $true }
            @{ Name = 'AccessToken'; Source = 'Supply'; Prompt = 'Vault access token'; Purpose = 'entro-policy token'; Required = $true; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-vault-policy'
                    Title = 'Create entro-policy and renewable token'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'Entro Vault ACL'
                        Write-Info "Write entro-policy on $($c['VaultUrl']) with list/read capabilities from Entro docs."
                        Write-Info 'Create renewable token: vault token create -policy=entro-policy'
                    }
                    BuildScript = {
                        param($c)
                        @"
# vault policy write entro-policy entro-acl.hcl
# vault token create -policy=entro-policy -renewable
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Environment: $($ctx['Environment'])"
            Write-Host "  Vault URL: $($ctx['VaultUrl'])"
            Write-Host '  Access token: entro-policy token (vault)'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-HashiCorpEntroDefinitions

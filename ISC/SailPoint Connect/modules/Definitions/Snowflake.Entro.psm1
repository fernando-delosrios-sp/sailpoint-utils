Set-StrictMode -Version Latest

function Register-SnowflakeEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'snowflake-entro'
        Platform     = 'Snowflake'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'snow'
        Title        = 'Entro Snowflake integration'
        FolderName   = 'Entro-Snowflake'
        AccessLevels = @()
        AdminRoles   = @('Snowflake ACCOUNTADMIN or SECURITYADMIN')
        OutputsHelp  = 'Paste Environment, Display Name, and Account URL into Entro after key-pair user setup.'
        Inputs       = @(
            @{ Name = 'Environment'; Source = 'Supply'; Prompt = 'Environment label'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'DisplayName'; Source = 'Supply'; Prompt = 'Display name in Entro'; Purpose = 'Operator-chosen label'; Required = $true }
            @{ Name = 'AccountUrl'; Source = 'Supply'; Prompt = 'Snowflake account URL'; Purpose = 'https://account.snowflakecomputing.com'; Required = $true }
            @{ Name = 'EntroUser'; Source = 'Supply'; Prompt = 'Snowflake username for Entro'; Purpose = 'User created for Entro (default ENTRO)'; Required = $false; Default = 'ENTRO' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'AccountUrl'; Source = 'Supply'; Prompt = 'Snowflake account URL'; Purpose = 'Account to verify'; Required = $true }
            @{ Name = 'EntroUser'; Source = 'Supply'; Prompt = 'Snowflake username for Entro'; Purpose = 'User to verify'; Required = $false; Default = 'ENTRO' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-snowflake-user'
                    Title = 'Create Entro Snowflake user with key-pair auth'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $user = if ($c['EntroUser']) { $c['EntroUser'] } else { 'ENTRO' }
                        Write-Step 'Entro Snowflake user'
                        Write-Info "Create Snowflake user $user with RSA key-pair and Entro-documented role grants."
                        Write-Info "Account: $($c['AccountUrl'])"
                    }
                    BuildScript = {
                        param($c)
                        $user = if ($c['EntroUser']) { $c['EntroUser'] } else { 'ENTRO' }
                        @"
# Entro Snowflake: CREATE USER $user WITH RSA_PUBLIC_KEY=...; GRANT ROLE ...
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
            Write-Host "  Display Name: $($ctx['DisplayName'])"
            Write-Host "  Account URL: $($ctx['AccountUrl'])"
            Write-Host "  User: $(if ($ctx['EntroUser']) { $ctx['EntroUser'] } else { 'ENTRO' })"
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-SnowflakeEntroDefinitions

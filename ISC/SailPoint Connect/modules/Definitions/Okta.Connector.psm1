Set-StrictMode -Version Latest

$script:OktaFabricMandatoryScopes = @(
    'okta.logs.read'
    'okta.users.manage'
    'okta.groups.manage'
    'okta.appGrants.read'
    'okta.apiTokens.read'
)

function Register-OktaConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'okta-connector'
        Platform     = 'Okta'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'okta'
        Title        = 'Okta SaaS connector & Admin API token discovery'
        FolderName   = 'Okta'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Okta Super Administrator (Custom service app + API scopes)')
        OutputsHelp  = 'Paste Okta domain, OAuth client ID, JWT header, PEM private key, scopes, and token URL into Agentic Fabric / ISC Connection Settings.'
        Inputs       = @(
            @{ Name = 'OktaDomain'; Source = 'Supply'; Prompt = 'Okta org URL'; Purpose = 'e.g. https://yourOrg.okta.com'; Required = $true }
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'OAuth 2.0 service app Client ID'; Purpose = 'JWT issuer and subject'; Required = $true }
            @{ Name = 'TokenUrl'; Source = 'Supply'; Prompt = 'OAuth 2.0 token URL'; Purpose = 'Usually https://{domain}/oauth2/v1/token'; Required = $false }
            @{ Name = 'Scope'; Source = 'Supply'; Prompt = 'Granted scopes (space-separated)'; Purpose = 'Mandatory Agentic Fabric scopes'; Required = $false; Default = ($script:OktaFabricMandatoryScopes -join ' ') }
            @{ Name = 'JwtHeader'; Source = 'Supply'; Prompt = 'JWT header JSON'; Purpose = 'Algorithm used to sign the client assertion'; Required = $false }
            @{ Name = 'PrivateKey'; Source = 'Supply'; Prompt = 'Private key (PEM)'; Purpose = 'Service app private key; include BEGIN/END lines'; Required = $true; Secret = $true }
            @{ Name = 'PrivateKeyPassword'; Source = 'Supply'; Prompt = 'Private key password (optional)'; Purpose = 'If the PEM key is encrypted'; Required = $false; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings file path'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'OktaDomain'; Source = 'Supply'; Prompt = 'Okta org URL'; Purpose = 'Org to verify'; Required = $true }
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'OAuth 2.0 service app Client ID'; Purpose = 'Client ID to verify'; Required = $true }
            @{ Name = 'PrivateKey'; Source = 'Supply'; Prompt = 'Private key (PEM)'; Purpose = 'Key to verify JWT auth'; Required = $true; Secret = $true }
            @{ Name = 'Scope'; Source = 'Supply'; Prompt = 'Granted scopes (space-separated)'; Purpose = 'Scopes to verify'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'okta-service-app'
                    Title = 'Create Okta service app with JWT auth and mandatory scopes'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'Okta service application'
                        $domain = [string]$c['OktaDomain']
                        Write-Info "Create an OAuth 2.0 service app in $domain with admin roles and a JWKS key pair."
                        Write-Info "Grant scopes: $($script:OktaFabricMandatoryScopes -join ', ')"
                        Write-Info 'Sign a JWT assertion; Client ID is both Issuer and Subject in Agentic Fabric.'
                    }
                    BuildScript = {
                        param($c)
                        $scopes = if ($c['Scope']) { [string]$c['Scope'] } else { ($script:OktaFabricMandatoryScopes -join ' ') }
                        @"
# Okta SaaS connector — service app checklist for '$($c['OktaDomain'])'
Write-Host 'Required scopes: $scopes'
Write-Host 'Token URL: https://{yourOktaDomain}/oauth2/v1/token'
Write-Host 'Convert JWK private keys to PEM before pasting into ISC.'
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $tokenUrl = if ($ctx['TokenUrl']) { $ctx['TokenUrl'] } else { "https://$(([uri]$ctx['OktaDomain']).Host)/oauth2/v1/token" }
            Write-Host ''
            Write-Host 'Okta SaaS connector handoff' -ForegroundColor Cyan
            Write-Host "  Okta URL: $($ctx['OktaDomain'])"
            Write-Host "  Token URL: $tokenUrl"
            Write-Host "  Client ID: $($ctx['ClientId'])"
            Write-Host "  Scopes: $(if ($ctx['Scope']) { $ctx['Scope'] } else { ($script:OktaFabricMandatoryScopes -join ' ') })"
            Write-Host '  Private key: [stored in vault]'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-OktaConnectorDefinitions

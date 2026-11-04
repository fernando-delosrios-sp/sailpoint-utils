#Requires -Version 5.1
Set-StrictMode -Version Latest

function Initialize-EntraCiemConnectorData {
    $script:EmbeddedCiemFeaturePack = @{
        Label       = 'CIEM - PIM group eligibility'
        Permissions = @(
            @{ Value = 'PrivilegedAccess.Read.AzureADGroup' }
            @{ Value = 'PrivilegedAssignmentSchedule.Read.AzureADGroup' }
            @{ Value = 'PrivilegedEligibilitySchedule.Read.AzureADGroup' }
        )
    }
}

function Test-EmbeddedCiemSelected {
    param([string[]]$FeatureNames)
    return @($FeatureNames) -contains 'Ciem'
}

function Get-EmbeddedCiemFeaturePack {
    return $script:EmbeddedCiemFeaturePack
}

function Merge-EntraCiemPermissions {
    param([string[]]$FeatureNames)

    if (-not (Test-EmbeddedCiemSelected -FeatureNames $FeatureNames)) {
        return @()
    }

    $merged = [System.Collections.Generic.List[object]]::new()
    foreach ($permission in $script:EmbeddedCiemFeaturePack.Permissions) {
        $merged.Add([PSCustomObject]@{
            Resource = 'Graph'
            Value    = $permission.Value
            Pack     = 'Ciem'
        })
    }
    return @($merged)
}

function Apply-EmbeddedCiemPrerequisites {
    param($Context)
    # Entra embedded CIEM is Graph application permissions only; granted via Get-SelectedPermissions.
    if (-not (Test-EmbeddedCiemSelected -FeatureNames $Context.FeatureNames)) { return }
    Write-Verbose 'Entra embedded CIEM: ensure -Feature Ciem permissions are consented on the app registration.'
}

function Build-EmbeddedCiemConnectionSettings {
    param($Context)
    if (-not (Test-EmbeddedCiemSelected -FeatureNames $Context.FeatureNames)) {
        return [ordered]@{}
    }
    return [ordered]@{
        'Enable CIEM on SaaS source' = 'Feature Management: enable CIEM / PIM group eligibility analysis after permissions are granted'
    }
}

Export-ModuleMember -Function @(
    'Initialize-EntraCiemConnectorData'
    'Test-EmbeddedCiemSelected'
    'Get-EmbeddedCiemFeaturePack'
    'Merge-EntraCiemPermissions'
    'Apply-EmbeddedCiemPrerequisites'
    'Build-EmbeddedCiemConnectionSettings'
)

#Requires -Version 7
<#
.SYNOPSIS
    Creates requestable SailPoint access profiles from Microsoft Entra service-plan entitlements.

.DESCRIPTION
    Interactive wizard that authenticates to ISC via PSSailpoint, discovers Microsoft Entra
    sources with servicePlan entitlements, displays friendly Microsoft 365 licensing plan
    names, and creates requestable access profiles with an optional source app.
    Forwarding entrypoint for 'Microsoft 365 Access Profiles.ps1'.
#>
$target = Join-Path $PSScriptRoot 'Microsoft 365 Access Profiles.ps1'
if ($MyInvocation.ExpectingInput) {
    $input | & $target @args
} else {
    & $target @args
}

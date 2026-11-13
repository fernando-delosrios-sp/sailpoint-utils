#Requires -Version 7
<#
.SYNOPSIS
    Guided setup for Entro on-prem Active Directory.

.DESCRIPTION
    Creates the read-only AD service account and exports the LDAPS root CA for Entro.
    Forwarding entrypoint for 'On-Prem Active Directory.ps1'.
#>
$target = Join-Path $PSScriptRoot 'On-Prem Active Directory.ps1'
if ($MyInvocation.ExpectingInput) {
    $input | & $target @args
} else {
    & $target @args
}

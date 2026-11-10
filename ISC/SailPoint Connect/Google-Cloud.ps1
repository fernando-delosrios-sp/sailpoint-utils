#Requires -Version 7
<#
.SYNOPSIS
    Guided setup for Google Workspace SaaS connector, GCP CIEM connector,
    and Entro GCP / Google Workspace non-human identity governance.

.DESCRIPTION
    Unified runner for Google Workspace SaaS connector, GCP CIEM connector,
    and Entro GCP / Google Workspace non-human identity governance.
    Forwarding entrypoint for 'Google Cloud.ps1'.
#>
$target = Join-Path $PSScriptRoot 'Google Cloud.ps1'
if ($MyInvocation.ExpectingInput) {
    $input | & $target @args
} else {
    & $target @args
}

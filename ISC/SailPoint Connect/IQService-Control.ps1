#Requires -Version 5.1
<#
.SYNOPSIS
    Downloads, installs, updates, and manages SailPoint IQService on a Windows host.

.DESCRIPTION
    Operator script for IQService hosts that need the Integration Service for Active Directory,
    Azure AD, Windows Local, SharePoint, or Domino connectors.
    Forwarding entrypoint for 'IQService Control.ps1'.
#>
$target = Join-Path $PSScriptRoot 'IQService Control.ps1'
if ($MyInvocation.ExpectingInput) {
    $input | & $target @args
} else {
    & $target @args
}

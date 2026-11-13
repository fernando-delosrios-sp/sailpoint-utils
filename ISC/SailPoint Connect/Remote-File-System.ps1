#Requires -Version 7
<#
.SYNOPSIS
    Guided setup for Entro remote file scanning (SMB, SFTP, WinRM).

.DESCRIPTION
    Prepares a read-only file account and the Entro handoff for SMB, SFTP, or WinRM.
    Forwarding entrypoint for 'Remote File System.ps1'.
#>
$target = Join-Path $PSScriptRoot 'Remote File System.ps1'
if ($MyInvocation.ExpectingInput) {
    $input | & $target @args
} else {
    & $target @args
}

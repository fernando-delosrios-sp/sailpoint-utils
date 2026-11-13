#Requires -Version 7
<#
.SYNOPSIS
    Guided setup for Entro Outpost on-premise container runtime (Docker Compose or Kubernetes Helm).

.DESCRIPTION
    Deploys, checks, or builds prerequisite checklists and deployment scripts for an
    Entro Outpost worker group using Docker Compose or Kubernetes Helm.
    Forwarding entrypoint for 'Entro Outpost.ps1'.
#>
$target = Join-Path $PSScriptRoot 'Entro Outpost.ps1'
if ($MyInvocation.ExpectingInput) {
    $input | & $target @args
} else {
    & $target @args
}

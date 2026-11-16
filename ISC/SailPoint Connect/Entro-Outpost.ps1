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
$named = @{}
$positional = [System.Collections.Generic.List[object]]::new()
$byName = @{}
foreach ($entry in (Get-Command -Name $target -CommandType ExternalScript).Parameters.GetEnumerator()) {
    $byName[$entry.Key] = $entry.Value
    foreach ($alias in $entry.Value.Aliases) {
        $byName[$alias] = $entry.Value
    }
}
for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    if ($arg -is [string] -and $arg -match '^-([A-Za-z_][A-Za-z0-9_]*):$' -and ($i + 1) -lt $args.Count) {
        $named[$Matches[1]] = $args[$i + 1]
        $i++
    }
    elseif ($arg -is [string] -and $arg -match '^-([A-Za-z_][A-Za-z0-9_]*)$') {
        $pName = $Matches[1]
        $pInfo = $byName[$pName]
        if ($null -eq $pInfo) {
            $matchedNames = @($byName.Keys | Where-Object { $_ -like "$pName*" } | ForEach-Object { $byName[$_].Name } | Select-Object -Unique)
            if ($matchedNames.Count -eq 1) {
                $pName = $matchedNames[0]
                $pInfo = $byName[$pName]
            }
        }
        if ($null -ne $pInfo) {
            if ($pInfo.SwitchParameter) {
                $named[$pName] = $true
            }
            elseif (($i + 1) -lt $args.Count) {
                $named[$pName] = $args[$i + 1]
                $i++
            }
            else {
                throw "Missing an argument for parameter '$pName'."
            }
        }
        elseif (($i + 1) -lt $args.Count -and -not ($args[$i + 1] -is [string] -and $args[$i + 1] -match '^-[A-Za-z_]')) {
            $named[$pName] = $args[$i + 1]
            $i++
        }
        else {
            $named[$pName] = $true
        }
    }
    else {
        $positional.Add($arg)
    }
}
$posArgs = $positional.ToArray()
if ($MyInvocation.ExpectingInput) {
    $input | & $target @named @posArgs
} else {
    & $target @named @posArgs
}

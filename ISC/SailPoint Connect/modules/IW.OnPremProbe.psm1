# Shared reachability helpers for on-prem Entro integrations.
Set-StrictMode -Version Latest

function Get-OnPremEndpoint {
    param(
        [Parameter(Mandatory)][string]$Address,
        [int]$DefaultPort = 443
    )
    $text = $Address.Trim()
    if ($text -notmatch '^[a-z][a-z0-9+\.-]*://') { $text = "https://$text" }
    $uri = [Uri]$text
    $port = if ($uri.Port -gt 0) { $uri.Port } else { $DefaultPort }
    [pscustomobject]@{
        Host = $uri.Host
        Port = $port
        Url  = $uri.GetLeftPart([System.UriPartial]::Authority).TrimEnd('/')
    }
}

function Test-OnPremTcpPort {
    param(
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][int]$Port,
        [int]$TimeoutMs = 4000
    )
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $wait = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $wait.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
        $client.EndConnect($wait)
        return $client.Connected
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Write-OnPremSecretFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Value
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Value -Encoding ascii
    if ([System.OperatingSystem]::IsLinux() -or [System.OperatingSystem]::IsMacOS()) {
        try { & chmod 600 $Path 2>$null } catch { }
    }
}

Export-ModuleMember -Function Get-OnPremEndpoint, Test-OnPremTcpPort, Write-OnPremSecretFile

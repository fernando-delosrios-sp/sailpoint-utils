RTR Scanning | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/crowdstrike/rtr-scanning.md).

You can use Crowdstrike's RTR (Real-Time Response) to perform background secret scanning check on your employee's laptops, gaining visibility into rouge exposures across your infrastructure in the Entro platform.
GitBook Assistant

Only RTR Administrators can run scripts on hosts
GitBook AssistantExample Mac RTR script[#example-mac-rtr-script](#example-mac-rtr-script)GitBook AssistantAskCopy
```
#!/bin/bash

# --- Configuration ---
API_KEY="ENTRO_SCANNER_API_KEY"
API_URL="https://api.entro.security/v2/scan?redact=true"
MAX_SIZE_KB=2560
CONCURRENCY=10
LOG_FILE="/tmp/entro_secret_scanner.log"

# --- Logic ---

# We wrap the entire heavy lifting in a function
run_scan() {
    # 1. Setup
    DIRS=("/Users" "/private/var" "/etc" "/opt" "/Library")
    EXTENSIONS=(txt md json yml yaml env conf ini properties csv toml xml sql ps1)
    
    # Excludes (Standard noise filters)
    EXCLUDES=(
        "*/cache" "*/caches" "*/.cache" "*/__pycache__"
        "/System" "/private/var/vm" "/private/var/folders" "*.git" "*.Trash"
        "*/node_modules" "*/bower_components" "*/pnpm/store" "*/.pnpm-store"
        "*/go/pkg" "*/go/bin" "*/site-packages" "*/DerivedData" "*/.terraform"
    )

    # 2. Define the Python Processor (Embedded for safety)
    PY_SCRIPT="import sys, json, base64
try:
    d = sys.stdin.read()
    print(json.dumps({'data': d}))
except:
    sys.stdin = open(sys.stdin.fileno(), 'rb')
    d = base64.b64encode(sys.stdin.read()).decode('utf-8')
    print(json.dumps({'data': d, 'encoding': 'base64'}))"

    # 3. Export variables/functions so xargs (subshell) can see them
    export API_KEY API_URL LOG_FILE PY_SCRIPT

    process_file() {
        f="$1"
        # Check file exists and is text/json/xml
        if [[ ! -r "$f" ]] || ! file -b --mime "$f" | grep -qE "text/|json|xml|empty"; then return; fi
        
        # Encode & Upload
        code=$(python3 -c "$PY_SCRIPT" < "$f" 2>/dev/null | \
               curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL" \
               -H "Content-Type: application/json" -H "Authorization: $API_KEY" \
               --data-binary @- --max-time 15 --retry 1) || code="ERR"
        
        echo "$(date +'%FT%T') [$code] $f" >> "$LOG_FILE"
    }
    export -f process_file

    # 4. Build Find Command
    find_opts=()
    for ex in "${EXCLUDES[@]}"; do find_opts+=( -path "$ex" -prune -o ); done
    find_opts+=( \( )
    for i in "${!EXTENSIONS[@]}"; do
        if [[ $i -eq 0 ]]; then find_opts+=( -name "*.${EXTENSIONS[$i]}" ); 
        else find_opts+=( -o -name "*.${EXTENSIONS[$i]}" ); fi
    done
    find_opts+=( \) )

    # 5. Execute Scan
    # Filter valid dirs, run find, pipe to parallel xargs
    for d in "${DIRS[@]}"; do [[ -d "$d" ]] && echo "$d"; done | while read valid_d; do
        find "$valid_d" "${find_opts[@]}" -a -type f -size -"${MAX_SIZE_KB}k" -print0 \
        | xargs -0 -P "$CONCURRENCY" -I {} bash -c 'process_file "$@"' _ "{}"
    done
}

# --- Execution ---

# Run the function in background, detached, ensuring no output hangs the session.
(run_scan) >/dev/null 2>&1 &
disown
exit 0
```
Example Windows RTR script[#example-windows-rtr-script](#example-windows-rtr-script)GitBook AssistantAskCopy
```
<#
.SYNOPSIS
    win_secret_scanner_memory.ps1
    Fire-and-Forget Scanner.
    1. Encodes the logic in memory (Base64).
    2. Spawns a detached PowerShell process.
    3. Exits immediately.
    NO files are written to disk.
#>

$ErrorActionPreference = "Stop"

# --- 1. Define the Worker Logic (In Memory) ---
$WorkerBlock = {
    # ================= WORKER START =================
    $API_KEY     = "ENTRO_API_KEY"
    $API_URL     = "https://api.entro.security/v2/scan?redact=true"
    $MAX_SIZE_KB = 2560
    $CONCURRENCY = 10
    
    # Use ProgramData for logs (System writable)
    $LOG_DIR     = "$env:ProgramData\secret_scanner"
    $LOG_FILE    = "$LOG_DIR\scan.log"
    $LOCK_FILE   = "$LOG_DIR\scan.lock"

    # Target Users
    $DIRS        = @("C:\Users") 

    $EXTENSIONS  = @("txt","md","json","yml","yaml","env","conf","ini","properties","csv","toml","xml","sql","ps1")
    $EXCLUDES    = @(
        "\\cache\\", "\\caches\\", "\\.cache\\", "\\__pycache__\\",
        "\\Windows\\", "\\AppData\\Local\\Temp", "\\\.git\\", "\\\.Trash",
        "\\node_modules\\", "\\bower_components\\", "\\pnpm\\store\\", "\\\.pnpm-store\\",
        "\\go\\pkg\\", "\\go\\bin\\", "\\site-packages\\",
        "\\build\\", "\\dist\\", "\\target\\", "\\vendor\\", "\\bin\\", "\\obj\\",
        "\\DerivedData\\", "\\\.terraform\\", "\\\.serverless\\"
    )

    # Ensure Log Dir
    if (-not (Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null }

    function Write-Log {
        param($Msg)
        "$([DateTime]::UtcNow.ToString('s'))Z $Msg" | Out-File -Append -FilePath $LOG_FILE -Encoding utf8
    }

    # Lock Check
    if (Test-Path $LOCK_FILE) {
        $existing = Get-Content $LOCK_FILE -ErrorAction SilentlyContinue
        if ($existing -and (Get-Process -Id $existing -ErrorAction SilentlyContinue)) { exit }
        Remove-Item $LOCK_FILE -Force
    }
    $PID | Out-File $LOCK_FILE -Encoding ascii

    # Thread Logic
    $ScriptBlock = {
        param($P, $U, $K, $M)
        try {
            if ((Get-Item $P).Length -gt ($M * 1024)) { return }
            if ((Get-Content $P -Encoding Byte -TotalCount 512) -contains 0) { return }
            
            try { $c = [IO.File]::ReadAllText($P); $pl = @{data=$c} }
            catch { $b = [Convert]::ToBase64String([IO.File]::ReadAllBytes($P)); $pl = @{data=$b;encoding="base64"} }
            
            $j = $pl | ConvertTo-Json -Depth 2 -Compress
            $r = Invoke-WebRequest -Uri $U -Method POST -Body $j -Headers @{"Authorization"=$K} -ContentType "application/json" -TimeoutSec 15 -UseBasicParsing
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) { return "OK: $P" }
            return "ERR: $P ($($r.StatusCode))"
        } catch { return "ERR: $P" }
    }

    try {
        Write-Log "Started (PID $PID)"
        $Pool = [runspacefactory]::CreateRunspacePool(1, $CONCURRENCY)
        $Pool.Open()
        $Jobs = @()
        $ExReg = ($EXCLUDES -join "|").Replace(".", "\.")
        
        $Stack = [Collections.Generic.Stack[string]]::new()
        foreach ($d in $DIRS) { if (Test-Path $d) { $Stack.Push($d) } }

        while ($Stack.Count -gt 0) {
            $Cur = $Stack.Pop()
            try {
                if ($Cur -match $ExReg) { continue }
                foreach ($f in [IO.Directory]::EnumerateFiles($Cur)) {
                    $ext = [IO.Path]::GetExtension($f).TrimStart('.').ToLower()
                    if ($EXTENSIONS -contains $ext -and $f -notmatch $ExReg) {
                        $ps = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($f).AddArgument($API_URL).AddArgument($API_KEY).AddArgument($MAX_SIZE_KB)
                        $ps.RunspacePool = $Pool
                        $Jobs += @{ Pipe = $ps; Status = $ps.BeginInvoke() }
                    }
                }
                foreach ($d in [IO.Directory]::EnumerateDirectories($Cur)) {
                    if ($d -notmatch $ExReg) { $Stack.Push($d) }
                }
            } catch {}
            
            $Jobs | ? { $_.Status.IsCompleted } | % { $r=$_.Pipe.EndInvoke($_.Status); if($r){Write-Log $r}; $_.Pipe.Dispose() }
            $Jobs = $Jobs | ? { -not $_.Status.IsCompleted }
        }
        
        while ($Jobs.Count -gt 0) {
            $Jobs | ? { $_.Status.IsCompleted } | % { $r=$_.Pipe.EndInvoke($_.Status); if($r){Write-Log $r}; $_.Pipe.Dispose() }
            $Jobs = $Jobs | ? { -not $_.Status.IsCompleted }
            Start-Sleep -Milliseconds 100
        }
        Write-Log "Finished"
    } finally {
        if (Test-Path $LOCK_FILE) { Remove-Item $LOCK_FILE -Force }
    }
    # ================= WORKER END =================
}

# --- 2. Encode and Launch ---

# Convert the scriptblock to a string
$ScriptString = $WorkerBlock.ToString()

# Convert to Base64 (Standard PowerShell technique for passing scripts in CLI)
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptString)
$Encoded = [Convert]::ToBase64String($Bytes)

Write-Host "Launching background scanner (No file mode)..."

# Spawn independent process. 
# -WindowStyle Hidden: Invisible
# -EncodedCommand: Accepts the Base64 string
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -EncodedCommand $Encoded"

Write-Host "Success. Check logs at $env:ProgramData\secret_scanner\scan.log"
```

An execute flow would be as follows -
GitBook Assistant

1. 

Create an Entro Scanner only API key
GitBook Assistant
1. 

Place the API key in the place holder
GitBook Assistant
1. 

Head over to RTR Custom scripts
GitBook Assistant

1. 

e.g [https://falcon.crowdstrike.com/real-time-response/scripts/custom-scripts](https://falcon.us-2.crowdstrike.com/real-time-response/scripts/custom-scripts)
GitBook Assistant

1. 

Save the script into your Crowdstrike Falcon
GitBook Assistant

1. 

Execute the script on desired hosts using the Crowdstrike API
GitBook Assistant

e.g for Mac only hosts-
GitBook Assistant

Last updated 4 months ago
GitBook AssistantAskCopy
```
curl -X GET .../devices/queries/devices-scroll/v1?filter=platform_name:'Mac'
```
GitBook AssistantAskCopy
```
curl -L 'https://api.us-2.crowdstrike.com/real-time-response/entities/sessions/v1' \
-H 'Authorization: <redacted> \
-H 'Content-Type: application/json' \
-d '{
  "device_id": "host_id",
  "queue_offline": true
}'
```
GitBook AssistantAskCopy
```
curl -L 'https://api.us-2.crowdstrike.com/real-time-response/entities/admin-command/v1' \
-H 'Authorization: <redacted> \
-H 'Content-Type: application/json' \
-d '{
  "base_command": "",
  "command_string": "runscript -CloudFile=\"secret-scanner-mac\"",
  "device_id": "device_id",
  "id": 0,
  "persist": true,
  "session_id": "rtr_session_id"
}'
```

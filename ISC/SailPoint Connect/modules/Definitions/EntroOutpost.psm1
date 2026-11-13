Set-StrictMode -Version Latest

function Get-EntroOutpostEgressEndpoints {
    param([string]$AwsRegion = 'us-east-1')
    $region = if ([string]::IsNullOrWhiteSpace($AwsRegion)) { 'us-east-1' } else { $AwsRegion.Trim() }
    return @(
        @{ Host = 'api.entro.security'; Purpose = 'Entro control plane & API (no TLS MITM/inspection)' }
        @{ Host = 'ghcr.io'; Purpose = 'GitHub Container Registry (Outpost images & Helm chart)' }
        @{ Host = "s3.$region.amazonaws.com"; Purpose = "AWS S3 ($region) output & data transfer" }
        @{ Host = "sqs.$region.amazonaws.com"; Purpose = "AWS SQS ($region) task queue" }
        @{ Host = "logs.$region.amazonaws.com"; Purpose = "AWS CloudWatch Logs ($region)" }
        @{ Host = "secretsmanager.$region.amazonaws.com"; Purpose = "AWS Secrets Manager ($region)" }
        @{ Host = "sts.$region.amazonaws.com"; Purpose = "AWS STS ($region)" }
        @{ Host = 'iam.amazonaws.com'; Purpose = 'AWS IAM endpoint' }
        @{ Host = 'monitoring.us-east-1.amazonaws.com'; Purpose = 'AWS CloudWatch monitoring (us-east-1)' }
    )
}

function Test-EntroOutpostTcpEndpoint {
    param(
        [Parameter(Mandatory)][string]$HostName,
        [int]$Port = 443,
        [int]$TimeoutMs = 2500
    )
    $client = $null
    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $task = $client.ConnectAsync($HostName, $Port)
        if ($task.Wait($TimeoutMs) -and $client.Connected) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
    finally {
        if ($client) {
            try { $client.Dispose() } catch { }
        }
    }
}

function Get-EntroOutpostHostFacts {
    param(
        [string]$TargetPath = '',
        [string]$AwsRegion = 'us-east-1',
        [switch]$ProbeNetwork
    )
    if ($env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON) {
        $raw = $env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON | ConvertFrom-Json -AsHashtable
        return @{
            IsLinux              = [bool]($raw['IsLinux'])
            Architecture         = if ($raw.ContainsKey('Architecture')) { [string]$raw['Architecture'] } else { 'X64' }
            CpuCores             = if ($raw.ContainsKey('CpuCores')) { [int]$raw['CpuCores'] } else { 0 }
            RamGb                = if ($raw.ContainsKey('RamGb')) { [double]$raw['RamGb'] } else { 0 }
            FreeDiskGb           = if ($raw.ContainsKey('FreeDiskGb')) { [double]$raw['FreeDiskGb'] } else { 0 }
            DockerAvailable      = [bool]($raw['DockerAvailable'])
            ComposeAvailable     = [bool]($raw['ComposeAvailable'])
            HelmAvailable        = [bool]($raw['HelmAvailable'])
            KubectlAvailable     = [bool]($raw['KubectlAvailable'])
            KubeLinuxAmd64Nodes  = if ($raw.ContainsKey('KubeLinuxAmd64Nodes')) { [int]$raw['KubeLinuxAmd64Nodes'] } else { 0 }
            KubeClusterCpu       = if ($raw.ContainsKey('KubeClusterCpu')) { [double]$raw['KubeClusterCpu'] } else { 0 }
            KubeClusterRamGb     = if ($raw.ContainsKey('KubeClusterRamGb')) { [double]$raw['KubeClusterRamGb'] } else { 0 }
            DefaultEgressOk      = if ($raw.ContainsKey('DefaultEgressOk')) { $raw['DefaultEgressOk'] } else { $null }
            EgressResults        = if ($raw.ContainsKey('EgressResults') -and $raw['EgressResults']) { $raw['EgressResults'] } else { @{} }
            ExistingStackRunning = [bool]($raw['ExistingStackRunning'])
        }
    }

    $isLinux = [System.OperatingSystem]::IsLinux()
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    $cpuCores = [Environment]::ProcessorCount

    $ramGb = 0.0
    try {
        if ($isLinux -and (Test-Path -LiteralPath '/proc/meminfo')) {
            $memLine = Get-Content -LiteralPath '/proc/meminfo' | Where-Object { $_ -match '^MemTotal:\s+(\d+)\s+kB' } | Select-Object -First 1
            if ($memLine -and $memLine -match '^MemTotal:\s+(\d+)\s+kB') {
                $ramGb = [Math]::Round(([double]$Matches[1]) / 1048576.0, 1)
            }
        }
        elseif ([System.OperatingSystem]::IsMacOS()) {
            $memBytes = & sysctl -n hw.memsize 2>$null
            if ($LASTEXITCODE -eq 0 -and $memBytes) {
                $ramGb = [Math]::Round(([double]$memBytes) / 1073741824.0, 1)
            }
        }
        elseif ([System.OperatingSystem]::IsWindows()) {
            $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
            if ($cs -and $cs.TotalPhysicalMemory) {
                $ramGb = [Math]::Round(([double]$cs.TotalPhysicalMemory) / 1073741824.0, 1)
            }
        }
    }
    catch { }

    $freeDiskGb = 0.0
    try {
        $probeDir = if ($TargetPath -and (Test-Path -LiteralPath $TargetPath)) { $TargetPath } else { (Get-Location).Path }
        $root = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($probeDir))
        if ($root) {
            $di = [System.IO.DriveInfo]::new($root)
            $freeDiskGb = [Math]::Round($di.AvailableFreeSpace / 1073741824.0, 1)
        }
    }
    catch { }

    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    $dockerAvailable = $null -ne $dockerCmd
    $composeAvailable = $false
    if ($dockerAvailable) {
        try {
            $null = & docker compose version 2>$null
            if ($LASTEXITCODE -eq 0) { $composeAvailable = $true }
        }
        catch { }
    }

    $helmCmd = Get-Command helm -ErrorAction SilentlyContinue
    $helmAvailable = $null -ne $helmCmd
    $kubectlCmd = Get-Command kubectl -ErrorAction SilentlyContinue
    $kubectlAvailable = $null -ne $kubectlCmd

    $kubeLinuxAmd64Nodes = 0
    $kubeCpu = 0.0
    $kubeRamGb = 0.0
    if ($kubectlAvailable) {
        try {
            $nodesJson = & kubectl get nodes -o json 2>$null
            if ($LASTEXITCODE -eq 0 -and $nodesJson) {
                $nodesObj = $nodesJson | ConvertFrom-Json
                foreach ($node in @($nodesObj.items)) {
                    $os = [string]$node.status.nodeInfo.operatingSystem
                    $nArch = [string]$node.status.nodeInfo.architecture
                    if ($os -eq 'linux' -and $nArch -eq 'amd64') {
                        $kubeLinuxAmd64Nodes++
                        $rawCpu = [string]$node.status.allocatable.cpu
                        if ($rawCpu -match '^(\d+)m$') { $kubeCpu += [double]$Matches[1] / 1000.0 }
                        elseif ($rawCpu -match '^[\d.]+$') { $kubeCpu += [double]$rawCpu }
                        $rawMem = [string]$node.status.allocatable.memory
                        if ($rawMem -match '^(\d+)Ki$') { $kubeRamGb += [double]$Matches[1] / 1048576.0 }
                        elseif ($rawMem -match '^(\d+)Mi$') { $kubeRamGb += [double]$Matches[1] / 1024.0 }
                        elseif ($rawMem -match '^(\d+)Gi$') { $kubeRamGb += [double]$Matches[1] }
                    }
                }
            }
        }
        catch { }
    }

    $egressResults = @{}
    if ($ProbeNetwork) {
        foreach ($ep in @(Get-EntroOutpostEgressEndpoints -AwsRegion $AwsRegion)) {
            $egressResults[$ep.Host] = Test-EntroOutpostTcpEndpoint -HostName $ep.Host -Port 443
        }
    }

    return @{
        IsLinux              = $isLinux
        Architecture         = $arch
        CpuCores             = $cpuCores
        RamGb                = $ramGb
        FreeDiskGb           = $freeDiskGb
        DockerAvailable      = $dockerAvailable
        ComposeAvailable     = $composeAvailable
        HelmAvailable        = $helmAvailable
        KubectlAvailable     = $kubectlAvailable
        KubeLinuxAmd64Nodes  = $kubeLinuxAmd64Nodes
        KubeClusterCpu       = [Math]::Round($kubeCpu, 1)
        KubeClusterRamGb     = [Math]::Round($kubeRamGb, 1)
        DefaultEgressOk      = $null
        EgressResults        = $egressResults
        ExistingStackRunning = $false
    }
}

function Invoke-EntroOutpostCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$StdinText = ''
    )
    if ($env:SAILPOINT_CONNECT_TEST_OUTPOST_MOCK_CLI -in @('1', 'true', '$true', 'True')) {
        if ($env:SAILPOINT_CONNECT_TEST_OUTPOST_LOG_PATH) {
            $safeArgs = @($Arguments | ForEach-Object {
                if ($_ -match '(?i)(secret|password|pat|token|private_key)=') {
                    ($_ -replace '=.*', '=***')
                } else { $_ }
            })
            Add-Content -LiteralPath $env:SAILPOINT_CONNECT_TEST_OUTPOST_LOG_PATH -Value ("{0} {1}" -f $FilePath, ($safeArgs -join ' ')) -Encoding utf8
        }
        return @{ ExitCode = 0; Output = 'mocked' }
    }
    if ($StdinText) {
        $output = $StdinText | & $FilePath @Arguments 2>&1 | Out-String
    }
    else {
        $output = & $FilePath @Arguments 2>&1 | Out-String
    }
    $code = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    if ($code -ne 0) {
        throw "Command failed ($FilePath $($Arguments -join ' ')): $output"
    }
    return @{ ExitCode = $code; Output = $output }
}

function New-EntroOutpostRsaKeyPair {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [switch]$WhatIf
    )
    $privPath = Join-Path $Directory 'private.key'
    $pubPath = Join-Path $Directory 'public.key'
    if ($WhatIf) {
        return @{
            PrivateKeyPath = $privPath
            PublicKeyPath  = $pubPath
            PrivateKeyB64  = ''
        }
    }
    if (-not (Test-Path -LiteralPath $Directory)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)
    try {
        $privPem = $rsa.ExportPkcs8PrivateKeyPem()
        $pubPem = $rsa.ExportSubjectPublicKeyInfoPem()
        Set-Content -LiteralPath $privPath -Value $privPem -Encoding ascii -NoNewline
        Set-Content -LiteralPath $pubPath -Value $pubPem -Encoding ascii -NoNewline
        if ([System.OperatingSystem]::IsLinux() -or [System.OperatingSystem]::IsMacOS()) {
            try { & chmod 600 $privPath 2>$null } catch { }
        }
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($privPem))
        return @{
            PrivateKeyPath = $privPath
            PublicKeyPath  = $pubPath
            PrivateKeyB64  = $b64
        }
    }
    finally {
        $rsa.Dispose()
    }
}

function Test-EntroOutpostDockerCheck {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [bool]$WhatIf = $false
    )
    $tier = if ($Context['DeploymentTier']) { [string]$Context['DeploymentTier'] } else { 'Standard' }
    $region = if ($Context['AwsRegion']) { [string]$Context['AwsRegion'] } else { 'us-east-1' }
    $installDir = if ($Context['InstallDirectory']) { [string]$Context['InstallDirectory'] } else { '/opt/entro-outpost' }

    $minCpu = if ($tier -eq 'Large') { 16 } else { 8 }
    $minRam = if ($tier -eq 'Large') { 64 } else { 32 }
    $minDisk = if ($tier -eq 'Large') { 250 } else { 64 }

    $reqOs = 'host:linux-amd64'
    $reqCpu = "host:cpu>=$minCpu ($tier)"
    $reqRam = "host:ram>=${minRam}GB ($tier)"
    $reqDisk = "host:disk>=${minDisk}GB ($tier)"
    $reqDocker = 'cli:docker'
    $reqCompose = 'cli:docker-compose-v2'
    $endpoints = @(Get-EntroOutpostEgressEndpoints -AwsRegion $region)

    $required = [System.Collections.Generic.List[string]]::new()
    $purposeMap = @{}
    $required.Add($reqOs); $purposeMap[$reqOs] = 'Linux AMD64 (x86_64) OS & CPU architecture'
    $required.Add($reqCpu); $purposeMap[$reqCpu] = "Minimum $minCpu vCPU for Docker Compose $tier tier"
    $required.Add($reqRam); $purposeMap[$reqRam] = "Minimum ${minRam} GB RAM for Docker Compose $tier tier"
    $required.Add($reqDisk); $purposeMap[$reqDisk] = "Minimum ${minDisk} GB free disk space ($installDir)"
    $required.Add($reqDocker); $purposeMap[$reqDocker] = 'Docker Engine installed on target host'
    $required.Add($reqCompose); $purposeMap[$reqCompose] = 'Docker Compose v2 plugin available'
    foreach ($ep in $endpoints) {
        $k = "egress:$($ep.Host):443"
        $required.Add($k)
        $purposeMap[$k] = $ep.Purpose
    }

    if ($WhatIf) {
        return @{
            Subject       = @{ Kind = 'HostPrerequisites'; Label = 'Docker Outpost host'; Name = $installDir; Note = "WhatIf: would check Linux AMD64 host, Docker Compose v2, sizing ($tier), and HTTPS egress. Nothing was changed."; Readable = $true; ReadableFamilies = @() }
            Verdict       = 'Review'
            AttemptedRead = $false
            Found         = $false
            Required      = @($required)
            Met           = @()
            Missing       = @()
            Manual        = @($required)
            PurposeMap    = $purposeMap
            ReadNote      = 'WhatIf: host and network probes skipped.'
        }
    }

    $facts = Get-EntroOutpostHostFacts -TargetPath $installDir -AwsRegion $region -ProbeNetwork
    $met = [System.Collections.Generic.List[string]]::new()
    $missing = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()

    if ($facts.IsLinux -and $facts.Architecture -eq 'X64') { $met.Add($reqOs) } else { $missing.Add($reqOs) }
    if ($facts.CpuCores -ge $minCpu) { $met.Add($reqCpu) } else { $missing.Add($reqCpu) }
    if ($facts.RamGb -ge $minRam) { $met.Add($reqRam) } else { $missing.Add($reqRam) }
    if ($facts.FreeDiskGb -ge $minDisk) { $met.Add($reqDisk) } else { $missing.Add($reqDisk) }
    if ($facts.DockerAvailable) { $met.Add($reqDocker) } else { $missing.Add($reqDocker) }
    if ($facts.ComposeAvailable) { $met.Add($reqCompose) } else { $missing.Add($reqCompose) }

    foreach ($ep in $endpoints) {
        $k = "egress:$($ep.Host):443"
        $ok = if ($facts.EgressResults -and $facts.EgressResults.ContainsKey($ep.Host)) {
            [bool]$facts.EgressResults[$ep.Host]
        } elseif ($null -ne $facts.DefaultEgressOk) {
            [bool]$facts.DefaultEgressOk
        } else {
            $false
        }
        if ($ok) { $met.Add($k) } else { $missing.Add($k) }
    }

    $verdict = if ($missing.Count -gt 0) { 'Fail' } elseif ($manual.Count -gt 0) { 'Review' } else { 'Pass' }
    $note = "Checked host $([Environment]::MachineName) (IsLinux=$($facts.IsLinux), Arch=$($facts.Architecture), CPU=$($facts.CpuCores), RAM=$($facts.RamGb)GB, Disk=$($facts.FreeDiskGb)GB)."
    return @{
        Subject       = @{ Kind = 'HostPrerequisites'; Label = 'Docker Outpost host'; Name = $installDir; Note = 'Read-only prerequisite probe for Entro Outpost (Docker Compose). Nothing was changed.'; Readable = $true; ReadableFamilies = @() }
        Verdict       = $verdict
        AttemptedRead = $true
        Found         = $true
        Required      = @($required)
        Met           = @($met)
        Missing       = @($missing)
        Manual        = @($manual)
        PurposeMap    = $purposeMap
        ReadNote      = $note
    }
}

function Test-EntroOutpostKubernetesCheck {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [bool]$WhatIf = $false
    )
    $region = if ($Context['AwsRegion']) { [string]$Context['AwsRegion'] } else { 'us-east-1' }
    $ns = if ($Context['KubernetesNamespace']) { [string]$Context['KubernetesNamespace'] } else { 'entro' }

    $reqHelm = 'cli:helm-v3+'
    $reqKubectl = 'cli:kubectl'
    $reqNodes = 'k8s:linux-amd64-nodes'
    $reqClusterCap = 'k8s:capacity>=6cpu-12gb'
    $endpoints = @(Get-EntroOutpostEgressEndpoints -AwsRegion $region)

    $required = [System.Collections.Generic.List[string]]::new()
    $purposeMap = @{}
    $required.Add($reqHelm); $purposeMap[$reqHelm] = 'Helm v3+ CLI on workstation'
    $required.Add($reqKubectl); $purposeMap[$reqKubectl] = 'kubectl CLI configured with target cluster context'
    $required.Add($reqNodes); $purposeMap[$reqNodes] = 'At least 1 Linux AMD64 worker node in cluster'
    $required.Add($reqClusterCap); $purposeMap[$reqClusterCap] = 'Cluster allocatable >= 6 vCPU & 12 GB RAM (connector, scanner, nats pods)'
    foreach ($ep in $endpoints) {
        $k = "egress:$($ep.Host):443"
        $required.Add($k)
        $purposeMap[$k] = $ep.Purpose + ' (cluster egress)'
    }

    if ($WhatIf) {
        return @{
            Subject       = @{ Kind = 'KubernetesCluster'; Label = 'Kubernetes Outpost target'; Name = $ns; Note = 'WhatIf: would check Helm v3+, kubectl, Linux AMD64 node capacity, and egress endpoints. Nothing was changed.'; Readable = $true; ReadableFamilies = @() }
            Verdict       = 'Review'
            AttemptedRead = $false
            Found         = $false
            Required      = @($required)
            Met           = @()
            Missing       = @()
            Manual        = @($required)
            PurposeMap    = $purposeMap
            ReadNote      = 'WhatIf: Helm/kubectl cluster probes skipped.'
        }
    }

    $facts = Get-EntroOutpostHostFacts -AwsRegion $region -ProbeNetwork
    $met = [System.Collections.Generic.List[string]]::new()
    $missing = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()

    if ($facts.HelmAvailable) { $met.Add($reqHelm) } else { $missing.Add($reqHelm) }
    if ($facts.KubectlAvailable) { $met.Add($reqKubectl) } else { $missing.Add($reqKubectl) }
    if ($facts.KubeLinuxAmd64Nodes -ge 1) { $met.Add($reqNodes) } else { $missing.Add($reqNodes) }
    if ($facts.KubeClusterCpu -ge 6 -and $facts.KubeClusterRamGb -ge 12) { $met.Add($reqClusterCap) } else { $missing.Add($reqClusterCap) }

    foreach ($ep in $endpoints) {
        $k = "egress:$($ep.Host):443"
        $ok = if ($facts.EgressResults -and $facts.EgressResults.ContainsKey($ep.Host)) {
            [bool]$facts.EgressResults[$ep.Host]
        } elseif ($null -ne $facts.DefaultEgressOk) {
            [bool]$facts.DefaultEgressOk
        } else {
            $null
        }
        if ($true -eq $ok) { $met.Add($k) }
        elseif ($false -eq $ok) { $missing.Add($k) }
        else { $manual.Add($k) }
    }

    $verdict = if ($missing.Count -gt 0) { 'Fail' } elseif ($manual.Count -gt 0) { 'Review' } else { 'Pass' }
    $note = "Checked helm/kubectl on $([Environment]::MachineName); Linux/amd64 nodes=$($facts.KubeLinuxAmd64Nodes), allocatable CPU=$($facts.KubeClusterCpu), RAM=$($facts.KubeClusterRamGb)GB."
    return @{
        Subject       = @{ Kind = 'KubernetesCluster'; Label = 'Kubernetes Outpost target'; Name = $ns; Note = 'Read-only prerequisite probe for Entro Outpost (Kubernetes Helm). Nothing was changed.'; Readable = $true; ReadableFamilies = @() }
        Verdict       = $verdict
        AttemptedRead = $true
        Found         = $true
        Required      = @($required)
        Met           = @($met)
        Missing       = @($missing)
        Manual        = @($manual)
        PurposeMap    = $purposeMap
        ReadNote      = $note
    }
}

function Register-EntroOutpostDefinitions {
    $runRequired = { param($c) [string]$c['Action'] -eq 'Run' }

    Register-IntegrationWizardDefinition @{
        Id                = 'entro-outpost-docker'
        Platform          = 'EntroOutpost'
        Product           = 'Entro'
        CoreSwitch        = 'DockerCompose'
        CliName           = 'pwsh'
        OutpostDefinition = $true
        Title             = 'Entro Outpost (Docker Compose)'
        FolderName        = 'Entro-Outpost-Docker'
        RequiredTools     = @('docker', 'docker compose (v2)')
        AccessLevels      = @()
        AdminRoles        = @(
            'Linux host root/sudo or docker group member (AMD64 / x86_64 host)'
            'Entro Administrator (Settings -> Outposts -> Add Outpost)'
        )
        OutputsHelp       = 'In Entro UI (Settings -> Outposts), confirm the Worker Group shows Connected. If Encrypted Integration Secrets was enabled, upload the generated public.key in Entro.'
        TargetHost        = @{
            Role         = 'On-Premises Linux Docker Host (AMD64 / x86_64)'
            Notes        = 'Must run on the Linux AMD64 host running Docker Engine + Compose v2 with outbound HTTPS (443) to api.entro.security, ghcr.io, and AWS S3/SQS/Logs without TLS MITM.'
            Assert       = {
                param($c)
                $facts = Get-EntroOutpostHostFacts -TargetPath ([string]$c['InstallDirectory'])
                if (-not $facts.IsLinux -or $facts.Architecture -ne 'X64') {
                    throw "Entro Outpost (Docker Compose) requires a Linux AMD64 (x86_64) host. Current host: IsLinux=$($facts.IsLinux), Architecture=$($facts.Architecture). Run on the target Linux host or choose BuildScript/BuildRequirements."
                }
                if (-not $facts.DockerAvailable -or -not $facts.ComposeAvailable) {
                    throw 'Docker Engine and Docker Compose v2 are required on PATH to deploy Entro Outpost.'
                }
            }
            AssertScript = @'
if (-not [System.OperatingSystem]::IsLinux() -or [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne [System.Runtime.InteropServices.Architecture]::X64) {
    throw 'Entro Outpost (Docker Compose) must run on a Linux AMD64 (x86_64) host.'
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Install Docker Engine and Docker Compose v2 first.' }
'@
        }
        Inputs            = @(
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Worker Group name'; Purpose = 'Logical Worker Group name shown in Entro Outposts'; Default = 'default-outpost'; Required = $true }
            @{ Name = 'DeploymentTier'; Source = 'Supply'; Prompt = 'Host sizing tier (Standard: 8 vCPU/32GB/64GB, Large: 16 vCPU/64GB/250GB)'; Purpose = 'Docker host resource sizing tier'; ValidateSet = @('Standard', 'Large'); Default = 'Standard'; Required = $false }
            @{ Name = 'InstallDirectory'; Source = 'Supply'; Prompt = 'Target install directory on the Linux host'; Purpose = 'Directory storing docker-compose.yaml, .env-connector, and var/nats'; Default = '/opt/entro-outpost'; Required = $true }
            @{ Name = 'AwsRegion'; Source = 'Supply'; Prompt = 'AWS region for Entro Outpost S3/SQS/Logs'; Purpose = 'Outpost AWS region (default us-east-1)'; Default = 'us-east-1'; Required = $true }
            @{ Name = 'AwsAccessKeyId'; Source = 'Supply'; Prompt = 'AWS Access Key ID (from Entro Outpost wizard)'; Purpose = 'AWS_ACCESS_KEY_ID for .env-connector'; Required = $runRequired }
            @{ Name = 'AwsSecretAccessKey'; Source = 'Supply'; Prompt = 'AWS Secret Access Key (from Entro Outpost wizard)'; Purpose = 'AWS_SECRET_ACCESS_KEY for .env-connector'; Secret = $true; Required = $runRequired }
            @{ Name = 'CrPat'; Source = 'Supply'; Prompt = 'GitHub Container Registry PAT (CR_PAT for entro-registry)'; Purpose = 'Password/PAT for docker login ghcr.io -u entro-registry'; Secret = $true; Required = $runRequired }
            @{ Name = 'ComposeFileUrl'; Source = 'Supply'; Prompt = 'docker-compose.yaml file path or download URL (from Entro Outpost wizard)'; Purpose = 'Source path or URL for Entro docker-compose.yaml'; Required = $runRequired }
            @{ Name = 'OutputBucket'; Source = 'Supply'; Prompt = 'S3 output bucket name (OUTPUT_BUCKET)'; Purpose = 'S3 bucket for Outpost scan outputs'; Required = $runRequired }
            @{ Name = 'SqsQueueUrl'; Source = 'Supply'; Prompt = 'SQS queue URL (SQS_QUEUE_URL)'; Purpose = 'SQS queue URL for Outpost jobs'; Required = $runRequired }
            @{ Name = 'RedshiftBucket'; Source = 'Supply'; Prompt = 'S3 Redshift bucket name (REDSHIFT_BUCKET, optional)'; Purpose = 'Optional Redshift bucket in .env-connector'; Required = $false }
            @{ Name = 'LogGroup'; Source = 'Supply'; Prompt = 'CloudWatch log group (LOG_STREAMER_LOG_GROUP)'; Purpose = 'CloudWatch log group name'; Default = '/entro/connector'; Required = $false }
            @{ Name = 'LogStream'; Source = 'Supply'; Prompt = 'CloudWatch log stream (LOG_STREAMER_LOG_STREAM)'; Purpose = 'CloudWatch log stream name'; Default = 'connector-stream'; Required = $false }
            @{ Name = 'EnableEncryptedSecrets'; Source = 'Supply'; Prompt = 'Generate RSA-2048 key pair for Encrypted Integration Secrets?'; Purpose = 'Creates private.key / public.key and sets SECRET_PRIVATE_KEY'; ValidateSet = @('No', 'Yes'); Default = 'No'; Required = $false }
            @{ Name = 'UseProxy'; Source = 'Supply'; Prompt = 'Route outbound traffic through an HTTP/HTTPS proxy?'; Purpose = 'Configure HTTP_PROXY and NO_PROXY in .env-connector'; ValidateSet = @('No', 'Yes'); Default = 'No'; Required = $false }
            @{ Name = 'HttpProxy'; Source = 'Supply'; Prompt = 'HTTP/HTTPS proxy URL (e.g. http://proxy.corp:3128)'; Purpose = 'HTTP_PROXY value'; When = { param($c) $c['UseProxy'] -eq 'Yes' }; Required = { param($c) $c['UseProxy'] -eq 'Yes' -and $c['Action'] -eq 'Run' } }
            @{ Name = 'NoProxy'; Source = 'Supply'; Prompt = 'NO_PROXY comma-separated bypass list'; Purpose = 'NO_PROXY value'; Default = 'localhost,127.0.0.1'; When = { param($c) $c['UseProxy'] -eq 'Yes' }; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe        = { param($ctx, $whatIf) Test-EntroOutpostDockerCheck -Context $ctx -WhatIf:$whatIf }
        Steps             = {
            param($ctx)
            $installDir = if ($ctx['InstallDirectory']) { [string]$ctx['InstallDirectory'] } else { '/opt/entro-outpost' }
            $region = if ($ctx['AwsRegion']) { [string]$ctx['AwsRegion'] } else { 'us-east-1' }
            @(
                @{
                    Id     = 'entro-outpost-ui-bundle'
                    Title  = 'Retrieve Outpost credentials and docker-compose.yaml from Entro UI'
                    Kind   = 'Manual'
                    Why    = 'Entro generates unique S3, SQS, AWS IAM keys, CR_PAT, and the docker-compose.yaml for each Outpost.'
                    Manual = 'In Entro Console -> Settings -> Outposts -> Add Outpost -> Docker Compose, copy CR_PAT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, OUTPUT_BUCKET, SQS_QUEUE_URL, and docker-compose.yaml.'
                }
                @{
                    Id    = 'entro-outpost-docker-env'
                    Title = "Prepare install directory ($installDir), persistent volumes, and .env-connector"
                    Kind  = 'Ensure'
                    Why   = 'Ensures var/nats (>=10GB) exists, optionally generates RSA-2048 key pair, and writes restricted .env-connector.'
                    Probe = {
                        param($c)
                        $dir = if ($c['InstallDirectory']) { [string]$c['InstallDirectory'] } else { '/opt/entro-outpost' }
                        if (Test-Path -LiteralPath (Join-Path $dir '.env-connector')) { 'Update' } else { 'Create' }
                    }
                    Run   = {
                        param($c)
                        $dir = if ($c['InstallDirectory']) { [string]$c['InstallDirectory'] } else { '/opt/entro-outpost' }
                        $natsDir = Join-Path $dir 'var/nats'
                        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                        if (-not (Test-Path -LiteralPath $natsDir)) { New-Item -ItemType Directory -Path $natsDir -Force | Out-Null }

                        $secretPrivateKeyB64 = ''
                        if ($c['EnableEncryptedSecrets'] -eq 'Yes') {
                            $keyDir = Join-Path $dir 'keys'
                            $keys = New-EntroOutpostRsaKeyPair -Directory $keyDir
                            $c['OutpostPublicKeyPath'] = $keys.PublicKeyPath
                            $secretPrivateKeyB64 = $keys.PrivateKeyB64
                            Write-Ok "Generated RSA-2048 key pair: $($keys.PublicKeyPath)"
                        }

                        $envLines = [System.Collections.Generic.List[string]]::new()
                        $envLines.Add("AWS_ACCESS_KEY_ID=$($c['AwsAccessKeyId'])")
                        $envLines.Add("AWS_SECRET_ACCESS_KEY=$($c['AwsSecretAccessKey'])")
                        $envLines.Add("AWS_REGION=$(if ($c['AwsRegion']) { $c['AwsRegion'] } else { 'us-east-1' })")
                        $envLines.Add("OUTPUT_BUCKET=$($c['OutputBucket'])")
                        $envLines.Add("SQS_QUEUE_URL=$($c['SqsQueueUrl'])")
                        if ($c['RedshiftBucket']) { $envLines.Add("REDSHIFT_BUCKET=$($c['RedshiftBucket'])") }
                        $envLines.Add("LOG_STREAMER_LOG_GROUP=$(if ($c['LogGroup']) { $c['LogGroup'] } else { '/entro/connector' })")
                        $envLines.Add("LOG_STREAMER_LOG_STREAM=$(if ($c['LogStream']) { $c['LogStream'] } else { 'connector-stream' })")
                        $envLines.Add('LOG_STREAMER_TYPE=cloudwatch')
                        $envLines.Add('LOG_STREAMER_ENABLED=true')
                        if ($secretPrivateKeyB64) { $envLines.Add("SECRET_PRIVATE_KEY=$secretPrivateKeyB64") }
                        if ($c['UseProxy'] -eq 'Yes' -and $c['HttpProxy']) {
                            $envLines.Add("HTTP_PROXY=$($c['HttpProxy'])")
                            if ($c['NoProxy']) { $envLines.Add("NO_PROXY=$($c['NoProxy'])") }
                        }

                        $envPath = Join-Path $dir '.env-connector'
                        Set-Content -LiteralPath $envPath -Value ($envLines -join "`n") -Encoding utf8
                        if ([System.OperatingSystem]::IsLinux() -or [System.OperatingSystem]::IsMacOS()) {
                            try { & chmod 600 $envPath 2>$null } catch { }
                        }
                    }
                }
                @{
                    Id    = 'entro-outpost-docker-compose-file'
                    Title = 'Stage docker-compose.yaml in install directory'
                    Kind  = 'Ensure'
                    Why   = 'Places the Entro docker-compose.yaml definition in the Outpost install directory.'
                    Probe = {
                        param($c)
                        $dir = if ($c['InstallDirectory']) { [string]$c['InstallDirectory'] } else { '/opt/entro-outpost' }
                        if (Test-Path -LiteralPath (Join-Path $dir 'docker-compose.yaml')) { 'Update' } else { 'Create' }
                    }
                    Run   = {
                        param($c)
                        $dir = if ($c['InstallDirectory']) { [string]$c['InstallDirectory'] } else { '/opt/entro-outpost' }
                        $dest = Join-Path $dir 'docker-compose.yaml'
                        $src = [string]$c['ComposeFileUrl']
                        if ($src -match '^https?://') {
                            Invoke-WebRequest -Uri $src -OutFile $dest -UseBasicParsing -ErrorAction Stop
                        }
                        elseif (-not [string]::IsNullOrWhiteSpace($src)) {
                            if (-not (Test-Path -LiteralPath $src)) {
                                throw "ComposeFileUrl path not found: $src"
                            }
                            if ([System.IO.Path]::GetFullPath($src) -ne [System.IO.Path]::GetFullPath($dest)) {
                                Copy-Item -LiteralPath $src -Destination $dest -Force
                            }
                        }
                        elseif (-not (Test-Path -LiteralPath $dest)) {
                            throw "ComposeFileUrl is required when $dest does not already exist."
                        }
                    }
                }
                @{
                    Id    = 'entro-outpost-docker-up'
                    Title = 'Authenticate to ghcr.io and start Outpost containers'
                    Kind  = 'Ensure'
                    Why   = 'Logs into ghcr.io as entro-registry, pulls images, and starts detached Compose services.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $dir = if ($c['InstallDirectory']) { [string]$c['InstallDirectory'] } else { '/opt/entro-outpost' }
                        $composePath = Join-Path $dir 'docker-compose.yaml'
                        $envPath = Join-Path $dir '.env-connector'
                        Invoke-EntroOutpostCommand -FilePath 'docker' -Arguments @('login', 'ghcr.io', '-u', 'entro-registry', '--password-stdin') -StdinText ([string]$c['CrPat']) | Out-Null
                        Invoke-EntroOutpostCommand -FilePath 'docker' -Arguments @('compose', '-f', $composePath, '--env-file', $envPath, 'pull') | Out-Null
                        Invoke-EntroOutpostCommand -FilePath 'docker' -Arguments @('compose', '-f', $composePath, '--env-file', $envPath, 'up', '-d') | Out-Null
                        $psRes = Invoke-EntroOutpostCommand -FilePath 'docker' -Arguments @('compose', '-f', $composePath, '--env-file', $envPath, 'ps')
                        Write-Info ($psRes.Output.Trim())
                    }
                }
                @{
                    Id     = 'entro-outpost-network-egress'
                    Title  = "Verify HTTPS (443) egress without TLS MITM (region: $region)"
                    Kind   = 'Manual'
                    Why    = 'Outpost requires direct TLS connectivity without SSL interception to Entro API, ghcr.io, and AWS endpoints.'
                    Manual = "Confirm firewall allows outbound TCP 443 to api.entro.security, ghcr.io, *.s3.$region.amazonaws.com, sqs.$region.amazonaws.com, logs.$region.amazonaws.com, secretsmanager.$region.amazonaws.com, sts.$region.amazonaws.com, iam.amazonaws.com, monitoring.us-east-1.amazonaws.com."
                }
            )
        }
        BuildScript       = {
            param($c)
            $proxyBlock = if ($c['UseProxy'] -eq 'Yes') {
                @"
if (`$HttpProxy) { `$envLines += "HTTP_PROXY=`$HttpProxy" }
if (`$NoProxy) { `$envLines += "NO_PROXY=`$NoProxy" }
"@
            } else { '' }
            $encBlock = if ($c['EnableEncryptedSecrets'] -eq 'Yes') {
                @'
$keyDir = Join-Path $InstallDirectory 'keys'
New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
$privKeyPath = Join-Path $keyDir 'private.key'
$pubKeyPath = Join-Path $keyDir 'public.key'
if (-not (Test-Path -LiteralPath $privKeyPath)) {
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)
    try {
        Set-Content -LiteralPath $privKeyPath -Value ($rsa.ExportPkcs8PrivateKeyPem()) -Encoding ascii -NoNewline
        Set-Content -LiteralPath $pubKeyPath -Value ($rsa.ExportSubjectPublicKeyInfoPem()) -Encoding ascii -NoNewline
        & chmod 600 $privKeyPath
    }
    finally { $rsa.Dispose() }
}
$privPem = Get-Content -LiteralPath $privKeyPath -Raw -Encoding ascii
$secretPrivateKeyB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($privPem))
Write-Host "Upload public key in Entro UI: $pubKeyPath" -ForegroundColor Cyan
'@
            } else {
                '$secretPrivateKeyB64 = '''''
            }
            @"
if (-not (Test-Path variable:InstallDirectory) -or -not `$InstallDirectory) { `$InstallDirectory = '/opt/entro-outpost' }
if (-not (Test-Path variable:AwsRegion) -or -not `$AwsRegion) { `$AwsRegion = 'us-east-1' }
if (-not (Test-Path variable:LogGroup) -or -not `$LogGroup) { `$LogGroup = '/entro/connector' }
if (-not (Test-Path variable:LogStream) -or -not `$LogStream) { `$LogStream = 'connector-stream' }
if (-not (Test-Path variable:RedshiftBucket)) { `$RedshiftBucket = '' }
if (-not (Test-Path variable:UseProxy)) { `$UseProxy = 'No' }
if (-not (Test-Path variable:HttpProxy)) { `$HttpProxy = '' }
if (-not (Test-Path variable:NoProxy) -or -not `$NoProxy) { `$NoProxy = 'localhost,127.0.0.1' }
if (-not (Test-Path variable:CrPat) -or -not `$CrPat) { `$CrPat = `$env:CrPat }
if (-not (Test-Path variable:AwsSecretAccessKey) -or -not `$AwsSecretAccessKey) { `$AwsSecretAccessKey = `$env:AwsSecretAccessKey }
if (-not (Test-Path variable:AwsAccessKeyId)) { `$AwsAccessKeyId = '' }
if (-not (Test-Path variable:OutputBucket)) { `$OutputBucket = '' }
if (-not (Test-Path variable:SqsQueueUrl)) { `$SqsQueueUrl = '' }
if (-not (Test-Path variable:ComposeFileUrl)) { `$ComposeFileUrl = '' }

if (-not `$CrPat) { `$CrPat = Read-Host -Prompt 'Enter GHCR PAT (CR_PAT for entro-registry)' -MaskInput }
if (-not `$AwsSecretAccessKey) { `$AwsSecretAccessKey = Read-Host -Prompt 'Enter AWS_SECRET_ACCESS_KEY' -MaskInput }
if (-not `$AwsAccessKeyId) { `$AwsAccessKeyId = Read-Host -Prompt 'Enter AWS_ACCESS_KEY_ID' }
if (-not `$OutputBucket) { `$OutputBucket = Read-Host -Prompt 'Enter OUTPUT_BUCKET' }
if (-not `$SqsQueueUrl) { `$SqsQueueUrl = Read-Host -Prompt 'Enter SQS_QUEUE_URL' }
if (-not `$ComposeFileUrl) { `$ComposeFileUrl = Read-Host -Prompt 'Enter docker-compose.yaml path or URL' }

New-Item -ItemType Directory -Path `$InstallDirectory -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path `$InstallDirectory 'var/nats') -Force | Out-Null

$encBlock

`$envLines = @(
    "AWS_ACCESS_KEY_ID=`$AwsAccessKeyId"
    "AWS_SECRET_ACCESS_KEY=`$AwsSecretAccessKey"
    "AWS_REGION=`$AwsRegion"
    "OUTPUT_BUCKET=`$OutputBucket"
    "SQS_QUEUE_URL=`$SqsQueueUrl"
    "LOG_STREAMER_LOG_GROUP=`$LogGroup"
    "LOG_STREAMER_LOG_STREAM=`$LogStream"
    'LOG_STREAMER_TYPE=cloudwatch'
    'LOG_STREAMER_ENABLED=true'
)
if (`$RedshiftBucket) { `$envLines += "REDSHIFT_BUCKET=`$RedshiftBucket" }
if (`$secretPrivateKeyB64) { `$envLines += "SECRET_PRIVATE_KEY=`$secretPrivateKeyB64" }
$proxyBlock

`$envPath = Join-Path `$InstallDirectory '.env-connector'
Set-Content -LiteralPath `$envPath -Value (`$envLines -join "``n") -Encoding utf8
& chmod 600 `$envPath

`$composePath = Join-Path `$InstallDirectory 'docker-compose.yaml'
if (`$ComposeFileUrl -match '^https?://') {
    Invoke-WebRequest -Uri `$ComposeFileUrl -OutFile `$composePath -UseBasicParsing
}
elseif ([System.IO.Path]::GetFullPath(`$ComposeFileUrl) -ne [System.IO.Path]::GetFullPath(`$composePath)) {
    Copy-Item -LiteralPath `$ComposeFileUrl -Destination `$composePath -Force
}

`$CrPat | docker login ghcr.io -u entro-registry --password-stdin
if (`$LASTEXITCODE -ne 0) { throw 'docker login ghcr.io failed.' }
docker compose -f `$composePath --env-file `$envPath pull
if (`$LASTEXITCODE -ne 0) { throw 'docker compose pull failed.' }
docker compose -f `$composePath --env-file `$envPath up -d
if (`$LASTEXITCODE -ne 0) { throw 'docker compose up -d failed.' }
docker compose -f `$composePath --env-file `$envPath ps
"@
        }
        OnRunComplete     = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro Outpost (Docker Compose) deployed' -ForegroundColor Cyan
            Write-Host "  Worker Group: $($ctx['WorkerGroup'])"
            Write-Host "  Install Dir:  $($ctx['InstallDirectory'])"
            if ($ctx['OutpostPublicKeyPath']) {
                Write-Host "  Public Key:   $($ctx['OutpostPublicKeyPath']) (upload to Entro UI if using encrypted secrets)"
            }
            Write-Host ''
        }
    }

    Register-IntegrationWizardDefinition @{
        Id                = 'entro-outpost-kubernetes'
        Platform          = 'EntroOutpost'
        Product           = 'Entro'
        CoreSwitch        = 'KubernetesHelm'
        CliName           = 'pwsh'
        OutpostDefinition = $true
        Title             = 'Entro Outpost (Kubernetes Helm)'
        FolderName        = 'Entro-Outpost-Kubernetes'
        RequiredTools     = @('helm (v3+)', 'kubectl (configured cluster context)')
        AccessLevels      = @()
        AdminRoles        = @(
            'Kubernetes cluster namespace admin (deploy Helm chart + secrets)'
            'Entro Administrator (Settings -> Outposts -> Add Outpost)'
        )
        OutputsHelp       = 'Verify all 3 core pods (connector, scanner, nats) reach Running/Ready in the target namespace and confirm Worker Group Connected in Entro UI.'
        TargetHost        = @{
            Role         = 'Kubernetes Control Workstation (helm + kubectl -> Linux AMD64 nodes)'
            Notes        = 'Requires Helm v3+, kubectl targeting a cluster with Linux AMD64 worker nodes (>= 6 vCPU / 12 GB RAM / 30 GB SSD), and outbound HTTPS (443) without TLS MITM.'
            Assert       = {
                param($c)
                $facts = Get-EntroOutpostHostFacts
                if (-not $facts.HelmAvailable) {
                    throw 'Helm v3+ (helm) is required on PATH for Entro Outpost Kubernetes deployment.'
                }
                if (-not $facts.KubectlAvailable) {
                    throw 'kubectl is required on PATH for Entro Outpost Kubernetes deployment.'
                }
            }
            AssertScript = @'
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) { throw 'Install Helm v3+ first.' }
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'Install kubectl first.' }
'@
        }
        Inputs            = @(
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Worker Group name'; Purpose = 'Logical Worker Group name shown in Entro Outposts'; Default = 'default-outpost'; Required = $true }
            @{ Name = 'KubernetesNamespace'; Source = 'Supply'; Prompt = 'Target Kubernetes namespace'; Purpose = 'Namespace where Helm release is installed'; Default = 'entro'; Required = $true }
            @{ Name = 'HelmReleaseName'; Source = 'Supply'; Prompt = 'Helm release name'; Purpose = 'Release name for helm upgrade --install'; Default = 'entro-connector'; Required = $true }
            @{ Name = 'ChartVersion'; Source = 'Supply'; Prompt = 'Helm chart version (or latest)'; Purpose = 'Version of oci://ghcr.io/entro-security-registry/entro-connector-helm'; Default = 'latest'; Required = $false }
            @{ Name = 'AwsAccountId'; Source = 'Supply'; Prompt = 'Entro AWS Account ID'; Purpose = 'entro.awsAccountId value (default 937217723901)'; Default = '937217723901'; Required = $false }
            @{ Name = 'AwsRegion'; Source = 'Supply'; Prompt = 'AWS region for Entro Outpost S3/SQS/Logs'; Purpose = 'Outpost AWS region (default us-east-1)'; Default = 'us-east-1'; Required = $true }
            @{ Name = 'AwsAccessKeyId'; Source = 'Supply'; Prompt = 'AWS Access Key ID (from Entro Outpost wizard)'; Purpose = 'entro.awsAccessKeyId'; Required = $runRequired }
            @{ Name = 'AwsSecretAccessKey'; Source = 'Supply'; Prompt = 'AWS Secret Access Key (from Entro Outpost wizard)'; Purpose = 'entro.awsSecretAccessKey'; Secret = $true; Required = $runRequired }
            @{ Name = 'CrPat'; Source = 'Supply'; Prompt = 'GitHub Container Registry PAT (CR_PAT for entro-registry)'; Purpose = 'Password/PAT for helm registry login ghcr.io'; Secret = $true; Required = $runRequired }
            @{ Name = 'EntroConnectorId'; Source = 'Supply'; Prompt = 'Entro Connector ID (from Entro Outpost wizard)'; Purpose = 'entro.connectorId'; Required = $runRequired }
            @{ Name = 'EntroPassword'; Source = 'Supply'; Prompt = 'Entro Connector password (from Entro Outpost wizard)'; Purpose = 'entro.password'; Secret = $true; Required = $runRequired }
            @{ Name = 'LogGroup'; Source = 'Supply'; Prompt = 'CloudWatch log group (env.LOG_GROUP)'; Purpose = 'Log group passed to Helm values'; Default = '/entro/connector'; Required = $false }
            @{ Name = 'EnableScheduling'; Source = 'Supply'; Prompt = 'Enable KEDA / cron pod scaling schedule?'; Purpose = 'Configures connector.scheduling & scaleUp/scaleDown'; ValidateSet = @('No', 'Yes'); Default = 'No'; Required = $false }
            @{ Name = 'ScheduleScaleUp'; Source = 'Supply'; Prompt = 'Scale-up cron schedule (e.g. 0 7 * * 1-5)'; Purpose = 'connector.schedule.scaleUp'; Default = '0 7 * * 1-5'; When = { param($c) $c['EnableScheduling'] -eq 'Yes' }; Required = $false }
            @{ Name = 'ScheduleScaleDown'; Source = 'Supply'; Prompt = 'Scale-down cron schedule (e.g. 0 19 * * 1-5)'; Purpose = 'connector.schedule.scaleDown'; Default = '0 19 * * 1-5'; When = { param($c) $c['EnableScheduling'] -eq 'Yes' }; Required = $false }
            @{ Name = 'ScheduleTimeZone'; Source = 'Supply'; Prompt = 'Schedule IANA time zone (e.g. UTC or America/New_York)'; Purpose = 'spec.timeZone'; Default = 'UTC'; When = { param($c) $c['EnableScheduling'] -eq 'Yes' }; Required = $false }
            @{ Name = 'EnableEncryptedSecrets'; Source = 'Supply'; Prompt = 'Generate RSA-2048 key pair for Encrypted Integration Secrets?'; Purpose = 'Creates private.key / public.key and sets env.SECRET_PRIVATE_KEY'; ValidateSet = @('No', 'Yes'); Default = 'No'; Required = $false }
            @{ Name = 'UseProxy'; Source = 'Supply'; Prompt = 'Route cluster pod outbound traffic through an HTTP/HTTPS proxy?'; Purpose = 'Configure env.HTTP_PROXY and env.NO_PROXY'; ValidateSet = @('No', 'Yes'); Default = 'No'; Required = $false }
            @{ Name = 'HttpProxy'; Source = 'Supply'; Prompt = 'HTTP/HTTPS proxy URL (e.g. http://proxy.corp:3128)'; Purpose = 'env.HTTP_PROXY value'; When = { param($c) $c['UseProxy'] -eq 'Yes' }; Required = { param($c) $c['UseProxy'] -eq 'Yes' -and $c['Action'] -eq 'Run' } }
            @{ Name = 'NoProxy'; Source = 'Supply'; Prompt = 'NO_PROXY comma-separated bypass list'; Purpose = 'env.NO_PROXY value'; Default = 'localhost,127.0.0.1,.cluster.local'; When = { param($c) $c['UseProxy'] -eq 'Yes' }; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe        = { param($ctx, $whatIf) Test-EntroOutpostKubernetesCheck -Context $ctx -WhatIf:$whatIf }
        Steps             = {
            param($ctx)
            $ns = if ($ctx['KubernetesNamespace']) { [string]$ctx['KubernetesNamespace'] } else { 'entro' }
            $release = if ($ctx['HelmReleaseName']) { [string]$ctx['HelmReleaseName'] } else { 'entro-connector' }
            $region = if ($ctx['AwsRegion']) { [string]$ctx['AwsRegion'] } else { 'us-east-1' }
            @(
                @{
                    Id     = 'entro-outpost-k8s-ui'
                    Title  = 'Retrieve Helm Outpost credentials from Entro UI'
                    Kind   = 'Manual'
                    Why    = 'Entro provisions the Connector ID, password, AWS IAM keys, and CR_PAT for the Helm chart.'
                    Manual = 'In Entro Console -> Settings -> Outposts -> Add Outpost -> Kubernetes Helm, copy CR_PAT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, Connector ID, and Entro password.'
                }
                @{
                    Id    = 'entro-outpost-helm-deploy'
                    Title = "Authenticate Helm to ghcr.io and deploy release '$release' in namespace '$ns'"
                    Kind  = 'Ensure'
                    Why   = 'Logs into ghcr.io, pulls oci://ghcr.io/entro-security-registry/entro-connector-helm, and installs/upgrades using an ephemeral restricted values file.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $targetNs = if ($c['KubernetesNamespace']) { [string]$c['KubernetesNamespace'] } else { 'entro' }
                        $rel = if ($c['HelmReleaseName']) { [string]$c['HelmReleaseName'] } else { 'entro-connector' }
                        $acct = if ($c['AwsAccountId']) { [string]$c['AwsAccountId'] } else { '937217723901' }
                        $logGrp = if ($c['LogGroup']) { [string]$c['LogGroup'] } else { '/entro/connector' }
                        $ver = if ($c['ChartVersion']) { [string]$c['ChartVersion'] } else { 'latest' }
                        $outDir = if ($c['OutputDirectory']) { [string]$c['OutputDirectory'] } else { (Get-Location).Path }

                        $secretPrivateKeyB64 = ''
                        if ($c['EnableEncryptedSecrets'] -eq 'Yes') {
                            $keyDir = Join-Path $outDir 'keys'
                            $keys = New-EntroOutpostRsaKeyPair -Directory $keyDir
                            $c['OutpostPublicKeyPath'] = $keys.PublicKeyPath
                            $secretPrivateKeyB64 = $keys.PrivateKeyB64
                            Write-Ok "Generated RSA-2048 key pair: $($keys.PublicKeyPath)"
                        }

                        Invoke-EntroOutpostCommand -FilePath 'helm' -Arguments @('registry', 'login', 'ghcr.io', '--username', 'entro-registry', '--password-stdin') -StdinText ([string]$c['CrPat']) | Out-Null

                        $chartRef = 'oci://ghcr.io/entro-security-registry/entro-connector-helm'
                        $pullArgs = @('pull', $chartRef, '--destination', $outDir, '--untar')
                        if ($ver -and $ver -ne 'latest') {
                            $pullArgs += @('--version', $ver)
                        }
                        Invoke-EntroOutpostCommand -FilePath 'helm' -Arguments $pullArgs | Out-Null

                        $yaml = [System.Text.StringBuilder]::new()
                        [void]$yaml.AppendLine('scanner:')
                        [void]$yaml.AppendLine('  replicaCount: 1')
                        [void]$yaml.AppendLine('connector:')
                        [void]$yaml.AppendLine('  replicaCount: 1')
                        if ($c['EnableScheduling'] -eq 'Yes') {
                            [void]$yaml.AppendLine('  scheduling: true')
                            [void]$yaml.AppendLine('  schedule:')
                            [void]$yaml.AppendLine("    scaleUp: `"$(if ($c['ScheduleScaleUp']) { $c['ScheduleScaleUp'] } else { '0 7 * * 1-5' })`"")
                            [void]$yaml.AppendLine("    scaleDown: `"$(if ($c['ScheduleScaleDown']) { $c['ScheduleScaleDown'] } else { '0 19 * * 1-5' })`"")
                        }
                        [void]$yaml.AppendLine('entro:')
                        [void]$yaml.AppendLine("  awsAccountId: `"$acct`"")
                        [void]$yaml.AppendLine("  awsAccessKeyId: `"$($c['AwsAccessKeyId'])`"")
                        [void]$yaml.AppendLine("  awsSecretAccessKey: `"$($c['AwsSecretAccessKey'])`"")
                        [void]$yaml.AppendLine("  password: `"$($c['EntroPassword'])`"")
                        [void]$yaml.AppendLine("  connectorId: `"$($c['EntroConnectorId'])`"")
                        [void]$yaml.AppendLine('env:')
                        [void]$yaml.AppendLine("  LOG_GROUP: `"$logGrp`"")
                        if ($secretPrivateKeyB64) {
                            [void]$yaml.AppendLine("  SECRET_PRIVATE_KEY: `"$secretPrivateKeyB64`"")
                        }
                        if ($c['UseProxy'] -eq 'Yes' -and $c['HttpProxy']) {
                            [void]$yaml.AppendLine("  HTTP_PROXY: `"$($c['HttpProxy'])`"")
                            if ($c['NoProxy']) { [void]$yaml.AppendLine("  NO_PROXY: `"$($c['NoProxy'])`"") }
                        }
                        if ($c['EnableScheduling'] -eq 'Yes' -and $c['ScheduleTimeZone']) {
                            [void]$yaml.AppendLine('spec:')
                            [void]$yaml.AppendLine("  timeZone: `"$($c['ScheduleTimeZone'])`"")
                        }

                        $tmpValues = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-values-{0}.yaml" -f [Guid]::NewGuid().ToString('N'))
                        try {
                            Set-Content -LiteralPath $tmpValues -Value $yaml.ToString() -Encoding utf8
                            if ([System.OperatingSystem]::IsLinux() -or [System.OperatingSystem]::IsMacOS()) {
                                try { & chmod 600 $tmpValues 2>$null } catch { }
                            }
                            $chartDir = Join-Path $outDir 'entro-connector-helm'
                            $targetChart = if (Test-Path -LiteralPath $chartDir) { $chartDir } else { $chartRef }
                            $helmArgs = @('upgrade', '--install', $rel, $targetChart, '-n', $targetNs, '--create-namespace', '-f', $tmpValues)
                            if ($ver -and $ver -ne 'latest' -and $targetChart -eq $chartRef) {
                                $helmArgs += @('--version', $ver)
                            }
                            Invoke-EntroOutpostCommand -FilePath 'helm' -Arguments $helmArgs | Out-Null
                        }
                        finally {
                            if (Test-Path -LiteralPath $tmpValues) {
                                Remove-Item -LiteralPath $tmpValues -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                }
                @{
                    Id    = 'entro-outpost-k8s-verify'
                    Title = "Verify Outpost pods in namespace '$ns'"
                    Kind  = 'Ensure'
                    Why   = 'Confirms connector, scanner, and nats pods are scheduled and running.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $targetNs = if ($c['KubernetesNamespace']) { [string]$c['KubernetesNamespace'] } else { 'entro' }
                        $podsRes = Invoke-EntroOutpostCommand -FilePath 'kubectl' -Arguments @('get', 'pods', '-n', $targetNs)
                        Write-Info ($podsRes.Output.Trim())
                    }
                }
                @{
                    Id     = 'entro-outpost-k8s-egress'
                    Title  = "Verify cluster HTTPS (443) egress without TLS MITM (region: $region)"
                    Kind   = 'Manual'
                    Why    = 'Worker nodes and pods require direct TLS connectivity to Entro API, ghcr.io, and AWS endpoints.'
                    Manual = "Confirm cluster egress firewall permits TCP 443 to api.entro.security, ghcr.io, *.s3.$region.amazonaws.com, sqs.$region.amazonaws.com, logs.$region.amazonaws.com, secretsmanager.$region.amazonaws.com, sts.$region.amazonaws.com, iam.amazonaws.com, monitoring.us-east-1.amazonaws.com."
                }
            )
        }
        BuildScript       = {
            param($c)
            $encBlock = if ($c['EnableEncryptedSecrets'] -eq 'Yes') {
                @'
$keyDir = Join-Path (Get-Location).Path 'entro-outpost-keys'
New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
$privKeyPath = Join-Path $keyDir 'private.key'
$pubKeyPath = Join-Path $keyDir 'public.key'
if (-not (Test-Path -LiteralPath $privKeyPath)) {
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)
    try {
        Set-Content -LiteralPath $privKeyPath -Value ($rsa.ExportPkcs8PrivateKeyPem()) -Encoding ascii -NoNewline
        Set-Content -LiteralPath $pubKeyPath -Value ($rsa.ExportSubjectPublicKeyInfoPem()) -Encoding ascii -NoNewline
    }
    finally { $rsa.Dispose() }
}
$privPem = Get-Content -LiteralPath $privKeyPath -Raw -Encoding ascii
$secretPrivateKeyB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($privPem))
Write-Host "Upload public key in Entro UI: $pubKeyPath" -ForegroundColor Cyan
'@
            } else {
                '$secretPrivateKeyB64 = '''''
            }
            @"
if (-not (Test-Path variable:KubernetesNamespace) -or -not `$KubernetesNamespace) { `$KubernetesNamespace = 'entro' }
if (-not (Test-Path variable:HelmReleaseName) -or -not `$HelmReleaseName) { `$HelmReleaseName = 'entro-connector' }
if (-not (Test-Path variable:ChartVersion) -or -not `$ChartVersion) { `$ChartVersion = 'latest' }
if (-not (Test-Path variable:AwsAccountId) -or -not `$AwsAccountId) { `$AwsAccountId = '937217723901' }
if (-not (Test-Path variable:LogGroup) -or -not `$LogGroup) { `$LogGroup = '/entro/connector' }
if (-not (Test-Path variable:EnableScheduling)) { `$EnableScheduling = 'No' }
if (-not (Test-Path variable:ScheduleScaleUp) -or -not `$ScheduleScaleUp) { `$ScheduleScaleUp = '0 7 * * 1-5' }
if (-not (Test-Path variable:ScheduleScaleDown) -or -not `$ScheduleScaleDown) { `$ScheduleScaleDown = '0 19 * * 1-5' }
if (-not (Test-Path variable:ScheduleTimeZone) -or -not `$ScheduleTimeZone) { `$ScheduleTimeZone = 'UTC' }
if (-not (Test-Path variable:UseProxy)) { `$UseProxy = 'No' }
if (-not (Test-Path variable:HttpProxy)) { `$HttpProxy = '' }
if (-not (Test-Path variable:NoProxy) -or -not `$NoProxy) { `$NoProxy = 'localhost,127.0.0.1,.cluster.local' }
if (-not (Test-Path variable:CrPat) -or -not `$CrPat) { `$CrPat = `$env:CrPat }
if (-not (Test-Path variable:AwsAccessKeyId)) { `$AwsAccessKeyId = '' }
if (-not (Test-Path variable:AwsSecretAccessKey) -or -not `$AwsSecretAccessKey) { `$AwsSecretAccessKey = `$env:AwsSecretAccessKey }
if (-not (Test-Path variable:EntroConnectorId)) { `$EntroConnectorId = '' }
if (-not (Test-Path variable:EntroPassword) -or -not `$EntroPassword) { `$EntroPassword = `$env:EntroPassword }

if (-not `$CrPat) { `$CrPat = Read-Host -Prompt 'Enter GHCR PAT (CR_PAT for entro-registry)' -MaskInput }
if (-not `$AwsAccessKeyId) { `$AwsAccessKeyId = Read-Host -Prompt 'Enter entro.awsAccessKeyId' }
if (-not `$AwsSecretAccessKey) { `$AwsSecretAccessKey = Read-Host -Prompt 'Enter entro.awsSecretAccessKey' -MaskInput }
if (-not `$EntroConnectorId) { `$EntroConnectorId = Read-Host -Prompt 'Enter entro.connectorId' }
if (-not `$EntroPassword) { `$EntroPassword = Read-Host -Prompt 'Enter entro.password' -MaskInput }

$encBlock

`$CrPat | helm registry login ghcr.io --username entro-registry --password-stdin
if (`$LASTEXITCODE -ne 0) { throw 'helm registry login failed.' }

`$chartRef = 'oci://ghcr.io/entro-security-registry/entro-connector-helm'
`$tmpValues = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-values-{0}.yaml" -f [Guid]::NewGuid().ToString('N'))
try {
    `$yaml = [System.Text.StringBuilder]::new()
    [void]`$yaml.AppendLine('scanner:')
    [void]`$yaml.AppendLine('  replicaCount: 1')
    [void]`$yaml.AppendLine('connector:')
    [void]`$yaml.AppendLine('  replicaCount: 1')
    if (`$EnableScheduling -eq 'Yes') {
        [void]`$yaml.AppendLine('  scheduling: true')
        [void]`$yaml.AppendLine('  schedule:')
        [void]`$yaml.AppendLine("    scaleUp: ``"`$ScheduleScaleUp``"")
        [void]`$yaml.AppendLine("    scaleDown: ``"`$ScheduleScaleDown``"")
    }
    [void]`$yaml.AppendLine('entro:')
    [void]`$yaml.AppendLine("  awsAccountId: ``"`$AwsAccountId``"")
    [void]`$yaml.AppendLine("  awsAccessKeyId: ``"`$AwsAccessKeyId``"")
    [void]`$yaml.AppendLine("  awsSecretAccessKey: ``"`$AwsSecretAccessKey``"")
    [void]`$yaml.AppendLine("  password: ``"`$EntroPassword``"")
    [void]`$yaml.AppendLine("  connectorId: ``"`$EntroConnectorId``"")
    [void]`$yaml.AppendLine('env:')
    [void]`$yaml.AppendLine("  LOG_GROUP: ``"`$LogGroup``"")
    if (`$secretPrivateKeyB64) { [void]`$yaml.AppendLine("  SECRET_PRIVATE_KEY: ``"`$secretPrivateKeyB64``"") }
    if (`$UseProxy -eq 'Yes' -and `$HttpProxy) {
        [void]`$yaml.AppendLine("  HTTP_PROXY: ``"`$HttpProxy``"")
        if (`$NoProxy) { [void]`$yaml.AppendLine("  NO_PROXY: ``"`$NoProxy``"") }
    }
    if (`$EnableScheduling -eq 'Yes' -and `$ScheduleTimeZone) {
        [void]`$yaml.AppendLine('spec:')
        [void]`$yaml.AppendLine("  timeZone: ``"`$ScheduleTimeZone``"")
    }
    Set-Content -LiteralPath `$tmpValues -Value `$yaml.ToString() -Encoding utf8
    `$helmArgs = @('upgrade', '--install', `$HelmReleaseName, `$chartRef, '-n', `$KubernetesNamespace, '--create-namespace', '-f', `$tmpValues)
    if (`$ChartVersion -and `$ChartVersion -ne 'latest') { `$helmArgs += @('--version', `$ChartVersion) }
    & helm @helmArgs
    if (`$LASTEXITCODE -ne 0) { throw 'helm upgrade --install failed.' }
    kubectl get pods -n `$KubernetesNamespace
}
finally {
    if (Test-Path -LiteralPath `$tmpValues) { Remove-Item -LiteralPath `$tmpValues -Force -ErrorAction SilentlyContinue }
}
"@
        }
        OnRunComplete     = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro Outpost (Kubernetes Helm) deployed' -ForegroundColor Cyan
            Write-Host "  Worker Group: $($ctx['WorkerGroup'])"
            Write-Host "  Namespace:    $($ctx['KubernetesNamespace'])"
            Write-Host "  Release:      $($ctx['HelmReleaseName'])"
            if ($ctx['OutpostPublicKeyPath']) {
                Write-Host "  Public Key:   $($ctx['OutpostPublicKeyPath']) (upload to Entro UI if using encrypted secrets)"
            }
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function @(
    'Get-EntroOutpostEgressEndpoints'
    'Get-EntroOutpostHostFacts'
    'New-EntroOutpostRsaKeyPair'
    'Register-EntroOutpostDefinitions'
)

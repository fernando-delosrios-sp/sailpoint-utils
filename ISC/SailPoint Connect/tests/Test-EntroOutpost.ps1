#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$connectRoot = Split-Path $PSScriptRoot -Parent
$manifestPath = Join-Path $connectRoot 'SailPoint.Connect.psd1'

Import-Module (Join-Path $connectRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $connectRoot 'modules/IW.Project.psm1') -Force -Global
Import-Module (Join-Path $connectRoot 'modules/IW.Render.psm1') -Force -Global
Import-Module (Join-Path $connectRoot 'modules/IW.Check.psm1') -Force -Global
Import-Module (Join-Path $connectRoot 'modules/IW.Catalog.psm1') -Force -Global
Import-Module (Join-Path $connectRoot 'modules/IW.CatalogMenu.psm1') -Force -Global
Import-Module (Join-Path $connectRoot 'modules/Definitions/EntroOutpost.psm1') -Force -Global
Import-Module $manifestPath -Force

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-outpost-test-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$env:SAILPOINT_CONNECT_ROOT = Join-Path $tmp 'projects'
$env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK = '1'

try {
    # 1) Register EntroOutpost platform and definitions
    Register-IntegrationWizardPlatform -Name 'EntroOutpost' -Title 'Entro Outpost' -CoreOptions @('DockerCompose', 'KubernetesHelm') -CliName 'pwsh'
    Register-EntroOutpostDefinitions

    $dockerDef = Get-IntegrationWizardDefinition -Id 'entro-outpost-docker'
    $k8sDef = Get-IntegrationWizardDefinition -Id 'entro-outpost-kubernetes'
    Assert-True ($null -ne $dockerDef) 'entro-outpost-docker definition is registered'
    Assert-True ($null -ne $k8sDef) 'entro-outpost-kubernetes definition is registered'
    Assert-Equal 'pwsh' ([string]$dockerDef.CliName) 'Docker definition uses pwsh CliName'
    Assert-True ([bool]$dockerDef.OutpostDefinition) 'Docker definition is marked OutpostDefinition'
    Assert-True ([bool]$k8sDef.OutpostDefinition) 'Kubernetes definition is marked OutpostDefinition'

    # 2) Show-IntegrationWizardDefinitionHelp surfaces Target host
    $helpOut = (& { Show-IntegrationWizardDefinitionHelp -Definition $dockerDef -ScriptName 'Entro Outpost.ps1' -Context @{} } 6>&1 | Out-String)
    Assert-True ($helpOut -match 'Target host: On-Premises Linux Docker Host') 'Definition help prints Target host line'

    # 3) RSA-2048 key pair generation
    $keyDir = Join-Path $tmp 'rsa-keys'
    $rsaResult = New-EntroOutpostRsaKeyPair -Directory $keyDir
    Assert-True (Test-Path -LiteralPath $rsaResult.PrivateKeyPath) 'RSA private.key file created'
    Assert-True (Test-Path -LiteralPath $rsaResult.PublicKeyPath) 'RSA public.key file created'
    Assert-True (-not [string]::IsNullOrWhiteSpace($rsaResult.PrivateKeyB64)) 'PrivateKeyB64 returned'
    $pubPem = Get-Content -LiteralPath $rsaResult.PublicKeyPath -Raw
    Assert-True ($pubPem -match 'BEGIN PUBLIC KEY') 'Public key uses SubjectPublicKeyInfo PEM format'

    # 4) Catalog integration & metadata verification
    $catalog = Import-IntegrationWizardCatalog -Force
    $vaultInt = @(Get-IntegrationCatalogIntegrations | Where-Object { $_.id -eq 'hashicorp-vault' })[0]
    Assert-Equal 'self-hosted' ([string]$vaultInt.hosting) 'hashicorp-vault is marked self-hosted'
    Assert-True ([bool]$vaultInt.requiresOutpost) 'hashicorp-vault requires Outpost'

    $outpostInt = @(Get-IntegrationCatalogIntegrations | Where-Object { $_.id -eq 'entro-outpost' })[0]
    Assert-Equal 'EntroOutpost' ([string]$outpostInt.platformName) 'entro-outpost catalog maps to EntroOutpost'

    $outpostDockerBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'entro-outpost' -Product 'entro' -VariantId 'docker-compose'
    $legacyDocker = Get-IntegrationCatalogLegacyLaunchParameters -Binding $outpostDockerBinding -Product 'entro'
    Assert-True ([bool]$legacyDocker['DockerCompose']) 'docker-compose variant maps to DockerCompose switch'

    $outpostK8sBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'entro-outpost' -Product 'entro' -VariantId 'kubernetes-helm'
    $legacyK8s = Get-IntegrationCatalogLegacyLaunchParameters -Binding $outpostK8sBinding -Product 'entro'
    Assert-True ([bool]$legacyK8s['KubernetesHelm']) 'kubernetes-helm variant maps to KubernetesHelm switch'

    # 5) Connect-SailPointEntroOutpost BuildRequirements (Text + Json) & Stream 1 purity
    Set-SailPointConnectProject -Name 'outpost-proj' | Out-Null
    $reqOutDir = Join-Path $tmp 'req-docker'
    $reqPipeline = @(Connect-SailPointEntroOutpost -DockerCompose -Action BuildRequirements -NonInteractive -Project 'outpost-proj' -OutputDirectory $reqOutDir -OutputFormat Json)
    Assert-Equal 1 $reqPipeline.Count 'Docker BuildRequirements returns exactly 1 PSCustomObject on Stream 1'
    Assert-Equal 'Success' $reqPipeline[0].Status 'Docker BuildRequirements status is Success'
    Assert-Equal 'EntroOutpost' $reqPipeline[0].Platform 'Platform is EntroOutpost'
    Assert-True (Test-Path -LiteralPath $reqPipeline[0].Path) 'Docker requirements markdown created'
    Assert-True (Test-Path -LiteralPath $reqPipeline[0].JsonPath) 'Docker requirements JSON created'

    $reqMd = Get-Content -LiteralPath $reqPipeline[0].Path -Raw
    Assert-True ($reqMd -match '## Target host') 'Requirements markdown includes Target host section'
    Assert-True ($reqMd -match 'Linux Docker Host') 'Requirements markdown specifies target Linux Docker Host role'
    Assert-True ($reqMd -match 'docker compose \(v2\)') 'Requirements markdown lists docker compose v2'

    Assert-True ($reqMd -match 'PowerShell 7\+ \(`pwsh`\)') 'Requirements markdown lists pwsh runtime'

    $reqJson = Get-Content -LiteralPath $reqPipeline[0].JsonPath -Raw | ConvertFrom-Json
    Assert-True ($null -ne $reqJson.targetHost) 'Requirements JSON includes targetHost object'
    Assert-True ($reqJson.targetHost.role -match 'Linux Docker Host') 'Requirements JSON records targetHost role'

    # 6) Invoke-SailPointConnect -Platform EntroOutpost KubernetesHelm BuildRequirements
    $k8sReqOutDir = Join-Path $tmp 'req-k8s'
    $k8sReqPipeline = @(Invoke-SailPointConnect -Platform EntroOutpost -KubernetesHelm -Action BuildRequirements -NonInteractive -Project 'outpost-proj' -OutputDirectory $k8sReqOutDir -OutputFormat Json)
    Assert-Equal 1 $k8sReqPipeline.Count 'Invoke-SailPointConnect EntroOutpost returns 1 PSCustomObject'
    $k8sReqMd = Get-Content -LiteralPath $k8sReqPipeline[0].Path -Raw
    Assert-True ($k8sReqMd -match 'Kubernetes Control Workstation') 'K8s requirements specifies Kubernetes Control Workstation role'
    Assert-True ($k8sReqMd -match 'helm \(v3\+\)') 'K8s requirements lists helm v3+'

    # 7) BuildScript excludes plaintext secrets & parses cleanly with zero syntax errors
    $bsOutDir = Join-Path $tmp 'build-script'
    $superCrPat = 'ghp_SENSITIVE_CR_PAT_DO_NOT_LEAK_12345'
    $superAwsSecret = 'AWS_SECRET_DO_NOT_LEAK_98765'
    $superEntroPw = 'ENTRO_PW_DO_NOT_LEAK_54321'

    $bsDocker = @(Connect-SailPointEntroOutpost -DockerCompose -Action BuildScript -NonInteractive `
        -Project 'outpost-proj' -WorkerGroup 'wg-prod-1' -InstallDirectory '/opt/custom-outpost' `
        -AwsRegion 'us-west-2' -AwsAccessKeyId 'AKIA_TEST_ID' -AwsSecretAccessKey $superAwsSecret `
        -CrPat $superCrPat -ComposeFileUrl 'https://example.invalid/docker-compose.yaml' `
        -OutputBucket 'entro-out-bucket' -SqsQueueUrl 'https://sqs.us-west-2.amazonaws.com/123/q' `
        -EnableEncryptedSecrets Yes -OutputDirectory $bsOutDir -OutputFormat Json)
    Assert-Equal 1 $bsDocker.Count 'Docker BuildScript returns 1 object'
    $dockerScriptText = Get-Content -LiteralPath $bsDocker[0].Path -Raw
    Assert-True ($dockerScriptText -notmatch 'Get-Command pwsh') 'BuildScript does not emit Get-Command pwsh check'
    Assert-True ($dockerScriptText -match '# Target Host:') 'BuildScript includes Target Host header comment'
    Assert-True ($dockerScriptText -match 'IsLinux\(\)') 'BuildScript includes Linux AMD64 assertion'
    Assert-True (-not $dockerScriptText.Contains($superCrPat)) 'Docker BuildScript does NOT contain plaintext CrPat'
    Assert-True (-not $dockerScriptText.Contains($superAwsSecret)) 'Docker BuildScript does NOT contain plaintext AwsSecretAccessKey'
    Assert-True ($dockerScriptText -match '\$CrPat = \$env:CrPat') 'Docker BuildScript reads CrPat from env var'
    Assert-True ($dockerScriptText -match '\$AwsSecretAccessKey = \$env:AwsSecretAccessKey') 'Docker BuildScript reads AwsSecretAccessKey from env var'

    $parseErrorsDocker = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($dockerScriptText, [ref]$null, [ref]$parseErrorsDocker)
    Assert-Equal 0 $parseErrorsDocker.Count 'Generated Docker BuildScript parses with zero PowerShell syntax errors'

    $bsK8s = @(Connect-SailPointEntroOutpost -KubernetesHelm -Action BuildScript -NonInteractive `
        -Project 'outpost-proj' -WorkerGroup 'wg-k8s-1' -KubernetesNamespace 'entro-ns' `
        -HelmReleaseName 'entro-rel' -AwsAccessKeyId 'AKIA_TEST_ID' -AwsSecretAccessKey $superAwsSecret `
        -CrPat $superCrPat -EntroConnectorId 'conn-123' -EntroPassword $superEntroPw `
        -EnableScheduling Yes -OutputDirectory $bsOutDir -OutputFormat Json)
    Assert-Equal 1 $bsK8s.Count 'K8s BuildScript returns 1 object'
    $k8sScriptText = Get-Content -LiteralPath $bsK8s[0].Path -Raw
    Assert-True (-not $k8sScriptText.Contains($superCrPat)) 'K8s BuildScript does NOT contain plaintext CrPat'
    Assert-True (-not $k8sScriptText.Contains($superAwsSecret)) 'K8s BuildScript does NOT contain plaintext AwsSecretAccessKey'
    Assert-True (-not $k8sScriptText.Contains($superEntroPw)) 'K8s BuildScript does NOT contain plaintext EntroPassword'
    Assert-True ($k8sScriptText -match 'Get-Command helm') 'K8s BuildScript checks helm CLI'

    $parseErrorsK8s = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($k8sScriptText, [ref]$null, [ref]$parseErrorsK8s)
    Assert-Equal 0 $parseErrorsK8s.Count 'Generated K8s BuildScript parses with zero PowerShell syntax errors'

    # 8) CheckProbe tests (Docker & K8s Pass / Fail via SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON)
    $checkOutDir = Join-Path $tmp 'check-out'
    $env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON = (@{
        IsLinux         = $true
        Architecture    = 'X64'
        CpuCores        = 16
        RamGb           = 64
        FreeDiskGb      = 120
        DockerAvailable = $true
        ComposeAvailable = $true
        DefaultEgressOk = $true
    } | ConvertTo-Json -Compress)

    $chkPass = @(Connect-SailPointEntroOutpost -DockerCompose -Action Check -NonInteractive -Project 'outpost-proj' -OutputDirectory $checkOutDir -OutputFormat Json)
    Assert-Equal 1 $chkPass.Count 'Docker Check returns 1 object'
    Assert-Equal 'Pass' $chkPass[0].Verdict 'Docker Check verdict is Pass when mocked host meets all criteria'
    $chkPassReport = Get-Content -LiteralPath $chkPass[0].Path -Raw
    Assert-True ($chkPassReport -match 'Target host:') 'Check report includes Target host line'

    $env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON = (@{
        IsLinux         = $false
        Architecture    = 'Arm64'
        CpuCores        = 4
        RamGb           = 16
        FreeDiskGb      = 20
        DockerAvailable = $false
        ComposeAvailable = $false
        DefaultEgressOk = $false
    } | ConvertTo-Json -Compress)

    $failCheckOutDir = Join-Path $tmp 'check-out-fail'
    $chkFailThrew = $false
    try {
        Connect-SailPointEntroOutpost -DockerCompose -Action Check -NonInteractive -Project 'outpost-proj' -OutputDirectory $failCheckOutDir -OutputFormat Json | Out-Null
    }
    catch {
        $chkFailThrew = $true
    }
    Assert-True $chkFailThrew 'Docker Check in NonInteractive mode throws when host requirements fail'
    $failReportPath = Join-Path $failCheckOutDir 'entro-outpost-docker-check.md'
    Assert-True (Test-Path -LiteralPath $failReportPath) 'Fail check still writes markdown report'
    $failReportText = Get-Content -LiteralPath $failReportPath -Raw
    Assert-True ($failReportText -match 'Verdict: FAIL' -and $failReportText -match '\*\*MISSING\*\*') 'Fail check report records FAIL verdict and MISSING items'

    $env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON = (@{
        HelmAvailable       = $true
        KubectlAvailable    = $true
        KubeLinuxAmd64Nodes = 2
        KubeClusterCpu      = 12
        KubeClusterRamGb    = 32
        DefaultEgressOk     = $true
    } | ConvertTo-Json -Compress)

    $k8sChkPass = @(Connect-SailPointEntroOutpost -KubernetesHelm -Action Check -NonInteractive -Project 'outpost-proj' -OutputDirectory $checkOutDir -OutputFormat Json)
    Assert-Equal 'Pass' $k8sChkPass[0].Verdict 'K8s Check verdict is Pass when mocked cluster meets all criteria'

    # 9) Action = Run on non-Linux/non-X64 fails TargetHost.Assert cleanly
    $env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON = (@{
        IsLinux          = $false
        Architecture     = 'Arm64'
        DockerAvailable  = $true
        ComposeAvailable = $true
    } | ConvertTo-Json -Compress)
    $composeSrc = Join-Path $tmp 'source-compose.yaml'
    Set-Content -LiteralPath $composeSrc -Value "services:`n  connector:`n    image: ghcr.io/entro/connector:latest" -Encoding utf8
    $installDir = Join-Path $tmp 'docker-install-fail'

    $nonLinuxThrew = $false
    try {
        Connect-SailPointEntroOutpost -DockerCompose -Action Run -NonInteractive `
            -InstallDirectory $installDir -ComposeFileUrl $composeSrc `
            -AwsAccessKeyId 'AKIA_TEST' -AwsSecretAccessKey $superAwsSecret `
            -CrPat $superCrPat -OutputBucket 'b' -SqsQueueUrl 'https://sqs.us-east-1.amazonaws.com/1/q' `
            -Confirm:$false | Out-Null
    }
    catch {
        $nonLinuxThrew = $true
    }
    Assert-True $nonLinuxThrew 'Docker Compose Run throws cleanly when target host is not Linux AMD64'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $installDir '.env-connector'))) 'Failed TargetHost.Assert does not write .env-connector'

    # 10) Action = Run (DockerCompose & KubernetesHelm) with mocked Linux X64 host & mock CLI
    $mockCliLog = Join-Path $tmp 'mock-cli.log'
    $env:SAILPOINT_CONNECT_TEST_OUTPOST_MOCK_CLI = '1'
    $env:SAILPOINT_CONNECT_TEST_OUTPOST_LOG_PATH = $mockCliLog
    $env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON = (@{
        IsLinux          = $true
        Architecture     = 'X64'
        CpuCores         = 8
        RamGb            = 32
        FreeDiskGb       = 80
        DockerAvailable  = $true
        ComposeAvailable = $true
        HelmAvailable    = $true
        KubectlAvailable = $true
    } | ConvertTo-Json -Compress)

    $dockerInstallDir = Join-Path $tmp 'docker-install-ok'
    $dockerRunOutDir = Join-Path $tmp 'docker-run-out'
    $dockerRunRes = @(Connect-SailPointEntroOutpost -DockerCompose -Action Run -NonInteractive `
        -Project 'outpost-proj' -WorkerGroup 'wg-docker-live' -InstallDirectory $dockerInstallDir `
        -ComposeFileUrl $composeSrc -AwsRegion 'us-east-1' `
        -AwsAccessKeyId 'AKIA_LIVE' -AwsSecretAccessKey $superAwsSecret `
        -CrPat $superCrPat -OutputBucket 'out-bkt' -SqsQueueUrl 'https://sqs.us-east-1.amazonaws.com/123/q' `
        -EnableEncryptedSecrets Yes -UseProxy Yes -HttpProxy 'http://proxy.corp:3128' -NoProxy 'localhost' `
        -OutputDirectory $dockerRunOutDir -OutputFormat Json -Confirm:$false)
    Assert-Equal 1 $dockerRunRes.Count 'Docker Run returns 1 PSCustomObject'
    Assert-Equal 'Success' $dockerRunRes[0].Status 'Docker Run succeeds on mocked Linux AMD64 host'
    Assert-True (Test-Path -LiteralPath (Join-Path $dockerInstallDir '.env-connector')) 'Docker Run creates .env-connector'
    Assert-True (Test-Path -LiteralPath (Join-Path $dockerInstallDir 'docker-compose.yaml')) 'Docker Run stages docker-compose.yaml'
    Assert-True (Test-Path -LiteralPath (Join-Path $dockerInstallDir 'keys/public.key')) 'Docker Run generates RSA public.key'

    $envFileContent = Get-Content -LiteralPath (Join-Path $dockerInstallDir '.env-connector') -Raw
    Assert-True ($envFileContent -match 'SECRET_PRIVATE_KEY=.+') 'Docker Run writes SECRET_PRIVATE_KEY to .env-connector'
    Assert-True ($envFileContent -match 'HTTP_PROXY=http://proxy\.corp:3128') 'Docker Run writes HTTP_PROXY to .env-connector'

    $k8sRunOutDir = Join-Path $tmp 'k8s-run-out'
    $k8sRunRes = @(Connect-SailPointEntroOutpost -KubernetesHelm -Action Run -NonInteractive `
        -Project 'outpost-proj' -WorkerGroup 'wg-k8s-live' -KubernetesNamespace 'entro-live' `
        -HelmReleaseName 'entro-rel-live' -AwsAccessKeyId 'AKIA_K8S' -AwsSecretAccessKey $superAwsSecret `
        -CrPat $superCrPat -EntroConnectorId 'conn-live' -EntroPassword $superEntroPw `
        -EnableEncryptedSecrets Yes -OutputDirectory $k8sRunOutDir -OutputFormat Json -Confirm:$false)
    Assert-Equal 1 $k8sRunRes.Count 'K8s Run returns 1 PSCustomObject'
    Assert-Equal 'Success' $k8sRunRes[0].Status 'K8s Run succeeds on mocked host'

    $cliLogContent = Get-Content -LiteralPath $mockCliLog -Raw
    Assert-True ($cliLogContent -match 'docker login ghcr\.io') 'Mock CLI logged docker login'
    Assert-True ($cliLogContent -match 'docker compose .* up -d') 'Mock CLI logged docker compose up -d'
    Assert-True ($cliLogContent -match 'helm registry login ghcr\.io') 'Mock CLI logged helm registry login'
    Assert-True ($cliLogContent -match 'helm upgrade --install entro-rel-live') 'Mock CLI logged helm upgrade --install'
    Assert-True (-not $cliLogContent.Contains($superCrPat)) 'Mock CLI log never records CrPat'
    Assert-True (-not $cliLogContent.Contains($superAwsSecret)) 'Mock CLI log never records AwsSecretAccessKey'
    Assert-True (-not $cliLogContent.Contains($superEntroPw)) 'Mock CLI log never records EntroPassword'

    # 11) Verify outpost-index.json persistence, rank protection, and secret exclusion
    $outpostIndexPath = Get-IntegrationProjectOutpostIndexPath -ProjectName 'outpost-proj'
    Assert-True (Test-Path -LiteralPath $outpostIndexPath) 'outpost-index.json created in project'
    $indexRaw = Get-Content -LiteralPath $outpostIndexPath -Raw
    Assert-True (-not $indexRaw.Contains($superCrPat)) 'outpost-index.json does NOT contain CrPat'
    Assert-True (-not $indexRaw.Contains($superAwsSecret)) 'outpost-index.json does NOT contain AwsSecretAccessKey'
    Assert-True (-not $indexRaw.Contains($superEntroPw)) 'outpost-index.json does NOT contain EntroPassword'

    $savedOutposts = @(Find-IntegrationProjectOutpost -ProjectName 'outpost-proj')
    $dockerSaved = @($savedOutposts | Where-Object { $_['workerGroupName'] -eq 'wg-docker-live' })[0]
    Assert-Equal 'Deployed' ([string]$dockerSaved['status']) 'Docker Run outpost recorded with Deployed status'
    Assert-Equal 'DockerCompose' ([string]$dockerSaved['deploymentMode']) 'Docker Run outpost recorded with DockerCompose mode'
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$dockerSaved['publicKeyPath'])) 'Docker Run outpost records publicKeyPath'

    # Subsequent BuildRequirements with same worker group must NOT downgrade Deployed -> Planned
    Connect-SailPointEntroOutpost -DockerCompose -Action BuildRequirements -NonInteractive `
        -Project 'outpost-proj' -WorkerGroup 'wg-docker-live' -OutputDirectory $reqOutDir | Out-Null
    $afterReq = @(Find-IntegrationProjectOutpost -ProjectName 'outpost-proj' | Where-Object { $_['workerGroupName'] -eq 'wg-docker-live' })[0]
    Assert-Equal 'Deployed' ([string]$afterReq['status']) 'BuildRequirements does not downgrade Deployed status in outpost-index.json'

    # 12) Outpost dependency resolver (Case C non-interactive + filtered launcher invocation)
    $depProj = 'dep-proj'
    Set-SailPointConnectProject -Name $depProj | Out-Null
    $vaultBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'hashicorp-vault' -Product 'entro' -VariantId 'vault'

    # 12a: 0 outposts + Action=Run + NonInteractive -> throws
    $depCtxNoOutpost = @{ Project = $depProj; IntegrationProjectName = $depProj; Action = 'Run' }
    $missingOutpostThrew = $false
    try {
        Resolve-IntegrationCatalogOutpostDependency -Context $depCtxNoOutpost -Binding $vaultBinding -WizardRoot $connectRoot -NonInteractive | Out-Null
    }
    catch {
        $missingOutpostThrew = $true
    }
    Assert-True $missingOutpostThrew 'Non-interactive Run on requiresOutpost integration throws when 0 outposts exist'

    # 12b: 1 outpost -> auto-links non-interactively
    $null = Save-IntegrationProjectOutpost -ProjectName $depProj -Context @{
        WorkerGroup          = 'wg-auto'
        DeploymentMode       = 'DockerCompose'
        OutpostPublicKeyPath = '/opt/keys/public.key'
        Action               = 'Run'
    } -Status 'Deployed'
    $depCtxOne = @{ Project = $depProj; IntegrationProjectName = $depProj; Action = 'Run' }
    $linkedOne = Resolve-IntegrationCatalogOutpostDependency -Context $depCtxOne -Binding $vaultBinding -WizardRoot $connectRoot -NonInteractive
    Assert-Equal 'wg-auto' ([string]$linkedOne['workerGroupName']) 'Single outpost is auto-linked in non-interactive mode'
    Assert-Equal 'wg-auto' ([string]$depCtxOne['WorkerGroup']) 'Context receives WorkerGroup from auto-linked outpost'

    # 12c: 2 outposts -> throws without -WorkerGroup, resolves with -WorkerGroup
    $null = Save-IntegrationProjectOutpost -ProjectName $depProj -Context @{
        WorkerGroup    = 'wg-second'
        DeploymentMode = 'KubernetesHelm'
        Action         = 'Check'
    } -Status 'Verified'
    $depCtxTwoAmbiguous = @{ Project = $depProj; IntegrationProjectName = $depProj; Action = 'Run' }
    $ambigThrew = $false
    try {
        Resolve-IntegrationCatalogOutpostDependency -Context $depCtxTwoAmbiguous -Binding $vaultBinding -WizardRoot $connectRoot -NonInteractive | Out-Null
    }
    catch {
        $ambigThrew = $true
    }
    Assert-True $ambigThrew 'Multiple outposts require explicit -WorkerGroup or -OutpostId in non-interactive mode'

    $depCtxTwoExplicit = @{ Project = $depProj; IntegrationProjectName = $depProj; Action = 'Run'; WorkerGroup = 'wg-second' }
    $linkedExplicit = Resolve-IntegrationCatalogOutpostDependency -Context $depCtxTwoExplicit -Binding $vaultBinding -WizardRoot $connectRoot -NonInteractive
    Assert-Equal 'wg-second' ([string]$linkedExplicit['workerGroupName']) 'Explicit -WorkerGroup resolves matching outpost'
    Assert-Equal 'KubernetesHelm' ([string]$depCtxTwoExplicit['OutpostDeploymentMode']) 'Explicit -WorkerGroup populates OutpostDeploymentMode'

    # 12d: Interactive Case B (0 outposts -> register External) using mocked ReadChoice/ReadInput
    $extProj = 'ext-proj'
    Set-SailPointConnectProject -Name $extProj | Out-Null
    $catalogModule = Get-Module 'IW.CatalogMenu'
    & $catalogModule {
        $script:OrigChoice = Get-Item Function:Invoke-IntegrationCatalogReadChoice
        $script:OrigInput = Get-Item Function:Read-InputString -ErrorAction SilentlyContinue
        $script:ExtChoices = [System.Collections.Generic.Queue[string]]::new()
        $script:ExtChoices.Enqueue('register')
        $script:ExtChoices.Enqueue('DockerCompose')
        $script:ExtInputs = [System.Collections.Generic.Queue[string]]::new()
        $script:ExtInputs.Enqueue('wg-external-ui')
        $script:ExtInputs.Enqueue('')
        function script:Invoke-IntegrationCatalogReadChoice {
            param([string]$Prompt, [string[]]$Options, [string[]]$Labels, [string]$Default, [switch]$AllowBack)
            if ($script:ExtChoices.Count -eq 0) { throw "Unexpected choice prompt: $Prompt" }
            return $script:ExtChoices.Dequeue()
        }
        function script:Read-InputString {
            param([string]$Prompt, [string]$Default, [switch]$Required, [switch]$Mask)
            if ($script:ExtInputs.Count -eq 0) { throw "Unexpected input prompt: $Prompt" }
            return $script:ExtInputs.Dequeue()
        }
    }
    try {
        $extCtx = @{ Project = $extProj; IntegrationProjectName = $extProj; Action = 'Run' }
        $extRes = Resolve-IntegrationCatalogOutpostDependency -Context $extCtx -Binding $vaultBinding -WizardRoot $connectRoot
        Assert-Equal 'wg-external-ui' ([string]$extRes['workerGroupName']) 'External registration saves workerGroupName'
        Assert-Equal 'External' ([string]$extRes['status']) 'External registration saves External status'
    }
    finally {
        & $catalogModule {
            Set-Item -Path Function:Invoke-IntegrationCatalogReadChoice -Value $script:OrigChoice
            if ($script:OrigInput) {
                Set-Item -Path Function:Read-InputString -Value $script:OrigInput
            }
            else {
                Remove-Item -Path Function:Read-InputString -ErrorAction SilentlyContinue
            }
        }
    }

    # 12e: Launcher filters OutpostParameters cleanly against HashiCorp Vault.ps1 (no ParameterBindingException)
    $vaultOutDir = Join-Path $tmp 'vault-with-outpost'
    $launchErr = $null
    try {
        Invoke-IntegrationCatalogLauncher -WizardRoot $connectRoot `
            -Integration $vaultInt -Binding $vaultBinding -Product 'entro' `
            -BaseParameters @{
                Project         = $depProj
                Action          = 'BuildRequirements'
                Environment     = 'prod'
                VaultUrl        = 'https://vault.corp.local:8200'
                OutputDirectory = $vaultOutDir
                NonInteractive  = $true
            } `
            -OutpostParameters @{ WorkerGroup = 'wg-auto'; OutpostId = $linkedOne['id']; OutpostDeploymentMode = 'DockerCompose' }
    }
    catch {
        $launchErr = $_
    }
    Assert-True ($null -eq $launchErr) "Launcher filters unsupported OutpostParameters cleanly (error: $launchErr)"
    Assert-True (Test-Path -LiteralPath (Join-Path $vaultOutDir 'hashicorp-vault-entro-requirements.md')) 'HashiCorp Vault launcher wrote requirements cleanly even when OutpostParameters were supplied'
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_ROOT -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_TEST_HOST_FACTS_JSON -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_TEST_OUTPOST_MOCK_CLI -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_TEST_OUTPOST_LOG_PATH -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "PASS ($script:AssertionCount assertions)"

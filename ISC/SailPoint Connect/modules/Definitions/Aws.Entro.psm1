Set-StrictMode -Version Latest

function Get-EntroAwsTemplatePath {
    param(
        [ValidateSet('Default', 'Europe')]
        [string]$Region = 'Default'
    )
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue
    $base = Join-Path (Get-EntroConnectSkillRoot) 'integrations/amazon-web-services'
    if ($Region -eq 'Europe') {
        return Join-Path $base 'Entro Security AWS Template - Europe region.json'
    }
    Join-Path $base 'Entro Security AWS Template.json'
}

function Get-EntroAwsCloudFormationStackName {
    param([Parameter(Mandatory)][string]$ExternalId)
    $safe = ($ExternalId -replace '[^A-Za-z0-9-]', '-').Trim('-')
    if (-not $safe) { $safe = 'account' }
    $name = "Entro-$safe"
    if ($name.Length -gt 128) { $name = $name.Substring(0, 128).TrimEnd('-') }
    return $name
}

function Get-EntroAwsCloudFormationProbeResult {
    param([string]$StackStatus)
    $status = if ($StackStatus) { $StackStatus.Trim() } else { '' }
    if (-not $status -or $status -eq 'None') { return 'Create' }
    if ($status -in @('CREATE_COMPLETE', 'UPDATE_COMPLETE')) { return 'Skip' }
    if ($status -like '*IN_PROGRESS') { return 'Skip' }
    return 'Update'
}

function Get-EntroAwsWizardWorkDirectory {
    param([hashtable]$Context)
    $base = if ($Context['OutputDirectory']) { $Context['OutputDirectory'] } else { Get-Location }
    Join-Path $base 'entro-aws'
}

function Get-EntroAwsRoleArn {
    param([hashtable]$Context)
    if ($Context['EntroRoleArn']) { return [string]$Context['EntroRoleArn'] }
    $rn = if ($Context['EntroRoleName']) { $Context['EntroRoleName'] } else { 'EntroReadOnly' }
    $arn = aws iam get-role --role-name $rn --query Role.Arn --output text 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$arn)) { return $null }
    $Context['EntroRoleArn'] = ([string]$arn).Trim()
    return $Context['EntroRoleArn']
}

function Get-EntroAwsHandoffStep {
    param([hashtable]$Context)
    $method = if ($Context['Method']) { $Context['Method'] } else { 'AssumeRole' }
    $rn = if ($Context['EntroRoleName']) { $Context['EntroRoleName'] } else { 'EntroReadOnly' }
    $manual = switch ($method) {
        'CloudFormation' { 'The wizard deployed the Entro CloudFormation stack, and the stack notifies Entro. In Entro, confirm the AWS account appears under Accounts.' }
        'Terraform' { 'Apply Terraform-Entro.tf from the Entro AWS integration folder, then add the account in Entro (Add account, AWS) with the Role ARN it outputs.' }
        default { "In Entro, Add account, AWS, Assume Role: paste the Role ARN of $rn (printed at the end of this run) and an Environment name." }
    }
    @{
        Id     = 'entro-handoff'
        Title  = 'Register in Entro UI'
        Kind   = 'Manual'
        Manual = $manual
    }
}

function Register-AwsEntroDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'aws-entro'
        Platform     = 'AWS'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'aws'
        Title        = 'Entro AWS integration'
        FolderName   = 'Entro-AWS'
        AccessLevels = @()
        AdminRoles   = @('IAM policy and role management')
        OutputsHelp  = 'Paste Environment label and AWS Role ARN into the Entro admin console (Add account → AWS).'
        Inputs       = @(
            @{ Name = 'EntroExternalId'; Source = 'Supply'; Prompt = 'Entro External ID from the wizard'; Purpose = 'IAM trust ExternalId for Entro'; Required = $true }
            @{ Name = 'Method'; Source = 'Supply'; Prompt = 'Integration method'; Purpose = 'How Entro connects'; Required = $true; ValidateSet = @('AssumeRole', 'CloudFormation', 'Terraform'); Default = 'AssumeRole' }
            @{ Name = 'EntroTemplateRegion'; Source = 'Supply'; Prompt = 'Entro template region'; Purpose = 'Default vs Europe SNS region'; Required = $false; ValidateSet = @('Default', 'Europe'); Default = 'Default' }
            @{ Name = 'EntroRoleName'; Source = 'Supply'; Prompt = 'Entro IAM role name'; Purpose = 'Entro read role'; Required = $false; Default = 'EntroReadOnly' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'EntroRoleName'; Source = 'Supply'; Prompt = 'Entro IAM role name'; Purpose = 'Entro read role to verify'; Required = $false; Default = 'EntroReadOnly' }
            @{ Name = 'ProfileName'; Source = 'Supply'; Prompt = 'AWS profile name (optional)'; Purpose = 'Credential profile for aws CLI'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-trust'
                    Title = 'Create Entro trust role and read policy'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        $method = if ($c['Method']) { $c['Method'] } else { 'AssumeRole' }
                        if ($method -eq 'Terraform') { return 'Skip' }
                        if ($method -eq 'CloudFormation') {
                            if ([string]::IsNullOrWhiteSpace([string]$c['EntroExternalId'])) { return 'Create' }
                            $stack = Get-EntroAwsCloudFormationStackName -ExternalId ([string]$c['EntroExternalId'])
                            $region = if ($c['Region']) { $c['Region'] } else { 'us-east-1' }
                            $status = aws cloudformation describe-stacks --stack-name $stack --region $region --query 'Stacks[0].StackStatus' --output text 2>$null
                            if ($LASTEXITCODE -ne 0) { return 'Create' }
                            return Get-EntroAwsCloudFormationProbeResult -StackStatus ([string]$status)
                        }
                        $rn = if ($c['EntroRoleName']) { $c['EntroRoleName'] } else { 'EntroReadOnly' }
                        $exists = aws iam get-role --role-name $rn 2>$null
                        if ($LASTEXITCODE -eq 0) { return 'Skip' }
                        'Create'
                    }
                    Run   = {
                        param($c)
                        $method = if ($c['Method']) { $c['Method'] } else { 'AssumeRole' }
                        if ($method -eq 'Terraform') {
                            Write-Info 'Terraform method: use Entro Terraform-Entro.tf in the Entro AWS integration folder.'
                            return
                        }
                        $modRoot = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'modules'
                        Import-Module (Join-Path $modRoot 'ISC.EntroAws.psm1') -Force
                        $tplRegion = if ($c['EntroTemplateRegion']) { $c['EntroTemplateRegion'] } else { 'Default' }
                        $tpl = Get-EntroAwsTemplatePath -Region $tplRegion
                        $work = Get-EntroAwsWizardWorkDirectory -Context $c
                        $rn = if ($c['EntroRoleName']) { $c['EntroRoleName'] } else { 'EntroReadOnly' }
                        if ($method -eq 'CloudFormation') {
                            $stack = Get-EntroAwsCloudFormationStackName -ExternalId ([string]$c['EntroExternalId'])
                            $region = if ($c['Region']) { $c['Region'] } else { 'us-east-1' }
                            Invoke-EntroAwsCloudFormationDeploy -TemplatePath $tpl -StackName $stack `
                                -ExternalId $c['EntroExternalId'] -Region $region | Out-Null
                        }
                        else {
                            $c['EntroRoleArn'] = Invoke-EntroAwsAssumeRoleSetup -EntroExternalId $c['EntroExternalId'] -RoleName $rn `
                                -TemplatePath $tpl -WorkDirectory $work
                        }
                    }
                    BuildScript = {
                        param($c)
                        $method = if ($c['Method']) { $c['Method'] } else { 'AssumeRole' }
                        if ($method -eq 'Terraform') {
                            return '# Use Entro Terraform-Entro.tf from the Entro AWS integration catalog.'
                        }
                        $rn = if ($c['EntroRoleName']) { $c['EntroRoleName'] } else { 'EntroReadOnly' }
                        $extId = [string]$c['EntroExternalId']

                        @"
# -----------------------------------------------------------------------------
# Entro AWS Integration Setup ($method)
# -----------------------------------------------------------------------------
`$roleName = '$rn'
`$externalId = '$extId'
`$entroAccountId = '937217723901'

Write-Host "Checking AWS account identity..." -ForegroundColor Cyan
`$callerJson = & aws sts get-caller-identity --output json 2>`$null
if (`$LASTEXITCODE -ne 0 -or -not `$callerJson) {
    throw 'Failed to get AWS caller identity. Ensure your AWS credentials/profile are configured.'
}
`$caller = `$callerJson | ConvertFrom-Json
`$accountId = `$caller.Account
Write-Host "AWS Account ID: `$accountId" -ForegroundColor Green

# Prepare Entro Trust Policy JSON
`$trustRoleArn = "arn:aws:iam::`$(`$entroAccountId):role/EntroTrustRole-`$externalId"
`$userArn = "arn:aws:iam::`$(`$entroAccountId):user/liminal-saas-assume-role"

`$trustPolicy = [ordered]@{
    Version = '2012-10-17'
    Statement = @(
        [ordered]@{
            Effect    = 'Allow'
            Principal = @{ AWS = `$userArn }
            Action    = 'sts:AssumeRole'
            Condition = @{ StringEquals = @{ 'sts:ExternalId' = `$externalId } }
        },
        [ordered]@{
            Effect    = 'Allow'
            Principal = @{ AWS = `$trustRoleArn }
            Action    = 'sts:AssumeRole'
            Condition = @{ StringEquals = @{ 'sts:ExternalId' = `$externalId } }
        }
    )
} | ConvertTo-Json -Depth 5 -Compress

# Create or Update IAM Role
Write-Host "Ensuring IAM Role `$roleName for Entro..." -ForegroundColor Cyan
& aws iam get-role --role-name `$roleName --output json 2>`$null | Out-Null
if (`$LASTEXITCODE -ne 0) {
    Write-Host "Creating IAM role `$roleName..."
    & aws iam create-role --role-name `$roleName --assume-role-policy-document `$trustPolicy --description "Entro Security AWS Integration Role" --output json --quiet
} else {
    Write-Host "Updating trust policy on `$roleName..."
    & aws iam update-assume-role-policy --role-name `$roleName --policy-document `$trustPolicy --output json --quiet
}

# Attach SecurityAudit policy
Write-Host "Attaching SecurityAudit policy..." -ForegroundColor Cyan
& aws iam attach-role-policy --role-name `$roleName --policy-arn "arn:aws:iam::aws:policy/SecurityAudit" --output json 2>`$null

`$roleArn = "arn:aws:iam::`$accountId:role/`$roleName"
Write-Host ''
Write-Host '========================================================================' -ForegroundColor Cyan
Write-Host "Entro AWS Role configuration complete: `$roleArn" -ForegroundColor Green
Write-Host "Register in Entro UI (Add account -> AWS -> Assume Role):" -ForegroundColor Yellow
Write-Host "  Role ARN:     `$roleArn"
Write-Host "  External ID:  `$externalId"
Write-Host "  Environment:  (your label)"
Write-Host '========================================================================' -ForegroundColor Cyan
"@
                    }
                }
                (Get-EntroAwsHandoffStep -Context $ctx)
            )
        }
        OnRunComplete = {
            param($ctx)
            $method = if ($ctx['Method']) { $ctx['Method'] } else { 'AssumeRole' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host '  Environment: (your label)'
            Write-Host "  External ID: $($ctx['EntroExternalId'])"
            if ($method -eq 'CloudFormation') {
                $tplRegion = if ($ctx['EntroTemplateRegion']) { $ctx['EntroTemplateRegion'] } else { 'Default' }
                Write-Host "  Template: $(Get-EntroAwsTemplatePath -Region $tplRegion)"
            }
            elseif ($method -eq 'AssumeRole') {
                $arn = Get-EntroAwsRoleArn -Context $ctx
                Write-Host "  Role ARN: $(if ($arn) { $arn } else { '(not found; run aws iam get-role)' })"
            }
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-AwsEntroDefinitions, Get-EntroAwsTemplatePath, Get-EntroAwsCloudFormationStackName, Get-EntroAwsCloudFormationProbeResult

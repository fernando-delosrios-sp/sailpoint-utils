#Requires -Version 7
Set-StrictMode -Version Latest

$script:EntroAwsAccountId = '937217723901'

function Get-EntroAwsReadPolicyDocument {
    param([Parameter(Mandatory)][string]$TemplatePath)

    $tpl = Get-Content -LiteralPath $TemplatePath -Raw | ConvertFrom-Json
    $statements = @($tpl.Resources.EntroRole.Properties.Policies[0].PolicyDocument.Statement)
    $actions = @($statements[0].Action)
    if ($actions.Count -eq 0) { throw "No actions found in Entro template: $TemplatePath" }
    return (@{
        Version   = '2012-10-17'
        Statement = @(@{ Effect = 'Allow'; Action = $actions; Resource = '*' })
    } | ConvertTo-Json -Depth 10 -Compress)
}

function Get-EntroAwsTrustPolicyDocument {
    param(
        [Parameter(Mandatory)][string]$ExternalId,
        [string]$EntroAccountId = $script:EntroAwsAccountId
    )

    $trustRoleArn = "arn:aws:iam::${EntroAccountId}:role/EntroTrustRole-${ExternalId}"
    $userArn = "arn:aws:iam::${EntroAccountId}:user/liminal-saas-assume-role"
    return (@{
        Version   = '2012-10-17'
        Statement = @(
            @{
                Effect    = 'Allow'
                Principal = @{ AWS = $userArn }
                Action    = 'sts:AssumeRole'
                Condition = @{ StringEquals = @{ 'sts:ExternalId' = $ExternalId } }
            }
            @{
                Effect    = 'Allow'
                Principal = @{ AWS = $trustRoleArn }
                Action    = 'sts:AssumeRole'
                Condition = @{ StringEquals = @{ 'sts:ExternalId' = $ExternalId } }
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress)
}

function Invoke-EntroAwsAssumeRoleSetup {
    param(
        [Parameter(Mandatory)][string]$EntroExternalId,
        [Parameter(Mandatory)][string]$RoleName,
        [Parameter(Mandatory)][string]$TemplatePath,
        [Parameter(Mandatory)][string]$WorkDirectory
    )

    if (-not (Test-Path -LiteralPath $WorkDirectory)) {
        New-Item -ItemType Directory -Path $WorkDirectory -Force | Out-Null
    }
    $trustPath = Join-Path $WorkDirectory 'entro-trust-policy.json'
    $readPath = Join-Path $WorkDirectory 'entro-read-policy.json'
    Set-Content -LiteralPath $trustPath -Value (Get-EntroAwsTrustPolicyDocument -ExternalId $EntroExternalId) -Encoding utf8
    Set-Content -LiteralPath $readPath -Value (Get-EntroAwsReadPolicyDocument -TemplatePath $TemplatePath) -Encoding utf8

    $policyName = 'EntroReadOnlyAccess'
    $policyArn = aws iam create-policy --policy-name $policyName --policy-document "file://$readPath" --query Policy.Arn --output text 2>$null
    if ($LASTEXITCODE -ne 0) {
        $policyArn = aws iam list-policies --scope Local --query "Policies[?PolicyName=='$policyName'].Arn | [0]" --output text
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($policyArn) -or $policyArn -eq 'None') {
            throw 'Failed to create or locate EntroReadOnlyAccess policy.'
        }
    }

    aws iam create-role --role-name $RoleName --assume-role-policy-document "file://$trustPath" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to create IAM role $RoleName" }

    aws iam attach-role-policy --role-name $RoleName --policy-arn $policyArn | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to attach policy to role $RoleName" }

    $roleArn = (aws iam get-role --role-name $RoleName --query Role.Arn --output text).Trim()
    if ($roleArn -match '^\{') {
        $parsed = $roleArn | ConvertFrom-Json
        $roleArn = [string]$parsed.Role.Arn
    }
    Write-Ok "Entro role ready: $roleArn"
    return $roleArn
}

function Invoke-EntroAwsCloudFormationDeploy {
    param(
        [Parameter(Mandatory)][string]$TemplatePath,
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$ExternalId,
        [string]$Environment = 'Entro',
        [string]$Region = 'us-east-1'
    )

    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString()
    aws cloudformation deploy `
        --template-file $TemplatePath `
        --stack-name $StackName `
        --parameter-overrides "ExternalId=$ExternalId" "Environment=$Environment" "Timestamp=$timestamp" `
        --capabilities CAPABILITY_NAMED_IAM `
        --region $Region | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "CloudFormation deploy failed for stack $StackName" }
    Write-Ok "CloudFormation stack $StackName deployed"
}

Export-ModuleMember -Function @(
    'Get-EntroAwsTrustPolicyDocument'
    'Get-EntroAwsReadPolicyDocument'
    'Invoke-EntroAwsAssumeRoleSetup'
    'Invoke-EntroAwsCloudFormationDeploy'
)

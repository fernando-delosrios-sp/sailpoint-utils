#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Check.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue

$script:AssertionCount = 0

$readOnlyLines = Get-CheckLinesForAccess -Lists @{ ReadOnly = @('iam:ListUsers'); ReadWrite = @('iam:CreateUser') } -Access 'ReadOnly'
Assert-Equal 'iam:ListUsers' (@($readOnlyLines.Required) -join ',') 'ReadOnly check requires the read actions'
Assert-Equal 'iam:CreateUser' (@($readOnlyLines.PlanningOnly) -join ',') 'ReadOnly check keeps write actions out of the requirement'

$readWriteLines = Get-CheckLinesForAccess -Lists @{ ReadOnly = @('iam:ListUsers'); ReadWrite = @('iam:CreateUser') } -Access 'ReadWrite'
Assert-Equal 'iam:CreateUser,iam:ListUsers' ((@($readWriteLines.Required) | Sort-Object) -join ',') 'ReadWrite check requires both'
Assert-Equal 0 @($readWriteLines.PlanningOnly).Count 'ReadWrite has no planning-only list'

$star = Compare-IntegrationRequirementCoverage -Required @('iam:ListUsers', 'iam:GetUser') -Granted @('iam:*') -ReadableFamilies @('Aws')
Assert-Equal 2 @($star.Met).Count 'iam:* covers both list and get'
Assert-Equal 0 @($star.Missing).Count 'iam:* leaves nothing missing'

$prefix = Compare-IntegrationRequirementCoverage -Required @('iam:GetUser') -Granted @('iam:List*') -ReadableFamilies @('Aws')
Assert-Equal 1 @($prefix.Missing).Count 'iam:List* does not cover iam:GetUser'

$agent = Compare-IntegrationRequirementCoverage -Required @('bedrock-agentcore:ListAgentRuntimes') -Granted @('bedrock-agentcore:*') -ReadableFamilies @('Aws')
Assert-Equal 1 @($agent.Met).Count 'hyphenated service actions are AWS actions and honor wildcards'

$denied = Compare-IntegrationRequirementCoverage -Required @('iam:ListUsers') -Granted @('iam:*') -Denied @('iam:ListUsers') -ReadableFamilies @('Aws')
Assert-Equal 0 @($denied.Met).Count 'an explicit deny is not treated as present'
Assert-True ((@($denied.Missing) -join ' ') -match 'denied') 'deny is called out in the gap'

$graph = Compare-IntegrationRequirementCoverage -Required @('Microsoft Graph: User.Read.All') -Granted @('User.Read.All') -ReadableFamilies @('Named')
Assert-Equal 1 @($graph.Met).Count 'a granted Graph permission matches the resource-qualified requirement'

$scopes = Compare-IntegrationRequirementCoverage -Required @('https://www.googleapis.com/auth/admin.directory.user.readonly', 'logging.buckets.get') -Granted @('logging.buckets.get') -ReadableFamilies @('Iam')
Assert-Equal 'logging.buckets.get' (@($scopes.Met) -join ',') 'GCP IAM permissions compare exactly'
Assert-Equal 1 @($scopes.Manual).Count 'OAuth scopes are left for a person when the reader cannot see them'
Assert-Equal 0 @($scopes.Missing).Count 'an unreadable scope is not reported as missing'

$encoded = [uri]::EscapeDataString('{"Statement":[{"Effect":"Allow","Action":"s3:ListBucket"}]}')
$decoded = Get-IamPolicyGrantSet -Document $encoded
Assert-Equal 's3:ListBucket' (@($decoded.Allow) -join ',') 'URL-encoded policy documents are read'

$mixed = Get-IamPolicyGrantSet -Document @{
    Statement = @(
        @{ Effect = 'Allow'; Action = 'iam:ListUsers' }
        @{ Effect = 'Deny'; Action = @('iam:CreateUser'); NotAction = 'iam:DeleteUser' }
    )
}
Assert-Equal 'iam:ListUsers' (@($mixed.Allow) -join ',') 'allow actions are collected'
Assert-Equal 'iam:CreateUser' (@($mixed.Deny) -join ',') 'deny actions are collected separately'
Assert-True $mixed.NotAction 'NotAction is flagged instead of being expanded'

$saas = Get-IntegrationCheckSubject -Definition @{ Id = 'aws-saas-connector'; Title = 'AWS' } -Context @{}
Assert-Equal 'SailPointAWSRole' $saas.Name 'AWS SaaS check defaults to the connector role name'
Assert-True $saas.Readable 'AWS SaaS role can be read'

$databricks = Get-IntegrationCheckSubject -Definition @{ Id = 'databricks-connector'; Title = 'Databricks' } -Context @{
    ServicePrincipalName = 'sp-1'; AccountId = 'acc'
}
Assert-Equal 'Manual' $databricks.Kind 'Databricks account admin is not read from the CLI'
Assert-True ($databricks.Note -match 'Account Admin') 'Databricks note names the requirement'
Assert-True ($databricks.Note -match 'does not call Databricks') 'Databricks note says the tenant is not called'

Assert-Equal 'Pass' (Get-IntegrationCheckVerdict -AttemptedRead $true -Found $true -Incomplete $false -RequiredCount 2 -MissingCount 0 -ManualCount 0) 'complete coverage passes'
Assert-Equal 'Fail' (Get-IntegrationCheckVerdict -AttemptedRead $true -Found $false -Incomplete $false -RequiredCount 3 -MissingCount 0 -ManualCount 0) 'a missing identity fails'
Assert-Equal 'Review' (Get-IntegrationCheckVerdict -AttemptedRead $false -Found $false -Incomplete $false -RequiredCount 3 -MissingCount 0 -ManualCount 3) 'skipping the read asks a person to compare'
Assert-Equal 'Review' (Get-IntegrationCheckVerdict -AttemptedRead $true -Found $true -Incomplete $false -RequiredCount 0 -MissingCount 0 -ManualCount 0) 'an empty requirement list is not a pass'

function Set-CheckInvoker {
    param([scriptblock]$Invoker)
    $script:CheckCalls = @()
    Set-IntegrationCheckInvoker -Invoker $Invoker
}

Set-CheckInvoker {
    param($Command, $Arguments)
    $line = (@($Command) + @($Arguments)) -join ' '
    $script:CheckCalls += $line
    if ($line -match 'get-policy-version') {
        return @{ ExitCode = 0; Output = '{"PolicyVersion":{"Document":{"Statement":[{"Effect":"Allow","Action":["iam:ListUsers","iam:GetUser"],"Resource":"*"}]}}}' }
    }
    if ($line -match 'get-policy ') {
        return @{ ExitCode = 0; Output = '{"Policy":{"DefaultVersionId":"v3","Arn":"arn:aws:iam::1:policy/SPAggregationPolicy"}}' }
    }
    if ($line -match 'list-attached-role-policies') {
        return @{ ExitCode = 0; Output = '{"AttachedPolicies":[{"PolicyName":"SPAggregationPolicy","PolicyArn":"arn:aws:iam::1:policy/SPAggregationPolicy"}]}' }
    }
    if ($line -match 'list-role-policies') {
        return @{ ExitCode = 0; Output = '{"PolicyNames":[]}' }
    }
    if ($line -match 'get-role') {
        return @{ ExitCode = 0; Output = '{"Role":{"RoleName":"SailPointAWSRole"}}' }
    }
    return @{ ExitCode = 1; Output = "unexpected $line" }
}
$role = Read-AwsIamRoleGrants -RoleName 'SailPointAWSRole' -Context @{}
Assert-True $role.Found 'existing IAM role is found'
Assert-Equal 'iam:GetUser,iam:ListUsers' ((@($role.Grants) | Sort-Object) -join ',') 'attached policy actions are the grants'
Assert-Equal 0 @($script:CheckCalls | Where-Object { $_ -match 'create-role|attach-role-policy|put-role-policy' }).Count 'reading a role does not call a write API'

Set-CheckInvoker {
    param($Command, $Arguments)
    return @{ ExitCode = 254; Output = 'An error occurred (NoSuchEntity) when calling the GetRole operation: The role with name Missing was not found' }
}
$missingRole = Read-AwsIamRoleGrants -RoleName 'Missing' -Context @{}
Assert-True (-not $missingRole.Found) 'unknown IAM role is not found'
Assert-True ($missingRole.Note -match 'Nothing was changed') 'unknown role note says nothing was changed'

Set-CheckInvoker {
    param($Command, $Arguments)
    $line = (@($Command) + @($Arguments)) -join ' '
    if ($line -match 'ad app list') {
        return @{ ExitCode = 0; Output = '[{"appId":"app-1","displayName":"SailPoint-ISC"}]' }
    }
    if ($line -match 'ad sp list') {
        return @{ ExitCode = 0; Output = '[{"id":"sp-1","appId":"app-1"}]' }
    }
    if ($line -match 'appRoleAssignments') {
        return @{ ExitCode = 0; Output = '{"value":[{"appRoleId":"role-1","resourceId":"graph-sp"}]}' }
    }
    if ($line -match 'graph-sp') {
        return @{ ExitCode = 0; Output = '{"displayName":"Microsoft Graph","appRoles":[{"id":"role-1","value":"User.Read.All"}]}' }
    }
    return @{ ExitCode = 1; Output = "unexpected $line" }
}
$app = Read-EntraApplicationGrants -DisplayName 'SailPoint-ISC'
Assert-True $app.Found 'existing app registration is found'
Assert-Equal 'User.Read.All' (@($app.Grants) -join ',') 'granted app role is resolved to its permission name'

Set-CheckInvoker {
    param($Command, $Arguments)
    return @{ ExitCode = 0; Output = '[]' }
}
$missingApp = Read-EntraApplicationGrants -DisplayName 'Not-There'
Assert-True (-not $missingApp.Found) 'unknown app registration is not found'
Assert-True ($missingApp.Note -match 'Nothing was changed') 'unknown app note says nothing was changed'

Set-CheckInvoker {
    param($Command, $Arguments)
    $line = (@($Command) + @($Arguments)) -join ' '
    if ($line -match 'service-accounts describe') { return @{ ExitCode = 0; Output = '{"email":"sa@proj.iam.gserviceaccount.com"}' } }
    if ($line -match 'projects get-iam-policy') {
        return @{ ExitCode = 0; Output = '{"bindings":[{"role":"roles/logging.viewer","members":["serviceAccount:sa@proj.iam.gserviceaccount.com"]}]}' }
    }
    if ($line -match 'organizations get-iam-policy') { return @{ ExitCode = 0; Output = '{"bindings":[]}' } }
    if ($line -match 'roles describe') { return @{ ExitCode = 0; Output = '{"includedPermissions":["logging.buckets.get","logging.logs.list"]}' } }
    return @{ ExitCode = 1; Output = "unexpected $line" }
}
$sa = Read-GcpServiceAccountGrants -Email 'sa@proj.iam.gserviceaccount.com' -ProjectId 'proj' -OrganizationId '123'
Assert-True $sa.Found 'existing service account is found'
Assert-Equal 'logging.buckets.get,logging.logs.list' ((@($sa.Grants) | Sort-Object) -join ',') 'bound role permissions are the grants'

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("iw-check-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

Set-IntegrationCheckInvoker -Invoker { param($Command, $Arguments) $script:CheckCalled = $true; return @{ ExitCode = 1; Output = 'should not be called' } }
$script:CheckCalled = $false
$noSession = Invoke-IntegrationRequirementCheck -Definition @{ Id = 'aws-saas-connector'; Title = 'Amazon Web Services SaaS connector IAM role' } -Context @{
    Access = 'ReadOnly'; RoleName = 'SailPointAWSRole'; PolicySet = 'Mgo'; ConnectionMode = 'NoSession'
} -OutputPath (Join-Path $tmp 'no-session-check.md')
Assert-Equal 'Review' $noSession.Verdict 'Check without a session does not pretend to have read the role'
Assert-True (-not $script:CheckCalled) 'Check without a session makes no CLI call'
$noSessionText = Get-Content (Join-Path $tmp 'no-session-check.md') -Raw
Assert-True ($noSessionText -match 'Nothing in the tenant was created or changed') 'check report states that the tenant was not changed'
Assert-True ($noSessionText -match 'No CLI session') 'check report explains that the live identity was not read'

$script:CheckCalled = $false
$whatIf = Invoke-IntegrationRequirementCheck -Definition @{ Id = 'aws-saas-connector'; Title = 'Amazon Web Services SaaS connector IAM role' } -Context @{
    Access = 'ReadOnly'; RoleName = 'SailPointAWSRole'; PolicySet = 'Mgo'
} -OutputPath (Join-Path $tmp 'whatif-check.md') -WhatIf
Assert-Equal 'Review' $whatIf.Verdict 'WhatIf Check does not claim a result'
Assert-True (-not $script:CheckCalled) 'WhatIf Check makes no CLI call'

Set-CheckInvoker {
    param($Command, $Arguments)
    $line = (@($Command) + @($Arguments)) -join ' '
    $script:CheckCalls += $line
    if ($line -match 'list-attached-role-policies') { return @{ ExitCode = 0; Output = '{"AttachedPolicies":[]}' } }
    if ($line -match 'list-role-policies') { return @{ ExitCode = 0; Output = '{"PolicyNames":["inline"]}' } }
    if ($line -match 'get-role-policy') {
        return @{ ExitCode = 0; Output = '{"PolicyDocument":{"Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}}' }
    }
    if ($line -match 'get-role') { return @{ ExitCode = 0; Output = '{"Role":{"RoleName":"SailPointAWSRole"}}' } }
    return @{ ExitCode = 1; Output = "unexpected $line" }
}
$pass = Invoke-IntegrationRequirementCheck -Definition @{ Id = 'aws-saas-connector'; Title = 'Amazon Web Services SaaS connector IAM role' } -Context @{
    Access = 'ReadWrite'; RoleName = 'SailPointAWSRole'; PolicySet = 'Mgo'
} -OutputPath (Join-Path $tmp 'pass-check.md')
Assert-Equal 'Pass' $pass.Verdict 'a role whose policy is * meets the AWS SaaS requirements'
Assert-Equal 0 @($script:CheckCalls | Where-Object { $_ -match 'create-|attach-|put-|delete-' }).Count 'a passing check does not call a write API'
$passText = Get-Content (Join-Path $tmp 'pass-check.md') -Raw
Assert-True ($passText -match 'Meets the requirements') 'pass report says the identity meets the requirements'

Set-CheckInvoker {
    param($Command, $Arguments)
    $line = (@($Command) + @($Arguments)) -join ' '
    if ($line -match 'list-attached-role-policies|list-role-policies') { return @{ ExitCode = 0; Output = '{"AttachedPolicies":[],"PolicyNames":[]}' } }
    if ($line -match 'get-role') { return @{ ExitCode = 0; Output = '{"Role":{"RoleName":"SailPointAWSRole"}}' } }
    return @{ ExitCode = 1; Output = "unexpected $line" }
}
$failed = $false
try {
    Invoke-IntegrationRequirementCheck -Definition @{ Id = 'aws-saas-connector'; Title = 'Amazon Web Services SaaS connector IAM role' } -Context @{
        Access = 'ReadOnly'; RoleName = 'SailPointAWSRole'; PolicySet = 'Mgo'; NonInteractive = $true
    } -OutputPath (Join-Path $tmp 'fail-check.md')
}
catch {
    $failed = $true
    Assert-True ($_.Exception.Message -match 'Nothing was changed') 'non-interactive failure says nothing was changed'
}
Assert-True $failed 'non-interactive Check fails the command when the role does not meet the requirements'
Assert-True (Test-Path (Join-Path $tmp 'fail-check.md')) 'the report is written before the command fails'
$failText = Get-Content (Join-Path $tmp 'fail-check.md') -Raw
Assert-True ($failText -match 'Does not meet the requirements') 'failure report names the verdict'

$fixture = @{
    Id = 'check-fixture'; Title = 'Fixture'; Platform = 'Test'; Product = 'ISC'; CliName = 'aws'
    Inputs = @(); Steps = { param($ctx) @() }
    BuildScript = { param($c) 'Write-Host fixture' }
}
New-IntegrationWizardRequirementsDoc -Definition $fixture -Context @{ Action = 'BuildRequirements' } -OutputPath (Join-Path $tmp 'fixture-requirements.md')
$reqText = Get-Content (Join-Path $tmp 'fixture-requirements.md') -Raw
Assert-True ($reqText -match 'did not change the tenant') 'requirements checklist says generating it changed nothing'

New-IntegrationWizardBuildScript -Definition $fixture -Context @{ Action = 'BuildScript' } -OutputPath (Join-Path $tmp 'fixture.ps1')
$scriptText = Get-Content (Join-Path $tmp 'fixture.ps1') -Raw
Assert-True ($scriptText -match 'only wrote this file') 'generated script says the module only wrote the file'
Assert-True ($scriptText -match 'Running it changes the tenant') 'generated script says running it is the change'

function global:Read-Choice {
    param($Prompt, $Options, $Labels, $Default)
    if ($Default) { return $Default }
    return @($Options)[0]
}
$actionCtx = @{}
& (Get-Module IW.Core) { Resolve-IntegrationWizardAction -Context $args[0] -Wizard } $actionCtx
Assert-Equal 'BuildRequirements' $actionCtx['Action'] 'the wizard defaults to the checklist, not Run'

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Set-IntegrationCheckInvoker -Invoker $null

Write-Host "PASS ($script:AssertionCount assertions)"

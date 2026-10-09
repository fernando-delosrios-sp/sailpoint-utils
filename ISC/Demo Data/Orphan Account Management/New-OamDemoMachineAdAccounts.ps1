#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Creates 13 demo Active Directory machine accounts for Identity Fusion NG Orphan Account Management.

.DESCRIPTION
    Machine accounts. Human accounts are created by New-OamDemoAdAccounts.ps1 in the Users OU.

    Accounts are created in the NHI OU aggregated by
    "Microsoft Active Directory @emea-tes-team (NHI)". Fusion treats that source as
    orphan ownership (assign an owner), not account assignment.

    givenName and sn are left empty. Ownership matching uses adminDisplayName.
    The NHI account schema must include adminDisplayName or aggregation will drop it.

    Account correlation (email=mail, name=sAMAccountName, displayName=displayName)
    is not satisfied: sAMAccountName is nhi.*, displayName is "NHI <sam>", and mail
    uses the same prefix. Those accounts stay uncorrelated.

    Three accounts set manager to an existing Users-OU account DN. The Machine Account
    Owner transform takes that DN's CN as the owner identity uid, which is a direct
    match. Their adminDisplayName does not match anyone, so Fusion has nothing to score.

    The other ten leave manager empty. adminDisplayName is the only match signal,
    compared with the identity display name. With one attribute the score is that
    attribute's score. Auto-merge is 95; manual review is 75.

    Mix:
      4 non-match            — adminDisplayName matches no identity
      3 direct correlation   — manager DN of an existing AD user; accept as that owner
      3 automatic match      — adminDisplayName equals the identity display name
      2 true-positive review — close adminDisplayName; accept
      1 false-positive review — similar display name, different person; reject

.PARAMETER BaseDN
    OU that receives the machine accounts.

.PARAMETER UPNSuffix
    User principal name suffix.

.PARAMETER MailSuffix
    Mail suffix. Mail values use the nhi.* prefix so they never equal identity email.

.PARAMETER Cleanup
    Delete previously created nhi.* users under BaseDN instead of creating them.

.EXAMPLE
    .\New-OamDemoMachineAdAccounts.ps1

.EXAMPLE
    .\New-OamDemoMachineAdAccounts.ps1 -WhatIf

.EXAMPLE
    .\New-OamDemoMachineAdAccounts.ps1 -Cleanup
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [string]$BaseDN = 'OU=NHI,OU=emea-tes-team,OU=Demo,DC=seri,DC=sailpointdemo,DC=com',

    [Parameter()]
    [string]$UPNSuffix = 'seri.sailpointdemo.com',

    [Parameter()]
    [string]$MailSuffix = 'seri.sailpointdemo.com',

    [Parameter()]
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'

$usersOu = 'OU=Users,OU=emea-tes-team,OU=Demo,DC=seri,DC=sailpointdemo,DC=com'

# sAMAccountName is nhi.<token> (≤20 chars) and does not equal an identity name.
# displayName is "NHI <sam>" so it does not equal an identity display name.
# adminDisplayName carries the Fusion ownership string. Manager, when set, is the
# DN of a user that already exists in the Users OU.
$accounts = @(
    [pscustomobject]@{
        Scenario            = 'non_match'
        Expected            = 'non-matched'
        SamAccountName      = 'nhi.thorvald'
        AdminDisplayName    = 'Xenia Thorvald'
        Department          = 'Production'
        Title               = 'Field Audit Service'
        City                = 'Oslo'
        Description         = 'OAM-DEMO machine non-match; no owner candidate'
        IntendedIdentityUid = ''
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'non_match'
        Expected            = 'non-matched'
        SamAccountName      = 'nhi.oakley'
        AdminDisplayName    = 'Bram Oakley'
        Department          = 'Non-Production'
        Title               = 'Night Batch Service'
        City                = 'Reykjavik'
        Description         = 'OAM-DEMO machine non-match; no owner candidate'
        IntendedIdentityUid = ''
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'non_match'
        Expected            = 'non-matched'
        SamAccountName      = 'nhi.voss'
        AdminDisplayName    = 'Ines Voss'
        Department          = 'Development'
        Title               = 'Catalog Index Service'
        City                = 'Lisbon'
        Description         = 'OAM-DEMO machine non-match; no owner candidate'
        IntendedIdentityUid = ''
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'non_match'
        Expected            = 'non-matched'
        SamAccountName      = 'nhi.lindholm'
        AdminDisplayName    = 'Tor Lindholm'
        Department          = 'Production'
        Title               = 'Harbor Schedule Service'
        City                = 'Bergen'
        Description         = 'OAM-DEMO machine non-match; no owner candidate'
        IntendedIdentityUid = ''
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'direct_correlation'
        Expected            = 'owner via manager'
        SamAccountName      = 'nhi.aaron'
        AdminDisplayName    = 'NHI Directory Sync'
        Department          = 'Production'
        Title               = 'Directory Sync Service'
        City                = 'Singapore'
        Description         = 'OAM-DEMO direct owner via manager CN aaron.nichols'
        IntendedIdentityUid = 'aaron.nichols'
        ManagerDn           = "CN=aaron.nichols,OU=Singapore,OU=APAC,$usersOu"
    }
    [pscustomobject]@{
        Scenario            = 'direct_correlation'
        Expected            = 'owner via manager'
        SamAccountName      = 'nhi.amanda'
        AdminDisplayName    = 'NHI Mail Relay'
        Department          = 'Production'
        Title               = 'Mail Relay Service'
        City                = 'London'
        Description         = 'OAM-DEMO direct owner via manager CN amanda.ross'
        IntendedIdentityUid = 'amanda.ross'
        ManagerDn           = "CN=amanda.ross,OU=United Kingdom,OU=EMEA,$usersOu"
    }
    [pscustomobject]@{
        Scenario            = 'direct_correlation'
        Expected            = 'owner via manager'
        SamAccountName      = 'nhi.alan'
        AdminDisplayName    = 'NHI Backup Agent'
        Department          = 'Non-Production'
        Title               = 'Backup Agent'
        City                = 'Singapore'
        Description         = 'OAM-DEMO direct owner via manager CN alan.bradley'
        IntendedIdentityUid = 'alan.bradley'
        ManagerDn           = "CN=alan.bradley,OU=Singapore,OU=APAC,$usersOu"
    }
    [pscustomobject]@{
        Scenario            = 'automatic_match'
        Expected            = 'auto'
        SamAccountName      = 'nhi.cole'
        AdminDisplayName    = 'Cole Aaronson'
        Department          = 'Production'
        Title               = 'Nursing Roster Service'
        City                = 'Austin'
        Description         = 'OAM-DEMO automatic owner match to cole.aaronson (exact adminDisplayName)'
        IntendedIdentityUid = 'cole.aaronson'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'automatic_match'
        Expected            = 'auto'
        SamAccountName      = 'nhi.kennedy'
        AdminDisplayName    = 'Adam Kennedy'
        Department          = 'Production'
        Title               = 'Payroll Posting Service'
        City                = 'London'
        Description         = 'OAM-DEMO automatic owner match to adam.kennedy (exact adminDisplayName)'
        IntendedIdentityUid = 'adam.kennedy'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'automatic_match'
        Expected            = 'auto'
        SamAccountName      = 'nhi.ward'
        AdminDisplayName    = 'Anna Ward'
        Department          = 'Development'
        Title               = 'Receivables Service'
        City                = 'San Jose'
        Description         = 'OAM-DEMO automatic owner match to anna.ward (exact adminDisplayName)'
        IntendedIdentityUid = 'anna.ward'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'manual_true_positive'
        Expected            = 'review/accept'
        SamAccountName      = 'nhi.garcia'
        AdminDisplayName    = 'Margo Garcia'
        Department          = 'Production'
        Title               = 'Database Ops Service'
        City                = 'Austin'
        Description         = 'OAM-DEMO true-positive review for margaret.garcia (Margo Garcia); accept'
        IntendedIdentityUid = 'margaret.garcia'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'manual_true_positive'
        Expected            = 'review/accept'
        SamAccountName      = 'nhi.bakers'
        AdminDisplayName    = 'Edward Bakers'
        Department          = 'Non-Production'
        Title               = 'Recruiting Bot'
        City                = 'Sao Paulo'
        Description         = 'OAM-DEMO true-positive review for edward.baker (Edward Bakers); accept'
        IntendedIdentityUid = 'edward.baker'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'manual_false_positive'
        Expected            = 'review/reject'
        SamAccountName      = 'nhi.bell'
        AdminDisplayName    = 'Andrea Bell'
        Department          = 'Development'
        Title               = 'Warehouse Bot'
        City                = 'Tokyo'
        Description         = 'OAM-DEMO false-positive review vs angela.bell (Andrea Bell); reject'
        IntendedIdentityUid = 'angela.bell'
        ManagerDn           = ''
    }
)

function Get-OamMachineCommonName {
    param($Account)
    'NHI {0}' -f $account.SamAccountName
}

function New-OamMachineRandomPassword {
    $chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%'
    $bytes = New-Object byte[] 24
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $plain = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
    ConvertTo-SecureString -String $plain -AsPlainText -Force
}

if ($Cleanup) {
    $existing = @(Get-ADUser -SearchBase $BaseDN -LDAPFilter '(sAMAccountName=nhi.*)' -ErrorAction Stop)
    if ($existing.Count -eq 0) {
        Write-Host "No nhi.* users under $BaseDN"
        return
    }
    foreach ($user in $existing) {
        if ($PSCmdlet.ShouldProcess($user.DistinguishedName, 'Remove-ADUser')) {
            Remove-ADUser -Identity $user.DistinguishedName -Confirm:$false
            Write-Host "Removed $($user.SamAccountName)"
        }
    }
    return
}

$ou = Get-ADOrganizationalUnit -Identity $BaseDN -ErrorAction Stop
Write-Host "Creating $($accounts.Count) machine accounts in $($ou.DistinguishedName)"

$accountPassword = New-OamMachineRandomPassword
$created = 0
$skipped = 0
foreach ($account in $accounts) {
    $sam = $account.SamAccountName
    if ($sam.Length -gt 20) {
        throw "sAMAccountName '$sam' exceeds 20 characters"
    }

    $cn = Get-OamMachineCommonName $account
    $displayName = $cn
    $upn = '{0}@{1}' -f $sam, $UPNSuffix
    $mail = '{0}@{1}' -f $sam, $MailSuffix
    $dn = 'CN={0},{1}' -f $cn, $BaseDN

    if (Get-ADUser -Filter "sAMAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Warning "Skip $sam — already exists"
        $skipped++
        continue
    }

    $params = @{
        Path                  = $BaseDN
        Name                  = $cn
        SamAccountName        = $sam
        UserPrincipalName     = $upn
        DisplayName           = $displayName
        EmailAddress          = $mail
        Department            = $account.Department
        Title                 = $account.Title
        City                  = $account.City
        Description           = $account.Description
        AccountPassword       = $accountPassword
        Enabled               = $true
        ChangePasswordAtLogon = $false
        PasswordNeverExpires  = $true
        OtherAttributes       = @{
            employeeType     = 'service-account'
            adminDisplayName = $account.AdminDisplayName
        }
    }
    if ($account.ManagerDn) {
        $params.Manager = $account.ManagerDn
    }

    if ($PSCmdlet.ShouldProcess($dn, 'New-ADUser')) {
        New-ADUser @params
        Set-ADUser -Identity $sam -Replace @{
            info = ('scenario={0}; expected={1}; identityUid={2}' -f $account.Scenario, $account.Expected, $account.IntendedIdentityUid)
            mail = $mail
        }
        $created++
        Write-Host ("{0,-24} {1,-22} {2}" -f $sam, $account.Scenario, $account.Expected)
    }
}

Write-Host "Created $created, skipped $skipped. Aggregate Microsoft Active Directory @emea-tes-team (NHI), then Orphan Account Management."

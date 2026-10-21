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
        SamAccountName      = 'nhi.solberg'
        AdminDisplayName    = 'Sigrid Solberg'
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
        SamAccountName      = 'nhi.kroner'
        AdminDisplayName    = 'Henrik Kroner'
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
        SamAccountName      = 'nhi.strand'
        AdminDisplayName    = 'Astrid Strand'
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
        SamAccountName      = 'nhi.engberg'
        AdminDisplayName    = 'Mads Engberg'
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
        SamAccountName      = 'nhi.antonio'
        AdminDisplayName    = 'NHI Directory Sync'
        Department          = 'Production'
        Title               = 'Directory Sync Service'
        City                = 'Madrid'
        Description         = 'OAM-DEMO direct owner via manager CN antonio.mawad'
        IntendedIdentityUid = 'antonio.mawad'
        ManagerDn           = "CN=antonio.mawad,$usersOu"
    }
    [pscustomobject]@{
        Scenario            = 'direct_correlation'
        Expected            = 'owner via manager'
        SamAccountName      = 'nhi.cristian'
        AdminDisplayName    = 'NHI Mail Relay'
        Department          = 'Production'
        Title               = 'Mail Relay Service'
        City                = 'Barcelona'
        Description         = 'OAM-DEMO direct owner via manager CN cristian.grau'
        IntendedIdentityUid = 'cristian.grau'
        ManagerDn           = "CN=cristian.grau,$usersOu"
    }
    [pscustomobject]@{
        Scenario            = 'direct_correlation'
        Expected            = 'owner via manager'
        SamAccountName      = 'nhi.yannick'
        AdminDisplayName    = 'NHI Backup Agent'
        Department          = 'Non-Production'
        Title               = 'Backup Agent'
        City                = 'Paris'
        Description         = 'OAM-DEMO direct owner via manager CN yannick.beot'
        IntendedIdentityUid = 'yannick.beot'
        ManagerDn           = "CN=yannick.beot,$usersOu"
    }
    [pscustomobject]@{
        Scenario            = 'automatic_match'
        Expected            = 'auto'
        SamAccountName      = 'nhi.simmons'
        AdminDisplayName    = 'Catherine Simmons'
        Department          = 'Production'
        Title               = 'Nursing Roster Service'
        City                = 'London'
        Description         = 'OAM-DEMO automatic owner match to catherine.simmons (exact adminDisplayName)'
        IntendedIdentityUid = 'catherine.simmons'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'automatic_match'
        Expected            = 'auto'
        SamAccountName      = 'nhi.juergensen'
        AdminDisplayName    = 'Volker Juergensen'
        Department          = 'Production'
        Title               = 'Payroll Posting Service'
        City                = 'Berlin'
        Description         = 'OAM-DEMO automatic owner match to volker.juergensen (exact adminDisplayName)'
        IntendedIdentityUid = 'volker.juergensen'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'automatic_match'
        Expected            = 'auto'
        SamAccountName      = 'nhi.helmy'
        AdminDisplayName    = 'Mostafa Helmy'
        Department          = 'Development'
        Title               = 'Receivables Service'
        City                = 'Cairo'
        Description         = 'OAM-DEMO automatic owner match to mostafa.helmy (exact adminDisplayName)'
        IntendedIdentityUid = 'mostafa.helmy'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'manual_true_positive'
        Expected            = 'review/accept'
        SamAccountName      = 'nhi.wilson'
        AdminDisplayName    = 'Barbie Wilson'
        Department          = 'Production'
        Title               = 'Database Ops Service'
        City                = 'Austin'
        Description         = 'OAM-DEMO true-positive review for barbara.wilson (Barbie Wilson); accept'
        IntendedIdentityUid = 'barbara.wilson'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'manual_true_positive'
        Expected            = 'review/accept'
        SamAccountName      = 'nhi.mueller'
        AdminDisplayName    = 'Johnny Mueller'
        Department          = 'Non-Production'
        Title               = 'Recruiting Bot'
        City                = 'Munich'
        Description         = 'OAM-DEMO true-positive review for jonathan.mueller (Johnny Mueller); accept'
        IntendedIdentityUid = 'jonathan.mueller'
        ManagerDn           = ''
    }
    [pscustomobject]@{
        Scenario            = 'manual_false_positive'
        Expected            = 'review/reject'
        SamAccountName      = 'nhi.freeman'
        AdminDisplayName    = 'Noel Freeman'
        Department          = 'Development'
        Title               = 'Warehouse Bot'
        City                = 'London'
        Description         = 'OAM-DEMO false-positive review vs nigel.freeman (Noel Freeman); reject'
        IntendedIdentityUid = 'nigel.freeman'
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

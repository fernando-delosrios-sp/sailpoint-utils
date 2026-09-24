#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Creates 13 demo Active Directory accounts for Identity Fusion NG Orphan Account Management.

.DESCRIPTION
    Targets identities on emea-tes-team that have no account on
    "Microsoft Active Directory @emea-tes-team (Users)".

    Fusion NG on "Orphan Account Management" scores givenName (name-matcher, 80) and
    sn (double-metaphone, 90). Auto-merge is 95; manual review is 75. Email is mapped for
    the review form but is not a matching attribute.

    Combined score is the weighted mean: (80 * givenName + 90 * sn) / 170. Neither rule is
    mandatory and neither skips on a missing value, so both always contribute.

    Nicknames do not work as review candidates here. name-matcher has no nickname list, so
    Peggy/Margaret scores 9 and Ned/Edward scores 13 — both land far below review. Review
    candidates instead use a close spelling variant or a surname typo.

    AD account correlation (email=mail, name=sAMAccountName, displayName=displayName) is
    deliberately not satisfied, so the accounts stay uncorrelated orphans for Fusion.

    Mix (expected combined score against the intended identity):
      5 non-match            — names that do not exist on any identity (all below 48)
      5 automatic match      — exact givenName + sn of identities without AD (100, auto)
      2 true-positive review — Margo/Margaret exact sn (93.9); Edward + sn typo (78.8); accept
      1 false-positive review — Andrea vs Angela, shared sn (89.7); reject

.PARAMETER BaseDN
    OU that receives the users.

.PARAMETER UPNSuffix
    User principal name suffix.

.PARAMETER MailSuffix
    Mail suffix. Mail values use the oam.* prefix so they never equal identity email.

.PARAMETER Cleanup
    Delete previously created oam.* users under BaseDN instead of creating them.

.EXAMPLE
    .\New-OamDemoAdAccounts.ps1

.EXAMPLE
    .\New-OamDemoAdAccounts.ps1 -WhatIf

.EXAMPLE
    .\New-OamDemoAdAccounts.ps1 -Cleanup
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [string]$BaseDN = 'OU=Users,OU=emea-tes-team,OU=Demo,DC=seri,DC=sailpointdemo,DC=com',

    [Parameter()]
    [string]$UPNSuffix = 'seri.sailpointdemo.com',

    [Parameter()]
    [string]$MailSuffix = 'seri.sailpointdemo.com',

    [Parameter()]
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'

# sAMAccountName is oam.<last> (≤20 chars). CN/displayName use "Last, First" so they
# do not equal identity displayName. mail is oam.<sam>@suffix so it does not equal
# identity email (those cubes use N/A or a personal address).
$accounts = @(
    [pscustomobject]@{
        Scenario           = 'non_match'
        Expected           = 'non-matched'
        SamAccountName     = 'oam.thorvald'
        GivenName          = 'Xenia'
        Surname            = 'Thorvald'
        Department         = 'Orphan Demo'
        Title              = 'Field Auditor'
        City               = 'Oslo'
        Description        = 'OAM-DEMO non-match; no identity candidate'
        IntendedIdentityUid = ''
    }
    [pscustomobject]@{
        Scenario           = 'non_match'
        Expected           = 'non-matched'
        SamAccountName     = 'oam.oakley'
        GivenName          = 'Bram'
        Surname            = 'Oakley'
        Department         = 'Orphan Demo'
        Title              = 'Night Operator'
        City               = 'Reykjavik'
        Description        = 'OAM-DEMO non-match; no identity candidate'
        IntendedIdentityUid = ''
    }
    [pscustomobject]@{
        Scenario           = 'non_match'
        Expected           = 'non-matched'
        SamAccountName     = 'oam.voss'
        GivenName          = 'Ines'
        Surname            = 'Voss'
        Department         = 'Orphan Demo'
        Title              = 'Catalog Librarian'
        City               = 'Lisbon'
        Description        = 'OAM-DEMO non-match; no identity candidate'
        IntendedIdentityUid = ''
    }
    [pscustomobject]@{
        Scenario           = 'non_match'
        Expected           = 'non-matched'
        SamAccountName     = 'oam.lindholm'
        GivenName          = 'Tor'
        Surname            = 'Lindholm'
        Department         = 'Orphan Demo'
        Title              = 'Harbor Pilot'
        City               = 'Bergen'
        Description        = 'OAM-DEMO non-match; no identity candidate'
        IntendedIdentityUid = ''
    }
    [pscustomobject]@{
        Scenario           = 'non_match'
        Expected           = 'non-matched'
        SamAccountName     = 'oam.okonkwo'
        GivenName          = 'Chioma'
        Surname            = 'Okonkwo'
        Department         = 'Orphan Demo'
        Title              = 'Textile Chemist'
        City               = 'Accra'
        Description        = 'OAM-DEMO non-match; no identity candidate'
        IntendedIdentityUid = ''
    }
    [pscustomobject]@{
        Scenario           = 'automatic_match'
        Expected           = 'auto'
        SamAccountName     = 'oam.aaronson'
        GivenName          = 'Cole'
        Surname            = 'Aaronson'
        Department         = 'Nursing'
        Title              = 'Nurse Staff-ER'
        City               = 'Austin'
        Description        = 'OAM-DEMO automatic match to cole.aaronson (exact givenName+sn)'
        IntendedIdentityUid = 'cole.aaronson'
    }
    [pscustomobject]@{
        Scenario           = 'automatic_match'
        Expected           = 'auto'
        SamAccountName     = 'oam.kennedy'
        GivenName          = 'Adam'
        Surname            = 'Kennedy'
        Department         = 'Accounting'
        Title              = 'Payroll Analyst II'
        City               = 'London'
        Description        = 'OAM-DEMO automatic match to adam.kennedy (exact givenName+sn)'
        IntendedIdentityUid = 'adam.kennedy'
    }
    [pscustomobject]@{
        Scenario           = 'automatic_match'
        Expected           = 'auto'
        SamAccountName     = 'oam.ward'
        GivenName          = 'Anna'
        Surname            = 'Ward'
        Department         = 'Accounting'
        Title              = 'Accounts Receivable Analyst'
        City               = 'San Jose'
        Description        = 'OAM-DEMO automatic match to anna.ward (exact givenName+sn)'
        IntendedIdentityUid = 'anna.ward'
    }
    [pscustomobject]@{
        Scenario           = 'automatic_match'
        Expected           = 'auto'
        SamAccountName     = 'oam.nelson'
        GivenName          = 'Brian'
        Surname            = 'Nelson'
        Department         = 'Human Resources'
        Title              = 'Recruiter'
        City               = 'Sao Paulo'
        Description        = 'OAM-DEMO automatic match to brian.nelson (exact givenName+sn)'
        IntendedIdentityUid = 'brian.nelson'
    }
    [pscustomobject]@{
        Scenario           = 'automatic_match'
        Expected           = 'auto'
        SamAccountName     = 'oam.woods'
        GivenName          = 'Albert'
        Surname            = 'Woods'
        Department         = 'Engineering'
        Title              = 'Inventory Analyst I'
        City               = 'Brussels'
        Description        = 'OAM-DEMO automatic match to albert.woods (exact givenName+sn)'
        IntendedIdentityUid = 'albert.woods'
    }
    [pscustomobject]@{
        Scenario           = 'manual_true_positive'
        Expected           = 'review/accept'
        SamAccountName     = 'oam.garcia'
        GivenName          = 'Margo'
        Surname            = 'Garcia'
        Department         = 'Information Technology'
        Title              = 'Oracle Administrator'
        City               = 'Austin'
        Description        = 'OAM-DEMO true-positive review for margaret.garcia (Margo/Margaret, exact sn); accept'
        IntendedIdentityUid = 'margaret.garcia'
    }
    [pscustomobject]@{
        Scenario           = 'manual_true_positive'
        Expected           = 'review/accept'
        SamAccountName     = 'oam.bakers'
        GivenName          = 'Edward'
        Surname            = 'Bakers'
        Department         = 'Human Resources'
        Title              = 'Recruiter'
        City               = 'Sao Paulo'
        Description        = 'OAM-DEMO true-positive review for edward.baker (exact givenName, sn typo); accept'
        IntendedIdentityUid = 'edward.baker'
    }
    [pscustomobject]@{
        Scenario           = 'manual_false_positive'
        Expected           = 'review/reject'
        SamAccountName     = 'oam.bell'
        GivenName          = 'Andrea'
        Surname            = 'Bell'
        Department         = 'Inventory'
        Title              = 'Warehouse Associate'
        City               = 'Tokyo'
        Description        = 'OAM-DEMO false-positive review vs angela.bell (similar givenName, shared sn); reject'
        IntendedIdentityUid = 'angela.bell'
    }
)

function Get-OamDisplayName {
    param($Account)
    '{0}, {1}' -f $Account.Surname, $Account.GivenName
}

function Get-OamCommonName {
    param($Account)
    'OAM {0} {1}' -f $Account.GivenName, $Account.Surname
}

function New-OamRandomPassword {
    $chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%'
    $bytes = New-Object byte[] 24
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $plain = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
    ConvertTo-SecureString -String $plain -AsPlainText -Force
}

if ($Cleanup) {
    $existing = @(Get-ADUser -SearchBase $BaseDN -LDAPFilter '(sAMAccountName=oam.*)' -ErrorAction Stop)
    if ($existing.Count -eq 0) {
        Write-Host "No oam.* users under $BaseDN"
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
Write-Host "Creating $($accounts.Count) users in $($ou.DistinguishedName)"

$accountPassword = New-OamRandomPassword
$created = 0
$skipped = 0
foreach ($account in $accounts) {
    $sam = $account.SamAccountName
    if ($sam.Length -gt 20) {
        throw "sAMAccountName '$sam' exceeds 20 characters"
    }

    $cn = Get-OamCommonName $account
    $displayName = Get-OamDisplayName $account
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
        GivenName             = $account.GivenName
        Surname               = $account.Surname
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

Write-Host "Created $created, skipped $skipped. Aggregate Microsoft Active Directory @emea-tes-team (Users), then Orphan Account Management."

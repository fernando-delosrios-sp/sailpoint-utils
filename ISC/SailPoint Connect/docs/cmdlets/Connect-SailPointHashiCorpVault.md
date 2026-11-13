# `Connect-SailPointHashiCorpVault`

Configures Entro HashiCorp Vault integration onboarding.

## Synopsis

```powershell
Connect-SailPointHashiCorpVault [-Wizard] [-Entro] [-Action <String>]
    [-VaultUrl <String>] [-Project <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointHashiCorpVault` configures read-only audit policies and authentication tokens for Entro non-human identity discovery in HashiCorp Vault.

## Parameters

### `-Wizard`
Launches the interactive questionnaire.

### `-VaultUrl`
HashiCorp Vault cluster address (e.g., `https://vault.corp.internal:8200`).

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Generate Checklist for Vault Admin
```powershell
Connect-SailPointHashiCorpVault -Entro -VaultUrl "https://vault.corp.internal:8200" -Action BuildRequirements
```

# `Connect-SailPointDatabricks`

Configures SailPoint ISC Databricks Account and Metastore connector.

## Synopsis

```powershell
Connect-SailPointDatabricks [-Wizard] [-Connector] [-Cloud <String>]
    [-Auth <String>] [-Action <String>] [-ServicePrincipalName <String>]
    [-AccountId <String>] [-MetastoreId <String>] [-Project <String>]
    [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointDatabricks` configures Databricks service principals and OAuth machine-to-machine (M2M) credentials:
1. Creates or resolves a Databricks service principal (default: `SailPoint-source`).
2. Assigns required `Account admin` privileges in the Databricks Account Console.
3. Generates OAuth M2M client credentials.
4. Outputs the exact settings to paste into SailPoint ISC Source Connection Settings.

## Parameters

### `-Cloud`
Hosting cloud provider: `Aws`, `Azure`, or `Gcp`.

### `-Auth`
Authentication mechanism: `DatabricksM2M` (OAuth) or `Entra`.

### `-AccountId`
Databricks Account ID.

### `-MetastoreId`
Unity Catalog Metastore ID.

## Examples

### Example 1: Interactive wizard
```powershell
Connect-SailPointDatabricks -Wizard
```

### Example 2: Headless script build
```powershell
Connect-SailPointDatabricks -Connector -Cloud Aws -AccountId "acc-1234" -Action BuildScript
```

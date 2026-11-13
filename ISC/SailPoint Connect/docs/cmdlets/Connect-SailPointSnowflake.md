# `Connect-SailPointSnowflake`

Configures Entro Snowflake integration onboarding.

## Synopsis

```powershell
Connect-SailPointSnowflake [-Wizard] [-Entro] [-Action <String>]
    [-AccountUrl <String>] [-EntroUser <String>] [-Project <String>]
    [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointSnowflake` sets up key-pair authentication and read-only governance roles for Entro non-human identity posture analysis in Snowflake.

## Parameters

### `-Wizard`
Launches the interactive questionnaire.

### `-AccountUrl`
Snowflake account identifier URL (e.g., `https://xy12345.snowflakecomputing.com`).

### `-EntroUser`
Designated Snowflake service user for Entro (default: `ENTRO_USER`).

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Generate Snowflake Setup Script
```powershell
Connect-SailPointSnowflake -Entro -AccountUrl "https://acme.snowflakecomputing.com" -Action BuildScript
```

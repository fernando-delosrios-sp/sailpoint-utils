Snowflake Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/snowflake/snowflake-permissions-reference.md).

This section defines the privileges required for Entro Security to integrate with Snowflake securely and effectively.
GitBook Assistant

Entro requires limited, read-only privileges through the `ENTRO_ROLE`. Identity metadata (users, roles, and grants) is collected through the Snowflake REST API using the dedicated `ENTRO` user.
GitBook Assistant

**Note: Entro does not query, modify, or store table data. Access is strictly metadata-based.**
GitBook Assistant
## Required Permissions[#required-permissions](#required-permissions)
Required PermissionsGitBook AssistantAskCopy
```
GRANT MONITOR ON ACCOUNT TO ROLE ENTRO_ROLE;
GRANT USAGE ON DATABASE SNOWFLAKE TO ROLE ENTRO_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE.ACCOUNT_USAGE TO ROLE ENTRO_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE.ACCOUNT_USAGE TO ROLE ENTRO_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SNOWFLAKE.ACCOUNT_USAGE TO ROLE ENTRO_ROLE;
GRANT USAGE ON SCHEMA SNOWFLAKE.ORGANIZATION_USAGE TO ROLE ENTRO_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE.ORGANIZATION_USAGE TO ROLE ENTRO_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SNOWFLAKE.ORGANIZATION_USAGE TO ROLE ENTRO_ROLE;
```

## Permissions Justification[#permissions-justification](#permissions-justification)
PrivilegeObjectPurpose

MONITOR
GitBook Assistant

ACCOUNT
GitBook Assistant

Read-only visibility into account activity and audit logs
GitBook Assistant

USAGE
GitBook Assistant

DATABASE SNOWFLAKE
GitBook Assistant

Access to the system database containing usage views
GitBook Assistant

USAGE, SELECT
GitBook Assistant

SNOWFLAKE.ACCOUNT_USAGE
GitBook Assistant

Read-only access to account-level metadata views
GitBook Assistant

USAGE, SELECT
GitBook Assistant

SNOWFLAKE.ORGANIZATION_USAGE
GitBook Assistant

Read-only access to organization-level metadata views
GitBook Assistant[PreviousSnowflake Troubleshooting And Validation](/integrations/security-and-identity/snowflake/snowflake-troubleshooting-and-validation)[NextWiz](/integrations/security-and-identity/wiz)

Last updated 2 months ago

- [Required Permissions](#required-permissions)
- [Permissions Justification](#permissions-justification)

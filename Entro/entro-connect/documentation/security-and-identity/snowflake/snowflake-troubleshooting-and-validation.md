Snowflake Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/snowflake/snowflake-troubleshooting-and-validation.md).
## Validation Steps[#validation-steps](#validation-steps)
1
#### Confirm integration status[#confirm-integration-status](#confirm-integration-status)

Ensure the integration status shows **Verified** in Entro.
GitBook Assistant2
#### Check last synchronization[#check-last-synchronization](#check-last-synchronization)

Verify the **Last Synchronization Timestamp** for recency.
GitBook Assistant3
#### Confirm metadata ingestion[#confirm-metadata-ingestion](#confirm-metadata-ingestion)

Ensure metadata from Snowflake appears under **NHI Tokens Inventory**.
GitBook Assistant4
#### Validate ENTRO_ROLE grants[#validate-entro_role-grants](#validate-entro_role-grants)

Run the following in Snowflake:
GitBook AssistantValidating Entro role grantsGitBook AssistantAskCopy
```
SHOW GRANTS TO ROLE ENTRO_ROLE;
DESC USER ENTRO;
-- Confirm RSA_PUBLIC_KEY_FP is set and DEFAULT_ROLE is ENTRO_ROLE
```

## Common Issues and Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
IssuePossible CauseResolution

Access denied
GitBook Assistant

Missing privileges on ENTRO_ROLE
GitBook Assistant

Re-run the role creation and grant script from the onboarding documentation
GitBook Assistant

No metadata visible
GitBook Assistant

First synchronization not yet completed
GitBook Assistant

Wait for the next sync cycle and retry
GitBook Assistant

Invalid credentials
GitBook Assistant

RSA public key not set on the ENTRO user, or the onboarding key expired before completion
GitBook Assistant

Reopen the Entro form to generate a new key and re-run the `ALTER USER ENTRO SET RSA_PUBLIC_KEY` statement in the Query Data in Snowflake
GitBook Assistant

Network timeout
GitBook Assistant

Restricted outbound access from the Entro worker
GitBook Assistant

Allow HTTPS (443) connectivity from the worker to your Snowflake account URL
GitBook Assistant[PreviousSnowflake Onboarding](/integrations/security-and-identity/snowflake/snowflake-onboarding)[NextSnowflake Permissions Reference](/integrations/security-and-identity/snowflake/snowflake-permissions-reference)

Last updated 2 months ago

- [Validation Steps](#validation-steps)
- [Common Issues and Resolutions](#common-issues-and-resolutions)

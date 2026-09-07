Active Directory Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/active-directory/active-directory-troubleshooting-and-validation.md).

Steps to validate a successful integration and troubleshoot common issues.
GitBook Assistant
## Validation steps after connection[#validation-steps-after-connection](#validation-steps-after-connection)
1
#### Verify integration in Entro Console[#verify-integration-in-entro-console](#verify-integration-in-entro-console)

In Entro Console go to **Management → Accounts & Integrations → Active Directory**.
GitBook Assistant2
#### Confirm account status[#confirm-account-status](#confirm-account-status)

Verify account status shows **Verified**.
GitBook Assistant3
#### Check findings and inventory[#check-findings-and-inventory](#check-findings-and-inventory)

Confirm findings appear in **Findings** and object inventory under **Activity Logs**.
GitBook Assistant4
#### Check sync timestamp[#check-sync-timestamp](#check-sync-timestamp)

Check last sync timestamp on the integration card.
GitBook Assistant
## Data visibility checks[#data-visibility-checks](#data-visibility-checks)

- 

Confirm users and groups listed in Entro match AD counts.
GitBook Assistant
- 

Search for a known user in Entro inventory and verify attributes such as `userPrincipalName` and `memberOf`.
GitBook Assistant

## LDAP bind test (run from connector host)[#ldap-bind-test-run-from-connector-host](#ldap-bind-test-run-from-connector-host)

- 

Test LDAP (unencrypted, if permitted):
GitBook Assistant
ldapsearch - LDAP (unencrypted)GitBook AssistantAskCopy
```
ldapsearch -x -H ldap://dc01.example.local -D "svc_entro@example.local" -w '<PASSWORD>' -b "DC=example,DC=local" "(objectClass=user)" -s sub cn
```

- 

Test LDAPS:
GitBook Assistant
ldapsearch - LDAPSGitBook AssistantAskCopy
```
ldapsearch -x -H ldaps://dc01.example.local -D "svc_entro@example.local" -w '<PASSWORD>' -b "DC=example,DC=local" "(objectClass=user)" -s sub cn
```

- 

TLS certificate check:
GitBook Assistant
openssl s_client - LDAPS cert checkGitBook AssistantAskCopy
```
openssl s_client -connect dc01.example.local:636
```

## Common issues and resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
**Status not Verified**[#status-not-verified](#status-not-verified)

- 

Cause: Network blocked between Worker Group and DC.
GitBook Assistant
- 

Fix: Verify DNS and port 636 or 389 from connector host. Confirm firewall rules.
GitBook Assistant
**Bind failed - invalid credentials**[#bind-failed-invalid-credentials](#bind-failed-invalid-credentials)

- 

Cause: Wrong service account or password.
GitBook Assistant
- 

Fix: Verify UPN and password. Test ldapsearch from connector host.
GitBook Assistant
**Certificate validation errors**[#certificate-validation-errors](#certificate-validation-errors)

- 

Cause: Internal CA used by LDAPS not trusted.
GitBook Assistant
- 

Fix: Paste root CA PEM into the Root CA (PEM) field in the Entro integration form.
GitBook Assistant
**Partial object visibility**[#partial-object-visibility](#partial-object-visibility)

- 

Cause: Service account lacks permission to read specific OUs or attributes.
GitBook Assistant
- 

Fix: Grant read access or check attribute-level restrictions. Ensure LDAP queries have appropriate base DN.
GitBook Assistant
**Time skew errors**[#time-skew-errors](#time-skew-errors)

- 

Cause: Large clock drift between connector and DC.
GitBook Assistant
- 

Fix: Sync time via NTP.
GitBook Assistant
**Throttling or size limits**[#throttling-or-size-limits](#throttling-or-size-limits)

- 

Cause: Very large AD forests causing long queries.
GitBook Assistant
- 

Fix: Use Worker Group with sufficient resources. Consider staged sync windows.
GitBook Assistant

## Advanced diagnostics[#advanced-diagnostics](#advanced-diagnostics)

- 

Enable debug logs on the Worker Group and collect connector logs.
GitBook Assistant
- 

Capture packet trace (tcpdump) on connector host to verify LDAPS handshake.
GitBook Assistant
- 

Export Entro connector log bundle and attach to support ticket.
GitBook Assistant

## Support[#support](#support)

If validation continues to fail, contact Entro Support:
GitBook Assistant

- 

Slack or Teams channel for your customer success manager
GitBook Assistant
- 

support@entro.security
GitBook Assistant

Provide connector logs and the connector log bundle when contacting support to expedite troubleshooting.
GitBook Assistant
## Security & Compliance Notes[#security-and-compliance-notes](#security-and-compliance-notes)

- 

Maintain read-only service account.
GitBook Assistant
- 

Use LDAPS and TLS 1.2+.
GitBook Assistant
[PreviousActive Directory Onboarding](/integrations/security-and-identity/active-directory/active-directory-onboarding)[NextActive Directory Permissions Reference](/integrations/security-and-identity/active-directory/active-directory-permissions-reference)

Last updated 4 months ago

- [Validation steps after connection](#validation-steps-after-connection)
- [Data visibility checks](#data-visibility-checks)
- [LDAP bind test (run from connector host)](#ldap-bind-test-run-from-connector-host)
- [Common issues and resolutions](#common-issues-and-resolutions)
- [Advanced diagnostics](#advanced-diagnostics)
- [Support](#support)
- [Security & Compliance Notes](#security-and-compliance-notes)

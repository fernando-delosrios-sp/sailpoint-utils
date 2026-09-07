Active Directory | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/active-directory.md).

Entro connects to your On-Premises Active Directory to discover, monitor, and analyze user identities, groups, and permissions.
GitBook Assistant
## Purpose[#purpose](#purpose)

This integration ingests Active Directory objects and ACLs to find identity risk, excessive permissions, and lateral movement paths.
GitBook Assistant
## Supported environments[#supported-environments](#supported-environments)

- 

On-premises Active Directory forests (single or multi-domain)
GitBook Assistant
- 

Hybrid environments where domain controllers are reachable from the Worker Group (Connector)
GitBook Assistant

## ASCII Architecture[#ascii-architecture](#ascii-architecture)
GitBook AssistantAskCopy
```
                       +--------------------+
                       |   Entro Console    |
                       |   (Control Plane)  |
                       +---------+----------+
                                 |
                                 | Control API + AES-256 token
                                 |
                       +---------v----------+
                       | Worker Group       |
                       | (Connector VM)     |
                       +---------+----------+
              LDAPS/LDAP     |     LDAP(S)      |
  +------------------+       |       +------------------+
  | Domain Controller |<-----+----->| Domain Controller |
  | (DC - dc01)       |             | (DC - dc02)       |
  +------------------+               +------------------+
                |                              |
                +----- Kerberos / LDAP / DNS --+
```

## What Entro scans[#what-entro-scans](#what-entro-scans)

- 

User accounts and attributes
GitBook Assistant
- 

Groups and nested group membership
GitBook Assistant
- 

Group Policy Objects (GPO metadata)
GitBook Assistant
- 

ACLs on objects (where accessible via LDAP)
GitBook Assistant
- 

Computer accounts and service principal names (SPNs)
GitBook Assistant
- 

Password and lockout policies (metadata)
GitBook Assistant
- 

LastLogon, account status, and privileged group membership
GitBook Assistant

## Authentication method summary[#authentication-method-summary](#authentication-method-summary)

- 

Primary method: LDAP/LDAPS bind using a dedicated service account (API Access Token used in Entro Console).
GitBook Assistant
- 

Entro requires a service account with read-only LDAP privileges.
GitBook Assistant

## Data access mode[#data-access-mode](#data-access-mode)

- 

Read-only LDAP queries from the Worker Group (Connector).
GitBook Assistant
- 

Network traffic should use LDAPS (port 636) whenever possible.
GitBook Assistant

Security & compliance
GitBook Assistant

- 

TLS 1.2+ required for LDAPS connections.
GitBook Assistant
- 

Entro uses read-only directory access.
GitBook Assistant
- 

Stored tokens encrypted using AES-256.
GitBook Assistant
- 

Applicable standards: SOC 2 Type II, ISO 27001, GDPR (data retention and export controls apply).
GitBook Assistant
[PreviousSalesforce Permissions Reference](/integrations/collaboration-and-saas/salesforce/salesforce-permissions-reference)[NextActive Directory Onboarding](/integrations/security-and-identity/active-directory/active-directory-onboarding)

Last updated 4 months ago

- [Purpose](#purpose)
- [Supported environments](#supported-environments)
- [ASCII Architecture](#ascii-architecture)
- [What Entro scans](#what-entro-scans)
- [Authentication method summary](#authentication-method-summary)
- [Data access mode](#data-access-mode)

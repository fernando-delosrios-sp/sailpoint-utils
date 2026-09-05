# sailpoint-utils

## Purpose

Curated collection of reusable [SailPoint Identity Security Cloud (ISC)](https://www.sailpoint.com/products/identity-security-cloud/) and IdentityIQ (IIQ) patterns — rules, transforms, connector tooling, and third-party integrations. Each utility is self-contained with its own README for setup, artifacts, and usage. Browse by area below or see [CHANGELOG.md](CHANGELOG.md) for release history.

## Repository layout

| Path | Description |
| --- | --- |
| [`ISC/`](ISC/) | Rules, transforms, forms, and tenant configuration patterns |
| [`SaaS Connectivity/`](SaaS%20Connectivity/) | Connector testing helpers and custom-operation templates |
| [`Third-Party/`](Third-Party/) | Integrations with external systems |
| [`IIQ/`](IIQ/) | IdentityIQ assets *(reserved)* |

## ISC utilities

| Utility | Description |
| --- | --- |
| [Active Directory Home Folders](ISC/Active%20Directory%20Home%20Folders/) | ConnectorAfterCreate rule (built from PowerShell Rule Template) that creates home folders with NTFS ACLs from configurable base path and template |
| [Active Directory OU Management](ISC/Active%20Directory%20OU%20Management/) | IQService BeforeScripts that create missing OUs—and optionally AD groups—during AD provisioning |
| [Dynamic forms and user data collection](ISC/Dynamic%20forms%20and%20user%20data%20collection/) | Example form with cascading dropdowns and CSV-backed reference data |
| [Generic Manager Correlation](ISC/Generic%20Manager%20Correlation/) | Reusable pattern for correlating managers across heterogeneous sources |
| [JDBC SaaS Driver Downloader](ISC/JDBC%20SaaS%20Driver%20Downloader/) | Download and package JDBC drivers from Maven Central for SaaS upload |
| [LCS Operations](ISC/LCS%20Operations/) | BeforeProvisioning rule that maps lifecycle-state dummy attributes to native connector operations |
| [Optimistic Provisioning Generic SDIM](ISC/Optimistic%20Provisioning%20Generic%20SDIM/) | Configuration guide for optimistic provisioning with Generic SDIM |
| [Organizational Hierarchy Path](ISC/Organizational%20Hierarchy%20Path/) | IdentityAttribute rule that builds a consolidated org hierarchy path from entitlements |
| [PowerShell Rule Template](ISC/PowerShell%20Rule%20Template/) | Copy-ready IQService connector-rule bootstrap with logging, redaction, exit handling, and optional replay |
| [Source Connection Setup](ISC/Source%20Connection%20Setup/) | Entra ID app registration, AWS SaaS IAM role setup, Google Workspace SaaS service account setup, and IQService host control (download, install, update, service, logging, Utils.dll unblock) |
| [Transforms](ISC/Transforms/) | Reusable transform definitions (dates, lifecycle state, attribute history, manager flag) |

## SaaS Connectivity

| Utility | Description |
| --- | --- |
| [Postman remote source evaluation](SaaS%20Connectivity/Postman%20remote%20source%20evaluation/) | Postman pre-request script for ISC auth, source resolution, and remote connector invoke |
| [saas-custom-operations](SaaS%20Connectivity/saas-custom-operations/) | Foundation template for ISC custom operations with loopback API and dummy result source |

## Third-Party integrations

| Integration | Description |
| --- | --- |
| [OrangeHRM → ISC aggregation](Third-Party/OrangeHRM/) | Triggers SailPoint account aggregation after OrangeHRM employee lifecycle events |

## Getting started

1. **Pick a utility** from the tables above and open its folder README.
2. **Import or deploy artifacts** as described in that README (rules, transforms, connector bundles, Postman collections, etc.).
3. **Adapt configuration** to your tenant—source IDs, attribute names, and OAuth clients are environment-specific.

Utilities that include a Node.js toolchain (for example, [JDBC SaaS Driver Downloader](ISC/JDBC%20SaaS%20Driver%20Downloader/) or [saas-custom-operations](SaaS%20Connectivity/saas-custom-operations/)) document their own prerequisites and npm scripts locally.

## Contributing

When adding a new utility or integration pattern:

1. Place it under the appropriate top-level folder (`ISC/`, `SaaS Connectivity/`, `Third-Party/`, or `IIQ/`).
2. Include a `README.md` with a **Purpose** section, setup steps, artifacts, and usage examples.
3. Add an entry under the newest dated section in [CHANGELOG.md](CHANGELOG.md) (create one for today's date if needed).

## Changelog

Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md), grouped by date in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.


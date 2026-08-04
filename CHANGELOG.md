# Changelog

All notable changes to **sailpoint-utils** — reusable SailPoint ISC/IIQ utilities, integration patterns, and supporting tools.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Dates use ISO 8601.

## 2026-08-04

### ✨ New Features

- **JDBC SaaS Driver Downloader** — Download and package JDBC drivers for SailPoint SaaS upload from Maven Central (`ISC/JDBC SaaS Driver Downloader/`).
  - Interactive command (`npm run download`) to pick a database engine, select a version, and download a ready-to-upload JAR + ZIP.
  - Batch command (`npm run download:all`) to download and zip all supported JDBC drivers using defaults from `config/drivers.json`.
  - Supports DB2, Oracle, Sybase (jTDS), SQL Server, MySQL, and PostgreSQL from Maven Central.
  - Generates `drivers/manifest.json` with JDBC class names, versions, and source URLs for SailPoint upload.

---

## 2026-07-31

### ✨ New Features

- **Organizational Hierarchy Path** — Identity attribute rule now reads hierarchy settings from source attributes, making separator, entitlement fields, and parent-organization mapping configurable per source without rule edits.

---

## 2026-07-27

### ✨ New Features

- **OrangeHRM → ISC aggregation (Job custom fields)** — Saving valid custom fields on an employee Job page now triggers a SailPoint account aggregation, keeping ISC in sync after job metadata changes.

---

## 2026-07-24

### ✨ New Features

- **Dynamic forms and user data collection** — Example ISC form configuration with cascading dropdowns (buildings, locations, rooms) and CSV-backed reference data for structured user input during provisioning or access requests.

### 📚 Documentation

- **Dynamic forms README** — Expanded guide covering cascading dropdowns and how user selections persist.

### 🐛 Fixes

- **Dynamic forms guide screenshot** — Restored promotional screenshot accidentally removed from the guide.

---

## 2026-07-22

### ✨ New Features

- **OrangeHRM → ISC aggregation (initial integration)** — OrangeHRM now requests SailPoint account aggregation after key employee lifecycle events:
  - New employee creation
  - Job details saved (including contract dates)
  - Contact details updated
  - Supervisor / subordinate relationships added or changed
  - Employment termination or reactivation confirmed
- **Repository bootstrap** — Initial commit and merge of OrangeHRM integration work into the shared utilities repo.

### 🐛 Fixes

- **OrangeHRM new-employee aggregation** — Corrected aggregation trigger on employee creation.

---

## 2026-07-19

### ✨ New Features

- **LCS Operations** — BeforeProvisioning rule for LCS (Lifecycle Services) operations workflows.
- **Optimistic Provisioning Generic SDIM** — Configuration guide and assets for optimistic provisioning with Generic SDIM.

### 🔧 Improvements

- **Repository layout** — Reorganized under `ISC/`, `SaaS Connectivity/`, and `Third-Party/` for clearer navigation.
- **LCS and SDIM READMEs** — Added setup and usage documentation for LCS Operations and Optimistic Provisioning Generic SDIM.
- **Gitignore updates** — Excludes build and coverage output directories.

### 🗑️ Removed

- **Legacy Emergency Termination assets** — Configuration consolidated elsewhere.

### 📚 Documentation

- **Generic SDIM guide** — Added promotional image to the configuration guide.

---

## 2026-07-03

### 🔧 Improvements

- **Branch consolidation** — Merged prior work from the `fernando` branch into the main utilities tree (squash merge).

---

## 2026-03-23

### ✨ New Features

- **Generic Manager Correlation** — Reusable ISC pattern for correlating manager identities across heterogeneous sources using a normalized `attribute|value` transform and source-side correlation rule with multi-attribute fallback.
- **Postman Remote Source Evaluation** — Postman collection pre-request script that authenticates to ISC, resolves a source by name, merges connector configuration, and supports remote connector invoke mode for SaaS connectivity testing.

### 📚 Documentation

- **Generic Manager Correlation infographic** — Added visual guide for setup and flow.

---

## Project Areas

| Path                 | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| `ISC/`               | Identity Security Cloud rules, transforms, forms, and utilities |
| `SaaS Connectivity/` | Connector testing and SaaS integration helpers                  |
| `Third-Party/`       | Integrations with external systems (e.g., OrangeHRM)            |
| `IIQ/`               | IdentityIQ assets (reserved)                                    |

---

## Contributing

When adding a new utility or integration pattern:

1. Place it under the appropriate top-level folder.
2. Include a `README.md` with setup, artifacts, and usage.
3. Add an entry under the newest `## YYYY-MM-DD` release section (create one for today's date if needed).

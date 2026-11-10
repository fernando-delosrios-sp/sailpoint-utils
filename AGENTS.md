# Agent Guidelines: sailpoint-utils

Welcome, AI agent! This repository contains utilities, connectors, tools, and automation for SailPoint Identity Security Cloud (ISC), Non-Employee Risk Management (NERM), and cloud infrastructure onboarding.

---

## CRITICAL RULE: SailPoint Connect Versioning

> [!IMPORTANT]
> **Every commit that involves changes to `ISC/SailPoint Connect/` MUST include a version bump.**
> - **Default bump level:** **Minor** (e.g., `1.2.0` → `1.3.0`), unless the user explicitly specifies a different increment (e.g. patch or major).
> - **Mandatory requirement:** Never commit modifications under `ISC/SailPoint Connect/` without bumping the module version and documenting the changes in the changelog.

### Version Bump Checklist for `ISC/SailPoint Connect`

Whenever you create, edit, or delete any file under `ISC/SailPoint Connect/` (including scripts, modules, definitions, documentation, or tests):

1. **Module Manifest (`SailPoint.Connect.psd1`)**:
   Bump `ModuleVersion` (minor bump by default, e.g., `1.2.0` → `1.3.0`):
   ```powershell
   ModuleVersion = '1.3.0'
   ```
   Also update `ReleaseNotes` in the private data block if applicable.

2. **Changelog (`CHANGELOG.md`)**:
   Add a new section at the top of `CHANGELOG.md` following the standard format:
   ```markdown
   ## YYYY-MM-DD · v1.3.0
   - Description of feature, enhancement, or bug fix...
   ```

3. **Fallback Version in Operator Console (`ISC.OperatorConsole.psm1`)**:
   Update the fallback string in `Get-SailPointConnectVersion` so standalone module execution without a manifest reflects the new version:
   ```powershell
   return '1.3.0'
   ```

4. **Test Assertions (`Test-OperatorConsole.ps1`)**:
   Update test assertions that verify the version number (e.g., in `Test-OperatorConsole.ps1` where `Get-SailPointConnectVersion` is asserted).

5. **Local Deployment**:
   If deploying or testing locally, copy files to the new versioned directory:
   `~/.local/share/powershell/Modules/SailPoint.Connect/<NewVersion>/`

---

## Quality & Architecture Guidelines

- **Always Run Tests Before Committing**:
  Verify the full test suite passes with zero failures:
  ```powershell
  pwsh "ISC/SailPoint Connect/tests/Invoke-AllSourceConnectionTests.ps1"
  ```
- **Terminal UX & Path Formatting**:
  - Keep all folder paths and directory names space-free (use kebab-case / hyphenated names like `Google-Cloud` and `Entro-GCP`).
  - Use `Format-TerminalHyperlink` for any output printing file paths in the console.
  - Never call `exit 0` or `exit 1` inside module functions or script catch blocks; use `return` or throw terminating exceptions to avoid killing the operator's host shell.
- **PowerShell Pipeline Compatibility**:
  Non-interactive cmdlets must emit structured objects (`PSCustomObject`) to Stream 1 without stdout/Write-Host stream pollution.

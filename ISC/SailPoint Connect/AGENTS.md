# SailPoint Connect Agent Guidelines

> [!IMPORTANT]
> **Every commit that involves changes to `ISC/SailPoint Connect/` MUST include a version bump.**
> - **Default bump level:** **Minor** (e.g. `1.2.0` → `1.3.0`), unless the user explicitly requests a different increment (e.g. patch or major).
> - Never commit changes here without updating the version in the manifest and changelog!

## Version Bump Checklist
Whenever modifying any files in this directory:
1. `SailPoint.Connect.psd1`: Bump `ModuleVersion` (minor bump by default).
2. `CHANGELOG.md` (root): Add a `## YYYY-MM-DD · vX.Y.Z` section detailing the changes.
3. `modules/ISC.OperatorConsole.psm1`: Update the default fallback version string in `Get-SailPointConnectVersion`.
4. `tests/Test-OperatorConsole.ps1`: Update version assertions to match the new version.
5. Local deployment: If deploying locally, copy module files to `~/.local/share/powershell/Modules/SailPoint.Connect/<NewVersion>/`.

## Testing
Always run the full test suite before committing:
```powershell
pwsh "tests/Invoke-AllSourceConnectionTests.ps1"
```

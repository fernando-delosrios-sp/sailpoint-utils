## Why

Entro's Automated PowerShell script can finish while the Entro permission audit
still shows Teams, SharePoint, Copilot, and Agentic AI as Not Granted. Create-app
only grants Mandatory plus Azure Cloud; menu 2 pre-selects already-granted groups;
Teams Bot names in the script disagree with docs. Az.Resources 9 already forced a
pin refresh. We need a maintained local script, and a maintainer ask when Entro
publishes a new attachment — without Connect fetching GitBook.

## What Changes

**Local Microsoft onboarding script**
- From: Skill-held file is treated as Entro's published bytes; create-app grants
  six Graph permissions; Teams Send Messages uses `ReadWriteForChat.All`
- To: Local onboarding fork grants the Entro permission-audit set (docs lists plus
  the 2026-09-02 portal gap, including Optional rows), uses Az.Resources 9
  `Actions`/`NotActions`, and uses `TeamsAppInstallation.ReadWriteSelfForUser.All`
- Reason: Connect evidence is the Entro audit, not script success text
- Impact: both skill trees and the Microsoft Ecosystem pin checksum/version

**Origin drift at ingest**
- From: origin SHA-256 ≠ Skill-held copy fails ingest
- To: for a Local onboarding fork, ingest succeeds with local bytes unchanged,
  records origin drift, tells the maintainer, and asks keep-local vs take-remote;
  take-remote rebases our patches onto Entro's new file then updates the pin
- Reason: Connect end-users never see this; ingest is the maintainer's job
- Impact: documentation-ingest validation and catalog pin fields (names in design)

**Connect runtime**
- From: checksum Skill-held file; never fetch `originUrl` (unchanged intent)
- To: same; checksum is the fork. Mismatch still stops. Temporary script copy
  stays names/menus for one run
- Reason: runtime must not download GitBook
- Impact: non-breaking for Connect fetch rules; pin `version` text names the fork

Design will pick catalog field names for origin vs Skill-held checksums and how
rebase patches are stored.

## Non-goals

No secrets in agent runtime. No Connect-time GitBook fetch. No asking a Connect
end-user remote vs local. No non-interactive rewrite of the whole menu script.
No Entro API account creation, Connector deployment, or other vendors' artifacts
in this change. No changing Operation mode or Approve beyond pin metadata.

## Capabilities

### New Capabilities

- None. Fork identity belongs on existing domains.

### Modified Capabilities

- `documentation-ingest`: Local onboarding fork pins; origin drift succeeds,
  notifies, and asks the maintainer; take-remote rebases then re-pins.
- `integration-prep`: Connect still runs checksummed Skill-held bytes only;
  Microsoft Automated PowerShell expectedChange matches the audit permission set.
- `ubiquitous-language`: add Local onboarding fork; adjust Skill-held notes so
  the Microsoft script may be a maintained copy, not origin-identical bytes.

## Impact

`Entro-Azure-Onboarding.ps1` in both skill trees, Microsoft Ecosystem Row
catalog pin, `catalog_contracts.py` / ingest validation, `tests/test_ingest_docs.py`,
entro-connect `prep.md` pin-refresh note if it still says origin-identical,
`CHANGELOG.md`. Connect logs stay gitignored. No Entro product API change.

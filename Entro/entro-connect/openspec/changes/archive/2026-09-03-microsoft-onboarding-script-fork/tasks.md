## 1. Pin model

- [x] 1.1 Extend `PinnedScript` with `local_fork` and `origin_checksum`; serialize `localFork` and `originChecksum` on the Microsoft Automated PowerShell pin only (D1; scenarios: Fork pin separates originChecksum from checksum)
- [x] 1.2 Reject `localFork` without a valid `originChecksum`, and reject `originChecksum` on unforked pins, in `validate_script_pin`

## 2. Origin validation

- [x] 2.1 Compare unforked origin GET to Skill-held `checksum` (scenario: Origin drift fails ingest unchanged)
- [x] 2.2 Compare Local onboarding fork origin GET to `originChecksum`; succeed when they match even if `checksum` differs (scenario: Unchanged origin with a fork succeeds silently)
- [x] 2.3 When fork origin GET ≠ `originChecksum`, do not overwrite Skill-held files; emit origin-published notice naming keep-local vs take-remote (scenario: New origin on a fork notifies without replacing local bytes)
- [x] 2.4 Keep-local path updates `originChecksum` to the new origin hash without changing Skill-held bytes (D3)

## 3. Local script and patch

- [x] 3.1 Edit both skill-tree copies of `Entro-Azure-Onboarding.ps1`: create-app and menu-2 defaults grant the Entro permission-audit set; Az.Resources 9 `Actions`/`NotActions`; Teams Bot uses `TeamsAppInstallation.ReadWriteSelfForUser.All` (scenarios: Create-app grants the audit permission set; API-permissions menu defaults to the full audit set; Teams Bot names match documentation)
- [x] 3.2 Commit `integrations/microsoft-ecosystem/Entro-Azure-Onboarding.local.patch` in both trees against current `originChecksum` bytes (scenario: Local patch file is skill-held beside the script)
- [x] 3.3 Record `originChecksum` from an anonymous GET (or last known origin hash) and `checksum` of the forked script; set `localFork` true and `version` text that names the fork
- [x] 3.4 Implement take-remote rebase: GET origin to temp, apply the local patch, write both trees, update pin hashes; stop on conflict (scenarios: Successful rebase updates pin and both trees; Patch conflict stops rebase)

## 4. Catalog expectedChange

- [x] 4.1 Update Microsoft Ecosystem Automated PowerShell Typed action `expectedChange` (and verification if needed) so the Identity object has Entro permission-audit Graph and Defender grants (scenario: Typed action expectedChange names the audit grants)
- [x] 4.2 Regenerate Skill catalogs and `documentation/integrations.json` from `catalog_contracts.py`

## 5. Connect skill docs

- [x] 5.1 Update both `entro-connect` `prep.md` copies: pin refresh / Local onboarding fork vs Temporary script copy; Connect verifies `checksum` only; never fetch origin; never ask remote vs local (scenarios: Connect uses the fork checksum not origin; Durable patches are not a Temporary script copy; Local checksum matches/mismatch unchanged)

## 6. Verification

- [x] 6.1 Confirm canonical test command: `python -m pytest`
- [x] 6.2 Named tests for: Fork pin separates originChecksum from checksum; Local patch file is skill-held beside the script; Unchanged origin with a fork succeeds silently; New origin on a fork notifies without replacing local bytes; Origin drift fails ingest (unforked); Anonymous alt=media fetch is accepted (fork vs unforked); Tokenized origin URL is rejected
- [x] 6.3 Named tests for: Create-app grants the audit permission set; API-permissions menu defaults to the full audit set; Teams Bot names match documentation; Typed action expectedChange names the audit grants; Durable patches are not a Temporary script copy; Connect uses the fork checksum not origin; Local checksum matches before Approve; Local checksum mismatch stops the plan
- [x] 6.4 Named tests for: Successful rebase updates pin and both trees (unit with fixture bytes); Patch conflict stops rebase; Specs use Local onboarding fork
- [x] 6.5 Run `openspec validate --all --json` and confirm all items valid
- [x] 6.6 Run `python -m pytest` and confirm it passes

## 7. Documentation

- [x] 7.1 Update `README.md` pin/origin wording: Local onboarding fork, `originChecksum`, ingest notice, Connect never fetches GitBook
- [x] 7.2 No Entro API or connector doc changes (out of scope)
- [x] 7.3 Update `catalog_contracts.py` / `skill_held.py` docstrings for `localFork` and origin-published notices

## 8. Changelog

- [x] 8.1 Create or update changelog entry for this change via changelog-generator
- [x] 8.2 Confirm the entry covers the Local onboarding fork permission set, origin-published maintainer ask, rebase, and Connect still local-only

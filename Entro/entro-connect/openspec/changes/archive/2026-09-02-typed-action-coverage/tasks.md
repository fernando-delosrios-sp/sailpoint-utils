## 1. Catalog pin model

- [x] 1.1 Extend `PinnedScript` / Typed action serialization in `catalog_contracts.py` with `skillPath`, `checksum`, `version`, optional Anonymous `originUrl`, optional `captureSource`; stop emitting GitBook as the Connect runtime URL
- [x] 1.2 Port pending catalog JSON hand-edits (Operator inputs, placeholders, label validation) into `catalog_contracts.py` so regenerate does not revert them
- [x] 1.3 Reject `token=` on stored `originUrl` in catalog validation (scenario: Tokenized origin URL is rejected)

## 2. Harvest GitBook attachments

- [x] 2.1 Inventory `files.gitbook.io` links under the design harvest set (`cloud-and-infrastructure/`, `collaboration-and-saas/`, `code-and-ci-cd/`, `ai-and-agents/`, `security-and-identity/`, `container-registries/`, `gemini-instructions/`)
- [x] 2.2 Anonymous GET each `?alt=media` URL (no token); write bytes under `vendor/` in both `.agents/skills/entro-connect/` and `skills/entro-connect/`; record pins in contracts (scenarios: GitBook attachment is committed in both skill trees; Anonymous alt=media fetch is accepted)
- [x] 2.3 During apply, inform the operator if Copilot `Entro-Onboard.ps1` or GitHub `onboard-script.zip` still has no anonymous attachment; if no public URL, skip a pin (scenario: Unpublished named script is not a fake pin)
- [x] 2.4 Keep accidental repo-root `.ps1` names in `.gitignore`; do not gitignore committed `vendor/` paths

## 3. Capture in-page snippets

- [x] 3.1 Save onboarding script bodies (GCP pre-check and equivalent “save as” fences) as Skill-held files with `captureSource` page paths (scenario: Embedded pre-check script is captured)

## 4. Prep coverage and Fit

- [x] 4.1 Bind every Prep step to a Skill-held artifact action, a Doc-derived Typed action, or Operator-only `{ reason, evidence }` (scenarios: Silent Prep step fails validation; Operator follows integration prep; UI-only step is operator-executed)
- [x] 4.2 Replace Copilot `sha256:verify-after-download` with Doc-derived Typed actions (`pac admin` application-user) unless a public URL is supplied
- [x] 4.3 Correct Fit `preferred` to `usable` or `none` with rationale wherever a selected path would otherwise stay incomplete (scenarios: Preferred path has complete coverage; Incomplete preferred Fit is rejected)
- [x] 4.4 Keep credential-minting (Azure script Client Secret) operator-executed; Connection details remain the Entro-form side (scenarios: Client Secret stays with the operator; Boundary with connection details)

## 5. Generator and dual trees

- [x] 5.1 `integration_catalog.py` writes both skill catalogs and copies the `vendor/` tree to both skill roots (design D1, D8 dual-tree equality)
- [x] 5.2 Regenerate `documentation/integrations.json` and both skill `integrations.json` files from contracts

## 6. Connect runtime

- [x] 6.1 Rewrite `.agents/skills/entro-connect/prep.md` (and the `skills/entro-connect/` copy) so Connect SHA-256s `script.skillPath` before Approve, never GETs GitBook, stops on mismatch, discloses path/size/checksum only (scenarios: Local checksum matches before Approve; Local checksum mismatch stops the plan)

## 7. Verification

- [x] 7.1 Confirm canonical test command: `python -m pytest`
- [x] 7.2 Named tests for: GitBook attachment is committed in both skill trees; Unpinned integration attachment fails ingest; Origin drift fails ingest; Tokenized origin URL is rejected; Anonymous alt=media fetch is accepted; Embedded pre-check script is captured; Snippet drift fails ingest; Silent Prep step fails validation; Unpublished named script is not a fake pin; Preferred path has complete coverage; Incomplete preferred Fit is rejected
- [x] 7.3 Named tests for: Local checksum matches before Approve; Local checksum mismatch stops the plan; Client Secret stays with the operator; UI-only step is operator-executed (skill-doc or catalog assertions as the seam)
- [x] 7.4 Glossary tests: Specs use Skill-held onboarding artifact; Specs use Anonymous origin URL; Specs distinguish Doc-derived Typed action and Operator-only step
- [x] 7.5 Run `openspec validate --all --json` and confirm all items valid

## 8. Documentation

- [x] 8.1 Update repo `README.md` if it describes index script/pin fields, to Skill-held path + checksum + Anonymous origin URL
- [x] 8.2 Update `integration_catalog.py` module docstring for dual skill trees and `vendor/`
- [x] 8.3 No API or connector doc changes (out of scope)

## 9. Changelog

- [x] 9.1 Create or update changelog entry for this change via changelog-generator
- [x] 9.2 Confirm the entry names Skill-held artifacts, anonymous origin ingest, Connect no longer fetching GitBook, Prep coverage, and Copilot fake-pin removal

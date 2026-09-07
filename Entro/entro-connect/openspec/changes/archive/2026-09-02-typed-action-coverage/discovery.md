## Scope

One change: inventory every GitBook file attachment under integration
documentation; fetch each anonymously; commit the bytes plus SHA-256 into both
`entro-connect` skill trees; Connect executes only those skill-local files.
In-page onboarding snippets become skill files the same way. Prep steps with no
obtainable file get Doc-derived Typed actions. Every remaining Prep step is
Operator-only with a reason. Preferred Fit is corrected until that coverage is
complete. Out of scope: Entro API account creation, Connector deployment,
per-integration skills, secrets in agent runtime, and storing GitBook tokens.

## Language

**Skill-held onboarding artifact** (`promote`):
A vendor-published file or in-page snippet copied into the `entro-connect` skill
(`vendor/` under both skill trees). Catalog entries name the skill-relative path
and SHA-256. Connect runs those bytes only — it does not download from GitBook.
_Avoid_: treating a GitBook URL as the runtime source; committing a tokenized URL

**Anonymous origin URL** (`promote`):
The GitBook `files.gitbook.io` object URL with `?alt=media` and no `token`
query. Ingest/CI uses it to refresh and to detect drift. A pin that requires a
signed token is invalid.
_Avoid_: storing `token=`; treating a 200 JSON metadata response (no
`alt=media`) as a successful script fetch

**Doc-derived Typed action** (`keep`):
A Typed action whose mutation, verification, and rollback come from the vendor's
documented operation when no Skill-held artifact covers the step.
_Avoid_: inventing commands the vendor does not document

**Operator-only step** (`keep`):
A Prep step the project does not automate (UI-only or credential-minting).
Carries reason and evidence. Absence of a Typed action is a recorded decision.
_Avoid_: leaving a step with no action and no reason

## Decisions

**Context**: a Connect run approved Azure onboarding and stalled on an unpinned
script. Docs now publish `Entro-Azure-Onboarding.ps1` as a GitBook attachment.
Anonymous GET with `?alt=media` (no token) returned 146695 bytes, SHA-256
`af42cb707a3edce614ba23eed7aa14add8ee336142061dc775edb3d4409666d1` (verified
2026-09-02). Copilot Studio still tells the customer to supply
`Entro-Onboard.ps1` — no attachment.

- **Q1: change vehicle?** Rewrite `typed-action-coverage` in place.
- **Q2: runtime bytes?** Commit fetched files under both
  `.agents/skills/entro-connect/` and `skills/entro-connect/` as auxiliary
  skill files. Catalog points at skill paths + SHA-256. Connect never hits
  GitBook.
- **Q3: harvest width?** Every GitBook attachment under integration sections of
  `documentation/` (cloud, SaaS, CI, AI, security/identity, …). Not
  admin/legal. Includes Azure Continuous (~22MB), GCP Terraform zip, Gemini zip,
  CrowdStrike scanner zip. Commit as normal git blobs (no LFS).
- **Q4: snippets?** In-page script bodies (GCP pre-check `.sh`, `setup.ps1`,
  JS console snippets used as onboarding) are saved as skill files; checksum is
  of the captured bytes.
- **Q5: origin refresh?** Ingest/CI: anonymous GET of the origin URL, compare
  SHA-256, fail if docs moved and the skill copy was not updated.
- **Q6: unpublished / non-anonymous file?** Inform the operator so they can
  supply a public URL. If not, Doc-derived Typed actions for that method. Do not
  pin a tokenized URL.
- **Q7: coverage?** Every Prep step: Skill-held artifact action, Doc-derived
  Typed action, or Operator-only with reason. Preferred path with a silent step
  is corrected to `usable` or `none`.
- **Q8: inventory authority?** Authors record artifacts in `catalog_contracts.py`.
  Ingest tests fail if an integration docs page links an attachment (or embeds
  a snippet we treat as onboarding) that is not skill-held and checksummed.
- **Q9: generator?** Port hand-edits back into `catalog_contracts.py`; regenerate
  both catalogs. Vendor files are written into both skill trees.

## Open questions

- Copilot `Entro-Onboard.ps1` and GitHub `onboard-script.zip` have no anonymous
  attachment in the crawl. Owner: operator during apply — supply a URL or accept
  Typed actions.
- `entro-connect-skill` delta specs still drift on Orientation / playbook /
  Worker Group. Owner: that change. This change only switches script runtime
  from GitBook fetch to skill-local files (checksum before Approve).

## Scenarios discussed

- Azure `.ps1` anonymous `?alt=media` → skill file + catalog checksum; Connect
  runs `vendor/…/Entro-Azure-Onboarding.ps1` after SHA-256 matches.
- Tokenized URL in catalog → invalid pin; ingest fails.
- Copilot page names a customer-supplied script → inform; then Typed actions
  (`pac admin` application-user), not a fake checksum.
- GCP pre-check pasted in markdown → skill-held `.sh`, not a GitBook pin.
- New attachment appears on an integration page and is not in the skill → ingest
  fails until copied and checksummed.
- Origin bytes change, skill copy stale → ingest fails.
- Fit `preferred` path with an uncovered Prep step → correct Fit.
- Credential-minting step (including a script that prints a Client Secret) →
  Operator-executed; agent records identifiers only.
- Published non-script operator input (AWS CloudFormation launch from the Entro
  wizard) stays an Operator input unless it is a GitBook attachment we harvest.

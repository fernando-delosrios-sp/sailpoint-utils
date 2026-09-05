## Context

`integration_catalog.py` holds the curated Add New Account rows and writes three artifacts: the ingest index `documentation/integrations.json` (full rows, including documentation page paths), and a Skill catalog tree in each of `.agents/skills/entro-connect/` and `skills/entro-connect/` (thin index plus per-row `catalog.json`, with documentation paths stripped because Connect must never open `documentation/`).

Each row declares `documentation` (the pages it was distilled from), `setupMethods`, and `authenticationMethods`. Method names are the only options Connect offers at its method gate. Validation today is forward-only: `validate_integration_paths` (`integration_catalog.py:2984`) asserts every cited path exists as a file. Nothing observes a page that exists but is uncited, so a Documented method can be absent with a green suite — and `test_one_target_one_row` (`tests/test_ingest_docs.py:314`) actively pins AWS to the incomplete pair.

Constraints: ingest needs `ENTRO_DOCS_COOKIE`, so the invariant cannot live only in the ingest path; the committed documentation tree is the independent source of truth already in the repo; the Skill catalog trees must stay free of documentation paths and byte-identical to one another.

## Goals / Non-Goals

**Goals:**
- Make an uncataloged Documented method a loud validation failure, derived from the documentation tree rather than from a list of expected names.
- Fail closed on revert: undoing a row's curation must leave the tree unsatisfied, not quietly correct.
- Catch both gap shapes — an uncited page or subtree, and a fork inside a cited page.
- Keep the failure reachable by `python -m pytest` with no vendor cookie.
- Bring the ten affected rows into compliance.

**Non-Goals:**
- Heuristic detection of fork phrases in prose.
- Changing Connect's gate rendering, Coverage semantics, or Typed action execution rules.
- Re-ingesting the documentation tree.

## Decisions

### D1: The invariant is stated against the documentation tree, not against expected method names
- **Choice**: validation enumerates markdown pages under the integration documentation folders and requires each to be cited by some row, method, or Coverage, or to carry a Method waiver.
- **Reason**: the tree is independent of the curation, so reverting a row removes citation and waiver together and the check goes red. A list of expected names cannot see a method nobody recorded, and is itself revertible.
- **Considered alternatives**: pinned per-row method inventory (defends only what was already recorded — the exact failure that lost the AWS fix); heuristic marker scan (false positives plus a suppression list, which is a waiver list with worse ergonomics).

### D2: Integration documentation folders are the existing published set
- **Choice**: reuse the folder set already fixed by the Skill-held attachments requirement — `cloud-and-infrastructure/`, `collaboration-and-saas/`, `code-and-ci-cd/`, `ai-and-agents/`, `security-and-identity/`, `container-registries/`, `gemini-instructions/`.
- **Reason**: one definition of "integration documentation" for both attachments and completeness; Entro Connector topology, SSO, and IDE plugin pages stay outside and need no waiver.
- **Considered alternatives**: per-row declared subtree roots (more curation, and drifts when Entro reorganizes); whole-tree scan (drags in non-integration pages).

### D3: Page ownership is by citation, with orphans waived at catalog level
- **Choice**: a page is owned by whichever row cites it. A page no row cites is an orphan and MUST be named in the waiver registry with a reason; it is not silently attributed to a nearest-neighbour row.
- **Reason**: prefix or nearest-folder attribution guesses, and a wrong guess would mark the AWS multi-account page "owned" while still uncataloged.
- **Considered alternatives**: longest-prefix match against cited paths (implicit and surprising); mandatory per-row roots (see D2).

### D4: A fork census entry must quote page text, and validation verifies the quote
- **Choice**: each cited page carries a census of the Documented methods it names; each entry binds to a method name or a waiver reason and carries an `evidence` quote. Validation asserts the quote occurs in that page's bytes.
- **Reason**: this is what makes an in-page fork checkable rather than self-asserted, and it fails when a documentation refresh moves the fork, forcing a re-read instead of silent staleness.
- **Considered alternatives**: unverified census (a comment, not a check); heading extraction (brittle against GitBook's flattened markdown, which interleaves "GitBook Assistant" lines).

### D5: Waivers are curation metadata — ingest index only
- **Choice**: declare waivers and census entries on the curated row in Python; emit them into `documentation/integrations.json`; strip them alongside documentation paths when writing Skill catalog Row catalogs and the thin index.
- **Reason**: Connect must never learn `documentation/` paths, and the operator has no use for curation bookkeeping. Keeps `INDEX_FORBIDDEN_KEYS` and the thin-index contract intact.
- **Considered alternatives**: a standalone registry file (review drifts away from the row it describes); carrying waivers into Row catalogs (leaks documentation paths into the skill).

### D6: A waiver reason is prose, and empty is a failure
- **Choice**: a waiver requires a non-empty reason sentence; a missing or blank reason fails validation.
- **Reason**: the point is to convert an invisible omission into a reviewable decision. A boolean flag would restore the silence.
- **Considered alternatives**: enumerated reason codes (loses the specifics a reviewer needs).

### D7: pytest is the durable gate; ingest validation is the same function
- **Choice**: implement one validation function, call it from `write_integrations_index` and assert it in `tests/test_ingest_docs.py` against the committed tree.
- **Reason**: ingest needs a cookie and runs rarely; the suite runs on every change. Both losses of the AWS fix would have been caught by the pytest assertion.
- **Considered alternatives**: ingest-only enforcement (invisible on the path where the regression actually happened).

### D8: Session conduct is its own capability, and the rule is written where sessions read it
- **Choice**: declare a new `change-isolation` capability for conduct toward a shared working tree, and write the same rule into `AGENTS.md` (read on session start) plus `docs/agents/change-isolation.md`.
- **Reason**: the loss had two independent causes — the catalog could not see the gap (D1 fixes that) and a concurrent session cleared the tree (this fixes that). A spec nobody loads changes nothing, and `AGENTS.md` is the file every session reads first.
- **Considered alternatives**: folding it into `documentation-ingest` (conduct is not ingest behaviour); leaving it as prose in `docs/` only (no requirement to verify against); a pre-commit or pre-stash hook (recorded as a deferred follow-up — mechanical enforcement is stronger but needs its own design, and a hook cannot bind a session that never installs it).

### D9: CrowdStrike's Terraform EC2 option is censused on the Coverage
- **Choice**: record it as a census entry on the Falcon RTR Coverage, not as a row Setup method.
- **Reason**: it deploys the RTR scanner, not the Entro connection to the tile; promoting it would make a Coverage look like an Add New Account setup path.
- **Considered alternatives**: a row Setup method (misrepresents what the operator is choosing).

## Risks / Trade-offs

[Risk] Backfilling ten rows is the bulk of the work and each new method needs prep steps, Typed actions, and Operator inputs → Mitigation: land the validation first with waivers covering every current gap, then convert waivers to real methods row by row, so the suite is green throughout and each row is a reviewable step.

[Risk] A documentation re-ingest that renames or moves pages turns every affected census quote red at once → Mitigation: that is the intended signal; failures name the page and the missing quote, and the waiver path gives a documented escape while the row is re-read.

[Trade-off] A curator can still omit a fork inside a cited page if they never census it → Accepted: the orphan-page check plus verified quotes raises the cost substantially, and the rejected heuristic scan would trade this residue for false positives. Recorded as a possible later layer.

[Trade-off] Waivers add a second place a row can be wrong (a stale waiver for a page that should now be a method) → Accepted: a stale waiver is visible and reviewable, which is strictly better than today's invisible absence.

[Risk] `change-isolation` is enforced by instruction, so a session that ignores `AGENTS.md` can still clear the tree → Mitigation: the catalog invariant is the backstop that makes the resulting loss fail `python -m pytest` instead of passing silently; a pre-stash hook is recorded as a deferred follow-up for mechanical enforcement.

## Migration Plan

No deployment surface — this is a local Python catalog writer plus committed JSON artifacts.

Sequence: add the validation function and its pytest assertions with waivers for all current gaps (suite green, invariant live) → convert AWS to real Terraform and StackSets methods and drop those waivers → repeat per remaining row → regenerate both Skill catalog trees via `write_integrations_index` → update tests that pinned the old AWS pair.

Rollback: revert the commit. Note that a partial revert of a row's curation now fails validation by design, which is the property this change exists to add.

Acceptance criteria: `python -m pytest` exits 0; a deliberately uncited integration page fails validation in a named test; a census entry with a quote absent from its page fails validation in a named test; AWS `setupMethodNames` includes Terraform; no Skill catalog Row catalog contains documentation paths or waivers; both Skill catalog trees are byte-identical.

## Open Questions

None blocking. Deferred to a later change: a narrow marker scan as a second layer over the census; whether waiver entries should carry a review date once the backfill is complete.

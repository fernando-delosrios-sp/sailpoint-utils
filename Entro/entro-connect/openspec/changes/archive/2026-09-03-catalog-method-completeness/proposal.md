## Why

Entro documents a Terraform path for AWS multi-account onboarding, but the AWS row cites only two of its documentation pages, so Terraform never became a Setup method and the Connect method gate cannot offer it. The same gap hides Documented methods on ten of thirty-six rows. Validation checks one direction only — cited pages must exist — so an uncited page is unobservable, and `test_one_target_one_row` pins AWS to the incomplete pair, making a revert to the gap green. A hand-applied fix has now been lost twice. Stating the invariant against the documentation tree makes omission loud instead of silent, and makes `python -m pytest` the gate that catches it.

## What Changes

**Documentation page citation**
- From: validation checks that every cited page exists on disk
- To: validation also checks the reverse — every page under the integration documentation folders MUST be cited by the row that owns it or carry a Method waiver with a reason
- Reason: an uncited page is how a Documented method disappears
- Impact: non-breaking to consumers; ten rows must be backfilled before validation is green

**Fork census on cited pages**
- From: a row names whichever methods the curator wrote
- To: each cited page carries a census of the Documented methods it names, each bound to a method name or a Method waiver, and each quoting page text that validation confirms is present
- Reason: catches forks inside pages the row already cites (GitLab tokens, Akeyless auth, SMB upload)
- Impact: curation metadata in the ingest index; stripped from Skill catalog trees

**Affected rows backfilled**
- From: AWS `{CloudFormation, Manual Assume Role}`; nine other rows missing documented paths
- To: AWS gains Terraform and CloudFormation StackSets; GCP, Microsoft Ecosystem, GitLab, SMB, Akeyless, Okta, Atlassian and CrowdStrike gain their documented methods or reasoned waivers
- Reason: the invariant is only credible once the catalog satisfies it
- Impact: new method names reach the Connect method gate; new Operator inputs and Typed actions

**Tests stop pinning the gap**
- From: tests assert AWS equals exactly two Setup methods
- To: tests assert the invariant and the backfilled names
- Reason: the suite currently defends the bug
- Impact: `tests/test_ingest_docs.py`

**Change isolation**
- From: nothing forbids a session from clearing the shared working tree
- To: a change MUST NOT stash, revert, or check out over work it did not create; it isolates itself instead, commits generator edits with their regenerated artifacts, and reports unrecognized dirt or stashes
- Reason: the Terraform work was lost twice to a concurrent session that stashed it as "unrelated"; the catalog invariant makes the loss loud, this makes it not happen
- Impact: binding on every future change; recorded in `AGENTS.md` so sessions read it at start

## Non-goals

No heuristic scanning of page prose for fork phrases. No change to how Connect gates the operator or renders options. No Coverage semantics change. No secrets handling. No new capability domain. No re-ingest of the documentation tree as part of this change.

## Capabilities

### New Capabilities

- `change-isolation`: **new domain, called out explicitly.** How a change behaves toward a shared working tree — never discarding work it does not own, obtaining a clean tree by isolation, committing generator edits with their regenerated artifacts, and reporting unrecognized dirt or stashes. No existing capability covers session conduct.

### Modified Capabilities

- `documentation-ingest`: every integration documentation page MUST be cited or waived; cited pages MUST carry a fork census whose evidence quotes are verified against the page; waivers MUST carry a reason and MUST NOT reach Skill catalog Row catalogs; validation MUST fail on any violation.
- `ubiquitous-language`: add Documented method and Method waiver, with an explicit non-collision note against Coverage.

## Impact

`integration_catalog.py` (validation, row declarations, index serialization), `catalog_contracts.py` (new Typed actions and Operator inputs for backfilled methods), `documentation/integrations.json`, both `entro-connect` Skill catalog trees, `tests/test_ingest_docs.py`, `AGENTS.md` and `docs/agents/change-isolation.md` for the isolation rule, `README.md`, `CHANGELOG.md`. Canonical test command: `python -m pytest`.

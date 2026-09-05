## Scope

In: a fail-closed catalog invariant — every integration documentation page is cited by the row that owns it or waived with a written reason, and every onboarding fork a cited page names is either a Setup / Authentication method or waived — plus the backfill of the ten rows that currently violate it, plus a binding rule on how any future change treats a shared working tree. Out: heuristic scanning of page prose, new Typed actions beyond what the backfilled methods need, and any change to how Connect gates the operator.

## Language

**Documented method** (`promote`):
A distinct way Entro's published documentation says one Add New Account target can be set up or authenticated. It exists in the documentation whether or not the curated catalog names it.
_Avoid_: "setup option", "onboarding flavour", "path" used alone.

**Method waiver** (`promote`):
An explicit catalog record that a Documented method or an integration documentation page is deliberately not carried as a Setup or Authentication method, carrying the reason it is out of scope. Absence without a waiver is a validation failure, not a decision.
_Avoid_: "exception", "ignore list", "skip list" — and never "coverage waiver", which collides with Coverage.

**Fork census** (`draft`):
The per-page list of Documented methods a cited page names, each bound to a method name or a Method waiver, and each quoting the page text that names it.
_Avoid_: "inventory" (overloaded), "method coverage" (collides with Coverage).

Conflict note: **Coverage** is already canonical for an additional surface of an Integration (SharePoint scanning, Falcon RTR). This change MUST NOT reuse "coverage" for catalog completeness. Requirement and identifier names use "completeness" or "census".

## Decisions

Context: the AWS row cites two of its documentation pages, so `aws-multiple-account-automation.md` — which documents Terraform and CloudFormation StackSets as first-class deployment options — never became a Setup method. The Connect method gate offers only what the row names, so Terraform is invisible to the operator. A hand-applied fix was lost twice, because it lived in uncommitted edits and no test defends it.

Q1 — Why did the fix vanish rather than fail loudly? `validate_integration_paths` (`integration_catalog.py:2984`) checks one direction only: every *cited* page must exist on disk. An uncited page is unobservable. `test_one_target_one_row` then pins AWS to exactly `{CloudFormation, Manual Assume Role}`, so the committed suite encodes the gap as correct and a revert to it is green.

Q2 — Is AWS special? No. Ten of thirty-six rows are affected: AWS, Google Cloud Platform, Microsoft Ecosystem, GitLab, File Shares (SMB), Akeyless, Okta, all four Atlassian rows, and CrowdStrike at Coverage level. Two shapes appear: a whole uncited page or subtree (AWS multi-account, Okta custom role, Atlassian legacy), and a fork inside a page the row already cites (GitLab group vs personal token, Akeyless Universal Identity vs API key, SMB manual vs JSON upload).

Q3 — What makes a check fail closed against a revert? The documentation tree is an independent source of truth already in the repo. If the invariant is stated against the tree, reverting a row's curation removes the citation *and* the waiver together, leaving the page orphaned and validation red. Chosen direction: derive the failure from the tree, never from a list of expected method names.

Q4 — Which enforcement model? Explicit-waiver (operator gate, chosen). Rejected: a pinned per-row method inventory, which defends recorded methods but cannot see a method nobody recorded; and a heuristic marker scan, which trades curation for false positives and a suppression list.

Q5 — Can a curator still silently omit an in-page fork? Partly, so the census entry MUST quote the page text that names the fork and validation MUST confirm that quote appears in the cited page. The census becomes checkable against the documentation rather than self-asserted.

Q6 — Where do waivers live? On the curated row in the Python module, emitted into ingest `documentation/integrations.json`, and stripped from the Skill catalog trees like other documentation paths — Connect never opens `documentation/`, so waivers must not reach a Row catalog.

Q7 — Does the check run without a documentation cookie? It must. Ingest needs `ENTRO_DOCS_COOKIE`, so the invariant is additionally asserted by pytest against the committed tree, making `python -m pytest` the gate that would have caught both losses.

Q8 — What actually removed the work? `git stash list` holds `wip: unrelated terraform catalog (not configure-once-prompts)`. A concurrent session working the `configure-once-prompts` change stashed the Terraform curation because it looked unrelated to the change in hand, twice, in a shared working tree. The catalog invariant makes such a loss loud; it does not stop it happening. Chosen direction: state the conduct as its own requirement — a change never discards work it does not own, obtains a clean tree by isolating itself, commits generator edits together with their regenerated artifacts, and reports uncommitted work or stashes it cannot attribute.

Q9 — Where does that conduct requirement live? It is not product behaviour, so no existing capability fits: `documentation-ingest`, `integration-prep`, `integration-automation`, and `connection-details` all describe the tool, not the session. A new `change-isolation` capability is declared explicitly in the proposal, and the same rule is written into `AGENTS.md` and `docs/agents/change-isolation.md`, which is what future sessions actually read at start.

## Open questions

None blocking. Deferred: whether a later change adds a narrow marker scan for fork phrases as a second layer (rejected here as heuristic); whether CrowdStrike's Terraform EC2 option belongs on the row or stays Coverage-level detail (design records it as a Coverage-level census entry, not a row method); whether a repo hook should refuse a stash that spans another session's files, which would enforce `change-isolation` mechanically rather than by instruction.

## Scenarios discussed

- An integration documentation page exists that no row cites and no waiver names → validation fails.
- A page is cited and its fork census names every option → validation passes.
- A census entry quotes text that does not appear in the page → validation fails, so a stale quote cannot survive a documentation refresh.
- A row's curation is reverted → the page loses citation and waiver together → validation fails.
- A waiver with an empty or missing reason → validation fails; a waiver is a sentence, not a flag.
- A Skill catalog Row catalog that carries waivers or documentation paths → validation fails, preserving the skill's isolation from `documentation/`.
- A Coverage-owned fork (Falcon RTR Terraform EC2) is censused on the Coverage, not promoted to a row Setup method.
- A non-integration page (Entro Connector topology, SSO setup, IDE plugins) is outside the integration documentation folders and therefore never requires a citation or waiver.
- A session finds uncommitted work it did not create → it leaves it in place and reports it, rather than stashing to get a clean tree.
- A session needs a clean tree for verification → it isolates into a worktree or branch instead of clearing the shared one.
- A session finds a stash it does not own → it surfaces the message and file list and lets the operator decide, never applying or dropping it unilaterally.
- A change edits the curated catalog and regenerates artifacts → both land in one commit, so the regeneration is never mistaken for stray work.

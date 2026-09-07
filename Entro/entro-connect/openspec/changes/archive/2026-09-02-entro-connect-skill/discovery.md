## Scope

One change: a self-contained Skill catalog plus a model-invoked `entro-connect`
skill that Locks a target, persists a full Intro before any Operation mode, then
runs instructions, supervised, or automated against typed catalog contracts, and
appends a Connect log. Out of scope: Entro API account creation, Connector
deployment install, per-integration skills, secrets in agent context, and
ad-hoc (non-catalog) mutation commands.

## Language

**Connect log** (`promote`):
A gitignored markdown file at the repo root (`entro-*.md`) for one Add New Account
target. Created after Lock and updated as the run proceeds. Secret field values are
never stored.
_Avoid_: session file (alias only), Integration log, dumping secrets, treating it as
the Integration index

**Operation mode** (`promote`):
How a Connect run performs Integration prep: `instructions` (full safe playbook,
operator executes every mutation), `supervised` (same disclosures; operator
executes after each approval), or `automated` (agent executes cataloged mutating
actions after per-change approval). Automated is offered only when the Lock has a
complete typed-action plan.
_Avoid_: manual (as the canonical name), collapsing supervised into instructions

**Prep step** (`promote`):
One curated item in `prepSteps`: `{title, instruction, evidence}`. Order and
done-when stay data. Typed actions bind to Prep steps; they are not a `command`
field on the step.
_Avoid_: calling a Prep step a Setup method; putting raw shell on the Prep step

**Skill catalog** (`promote`):
The generated Integration index copy at `.agents/skills/entro-connect/integrations.json`.
The skill reads this file (and sibling skill markdown). It MUST NOT read
`documentation/` markdown.
_Avoid_: hand-editing the skill copy; treating ingested pages as a skill dependency

**Lock** (`promote`):
The confirmed Add New Account target for one Connect run — tile plus
`targetSelection`, Coverages to include (default none), and Setup method /
Authentication method when the row has two or more of either.
_Avoid_: treating a Coverage as a tile; locking “Microsoft” without a target

**Operator input** (`promote`):
A cataloged non-secret value the operator supplies during Intro (`key`, prompt,
purpose, validation, optional default, `secret` false). Connection details and
typed actions reference the key.
_Avoid_: inferring names from “operator-chosen” prose; collecting secrets as inputs

**Typed action** (`promote`):
A cataloged Integration-prep action with preview (when the vendor supports it),
mutation, target, expected change, verification, reversal or irreversible-impact
note, and official source URL. Executable definitions are immutable at run time.
_Avoid_: ad-hoc replacement commands; a `command` field on Prep steps

**Platform identity** (`promote`):
Non-secret evidence that a Configuration tool session is authenticated: principal
plus service endpoint and active tenant / org / account / project / subscription
scope. Recorded in the Connect log after a successful auth check.
_Avoid_: persisting tokens; recording only a username with no scope

**Configuration plan** (`promote`):
The exact ordered list of tools, actions, targets, expected changes, and evidence
persisted after names and Operation mode are settled, before any mutation.
_Avoid_: treating the Intro outline as the executable plan

**Capability probe** (`promote`):
A cataloged safe check that a Configuration tool is present and suitable (module /
plugin / capability). A minimum version is stored only when the vendor requires one.
_Avoid_: treating any executable as suitable; always offering reinstall

**Connection details** (`draft`):
Canonical term stands. Vendor-specific fields stay `connectionFields`
`{name, secret, obtainedHow}`. Operator-chosen names are Operator inputs, not
inferred from `obtainedHow`.
_Avoid_: field map as the canonical name (alias only)

**Coverage** (`draft`):
Canonical term stands. Coverages add Prep steps and may add Configuration tools;
they do not add or replace Connection details.

**Connector deployment** (`draft`):
Canonical term stands. The skill names it in the intro from a short file inside
the skill folder; it does not install a connector or open `documentation/entro-connector/`.

**Integration automation** (`draft`):
Canonical term stands. Automated Operation mode executes Typed actions after
auth-once and per-change approval.

**Configuration tool** / **Fit** / **Credential boundary** (`draft`):
Canonical terms stand. Fit `preferred` is a promise of a complete typed-action
plan; otherwise Fit is corrected downward.

## Decisions

**Context** — Catalog and skill already exist. Operator feedback: mode is offered
before a real Intro; Intro is not persisted; already-installed tools are offered
again; auth success does not record platform; mutating steps are not disclosed;
names are not collected. Grilling rounds 1–7 plus a Microsoft-environment check.

**Q1–Q18** — Prior decisions stand except where this list supersedes them:
Q13 (automated bar) and Q17 (instructions batch skip ceremony).

**Q19 — Skill catalog?** Unchanged: two JSON writes; skill reads only the skill copy.
(`skill-local-catalog`)

**Q20 — Log write timing?** Create immediately after Lock; persist Intro before
offering Operation mode; append later results as they happen. (`progressive`)

**Q21 — Change approval?** Announce the complete Configuration plan after mode
and names; disclose and approve each mutating command immediately before execution.
(`each-change`)

**Q22 — Naming scope?** Every catalog Operator input plus Worker Group (Connector);
use catalog defaults only when explicitly present. (`all-operator-chosen`)

**Q23 — Unsuitable installed tool?** Record detection, explain mismatch, gate the
exact upgrade or dependency install. (`explain-and-gate`)

**Q24 — Auth help?** Collect non-secret error/output, diagnose, return to
Continue/check-or-help until authentication verifies. (`diagnose-nonsecret`)

**Q25 — Auth contract source?** Each `toolInstall` entry carries deterministic presence,
Capability probe, auth-check, and platform-identity queries. The skill executes that
contract only. (`catalog-contract`)

**Q26 — Platform identity bound?** Principal plus endpoint and active scope, every
applicable non-secret identifier. (`principal-and-scope`)

**Q27 — Naming timing?** During Intro, before Operation mode. (`before-mode`)

**Q28 — Instructions-only batch Intro?** Every target gets a persisted Lock and
Intro; only interactive tooling is skipped. Supervised/automated stay sequential.
(`always-intro`; supersedes Q17 skip)

**Q29 — Disclosure layers?** Intro states capabilities and a no-action-yet boundary.
After mode and names, persist the Configuration plan before any execution.
(`two-level-plan`)

**Q30 — Automation contract?** Typed actions with preview, mutation, target, expected
change, verification, rollback/help metadata. Automated only when every selected
Prep step has a valid action. (`typed-actions`)

**Q31 — Tool suitability?** Capability probe per tool; minimum version only when the
vendor requires one. (`capability-probe`)

**Q32 — Confirm authenticated target?** Gate displayed principal, endpoint, and
scope: continue with this environment or re-authenticate/help. (`confirm-target`)

**Q33 — Principal in the log?** Full non-secret username or service-principal name
plus platform scope. (`full-nonsecret`)

**Q34 — Supervised disclosure?** Same Configuration plan and per-change approval;
after approval the operator executes; the agent verifies evidence. (`same-disclosure`)

**Q35 — Existing auth?** Run the safe auth/identity check first. Valid → skip login
and confirm environment. Invalid → request login and end with Continue/check or Help.
(`check-first`)

**Q36 — Reversibility?** Executable rollback when safe; otherwise state
irreversibility and residual impact before approval. (`rollback-or-impact`)

**Q37 — Verification failure?** Stop, persist observed state, then gate safe rollback,
retry verification, or diagnosis/help. (`stop-and-gate`)

**Q38 — Name collision?** Inspect the existing object, disclose match, then gate
reuse, choose another name, or stop. (`inspect-and-gate`)

**Q39 — Dry-run?** Always run and persist vendor preview when supported; state when
the platform has none. (`always-when-supported`)

**Q40 — Change vehicle?** Revise this existing unarchived change. (`revise-open-change`)

**Q41 — Automation breadth?** Typed actions for every catalog row currently carrying
Fit `preferred`. (`all-preferred`)

**Q42 — Operator input schema?** Explicit typed inputs; actions and Connection
details reference keys. (`typed-inputs`)

**Q43 — Automation eligibility?** Every selected Prep step has a valid Typed action
and required tools have presence/auth/identity contracts; otherwise hide automated
and explain why. (`complete-plan`; supersedes Q13 Fit-preferred-only)

**Q44 — Persisted Intro?** Same operator-facing brief as chat: purpose, Coverages,
topology, prerequisites, tools/status, names, fields, step outline, safety
boundary, and C4. (`same-rendered-brief`)

**Q45 — External scripts?** Fetch only from a catalog-pinned URL/version with
checksum; save locally; show provenance and reviewable content/diff; per-change
approval before execution. (`pinned-review`)

**Q46 — Secret-producing actions?** Operator-executed even in automated mode; agent
verifies only non-secret metadata. (`operator-secret-step`)

**Q47 — Per-change gate?** Approve this change, adjust/replan, or stop and persist.
(`approve-adjust-stop`)

**Q48 — Catalog validation?** Fail tests/generation if any selectable preferred
automation path lacks typed inputs, complete actions, probes, auth checks,
identity evidence, verification, and reversal/impact metadata. (`fail-incomplete`)

**Q49 — Docs evidence?** Official vendor or Entro source URL and retrieval/version
date for every probe and action. (`official-source-per-action`)

**Q50 — Adjust/replan bound?** Change validated Operator inputs or remaining
Operation mode; Typed action definitions stay immutable. (`inputs-or-mode`)

**Q51 — Name prompt?** One name at a time: catalog-derived suggestion or enter
custom; validate and persist. (`suggest-or-custom`)

**Q52 — Instructions plan detail?** Same ordered disclosures, actions, targets,
evidence checks, and rollback/impact notes; every mutation operator-executed.
(`full-safe-playbook`)

**Q53 — Incomplete preferred path?** Correct that path's Fit to usable/none with
rationale. (`downgrade-fit`)

**Q54 — Acceptance?** Fixture replay of every preferred path plus one consented
Microsoft Ecosystem dry-run against a non-production environment. (`fixtures-plus-microsoft-dry-run`)

**Q55 — Microsoft live environment?** Ready; operator can provide local authenticated
access at the acceptance gate. (`ready`)

## Open questions

None blocking. Authoring of per-row Typed actions, Operator inputs, and probes is
apply work. If official evidence cannot be established for a currently preferred
path, Fit is corrected downward (Q53) rather than blocking the change.

## Scenarios discussed

- First operator-visible gate after Lock is Intro persistence, then Operation mode
- Instructions-only “do AWS, Okta, and Slack” writes three Connect logs, each with
  persisted Intro; no tool install
- `pwsh` already on PATH → probe, record version, skip install
- `az login` already valid → skip login; record tenant and principal; confirm
  environment; Continue
- Auth fails → Help diagnoses non-secret CLI output; loop Continue/check or Help
- Automated Microsoft Ecosystem: Configuration plan listed before any script;
  Entro onboarding script pinned, reviewed, then approved per change
- Secret Value creation stays operator-executed; log records app id, not the secret
- GitHub Cloud - New: `gh` usable → no automated unless a complete typed-action
  plan exists (it does not today)
- Incomplete preferred row: Fit downgraded; validation fails if Fit stays preferred
  without a complete plan
- Name collision on an Entra app display name → inspect, then reuse / rename / stop
- Verification fail after a mutating action → stop; rollback if declared; no
  later independent actions

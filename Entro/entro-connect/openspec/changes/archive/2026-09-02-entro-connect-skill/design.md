## Context

`documentation/integrations.json` and the Skill catalog already carry `summary`,
`connectionFields`, and `prepSteps`. The `entro-connect` skill Locks a target and
writes a Connect log, but it offers Operation mode before a persisted Intro, offers
install for tools already present, and cannot execute a complete automated plan
because Prep steps are prose. Constraint: never put secrets in agent context or
committed files. Prefer official CLIs after a verified local session.

## Architecture

[Container diagram](./diagrams/entro-connect-skill.drawio)

The skill runs in the operator’s agent. It reads the Skill catalog inside its
folder, not ingested GitBook pages. It does not call Entro’s API. The operator
pastes the field map into Entro. Configuration tools run in the operator’s CLI
session (token cache / MCP OAuth). Typed actions execute only after per-change
approval against that session.

## Goals / Non-Goals

**Goals:**

- Keep self-contained `summary`, `connectionFields`, and `prepSteps` for every target
- Generate a Skill catalog copy the skill reads; never open `documentation/` at run time
- Persist Intro (same brief as chat) before offering Operation mode; create the Connect log after Lock
- Collect Operator inputs during Intro; bind them to Connection details and Typed actions
- Probe tools before install; record Platform identity; confirm the environment
- Automated only with a complete Typed action plan; otherwise hide automated and explain
- Per-change disclosure with Approve / adjust / stop; secret-producing steps stay operator-executed
- Fail catalog validation when Fit `preferred` lacks a complete plan; downgrade Fit with rationale

**Non-Goals:**

- Entro API create-account
- Installing or configuring Connector deployment
- Per-integration skills
- Parsing GitBook tables at ingest or skill run time
- A `command` field on Prep steps
- Ad-hoc mutation commands invented at run time
- Automatic rollback without a gated choice
- Skill access to `documentation/` markdown
- Secrets-handling runtime beyond “stop and ask the operator”

## Decisions

### D1: One skill, catalog is data

- **Choice**: `.agents/skills/entro-connect/` with disclosed files (`lock-target`,
  `intro`, `modes`, `tools`, `session-log`, `connector-deployment`). Model-invoked.
  Reads `.agents/skills/entro-connect/integrations.json` only. No per-target skill.
- **Reason**: writing-for-agents; SKILL.md stays steps; the Skill catalog is the
  per-target data when `documentation/` is absent.
- **Considered alternatives**: User-invoked only — rejected. Read
  `documentation/integrations.json` plus pages — rejected, pages unavailable.
  Router plus later per-target skills — rejected as premature.

### D2: Curate self-contained fields and steps; emit two JSON files

- **Choice**: `connectionFields[]` `{name, secret, obtainedHow}`; `prepSteps[]`
  `{title, instruction, evidence}`; each row has `summary`. Same
  `integration_catalog.py` writes `documentation/integrations.json` and
  `.agents/skills/entro-connect/integrations.json`. Apply fills every row.
- **Reason**: the skill has no documentation tree. Page citations are useless at
  run time. Distilled `instruction` and `obtainedHow` do not rot the same way
  unversioned one-liners do.
- **Considered alternatives**: Cite ingested paths — rejected, skill cannot open
  them. Byte-identical files including dead `documentation[]` paths — rejected,
  agents follow the paths. Hand-maintained skill JSON — rejected, goes stale.

### D2b: Skill catalog omits ingest-only page paths

- **Choice**: Skill catalog includes targets, Coverages, tools, `toolInstall`,
  `summary`, fields, steps, Operator inputs, and Typed actions. It MUST NOT
  require `documentation` markdown paths.
- **Reason**: integrations.json is the minimal source of truth for a Connect run.
- **Considered alternatives**: Skill opens GitBook URLs — rejected, not local SoT.

### D3: Worker Group global; other Entro labels per row

- **Choice**: Every field map includes Worker Group (Connector). Environment,
  Display Name, Nickname are curated when that target’s docs name them, and are
  collected as Operator inputs during Intro.
- **Reason**: Worker Group is always required; the other three labels are not
  universal.
- **Considered alternatives**: Three globals — rejected after ingest grep.

### D4: Lock includes Coverages and plural routes

- **Choice**: Lock = tile + `targetSelection` + Coverages (default none) + Setup
  method / Authentication method when cardinality > 1.
- **Reason**: Copilot Studio is a Coverage; AWS and GitHub Legacy have real forks.
- **Considered alternatives**: Coverage after intro — rejected. Setup after mode —
  rejected, automated vs CloudFormation would race.

### D5: Operation modes and complete-plan bar

- **Choice**: instructions | supervised | automated. Automated iff every selected
  Prep step has a Typed action and required tools have presence, Capability probe,
  auth-check, and Platform identity contracts. Fit none or an incomplete plan
  hides automated and the skill explains why. Tools: match Setup method, else
  first preferred, then usable CLI, then MCP. Install/auth only for supervised
  and automated. Fit `preferred` without a complete plan is corrected to `usable`
  or `none` with rationale.
- **Reason**: Fit preferred was a false automation promise while Prep stayed prose.
- **Considered alternatives**: Automated iff Fit preferred — superseded. Partial
  automated plus leftover supervised steps — rejected. Keep Fit preferred with
  validation exceptions — rejected.

### D6: Connect log is progressive

- **Choice**: `entro-<tile-slug>[-<target-slug>].md` at repo root. `.gitignore`
  `entro-*.md`. Create after Lock; persist Intro before Operation mode; append
  Configuration plan, Platform identity, and Prep evidence as they occur.
  Re-run appends. Secret fields named, values blank. Principal identifiers are
  full non-secret names plus scope.
- **Reason**: the destination file is the operator’s picture and environment
  reference, not a late dump.
- **Considered alternatives**: Write only at the end — rejected. Persist compact
  machine snapshot instead of the chat brief — rejected.

### D7: Instructions-only batch still persists Intro

- **Choice**: Many targets + instructions → one Connect log each with Lock and
  Intro; skip tools, auth-once, and mutating execution. Supervised/automated stay
  sequential, one Lock at a time.
- **Reason**: the Intro is the picture of what connecting needs, even when the
  operator will execute later by hand.
- **Considered alternatives**: Skip intro/C4 for batches — superseded.

### D8: C4 in the run vs design

- **Choice**: Skill intro uses ASCII (same five boxes). This design records a
  draw.io of the skill’s containers.
- **Reason**: Draw.io every Connect run is heavy; ASCII matches grilling.
- **Considered alternatives**: `.drawio` beside every Connect log — rejected.

### D9: Intro names Connector deployment only

- **Choice**: Short `connector-deployment.md` inside the skill. Do not deploy
  Docker/Helm. Do not open `documentation/entro-connector/`.
- **Reason**: Connector is always required; topologies are product-level; the
  skill has no documentation tree.
- **Considered alternatives**: Walk connector if missing — out of scope. Point at
  ingested connector pages — rejected, unavailable to the skill.

### D10: Two-level disclosure

- **Choice**: Intro is capabilities plus a no-action-yet boundary. After names
  and Operation mode, persist the Configuration plan. Each mutation then has its
  own disclosure and Approve / adjust / stop. Adjust may change Operator inputs or
  remaining Operation mode; Typed action definitions stay immutable. Vendor
  dry-run runs and is persisted when the catalog says it is supported.
- **Reason**: operators need the whole picture first, then an exact plan, then
  a last look at each change.
- **Considered alternatives**: Exact commands during Intro — too early, before
  mode. One approval for the whole plan — rejected. Ad-hoc replacement commands
  — rejected.

### D11: Catalog contracts for tools and actions

- **Choice**: `toolInstall` carries presence, Capability probe, auth-check, and
  Platform identity queries. Operator inputs are explicit (`key`, prompt,
  purpose, validation, optional default, `secret` false). Typed actions bind to
  Prep steps and carry preview, mutation, target, expected change, verification,
  rollback or irreversible impact, source URL, and retrieval date. External
  scripts are pinned (URL, version, checksum), saved locally, reviewed, then
  approved. Secret-producing actions stay operator-executed. Validation fails
  incomplete preferred paths. Every probe and action records an official source.
- **Reason**: the skill must not infer checks or invent commands.
- **Considered alternatives**: Skill-inferred checks — rejected. Raw `command` on
  Prep steps — rejected. Repo-only scripts — too narrow given Entro onboarding
  scripts. Direct vault sink for secrets — out of scope.

### D12: Auth check first; Help loops

- **Choice**: Run auth-check before login. Valid session → skip login, confirm
  observed principal/endpoint/scope. Invalid → request `authOnce`; finish with
  Continue (check) or Help. Help diagnoses non-secret output and returns to that
  gate until the check succeeds.
- **Reason**: existing sessions should not be discarded; failed login needs a
  path other than ending the run.
- **Considered alternatives**: Always fresh login — rejected. Operator declares
  whether they are logged in — rejected, that is a fact the skill can look up.

### D13: Collision, failure, and acceptance

- **Choice**: Name collision → inspect, disclose, gate reuse / another name / stop.
  Verification fail → stop the plan, persist observed state, gate rollback if
  cataloged, retry verification, or Help. Acceptance: fixture replay of every
  preferred path plus one consented Microsoft Ecosystem dry-run against the
  ready non-production environment. This change is revised in place rather than
  a follow-up change.
- **Reason**: mutating customer tenants is sensitive; partial success must not
  continue blindly.
- **Considered alternatives**: Auto-rollback — rejected. Continue later independent
  actions — rejected. Live-run every preferred path — too much tenant access.

## Risks / Trade-offs

[Risk] Authoring Typed actions for every current preferred path is large apply work
→ Mitigation: official source per action; downgrade Fit when evidence is missing;
validation fails incomplete preferred paths.

[Risk] Skill catalog drifts from ingest index → Mitigation: one writer; tests fail
when the skill copy is missing keys or stale versus the catalog module.

[Risk] Agent invents commands despite Typed actions → Mitigation: skill forbids
ad-hoc mutations; tests and fixtures cover preferred paths.

[Risk] `entro-*.md` ignore is broad → Mitigation: documentation tree is not at
repo root; README notes the pattern.

[Trade-off] Duplicate Worker Group not in JSON → Reason: global rule in skill and
connection-details spec, not 40 identical fields.

[Trade-off] Automated still cannot fill the Entro form → Reason: secrets stay with
the operator.

[Trade-off] External scripts are fetched, not committed → Reason: pin, checksum,
local save, and review before execute.

## Migration Plan

Keep existing catalog emit and skill files. Extend `toolInstall` and row schema.
Author Operator inputs and Typed actions for every remaining Fit `preferred`
path, or downgrade Fit. Rewrite skill steps: Lock → log → Intro + names → mode →
probe/auth → Configuration plan → per-change prep → log. Acceptance: `.venv/bin/python
-m pytest`; fixture replay of every preferred path; consented Microsoft Ecosystem
dry-run; `openspec validate --all --json`.

## Open Questions

None blocking. Per-row Typed action text is apply authoring against official
sources. If a currently preferred path cannot be evidenced, Fit is corrected
downward rather than blocking archive.

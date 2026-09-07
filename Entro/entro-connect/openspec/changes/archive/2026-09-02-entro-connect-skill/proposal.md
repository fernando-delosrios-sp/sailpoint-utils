## Why

The Skill catalog and entro-connect skill exist, but a Connect run still offers
Operation mode before the operator sees what the Integration is and what connecting
it needs. The Intro is not written to the Connect log. Already-installed tools are
offered again. Auth success does not record which platform environment is in use.
Mutating configuration is not disclosed up front. Automated mode cannot execute a
complete plan because Prep steps are prose only.

## What Changes

**Progressive Connect log and Intro-first run**
- From: mode first; Intro skipped for instructions-only batches; log written at the end
- To: create the log after Lock; collect Operator inputs; persist the same Intro
  brief (purpose, Coverages, topology, prerequisites, tools, names, fields, step
  outline, safety boundary, C4) before offering Operation mode; append evidence as
  it happens. Instructions-only batches still persist Intro; they skip tools only
- Reason: the operator chooses an approach against a complete picture
- Impact: skill steps and session-log format; non-breaking for gitignored logs

**Tool probe, auth check, and Platform identity**
- From: offer install; request login; record little more than “ok”
- To: Capability probe first; gate install only when missing or unsuitable; auth
  check first; record principal, endpoint, and active scope; confirm the environment;
  failed auth ends with Continue/check or Help
- Reason: reuse what is already there; the log is the environment reference
- Impact: `toolInstall` contract plus skill tools.md

**Typed Operator inputs, Typed actions, and Configuration plan**
- From: Fit preferred is enough for automated; no executable actions; names guessed
- To: cataloged Operator inputs collected one at a time during Intro; Typed actions
  bind to Prep steps; automated only when the selected plan is complete; Fit
  `preferred` without a complete plan is corrected downward; per-change
  approve/adjust/stop; secret-producing steps stay operator-executed
- Reason: disclose every mutation; secrets stay out of agent context
- Impact: catalog schema, tests fail incomplete preferred paths, skill modes/prep

## Non-goals

No Entro API account creation. No Connector deployment install. No secrets in
agent context, Connect logs, or git. No per-integration skills. No ad-hoc mutation
commands. No automatic rollback without a gated choice. No live run of every
preferred path (fixtures plus one consented Microsoft dry-run).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `documentation-ingest`: Operator inputs; Typed actions; Capability probes; auth
  and identity contracts; source URLs; validation of preferred paths
- `connection-details`: Operator inputs bind to named Connection details
- `integration-prep`: Configuration plan; per-change disclosure; name collision
- `integration-automation`: Intro-first gates; complete-plan automated bar;
  Platform identity; Continue/check or Help
- `ubiquitous-language`: Operator input, Typed action, Platform identity,
  Configuration plan, Capability probe; Operation mode / Connect log notes

## Impact

`integration_catalog.py`, both `integrations.json` files, tests, fixtures,
`.agents/skills/entro-connect/`, README, ADR, `CHANGELOG.md`. GitBook fetch
unchanged. Consented Microsoft Ecosystem dry-run at apply acceptance.

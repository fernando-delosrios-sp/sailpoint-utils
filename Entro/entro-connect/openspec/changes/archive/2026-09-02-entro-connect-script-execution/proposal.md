## Why

Supervised Connect runs still had the operator execute every mutation. Hardcoded names in pinned scripts could not be adjusted without failing the checksum stop. Operators now want the skill to run safe actions after a clear Approve and recover from replace/collision by proposing a fix and retrying, while secret-producing actions stay outside agent context.

## What Changes

**Who runs Prep mutations**
- From: Supervised = operator executes after Approve; automated = skill runs only when `secretProducing` is false
- To: Supervised and automated = skill states the exact command, waits for Approve / Adjust / Stop, then runs non-secret-producing actions; secret-producing actions stay operator-executed; playbook stays write-only
- Reason: The skill is the runner; Approve is the control
- Impact: Breaking for operators who expected to type the command themselves in supervised; skill docs and specs

**Secret-producing Typed actions**
- From: Operator-executed in supervised and automated
- To: Unchanged: operator executes them so Client Secret (or equivalent) stays out of agent context, chat, and the Connect log
- Reason: Cursor captures command output into agent context before redaction
- Impact: No contract change; the catalog flag continues to enforce the credential boundary

**Collision / replace**
- From: Inspect before create; gate reuse / another name / stop; Typed action definitions immutable; checksum mismatch stops
- To: Same inspect-before-create. If a run would replace or collide, notify, propose a fix, gate, re-run. Temporary script copy after a matching checksum; never edit the Skill-held file. Interactive menus: bind unattended on the copy, or stop that step for the operator
- Reason: Vendor scripts hardcode names and menus
- Impact: Non-breaking for playbook; new Prep loop

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `integration-prep`: Skill runs pinned scripts after Approve; Temporary script copy; collision/replace retry gate
- `integration-automation`: Supervised and automated share execution for non-secret-producing actions
- `ubiquitous-language`: Temporary script copy and Operation mode notes

## Impact

entro-connect skill trees (`.agents/skills/entro-connect` and `skills/entro-connect`: `SKILL.md`, `modes.md`, `prep.md`, `session-log.md`). Skill-doc tests in `tests/test_ingest_docs.py`. Canonical specs after archive. ADR-0001 clarifies that supervised runs safe actions while secret-producing actions remain operator-executed. No Entro API or ingest schema change.

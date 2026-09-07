## Why

Automated mode does not currently automate the step operators care most about. Because every secret-producing action stays operator-executed, an automated Microsoft Ecosystem run stops and asks the operator to run the Azure onboarding script by hand — the same thing supervised would do. Meanwhile supervised is defined to execute commands itself, which is the opposite of what "supervised" leads an operator to expect. Swapping the two makes each mode mean what its name says: automated runs the plan, supervised watches the operator run it.

## What Changes

**Automated execution**
- From: after Approve, the agent runs non-secret-producing Typed actions only; secret-producing ones are handed back to the operator.
- To: the agent announces each change (full disclosure plus "running it now") and then runs it itself, secret-producing actions included, with no per-change gate.
- Reason: unattended execution is the mode's purpose; the secret-in-context problem is solvable by routing output.
- Impact: breaking behavior change for automated runs.

**Supervised execution**
- From: the agent runs the approved command and MUST NOT wait for the operator to type it.
- To: the agent discloses and gates, then hands the operator the exact command to run in their own terminal, and verifies the non-secret result. The agent runs no mutation.
- Reason: the gate is worth little if the agent executes anyway.
- Impact: breaking behavior change for supervised runs.

**Secret handling**
- From: secrets never reach agent context because the agent never runs the command that produces them.
- To: under automated, a secret-producing command writes to a Secret sink outside the repo and both skill trees; the agent reads back only named non-secret identifiers, tells the operator the path to vault from, and deletes it on confirmation. A command that cannot withhold its secret from terminal output is handed to the operator instead.
- Impact: the invariant holds — no secret in agent context, chat, or the Connect log.

Unchanged: playbook mode, signing in (`authOnce` stays operator-run in every mode), `operatorOnly` steps with no Typed action, and the safety pauses for name collision, checksum mismatch, and failed verification.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- `integration-prep`: the Approve-gate execution rule, the supervised and automated script scenarios, and the Client Secret scenario.
- `integration-automation`: the mode table semantics, the one-time-secret rule, and the Connect log execution actor.
- `ubiquitous-language`: narrow Operator-only step so minting a credential no longer implies operator execution; add Announcement and Secret sink.

## Impact

`.agents/skills/entro-connect/{SKILL.md,modes.md,prep.md,session-log.md,tools.md}` and the byte-identical mirror under `skills/entro-connect/`. Three assertions in `tests/test_ingest_docs.py` pin the old wording and move with the specs. No catalog schema change: `secretProducing` already exists on Typed actions.

## Scope

In supervised and automated Operation modes, entro-connect runs non-secret-producing cataloged Typed actions after stating the exact command and waiting for Approve. Secret-producing actions stay operator-executed, and playbook stays write-only. On replace or name collision, the skill notifies, proposes a fix, gates it, and re-runs — using a Temporary script copy when names or an interactive menu must change. Secrets never enter agent context, chat, or the Connect log. Out of scope: playbook execution, inventing mutations, writing Skill-held files, Operator-only UI steps, Connector deploy.

## Language

**Temporary script copy** (`promote`):
A disposable copy of a pinned Skill-held onboarding artifact, used only to bind names or skip an interactive menu for one run. The original file and checksum stay untouched.
_Avoid_: in-place edit, patched vendor script, rewritten Typed action

**Operation mode** (`conflicts-with-canonical`):
Canonical notes (archived Term entry, missing from current Term entries) say supervised means the operator executes after Approve. This change: supervised and automated both mean the skill runs non-secret-producing actions after Approve; secret-producing actions stay operator-executed; playbook remains write-only.
_Avoid_: collapsing playbook into supervised

**Operator-only step** (`draft`):
A Prep step with no executable Typed action. UI-only and secret-producing actions remain operator-executed, but a cataloged secret-producing action is still described by its Typed action.
_Avoid_: exposing a Client Secret to the agent

## Decisions

Context: Connect runs left configuration scripts to the operator in supervised mode, and in automated mode whenever `secretProducing` was true. Pinned checksum mismatch stopped the plan, so names hardcoded in vendor scripts could not be adjusted. Collision was inspect-then-reuse/rename/stop before create, not retry after a replace attempt.

- Q1 disclose-then-run → `approve-then-run`
- Q2 secret-producing → initially `agent-runs-redact`; apply found Cursor captures command output into agent context, so the operator selected `operator-runs-secret`
- Q3 replace-retry → `gate-fix-rerun`
- Q4 temp-script → `temp-copy`
- Q5 mode-split → `same-execution` for non-secret-producing actions (playbook write-only)
- Q6 interactive-script → `temp-unattended` (else stop that step for the operator)

## Open questions

None. Confirm `yes-propose`.

## Scenarios discussed

- Approve names `pwsh -File …`; skill runs it in supervised and in automated
- Azure script prints a Client Secret; operator runs it so the secret never enters agent context; chat and Connect log record Client ID and Tenant ID only
- Checksum of the Skill-held file fails → stop; no copy, no run
- Existing EntroSecurityApp (or equivalent) → disclose, propose a new name, gate, Temporary script copy, re-run
- Operator rejects the proposed fix → stop or Adjust; do not overwrite the destination
- Interactive menu cannot be bound unattended → stop that step; operator runs the original pinned file
- Operator-only UI step still has no mutation
- Playbook still writes the plan; no run

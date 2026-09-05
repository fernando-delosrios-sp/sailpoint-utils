## Context

entro-connect offers three Operation modes. Today supervised and automated differ only in how many gates the operator sees: both have the agent run non-secret-producing Typed actions after Approve, and both hand secret-producing actions back. For Microsoft Ecosystem's Automated PowerShell method, both cataloged Typed actions carry `secretProducing: true`, so an automated run automates nothing on that path.

The constraint that produced the old rule is real: an agent-run command's stdout enters agent context, and a Client Secret must not. This change keeps the constraint and moves the plumbing instead of the responsibility.

## Goals / Non-Goals

**Goals:**
- Automated executes every Typed action in the plan itself, announcing each one first, with no per-change gate.
- Supervised executes nothing; it discloses, gates, and the operator runs the command.
- No secret reaches agent context, chat, or the Connect log under either mode.
- Safety pauses (name collision, checksum mismatch, failed verification) survive in automated.

**Non-Goals:**
- Changing which integrations may offer automated, or the catalog schema.
- Changing playbook mode, the Lock, Intro, or Connection details steps.
- Having the agent hold, type, or store credentials — signing in stays the operator's.

## Decisions

### D1: Automated announces instead of gating
- **Choice**: Under automated, the message before each change carries the same disclosure supervised puts above its gate, plus a plain statement that the agent is running it now, and the agent then runs it. No question tool call.
- **Reason**: The operator approved the plan when they chose the mode; re-asking per change is supervised's job.
- **Considered alternatives**: Keep a one-line Approve gate in automated — rejected, it reproduces supervised with extra words.

### D2: Secret sink for secret-producing commands
- **Choice**: When `secretProducing` is true and the mode is automated, run the command with its output redirected to a file outside the repo and both skill trees. Read back only named non-secret identifiers (Client ID, Tenant ID, the success line) with a targeted match, never the whole file. Disclose the path in chat so the operator vaults from it; delete once they confirm. Never write that path to the Connect log.
- **Reason**: Preserves the no-secret-in-context invariant while letting the agent run the command.
- **Considered alternatives**: Run and then scrub the output — rejected, the secret is already in context by then. Ask the operator to run it — rejected, that is the behavior being removed.

### D3: Refusal beats leakage
- **Choice**: If a secret-producing command cannot be made to withhold the secret from terminal output — an interactive prompt that prints it, say — automated does not run that step; it says so and hands that one step to the operator.
- **Reason**: The invariant outranks the mode.

### D4: Supervised becomes fully operator-executed
- **Choice**: Supervised hands every approved command to the operator and verifies the non-secret result afterward, reversing the current "MUST NOT wait for the operator to type the command".
- **Reason**: Two modes that both execute leave the operator no middle option between reading a playbook and letting the agent act.

### D5: Operator-only narrows
- **Choice**: A step is Operator-only when it has no Typed action. Minting a credential no longer implies it.
- **Reason**: The `operatorOnly` catalog flag and the `secretProducing` flag are different facts; the glossary conflated them.

## Risks / Trade-offs

- [Risk] An agent-run script prints the secret despite redirection (interactive host, stderr) -> Mitigation: D3 refusal, plus reading back only named identifiers rather than whole files.
- [Risk] The Secret sink file lingers on disk with a live secret -> Mitigation: the agent deletes it once the operator confirms vaulting, and the path stays out of the Connect log.
- [Trade-off] Automated loses the per-change stop point -> Accepted: the operator can stop at any time, and collisions, checksum mismatches, and failed verifications still pause the run.
- [Trade-off] Supervised gets slower for safe actions the agent could have run -> Accepted: that is what the operator asked for by choosing it.

## Migration Plan

N/A — This change does not involve deployment changes. It is skill text plus specs; the three tests in `tests/test_ingest_docs.py` that pin the old wording move with it, and both skill trees stay byte-identical.

## Open Questions

None.

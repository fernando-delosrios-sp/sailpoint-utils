# Prep

Work the locked Integration path's `prepSteps` in order after Lock, from the locked `catalogPath` Row catalog. Before any optional-capability step, obtain just-in-time operator consent (including automated mode). One change at a time.

## Optional capabilities

Name optional capabilities during Intro; do not Lock them. When Prep reaches an optional capability the locked path supports, gate whether to enable it before that capability's instructions or Typed actions. Bundled scripts that grant optional permissions must disclose what they include; tell the operator which optional capabilities to select in the vendor UI when the script cannot enforce selective grants.

## Disclose in the prose

Every change is disclosed before it happens, in both modes: the step `title`, the `target`, the exact command or script path that will run, the `preview` (run the vendor preview first when the catalog names one and show its output; say plainly when the platform has none), `expectedChange`, `verification`, and `rollbackOrImpact`. Name who runs it — the agent under `automated`, the operator under `supervised`. This disclosure belongs in the message itself; under `supervised` the one-rendering rule governs the gate's options, not this prose.

## Supervised: gate, then the operator runs it

The prompt is one short line naming the step, because the prose above already explained everything: *"Approve `<step title>`?"*

| Option | Meaning |
|---|---|
| `approve` | Proceed with this change |
| `adjust` | Something should change first |
| `stop` | End Prep, leaving the target as it stands |

Keep the labels to a few words each. The disclosure never repeats inside an option.

After Approve, hand the operator the exact command to run in their own terminal and wait. The agent executes no mutation in this mode. The operator reports back; the agent then verifies the non-secret result.

## Automated: announce, then the agent runs it

The agent never asks the operator to run a command in this mode. Approval was the mode choice, so there is no per-change gate: say plainly what is about to run — the disclosure above plus a sentence that the agent is running it now — and then run it, verify it, and move to the next step. Announce before, never after.

This covers scripts that print a secret; see [Secrets the agent's command produces](#secrets-the-agents-command-produces) for keeping that output out of chat and the Connect log. Signing in ([tools.md](tools.md) `authOnce`) stays with the operator, because only they hold the credentials. Cataloged Typed actions have no per-change gate. An Uncataloged Prep step takes one consent gate on the derived command, then the agent runs it.

The run pauses and gates on trouble — a name collision, a checksum mismatch, a failed `verification`, optional-capability consent, or Uncataloged derived-command consent — as the sections above describe.

## Adjust opens its own gate

Supervised only. `adjust` is one option, never a family of them. When the operator picks it, the next message gates what to change, carrying only what applies to this change: the Operator inputs this action binds (named individually), the modes still available in [modes.md](modes.md), or the tool. Apply the choice, re-disclose the change as it now stands, and return to the Approve gate.

## Name collision

Both modes: `automated` interrupts itself here rather than overwriting. Inspect a name-bound target before create. Disclose what already exists — its identifier and shape — then gate reuse, another name, or stop. Keep every other decision out of this gate. A name the destination does not hold is no collision: proceed without asking.

If the preview, inspection, or attempted action reports that it would replace or collide with an existing entity, stop before overwrite. Disclose the existing entity, propose a fix such as a different name or equivalent configuration, then gate that fix alone with Approve / Adjust / Stop. The skill MUST NOT overwrite the existing entity before the fix is approved.

After Approve, bind the fix, re-disclose the exact command, and run the action again. For a pinned script with a hardcoded target, use the Temporary script copy below. Adjust re-asks only the affected input or fix; Stop leaves the destination unchanged.

## Pinned script

When the Typed action carries `script` and `script.checksum` is `sha256:` plus 64 hex digits, checksum the Skill-held file before the change is announced or gated. Any other checksum string means the file is not pinned: stop.

1. Resolve `script.skillPath` under this skill folder (skill-root-relative under the row folder, for example `integrations/microsoft-ecosystem/Entro-Azure-Onboarding.ps1`). Do not resolve Skill-held files under a retired vendor directory. Do not download `originUrl` or any GitBook URL. For a Local onboarding fork, compare only to `script.checksum` — never to `originChecksum`. Never ask the Connect operator remote versus local.
2. SHA-256 the local file. It must equal `script.checksum` (`sha256:` + 64 hex). Mismatch → stop. Do not execute the mutation. Do not create a Temporary script copy.
3. Disclose path, byte size, checksum, and the exact command — not the full file. Under `supervised` that disclosure is what the operator approves; under `automated` it is the announcement that precedes the run.

When the action needs a different hardcoded target or must skip an interactive menu, checksum the original first, then create a **Temporary script copy** in the Connect run folder. Give it a unique name beginning with `tmp-`. Change only the disclosed target names or menu binding. Never edit `script.skillPath`; disclose the temporary path and exact command, run it under the rules above, and discard it after the step. If the menu cannot be bound safely, stop the step and have the operator run the original pinned file.

A vendor script that crashes on a cmdlet object shape the installed module no longer has is a **pin refresh**, not a Temporary copy: patch both skill trees, update `script.checksum` (and `version`) in the catalog, then Connect against that pin. A **Local onboarding fork** is the durable Skill-held copy (`localFork`, `originChecksum`); Connect still checksums only `script.checksum` and never fetches origin. Temporary copy is this run's names and menus only.

Under `automated` the agent runs the pinned script itself, including one that prints a Client Secret. Under `supervised` the operator runs it.

## Secrets the agent's command produces

A secret an agent-run command prints would otherwise land in agent context, chat, and the log. So under `automated`, when the Typed action is secret-producing, send the command's output to a Secret sink in the Connect run folder instead of to the terminal. Give the file a unique name beginning with `sink-`. Read back only the non-secret identifiers, by name (Client ID, Tenant ID, the success line), never the whole file. Tell the operator the file path so they vault the secret, and delete the file once they say it is vaulted. The secret is never printed, quoted, echoed, or written to the Connect log; the Secret sink path is never written to the Connect log; record Client ID and Tenant ID only.

If the command cannot be made to withhold the secret from its terminal output, do not run it: say so and hand that one step to the operator.

## Operator-only and Uncataloged steps

**Operator-only.** When a Prep step carries `operatorOnly`, disclose `reason` and the evidence to collect. The operator executes it and reports evidence back. Record the operator as the execution actor. Do not derive a command for that step.

**Uncataloged.** When a Prep step carries `uncataloged`, look the operation up in vendor documentation and form a Runtime Doc-derived action. Disclose the exact command together with the documentation source it came from.

- `automated`: take one consent gate carrying that command and source. On consent, run and verify it as the execution actor. Record the agent as the execution actor.
- `supervised`: disclose the derived command and source; the operator runs it. Do not run the mutation.
- `instructions`: name the step as uncataloged in the write-up. Do not present it as a vendor constraint.

When the derived command mints a credential, follow [Secrets the agent's command produces](#secrets-the-agents-command-produces).

Record these fallbacks in the Connect log for that run. Leave the catalog classification unchanged.

- The operator declines the gate: the operator executes the step; log the decline.
- Vendor documentation yields no command: the operator executes the step; log the absent documentation as the reason. Do not compose a command from any other source.

## Execute and record

Under `automated` the agent runs every announced cataloged Typed action, secret-producing ones included, and each consented Uncataloged derived command, and verifies each. Under `supervised` the operator runs each approved action and the agent verifies the non-secret result. Record the execution actor, non-secret `evidence`, optional-capability consent, Uncataloged consent or decline, and any collision retry in the Connect log. A failed `verification` stops the plan.

**Done when:** every selected Prep step is approved and evidenced, or the run stopped at a gate with the remaining steps named in the Connect log.

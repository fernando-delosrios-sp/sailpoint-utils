---
name: entro-connect
description: >
  Walk a Connect run for a SailPoint Entro Integration — open with what the
  Integration needs plus the Operation mode gate, Lock a Select Provider tile and
  Integration path, brief it, write a Connect log. Use when the operator asks to
  connect, onboard, or prepare an Entro integration (AWS, Okta, GitHub,
  Microsoft ecosystem, Slack, and other catalog tiles). Read only this folder's
  Skill catalog index (integrations.json). Never open documentation/.
---

# entro-connect

Perform one **Connect run** at a time unless the operator asked for a playbook-only batch.

**Sources of truth:** the Skill catalog index `integrations.json` in this folder until Lock, then that Lock's `catalogPath` Row catalog, plus the disclosed files named below. A secret never reaches chat or the Connect log: under supervised the operator runs those steps in their own CLI, and under automated the agent runs them with the output routed away from the terminal for the operator to vault. Report only limits the catalog states: where it is silent, the operator's choice stands. Execute cataloged Typed actions; for an Uncataloged Prep step, derive the mutation from vendor documentation after one consent gate. Do not invent mutations.

**Every question is a call** — forks, confirmations, and each value the operator holds alike. When more than one answer can be true at once, one multi-select call (`allow_multiple`) with one option per item — the combinations are what the ticks are for.

**Options are candidates only.** The host already gives the operator a way to type an answer, so the options list the real values and stop there.

**Speak plainly.** The capitalised names below are this skill's own bookkeeping. In chat and in the Connect log, name the thing itself:

| The skill's name | What the operator hears |
|---|---|
| Lock, locked row | the Integration tile and path — "Amazon Web Services, using Terraform" |
| Integration path | the visible form choice — "Scoped API Token - Jira" |
| Optional capability | an extra surface or feature — "Vault management" |
| Typed action | the command, or the change it makes |
| Operator input | the value, named — "the app display name" |
| Prep step | the setup step |
| Platform identity | who you are signed in as |
| Skill catalog | what Entro's documentation specifies |

## Steps

1. **Orientation + Operation mode** — One message carries both: prose about the Integration, then the mode gate from [modes.md](modes.md) with all three modes. The one-rendering rule governs the gate's options, so this prose belongs beside the call, and the message does not end between them.

   Match the operator's words to a catalog tile from the Skill catalog index only — a candidate, confirmed later at the Lock. Do not open a Row catalog, `tool-install.json`, or Skill-held files yet. The prose says, in a few sentences and about **this** Integration:
   - what it is, from the index `summary`;
   - what Entro needs to connect to it — the Connector deployment from [connector-deployment.md](connector-deployment.md), the identity or credential the Prep steps will produce, and the admin access the operator must already hold;
   - that nothing is configured yet, and that no secret will appear in chat or the Connect log — it ends in the operator's vault.

   Prose only: optional capabilities, tool table, field table, Prep outline, and C4 are the Intro's job, after the Lock. When the operator named no tile, gate the tile first, then open with this Orientation. Done when the Integration-specific prose and the mode gate are in one message.

2. **Lock** — Follow [lock-target.md](lock-target.md). Done when tile and Integration path (when applicable) are confirmed. Stop before Lock when `captureRequired` is true.

3. **Create Connect log** — Follow [session-log.md](session-log.md) to resolve the **Connect run folder** and its Skill catalog collision fallback. Create `entro-<tile-slug>[-<path-slug>].md` there now (append if it exists). Done when the file exists with the tile and the chosen mode.

4. **Intro** — Follow [intro.md](intro.md) and [connector-deployment.md](connector-deployment.md). Deliver the brief twice: in chat first, then the same brief into the Connect log. Name the inputs the run will need; collecting them waits for Operator inputs, after authentication. State that no configuration has been performed yet. Done when the operator has read intro.md's checklist in chat **and** the same checklist is in the file. Do not deploy Docker or Helm.

5. **Tools** — For **supervised** and **automated** only, follow [tools.md](tools.md). Capability probe before install. Auth-check first; after a failed auth-check, run cataloged Configure once before `authOnce`; record Platform identity; confirm environment. Playbook skips this step.

6. **Operator inputs** — Follow [operator-inputs.md](operator-inputs.md). One question-tool call per input. The authenticated session answers what it can, so suggestions come from the recorded Platform identity before the catalog `default`. Done when every cataloged input on the locked path has a value or a stated blank in the Connect log, each with its origin.

7. **Configuration plan** — Persist the ordered Typed actions on the locked Integration path, tools, targets, exact commands, expected changes, evidence checks, execution actor, and rollback or impact notes. Note optional-capability branches that require just-in-time consent during Prep. Under automated the agent runs every cataloged Typed action itself, secret-producing ones included, and runs an Uncataloged Prep step after one consent gate on the derived command; under supervised the operator runs each approved command in their own terminal. Signing in stays operator-executed in both. Done when the plan is in the Connect log and no mutation has run.

8. **Prep** — Follow [prep.md](prep.md). Per change: disclose the exact command and actor. Obtain just-in-time consent before optional-capability steps. Under automated, say the agent is running a cataloged Typed action now and run it — no per-change gate, no command handed to the operator — and take one consent gate before an Uncataloged derived command. Under supervised, gate Approve / Adjust / Stop and the operator runs the approved command, with Adjust guided by its own follow-up gate. A replace or collision stops before overwrite, proposes and gates a fix, then runs again; pinned scripts use a Temporary script copy when names or menu choices must change. Done when every selected Prep step is approved and evidenced, or the run stopped with the remainder named in the Connect log.

9. **Connection details** — Field map = shared tile `connectionFields` plus the locked Integration path's `connectionFields`, bound to Operator input keys, plus the Worker Group (Connector) the form always carries. For that one, name the Connector kind this Integration requires from [connector-deployment.md](connector-deployment.md) and leave the choice to the operator in the Entro form. Name secret fields; leave values blank. Do not invent Environment unless that row lists it.

**Done when:** a Connect log exists for the Lock with the chosen mode, persisted Intro, inputs with origins, and plan/evidence as the mode produced them; secrets are unnamed-as-values; and the Skill catalog supplied every tile, path, tool, field, input, and action used.

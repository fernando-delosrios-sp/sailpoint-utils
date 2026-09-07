## Scope

In: redefine what supervised and automated mean in entro-connect — automated announces and then runs every Typed action itself, including secret-producing ones, while supervised discloses, gates, and hands the command to the operator. Out: the playbook mode, the Lock and Intro flow, the catalog schema, and anything about which integrations offer automated.

## Language

**Operation mode** (`draft`, canonical term already in the glossary):
Unchanged as a term; the two modes it names change meaning. Supervised is now the disclose-and-gate mode where the operator executes; automated is the mode where the agent executes.

**Announcement** (`draft`):
The message automated sends immediately before it runs a change — the same disclosure supervised puts above its gate, plus a statement that the agent is running it now. It asks for nothing.
_Avoid_: notification, heads-up, approval prompt.

**Secret sink** (`draft`):
The file, outside the repo and both skill trees, that an agent-run secret-producing command writes its output to instead of the terminal, so the secret never enters agent context, chat, or the Connect log. The operator vaults from it; the agent deletes it once they confirm.
_Avoid_: secret file, temp output, vault.

**Operator-only step** (`conflicts-with-canonical`):
The glossary defines it as a Prep step the project does not automate "because the platform exposes it only through its UI or because it mints a credential", noting "Secret values stay with the operator". Minting a credential no longer makes a step operator-only: under automated the agent runs it through a Secret sink. The classification narrows to steps with no Typed action — UI-only, or otherwise unautomatable. `promote` the narrowed definition.

## Decisions

Context: the previous rule kept every secret-producing action operator-executed in both modes, because an agent-run command's output enters agent context. In practice that made automated ask the operator to run the Azure onboarding script by hand — the mode's whole point, unattended execution, was lost at the one step that matters most for Microsoft Ecosystem.

- Q1 — Does automated run secret-producing actions? Yes. The output-in-context problem is real but it is a plumbing problem, not a reason to hand the command back.
- Q2 — How does the secret stay out of context? A Secret sink: route the command's output to a file outside both trees, read back only named non-secret identifiers (Client ID, Tenant ID, the success line), never the whole file, and delete after the operator vaults. When a command cannot be made to withhold the secret from its terminal output, automated refuses that one step and hands it over rather than pulling the secret in.
- Q3 — Does automated still gate each change? No. The mode choice was the approval. It announces, then runs. Approve / Adjust / Stop belongs to supervised only.
- Q4 — What becomes of supervised? It becomes the fully operator-executed mode: agent plans, discloses, gates, operator runs, agent verifies the non-secret result. This reverses the previous "supervised MUST NOT wait for the operator to type the command".
- Q5 — What still can't be delegated? Signing in (`authOnce`), because only the operator holds the credentials, and Prep steps the catalog marks `operatorOnly` with no Typed action.
- Q6 — Does automated ever stop? Yes, on trouble only: name collision, checksum mismatch, failed verification. Safety pauses survive; routine approval does not.

## Open questions

None. The `secretProducing` flag already exists on cataloged Typed actions, so no catalog schema work is needed.

## Scenarios discussed

- Automated reaches the Azure onboarding script: announces, runs it, routes output to a Secret sink, records Client ID and Tenant ID, tells the operator the path, deletes on confirmation.
- Supervised reaches the same script: discloses, gates, the operator runs it in their terminal, the agent verifies identifiers only.
- A secret-producing command that writes only to an interactive terminal: automated declines that step and hands it to the operator.
- Automated hits an existing Entra app with the chosen display name: it stops before overwrite and gates the fix, even though there is no per-change gate.
- Automated hits a checksum mismatch on a pinned script: it stops, runs nothing, creates no Temporary script copy.
- Playbook: unchanged, no mutation in any mode.
- Three tests in `tests/test_ingest_docs.py` assert the old wording (`non-secret-producing` in modes.md, a `## Gate three options` heading in prep.md, the old Client Secret sentence) and must move with the specs.
- Both skill trees (`.agents/skills/entro-connect/` and `skills/entro-connect/`) must stay byte-identical.

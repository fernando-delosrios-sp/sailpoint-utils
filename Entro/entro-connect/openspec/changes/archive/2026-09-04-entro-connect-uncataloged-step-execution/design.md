## Context

`entro-connect` classifies every Prep step as either covered by a Typed action or Operator-only. `integration_catalog.py` derives that split mechanically: a step whose title is absent from the Typed action set is stamped `operatorOnly`, taking the step's authored reason when one exists and `DEFAULT_OPERATOR_ONLY_REASON` when it does not.

```
if step.title not in covered:
    reason = step.operator_only.reason if step.operator_only else DEFAULT_OPERATOR_ONLY_REASON
```

`prep.md` then applies one rule to whatever comes out: disclose the reason, collect evidence, run no mutation in either mode. The result is that a catalog gap and a vendor constraint are indistinguishable at runtime, and automated mode declines work it is equipped to do. The GCP Console-manual private-key step is the observed instance; 31 of 38 `operatorOnly` blocks across 15 tiles share its shape.

Two constraints bound the fix. `SKILL.md` reserves execution to cataloged Typed actions, and the canonical Doc-derived Typed action term forbids inventing commands the vendor does not document. Both survive this change.

## Goals / Non-Goals

**Goals:**

- Make an authored reason necessary for the Operator-only classification, so the label describes the vendor rather than the catalog.
- Give automated Connect a path to execute a step the catalog has not pinned, without inventing commands and without a silent hand-off.
- State the rule once in `prep.md`, as the action the agent takes.
- Keep the gap visible in generated catalogs so it can be closed by authoring Typed actions later.

**Non-Goals:**

- Authoring Typed actions for the 31 affected steps.
- Reclassifying the 7 authored Operator-only reasons.
- Changing supervised or playbook execution, Secret sink handling, or how credentials reach the agent.

## Decisions

### D1: The generator emits a distinct kind rather than defaulting a reason

- **Choice**: A Prep step with no Typed action and no authored `operator_only` is emitted as an uncataloged kind; `DEFAULT_OPERATOR_ONLY_REASON` is retired. `catalog_contracts.py` validation accepts exactly one of: Typed action, authored Operator-only, uncataloged.
- **Reason**: The default reason is the conflation in literal form — its text states that nothing is cataloged while its field name asserts the operator must do it. Separating the kinds lets `prep.md` branch and makes the gap countable.
- **Considered alternatives**: Hard-fail the generator on an uncataloged step, rejected because it breaks 15 tiles at once and forces 31 Typed actions to be authored before anything ships. Keep one kind and branch on reason text, rejected because behavior would depend on string matching.

### D2: Automated Connect derives the mutation from vendor documentation

- **Choice**: On an uncataloged step, the agent looks the operation up in vendor documentation, forms a Runtime Doc-derived action, and discloses the command with its documentation source. When documentation yields no command, the step falls back to operator execution and the Connect log records the absence as the reason.
- **Reason**: Preserves the no-invented-mutations boundary while letting the agent use the authenticated CLI it already probed. The repo already prefers vendor CLIs over custom clients, and `find-docs` supplies the lookup.
- **Considered alternatives**: Let the agent compose a command from its own knowledge, rejected because it invents mutations the vendor may not document. Skip the step entirely, rejected because it leaves the run incomplete with no signal.

### D3: One consent gate, not per-change gating and not silent execution

- **Choice**: The uncataloged branch takes a single consent gate carrying the derived command and its source, then the agent runs and verifies it as the execution actor. Cataloged Typed actions keep running ungated under automated.
- **Reason**: Choosing automated approved the cataloged plan; a command the catalog never pinned is outside what was approved. One gate restores operator control over exactly the novel part without reverting the mode.
- **Considered alternatives**: No gate, rejected because the operator would consent to derived mutations by choosing a mode. Full per-change gating, rejected because it collapses automated into supervised.

### D4: `prep.md` states the rule once, positively

- **Choice**: Replace the duplicated operator-only sentences with one section carrying two branches, each phrased as the action the agent takes. Add the uncataloged branch to the existing trouble list alongside collision, checksum mismatch, and failed verification.
- **Reason**: The rule was stated twice and only as a prohibition, so it carried no positive target and the agent had nothing to do but hand over. Duplication also meant no single source of truth to change.
- **Considered alternatives**: Edit both sites to match, rejected because it preserves the duplication.

### D5: Secret-producing derived actions reuse the Secret sink

- **Choice**: A Runtime Doc-derived action that produces a secret routes output to a file outside both the repo and the skill tree, reports non-secret identifiers only, and is deleted once the operator confirms vaulting — the existing rules, unchanged.
- **Reason**: The GCP private-key step is precisely this case, and the machinery already exists. The canonical glossary already states that minting a credential does not make a step Operator-only.
- **Considered alternatives**: Keep secret-producing steps operator-bound, rejected because it contradicts canonical language and re-creates the hand-off this change removes.

### D6: The uncataloged kind is a sibling of `operatorOnly`, not a replacement discriminator

- **Choice**: Authored vendor-bound steps keep `operatorOnly` with `reason` and `evidence` exactly as today. A step with neither a Typed action nor an authored reason gains `uncataloged` carrying `evidence`. Validation requires exactly one of the three.
- **Reason**: `documentation-ingest` already frames coverage as "bind exactly one of," so a sibling matches the canonical language. It also leaves the 7 authored blocks byte-identical, keeping the regeneration diff confined to the 31 steps whose behavior actually changes.
- **Considered alternatives**: A single `execution` discriminator replacing `operatorOnly`, rejected because `operatorOnly` still needs to carry `reason` and `evidence` for the vendor-bound case, so the discriminator would sit beside the object it was meant to replace while rewriting all 38 blocks and their tests.

### D7: An uncataloged step no longer hides automated mode

- **Choice**: Automated stays hidden only when no Configuration tool can run anything (every tool Fit `none`). A Prep step that is uncataloged, or Operator-only, no longer disqualifies the mode.
- **Reason**: The derived-action branch and the operator fallback both cover those steps, so an incomplete Typed action plan is no longer a reason to withhold the mode.
- **Considered alternatives**: Keep hiding automated whenever any step lacks a Typed action, rejected because 31 steps across 15 tiles would keep automated hidden for exactly the gaps this change teaches it to handle.

## Risks / Trade-offs

[Risk] A derived command misreads vendor documentation and mutates the wrong target. → Mitigation: the consent gate carries the exact command and its documentation source; the operator sees both before it runs, and existing collision inspection still precedes name-bound creates.

[Risk] 31 steps change behavior at once across 15 tiles. → Mitigation: the change is documentation and classification only — no Typed actions are authored, so each tile's derived command is still gated on first use and can be promoted to a pinned Typed action later.

[Risk] Vendor documentation lookups add latency or fail offline. → Mitigation: failure is a defined branch, not an error — the step falls back to operator execution with the absence recorded.

[Trade-off] Automated mode gains a gate it did not have. → Accepted: the alternative is either a silent hand-off or unconsented derived mutations, and the gate fires only on steps the catalog has not pinned.

[Trade-off] The uncataloged kind makes catalog gaps visible in generated output. → Accepted: that visibility is the point; it converts a silent degradation into a countable backlog.

## Migration Plan

No deployment surface. Sequence: extend `catalog_contracts.py` validation to admit three kinds, change `integration_catalog.py` to emit the uncataloged kind and retire the default reason, regenerate `documentation/integrations.json` and all Row catalogs in both skill trees, rewrite the `prep.md` section in both trees, and update `tests/test_ingest_docs.py`. Generator edits and regenerated artifacts commit together.

Rollback is a git revert; no runtime state is migrated. Acceptance: `uv run python -m pytest` exits 0, `openspec validate --all --json` reports valid, both skill trees hold byte-identical catalogs, and no `operatorOnly` block carries a generator-supplied reason.

## Open Questions

- Pre-existing drift, out of scope here: `integration-automation` § Operation mode gates tools and the execution actor conditions the automated offer on the locked Integration path, but `modes.md` puts the mode gate before Lock, where no locked path exists yet. This change edits that requirement's execution-actor and offer-condition sentences without resolving where the gate belongs. Worth its own change.
- Whether the GCP organization audit-log step should later gain a read-modify-write Typed action with backoff rather than staying Operator-only. Deferred.

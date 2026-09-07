## Why

Automated Connect hands steps back to the operator that it is equipped to run. A GCP Console-manual run stopped at "Create the private key credential" with `gcloud` authenticated as Organization Administrator and the Secret sink rules that step needed already in `prep.md`. It stopped because no Typed action was authored, and the generator stamps `operatorOnly` on every Prep step lacking one — using a default reason whose own text admits the gap. Nothing distinguishes "the vendor exposes this only through its UI" from "nobody wrote the command yet." This is the dominant case: 31 of 38 `operatorOnly` blocks across 15 tiles carry the generator default, so automated mode is degraded across most of the catalog.

## What Changes

**Prep step classification**
- From: any Prep step without a Typed action becomes an Operator-only step, defaulted by the generator.
- To: Operator-only step requires an authored reason; a step without one becomes an Uncataloged Prep step, emitted as a distinct kind.
- Reason: absence of a Typed action describes the catalog, not the vendor.
- Impact: non-breaking for catalog consumers; 31 steps across 15 tiles change classification.

**Automated execution of an Uncataloged Prep step**
- From: the agent discloses the reason and the operator executes.
- To: the agent derives a Runtime Doc-derived action from vendor documentation, discloses it with its source, takes one consent gate, then runs and verifies it as the execution actor.
- Reason: automated mode should reach for its authenticated tools and fall back to the operator when blocked, not by default.
- Impact: behavioral change to automated runs only; supervised and playbook execution unchanged.

**prep.md rule statement**
- From: the rule appears twice, phrased as a prohibition.
- To: one branch per kind, stated once, phrased as the action the agent takes.
- Reason: duplication and negation left the branch unreachable.
- Impact: documentation-only.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `integration-prep`: require an authored reason for an Operator-only step and classify a step without one as an Uncataloged Prep step.
- `integration-automation`: require automated Connect to execute an Uncataloged Prep step as a Runtime Doc-derived action after one consent gate, falling back to the operator when no command is documented.
- `documentation-ingest`: require the generator to emit the uncataloged kind instead of defaulting an Operator-only reason.
- `ubiquitous-language`: redefine Operator-only step and add Uncataloged Prep step and Runtime Doc-derived action.

## Non-goals

- Authoring per-integration Typed actions for the 31 affected steps.
- Giving the GCP organization audit-log step a Typed action; it stays Operator-only.
- Letting the agent invent commands the vendor does not document.
- Changing Secret sink handling, supervised execution, or playbook output.
- Any change to how the agent holds secrets; credentials stay with the operator's CLI session.

## Impact

`integration_catalog.py`, `catalog_contracts.py`, the regenerated `documentation/integrations.json` and 15 Row catalogs, `prep.md` in both `entro-connect` skill trees, `tests/test_ingest_docs.py`, and `CHANGELOG.md`. The catalog shape gains one field; verification needs no vendor credentials or network access.

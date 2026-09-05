## 1. Contract tests

- [x] 1.1 Add named tests in `tests/test_ingest_docs.py` proving a Prep step with no Typed action and no authored `reason` is emitted with an `uncataloged` classification carrying `evidence` and no `operatorOnly` block.
- [x] 1.2 Add a named test proving a Prep step with an authored `reason` still emits `operatorOnly` with that reason and no `uncataloged` classification.
- [x] 1.3 Add a named test proving no generator-supplied default reason appears anywhere in the emitted catalogs.
- [x] 1.4 Add named tests proving validation fails when a Prep step binds more than one coverage kind, and when it binds none.
- [x] 1.5 Add a named test proving a Fit `preferred` path is complete when every Prep step binds a Typed action, an Operator-only classification, or an Uncataloged classification.
- [x] 1.6 Add a named test proving the 7 authored Operator-only blocks are unchanged by regeneration.

## 2. Catalog contracts and generator

- [x] 2.1 Extend `catalog_contracts.py` so a Prep step binds exactly one of Typed action, `operatorOnly` with authored `reason` and `evidence`, or `uncataloged` with `evidence`.
- [x] 2.2 Remove `DEFAULT_OPERATOR_ONLY_REASON` from `integration_catalog.py` and emit the `uncataloged` classification for a step whose author supplied no reason.
- [x] 2.3 Update the Fit `preferred` completeness check to accept the `uncataloged` kind as coverage.
- [x] 2.4 Regenerate `documentation/integrations.json` and every Row catalog in both `entro-connect` skill trees; commit generator edits and regenerated outputs together.
- [x] 2.5 Confirm the regenerated diff is confined to the 31 default-stamped steps and that both skill trees hold byte-identical catalogs.

## 3. Skill runtime rules

- [x] 3.1 Replace the two duplicated operator-only statements in `prep.md` with one section carrying an Operator-only branch and an Uncataloged branch, each phrased as the action the agent takes.
- [x] 3.2 Write the Uncataloged branch: derive the mutation from vendor documentation, disclose the command with its documentation source, take one consent gate, then run and verify it as the execution actor.
- [x] 3.3 Write the fallbacks: operator declines the gate, and vendor documentation yields no command — each recorded in the Connect log for that run without changing the catalog classification.
- [x] 3.4 Point the Uncataloged branch at the existing Secret sink rules for a derived command that mints a credential.
- [x] 3.5 State the supervised and instructions behavior for an Uncataloged Prep step: supervised discloses the derived command and the operator runs it; instructions names the step as uncataloged.
- [x] 3.6 Add the Uncataloged consent gate to `prep.md`'s list of points where automated pauses, beside collision, checksum mismatch, and failed verification.
- [x] 3.7 Update the automated-mode sentence that currently names signing in and operator-only steps as the two things that stay with the operator.
- [x] 3.8 Apply every `prep.md` edit identically to both `skills/entro-connect/` and `.agents/skills/entro-connect/`.

## 4. Operation mode offer

- [x] 4.1 Update the mode-offer rule so an Uncataloged or Operator-only Prep step does not by itself hide automated.
- [x] 4.2 Confirm automated stays hidden when every Configuration tool on the locked path is Fit `none`.

## 5. Verification

- [x] 5.1 Confirm canonical test command for this environment: `uv run python -m pytest`
- [x] 5.2 Confirm every delta spec scenario across `integration-prep`, `integration-automation`, `documentation-ingest`, and `ubiquitous-language` maps to a named automated test.
- [x] 5.3 Run `uv run python -m pytest` and confirm the suite passes without vendor credentials or network access.
- [x] 5.4 Run `openspec validate --all --json` and resolve every validation error.

## 6. Documentation

- [x] 6.1 Review the regenerated `documentation/integrations.json` entries for the 31 reclassified steps, confirming operator-visible text no longer claims a vendor constraint.
- [x] 6.2 Review both `prep.md` copies for a single statement of the rule with no duplicated or negated phrasing.
- [x] 6.3 Record the uncataloged classification in the ubiquitous-language delta terms so later changes name it consistently.

## 7. Changelog

- [x] 7.1 Invoke `changelog-generator` during apply to add the uncataloged-step execution entry to `CHANGELOG.md`.
- [x] 7.2 Confirm the entry covers the classification split, automated execution behind one consent gate, and the retired default reason.

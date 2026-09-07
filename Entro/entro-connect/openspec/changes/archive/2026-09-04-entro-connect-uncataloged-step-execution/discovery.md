## Scope

In: split the single `operatorOnly` classification into a vendor-bound Operator-only step and an Uncataloged Prep step, stop the generator from silently defaulting the second into the first, and let automated Connect execute an Uncataloged Prep step itself after one consent gate. Out: authoring per-integration Typed actions for the 31 affected steps, changing supervised or playbook execution, and touching the 7 authored Operator-only reasons.

## Language

**Uncataloged Prep step** (`draft`):
A Prep step carrying no Typed action and no authored reason for withholding one — the catalog has not written its mutation yet. It is a gap in the Skill catalog, not a statement about the vendor.
_Avoid_: manual step, operator step, unautomated step

**Operator-only step** (`conflicts-with-canonical`):
A Prep step the vendor exposes only through its UI, or whose documented command route is merge-sensitive enough that Connect declines to run it, carrying an authored reason and the evidence the operator reports.
_Avoid_: manual step, UI step

**Runtime Doc-derived action** (`draft`):
A mutation the agent derives from vendor documentation during a Connect run to cover an Uncataloged Prep step, disclosed with its documentation source and consented once before it runs.
_Avoid_: ad-hoc command, improvised command, invented mutation

Canonical conflict: `openspec/specs/ubiquitous-language/spec.md` § Term: Operator-only step states "Absence of a Typed action is this classification once reason is present, not an unwritten gap," and § Requirement: Skill-held onboarding terms carries the matching scenario "Operator-only step MUST remain reserved for steps with no Typed action." Both make absence of a Typed action sufficient for the classification. This change makes an authored reason necessary as well, so both need a ubiquitous-language delta during the specs phase.

## Decisions

**Context.** A GCP Console-manual Connect run in automated mode reached step 6, "Create the private key credential," and handed it to the operator. The tile's `gcloud` was installed, authenticated, and holding Organization Administrator. `prep.md` already carries the Secret sink machinery that step needed. The hand-off happened because no Typed action was authored, and `integration_catalog.py` stamps `operatorOnly` with `DEFAULT_OPERATOR_ONLY_REASON` on every prep step lacking one — a reason whose own text reads "No Skill-held artifact or Doc-derived Typed action is cataloged."

**Q1 — Is this a GCP catalog bug or a skill-wide one?** Skill-wide. 31 of 38 `operatorOnly` blocks across 15 tiles carry the generator default; only 7 are authored. The silent hand-off is the dominant case, not the exception.

**Q2 — Should the agent improvise commands for uncataloged steps?** No. `SKILL.md` reserves execution to cataloged Typed actions, and the canonical Doc-derived Typed action term already forbids inventing commands the vendor does not document. A Runtime Doc-derived action keeps that boundary: the agent derives from vendor documentation, cites the source, and never invents.

**Q3 — Does the uncataloged branch run unattended like the rest of automated mode?** No. The operator chose one consent gate on a command the catalog did not pin, because the mode choice approved cataloged mutations rather than derived ones. Vendor-bound Operator-only steps stay with the operator unchanged.

**Q4 — Should the generator hard-fail on an uncataloged step?** No. A hard fail breaks 15 tiles at once. The generator emits a distinct kind for the uncataloged case so `prep.md` can branch, and the gap becomes visible rather than silent.

**Q5 — Where do the 7 authored reasons land?** Unchanged. They remain Operator-only steps and continue to be operator-executed, including the GCP organization audit-log step whose documented route replaces the whole organization IAM policy.

**Direction.** Generator emits two distinct kinds; `prep.md` grows one branch per kind and states the rule once; the ubiquitous-language delta separates the two terms; the 31 default-stamped steps become Uncataloged Prep steps and gain agent execution behind a consent gate.

## Open questions

- Field name and shape for the generator's uncataloged marker — deferred to design; impact is confined to `integration_catalog.py`, `catalog_contracts.py`, the 31 regenerated catalog blocks, and the ingest tests.
- Whether the GCP organization audit-log step should later gain a read-modify-write Typed action with backoff rather than staying Operator-only — deferred to a separate change; out of scope here.

## Scenarios discussed

- Automated run reaches an Uncataloged Prep step with the picked tool authenticated: agent derives the command from vendor documentation, discloses it with its source, takes one consent gate, runs and verifies it, records itself as the execution actor.
- Operator declines at that consent gate: the step becomes operator-executed for that run, and the Connect log records the decline rather than a catalog property.
- Automated run reaches an Uncataloged Prep step that produces a secret: the existing Secret sink rules apply unchanged — output routed outside the repo, identifiers only in the Connect log.
- Automated run reaches an Uncataloged Prep step and vendor documentation yields no command: the step falls back to operator execution with the absence recorded as the reason.
- Supervised run reaches an Uncataloged Prep step: unchanged from today — the operator runs the command, now with a derived command disclosed rather than nothing.
- Playbook run reaches an Uncataloged Prep step: the write-up names it as uncataloged rather than presenting it as vendor-bound.
- A step carries both an authored Operator-only reason and a Typed action: existing validation already rejects this and must keep rejecting it.

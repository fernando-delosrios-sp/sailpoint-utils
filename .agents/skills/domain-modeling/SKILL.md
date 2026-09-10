---
name: domain-modeling
description: Build and sharpen a project's domain model.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline: challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* the glossary for vocabulary is not this skill: that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## Mode detection

OpenSpec mode: see [OPENSPEC-MODE.md](./OPENSPEC-MODE.md) §Detection. If OpenSpec mode, follow **OpenSpec mode** below; otherwise **Legacy mode**.

When OpenSpec is absent and the user needs to initialize it, suggest the `openspec-init` skill.

## During the session

#### Challenge against the glossary

When the user uses a term that conflicts with the project's glossary, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"

#### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account': do you mean the Customer or the User? Those are different things."

#### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

#### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"

## OpenSpec mode

See [OPENSPEC-MODE.md](./OPENSPEC-MODE.md) for file structure, flat capability naming, ubiquitous language, spec/ADR routing, and cross-linking.

Do **not** use `CONTEXT.md` or `CONTEXT-MAP.md` in OpenSpec mode.

**Specs and ADRs coexist:** capability specs encode *what*; ADRs in `docs/adr/` encode *why*. ferspec and similar schemas delegate ADR creation here.

### Where to write

#### Update ubiquitous language inline

When a term is resolved and usage is **consistent**, update `openspec/specs/ubiquitous-language/spec.md` right there. Don't batch these up: capture them as they happen. Use the term entry format in [OPENSPEC-MODE.md](./OPENSPEC-MODE.md).

When usage is **mixed or conflicting**, surface the conflict and **propose alignment** — do not silently pick one meaning.

The ubiquitous-language spec is a glossary only. No implementation details, no scratch-pad content.

#### Offer specs and ADRs sparingly

Only offer to record an architectural decision when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip it.

- **Behavioral contract** → ADDED/MODIFIED requirements in the most relevant capability spec (canonical if already implemented; delta under `openspec/changes/<name>/specs/<capability>/spec.md` if change is required — suggest `/opsx:propose`)
- **Non-obvious rationale** → ADR in `docs/adr/` using [ADR-FORMAT.md](./ADR-FORMAT.md)
- **Both apply** → write both; cross-link per [OPENSPEC-MODE.md](./OPENSPEC-MODE.md)

When working inside a ferspec change, `discovery.md` and `design.md` Decisions are working docs — distill durable decisions into ADRs as they crystallise or during apply Documentation tasks.

For complex ADRs (MADR, supersession chains), suggest the `architecture-decision-records` skill.

## Legacy mode

File structure and CONTEXT format: [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md). ADR format: [ADR-FORMAT.md](./ADR-FORMAT.md).

### Where to write

#### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up: capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` should be totally devoid of implementation details. Do not treat `CONTEXT.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

#### Offer ADRs sparingly

Only offer to create an ADR when all three criteria in [ADR-FORMAT.md](./ADR-FORMAT.md) pass. Use the format there.

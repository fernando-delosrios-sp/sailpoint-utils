---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when pinning down domain terminology or ubiquitous language, recording architectural decisions (ADRs plus capability specs when OpenSpec is present), or when another skill needs to maintain the domain model.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline: challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* the glossary for vocabulary is not this skill: that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

When OpenSpec is absent and the user needs to initialize it, suggest the `openspec-init` skill. For a heavier ADR process (MADR, supersession), suggest `architecture-decision-records`.

## Mode detection

Before any file-structure guidance, check whether OpenSpec is present in the target repo:

- `openspec/config.yaml` exists, or
- `openspec/specs/` exists

If either is true, follow **OpenSpec mode**. Otherwise follow **Legacy mode**.

## OpenSpec mode

Do **not** use `CONTEXT.md` or `CONTEXT-MAP.md`.

- Glossary: `openspec/specs/ubiquitous-language/spec.md` (replaces `CONTEXT.md`)
- Capability specs: `openspec/specs/<category-capability>/spec.md` — category encoded as a kebab-case slug prefix (e.g. `module-ordering`, `service-auth`), not nested folders like `specs/modules/<name>/`
- **ADRs remain in use** at `docs/adr/` — specs encode *what*, ADRs encode *why*. ferspec delegates ADR creation here; there is no separate `adr` artifact in the change workflow.

See [OPENSPEC-MODE.md](./OPENSPEC-MODE.md) for detection, naming, ubiquitous language, spec/ADR routing, and cross-linking.

Create files lazily: only when you have something to write.

## Legacy mode

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily: only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

Formats: [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md), [ADR-FORMAT.md](./ADR-FORMAT.md).

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"

- **OpenSpec:** read `openspec/specs/ubiquitous-language/spec.md`. When usage is consistent, update the spec inline. When mixed or conflicting, surface the conflict and propose alignment — do not silently canonicalize.
- **Legacy:** read `CONTEXT.md`.

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account': do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"

### Update the glossary inline

When a term is resolved, write it down right there. Don't batch these up: capture them as they happen.

- **OpenSpec:** update `openspec/specs/ubiquitous-language/spec.md` per [OPENSPEC-MODE.md](./OPENSPEC-MODE.md). The spec should be totally devoid of implementation details. It is a glossary and nothing else.
- **Legacy:** update `CONTEXT.md` per [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md). Same glossary-only rule.

### Architectural decisions

Only offer to record a decision when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip it.

- **OpenSpec:** route the behavioral contract to capability specs (canonical or change delta). Offer an ADR in `docs/adr/` when rationale is non-obvious. When both apply, write both with cross-links per [OPENSPEC-MODE.md](./OPENSPEC-MODE.md).
- **Legacy:** offer an ADR per [ADR-FORMAT.md](./ADR-FORMAT.md).

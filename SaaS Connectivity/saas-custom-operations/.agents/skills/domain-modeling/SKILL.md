---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when pinning down domain terminology or ubiquitous language, recording architectural decisions (or capability specs when OpenSpec is present), or when another skill needs to maintain the domain model.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* the glossary for vocabulary is not this skill — that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## Mode detection

Before any file-structure guidance, check whether OpenSpec is present in the target repo:

- `openspec/config.yaml` exists, or
- `openspec/specs/` exists with at least one capability spec

If either is true, follow **OpenSpec mode** below. Otherwise follow **Legacy mode**.

When OpenSpec is absent and the user needs to initialize it, suggest the `openspec-init` skill.

## OpenSpec mode

See [OPENSPEC-MODE.md](./OPENSPEC-MODE.md) for detection, flat capability naming, ubiquitous language, decision routing, and spec format.

Do **not** use `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/` in OpenSpec mode.

### File structure

```
openspec/
├── config.yaml
├── specs/
│   ├── ubiquitous-language/spec.md       ← replaces CONTEXT.md
│   ├── module-ordering/spec.md           ← flat; category in slug
│   ├── service-auth/spec.md
│   └── use-case-cancel-order/spec.md
└── changes/<change-name>/specs/          ← pending decision/spec deltas
```

Category is a kebab-case prefix on the capability slug (`<category>-<name>`). No nested folders like `specs/modules/<name>/spec.md`.

Create capability folders lazily — only when you have something to write.

### During the session

#### Challenge against the glossary

When the user uses a term that conflicts with `openspec/specs/ubiquitous-language/spec.md`, call it out immediately. "Your ubiquitous-language spec defines 'cancellation' as X, but you seem to mean Y — which is it?"

#### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

#### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

#### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

#### Update ubiquitous language inline

When a term is resolved and usage is **consistent**, update `openspec/specs/ubiquitous-language/spec.md` right there. Don't batch these up — capture them as they happen. Use the term entry format in [OPENSPEC-MODE.md](./OPENSPEC-MODE.md).

When usage is **mixed or conflicting**, surface the conflict and **propose alignment** — do not silently pick one meaning.

The ubiquitous-language spec is a glossary only. No implementation details, no scratch-pad content.

#### Offer spec updates sparingly

Only offer to record an architectural decision when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip it.

- **Already implemented** → add ADDED/MODIFIED requirements to the most relevant existing capability spec
- **Change required** → route through OpenSpec change workflow (`openspec/changes/<name>/specs/<capability>/spec.md`; suggest `/opsx:propose`)

See [OPENSPEC-MODE.md](./OPENSPEC-MODE.md) for what qualifies and how to name capability specs.

## Legacy mode

### File structure

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

Create files lazily — only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

### During the session

#### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

#### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

#### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

#### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

#### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` should be totally devoid of implementation details. Do not treat `CONTEXT.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

#### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

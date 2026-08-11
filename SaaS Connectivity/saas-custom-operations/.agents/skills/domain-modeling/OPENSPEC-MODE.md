# OpenSpec Mode

Use this reference when `openspec/config.yaml` or `openspec/specs/` exists in the target repo. Do not use `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/` in OpenSpec mode.

## Detection

OpenSpec mode activates when either exists:

- `openspec/config.yaml`
- `openspec/specs/` (directory with at least one capability spec)

Otherwise use legacy mode ([CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md), [ADR-FORMAT.md](./ADR-FORMAT.md)).

## File structure

```
openspec/
├── config.yaml
├── specs/
│   ├── ubiquitous-language/spec.md       ← replaces CONTEXT.md
│   ├── module-ordering/spec.md           ← flat; category in slug
│   ├── service-auth/spec.md
│   ├── component-checkout/spec.md
│   └── use-case-cancel-order/spec.md
└── changes/<change-name>/specs/          ← pending decision/spec deltas
```

**Naming rule:** OpenSpec does not support nested category folders. Path is always `openspec/specs/<capability>/spec.md`. Encode category as a kebab-case prefix on the capability slug (`<category>-<name>`). Do not create paths like `specs/modules/<name>/spec.md`.

Create capability folders lazily — only when you have something to write.

## Spec naming

1. **Infer from existing slugs** — scan `openspec/specs/*` for prefix patterns already in use (`module-`, `service-`, `component-`, `use-case-`, etc.).
2. **Infer from repo layout** — map structural groupings (`services/`, `packages/`, `apps/`, `src/modules/`) to slug prefixes.
3. **Sensible defaults** when nothing exists yet: `module-`, `service-`, `component-`, `use-case-`.

One `spec.md` per capability folder. Pick the slug that best matches where the decision or behavior lives.

## Ubiquitous language

**Target:** `openspec/specs/ubiquitous-language/spec.md`

This spec replaces `CONTEXT.md`. It is a glossary — no implementation details, no scratch-pad content.

### Term entry format

Add terms under the `## Term entries` section:

```md
### Term: <Preferred Name>
**Context**: <bounded context or "global">
**Definition**: <one or two sentences — what it IS, not what it does>
**Aliases**: <comma-separated alternatives, or "none">
**Notes**: <optional examples, anti-patterns, related terms>
```

Rules:

- **Be opinionated.** Pick one canonical term; list rejected alternatives under **Aliases**.
- **Only domain-specific terms.** General programming concepts do not belong.
- **Disambiguate homonyms.** Same word, different meanings → separate entries with bounded context noted.

### Language alignment

| Situation | Action |
|-----------|--------|
| Usage is **consistent** across specs, code, and conversation | Update the ubiquitous-language spec inline as terms resolve |
| Usage is **mixed or conflicting** | Surface the conflict and **propose alignment** — ask which meaning wins; do not silently pick one |

When challenging the user, reference the glossary spec: "Your ubiquitous-language spec defines 'cancellation' as X, but you seem to mean Y — which is it?"

## Architectural decisions

Apply the same three criteria as legacy ADRs — all must be true:

1. **Hard to reverse** — meaningful cost to change later
2. **Surprising without context** — a future reader will wonder why
3. **Real trade-off** — genuine alternatives existed and you picked one for specific reasons

If any criterion is missing, skip recording.

### Where decisions land

| Situation | Action |
|-----------|--------|
| Decision is **already implemented** | Add ADDED/MODIFIED requirements to the most relevant existing capability spec |
| **Change is required** to implement | Route through OpenSpec change workflow: `openspec/changes/<name>/specs/<capability>/spec.md` (suggest `/opsx:propose`) |

Prefer enhancing an existing spec over creating a new one. Create a new capability spec only when no existing slug is a reasonable home.

### What qualifies

Same categories as legacy ADRs:

- Architectural shape (monorepo, event sourcing, read/write split)
- Integration patterns between bounded contexts
- Technology choices with lock-in (database, message bus, auth, deployment)
- Boundary and scope decisions
- Deliberate deviations from the obvious path
- Constraints not visible in code
- Rejected alternatives when the rejection is non-obvious

## Spec format

Capability specs use OpenSpec requirement/scenario structure:

```md
## ADDED Requirements

### Requirement: <name>
<requirement text — use SHALL/MUST for normative statements>

#### Scenario: <name>
- **WHEN** <condition>
- **THEN** <expected outcome>
```

Delta sections for changes: `ADDED`, `MODIFIED`, `REMOVED`, `RENAMED Requirements`.

When editing canonical specs directly (implemented decisions), add requirements inline. When routing through a change, write delta specs under `openspec/changes/<name>/specs/<capability>/spec.md` for archive into the canonical spec.

## Do not use in OpenSpec mode

- `CONTEXT.md` / `CONTEXT-MAP.md` — use `ubiquitous-language` spec instead
- `docs/adr/` — use capability specs instead
- Nested spec paths like `specs/services/<name>/spec.md` — use flat `specs/service-<name>/spec.md`

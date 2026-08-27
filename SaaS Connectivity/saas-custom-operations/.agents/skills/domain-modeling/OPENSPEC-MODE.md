# OpenSpec Mode

Use this reference when `openspec/config.yaml` or `openspec/specs/` exists in the target repo. Do not use `CONTEXT.md` or `CONTEXT-MAP.md` in OpenSpec mode — use the ubiquitous-language spec instead.

**Specs and ADRs coexist.** Capability specs encode *what* (testable requirements). ADRs in `docs/adr/` encode *why* (rationale, trade-offs, rejected alternatives). ferspec and other schemas delegate ADR creation to domain-modeling — there is no separate `adr` artifact in the change workflow.

## Detection

OpenSpec mode activates when either exists:

- `openspec/config.yaml`
- `openspec/specs/` (directory with at least one capability spec)

Otherwise use legacy mode ([CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md), [ADR-FORMAT.md](./ADR-FORMAT.md)).

## File structure

```
/
├── docs/
│   └── adr/                              ← rationale (why); same as legacy
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── openspec/
    ├── config.yaml
    ├── specs/
    │   ├── ubiquitous-language/spec.md   ← replaces CONTEXT.md
    │   ├── module-ordering/spec.md         ← flat; category in slug
    │   ├── service-auth/spec.md
    │   └── use-case-cancel-order/spec.md
    └── changes/<change-name>/specs/        ← pending spec deltas
```

**Naming rule:** OpenSpec does not support nested category folders. Path is always `openspec/specs/<capability>/spec.md`. Encode category as a kebab-case prefix on the capability slug (`<category>-<name>`). Do not create paths like `specs/modules/<name>/spec.md`.

Create capability folders and `docs/adr/` lazily — only when you have something to write.

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

### Specs vs ADRs

| Artifact | Holds | Skip when |
|----------|-------|-----------|
| **Capability spec** requirement | Normative *what* — SHALL/MUST behavior, testable via scenarios | Decision is purely rationale with no behavioral contract |
| **ADR** (`docs/adr/`) | Narrative *why* — context, trade-offs, rejected alternatives | Requirement text is self-explanatory and no one will wonder why |

When both apply, write both and cross-link. Specs are the contract; ADRs are the memory.

### Where decisions land

| Situation | Spec | ADR |
|-----------|------|-----|
| **Already implemented** | ADDED/MODIFIED requirements in the most relevant capability spec | Offer ADR when rationale is non-obvious; write to `docs/adr/` |
| **Change required** to implement | Route through OpenSpec change workflow: `openspec/changes/<name>/specs/<capability>/spec.md` (suggest `/opsx:propose`) | Write ADR during apply or when the decision crystallises — distill from `design.md` Decisions when working inside a ferspec change |
| **Behavioral only**, self-explanatory | Requirement only | Skip ADR |
| **Rationale only**, no new behavior | Skip spec change | ADR only |

Prefer enhancing an existing spec over creating a new one. Create a new capability spec only when no existing slug is a reasonable home.

Use [ADR-FORMAT.md](./ADR-FORMAT.md) for ADR structure and numbering.

### Cross-linking

When a spec requirement and ADR cover the same decision:

**In the spec requirement** — add a trailing rationale pointer:

```md
### Requirement: Order write model persistence
The order write model SHALL persist events to PostgreSQL.

_Rationale: ADR-0042_
```

**In the ADR** — add a trailing spec pointer:

```md
# Event-sourced orders with Postgres write model

We chose event sourcing because partial cancellation requires an audit trail…

_Spec: module-ordering — Requirement: Order write model persistence_
```

### What qualifies

Same categories as legacy ADRs:

- Architectural shape (monorepo, event sourcing, read/write split)
- Integration patterns between bounded contexts
- Technology choices with lock-in (database, message bus, auth, deployment)
- Boundary and scope decisions
- Deliberate deviations from the obvious path
- Constraints not visible in code
- Rejected alternatives when the rejection is non-obvious

### ferspec and change workflows

When invoked from grill-with-docs, ferspec discovery, or `/opsx:apply`:

- `discovery.md` and `design.md` Decisions are **change-local working docs** — not durable ADRs.
- Distill decisions that pass the 3 criteria into `docs/adr/` as the change progresses or during apply Documentation tasks.
- Ensure related capability spec requirements exist (canonical or delta) so apply gate "design → specs" can pass.

For complex ADRs needing full MADR format, supersession chains, or team process, suggest the `architecture-decision-records` skill. Default to lightweight [ADR-FORMAT.md](./ADR-FORMAT.md).

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
- Nested spec paths like `specs/services/<name>/spec.md` — use flat `specs/service-<name>/spec.md`

# Agent Instructions

SailPoint ISC SaaS connector scaffold for custom operations. OpenSpec governs changes via the `ferspec` schema.

## Project context

-   **Stack:** TypeScript, Node.js, `@sailpoint/connector-sdk`, Vitest, ncc, spcx
-   **Entry:** `src/index.ts` — registers std command handlers
-   **Client:** `src/my-client.ts` — target application integration (currently mock)
-   **Manifest:** `connector-spec.json` — commands, sourceConfig, accountSchema
-   **Std commands:** `std:test-connection`, `std:account:list`, `std:account:read`
-   **Build/test:** `npm run build`, `npm test`, `npm run codegen:schemas`
-   **Schema codegen:** `OperationSignature.output` inline type literals → `*.schema.ts` sidecars; optional `command` literal → auto-registry + manifest sync (prebuild)
-   **Spec domains:** `connector-operations`, `target-client`, `connector-config` under `openspec/specs/`

See `openspec/config.yaml` for full project rules and artifact guidance.

## Agent communication

- Use **plain English** — avoid jargon unless the user already uses it.
- Keep explanations **succinct**. State the conclusion first; add detail only when it helps a decision.
- When a topic could go deep, **offer to develop it further** — do not unprompted long dissertations or essay-length replies.
- When you need input, **ask one question at a time** and wait for the answer before the next.

## Workflow routing (read on session start)

This repo uses the **ferspec** OpenSpec schema. Artifact instructions inject at each `/opsx:*` step; skills carry execution detail.

### Entry routing

| Trigger you observe | What to do |
|---|---|
| User starts a narrative design discussion | Run verbal grilling via **grill-with-docs**, but **do NOT** write repo-root CONTEXT.md. When converged per the 5 criteria below, promote to `/opsx:propose` |
| User invokes `/opsx:new` / `/opsx:ff` / `/opsx:propose` directly | Follow the ferspec schema flow |
| User explicitly says bug fix / typo / config tweak / doc update | Direct PR — **do NOT** open a change |
| User is mid-change | Advance with `/opsx:continue`, `/opsx:apply`, or `/opsx:archive` (archive is manual, never part of apply) |

### When NOT to use opsx (direct PR)

| Scenario | Direct PR? |
|---|---|
| New feature / new capability / architectural change / breaking change | ❌ Use opsx |
| Bug fix (no contract change) / test backfill / linter tweak / non-breaking upgrade / typo / docs / config value tweak | ✅ Direct PR |

Principle: **process ceremony scales with risk**. External contracts / schema / cross-system integration / compliance → opsx. Otherwise → direct PR.

### Verbal discovery → opsx promotion criteria

All 5 must hold before promoting (any missing → keep grilling, **never** write repo-root CONTEXT.md):

1. **Scope locked** — one sentence describes what's in / out
2. **Major design forks resolved** — alternatives weighed; remaining TBDs have an owner and impact-scope statement
3. **Cross-system dependencies mapped** — ready / mockable / genuinely unknown — pick one per dep
4. **Acceptance criteria stateable** — concrete pass conditions (e.g., `npm test` passes + N deliverables)
5. **Conversation converging** — recent turns are confirmations, not new alternatives

When all 5 hold → proactively suggest "ready to `/opsx:propose`?" — wait for user ack. Never auto-trigger.

### Front-door anti-patterns (don't do)

- Writing durable vocabulary to repo-root CONTEXT.md instead of discovery.md / ubiquitous-language spec
- Promoting to opsx with unresolved blocking TBDs
- Opening a change for bug fix / typo
- Running archive or spec sync inside apply — user runs `/opsx:archive` after merge or when ready

## Agent skills

### Issue tracker

Issues live in GitHub (`sailpoint-utils`). See `docs/agents/issue-tracker.md`.

### Domain docs

OpenSpec mode — vocabulary in `openspec/specs/ubiquitous-language/spec.md`. See `docs/agents/domain.md`.

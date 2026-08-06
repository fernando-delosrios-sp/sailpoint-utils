# Agent Instructions

SailPoint ISC SaaS connector scaffold for custom operations. OpenSpec governs changes via the `superpowers-bridge` schema.

## Project context

-   **Stack:** TypeScript, Node.js, `@sailpoint/connector-sdk`, Vitest, ncc, spcx
-   **Entry:** `src/index.ts` — registers std command handlers
-   **Client:** `src/my-client.ts` — target application integration (currently mock)
-   **Manifest:** `connector-spec.json` — commands, sourceConfig, accountSchema
-   **Std commands:** `std:test-connection`, `std:account:list`, `std:account:read`
-   **Build/test:** `npm run build`, `npm test`, `npm run codegen:schemas`
-   **Schema codegen:** `OperationSignature.output` inline type literals → `*.schema.ts` sidecars (prebuild); aliases/imports not parsed
-   **Spec domains:** `connector-operations`, `target-client`, `connector-config` under `openspec/specs/`

See `openspec/config.yaml` for full project rules and artifact guidance.

## Workflow routing (read on session start)

This repo uses [`superpowers-bridge`](https://github.com/JiangWay/openspec-schemas/tree/main/superpowers-bridge) to bridge OpenSpec and Superpowers. Integration rules (language, artifact paths, PRECHECK) follow that bridge's README; this section is the routing guidance for agents.

### Entry routing

| Trigger you observe                                              | What to do                                                                                                                                                                      |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| User starts a narrative "design discussion / let's brainstorm"   | Run verbal `superpowers:brainstorming`, but **do NOT** write to `docs/superpowers/specs/`. Once the conversation converges per the 5 criteria below, promote to `/opsx:propose` |
| User invokes `/opsx:new` / `/opsx:ff` / `/opsx:propose` directly | Follow the schema's flow; artifact instructions inject at each step                                                                                                             |
| User explicitly says bug fix / typo / config tweak / doc update  | Direct PR — **do NOT** open a change (see skip rules below)                                                                                                                     |
| User is mid-change                                               | Advance with `/opsx:continue`, `/opsx:apply`, `/opsx:verify`, or `/opsx:archive`                                                                                                |

### When NOT to use opsx (direct PR)

| Scenario                                                                                                              | Direct PR?   |
| --------------------------------------------------------------------------------------------------------------------- | ------------ |
| New feature / new capability / architectural change / breaking change                                                 | ❌ Use opsx  |
| Bug fix (no contract change) / test backfill / linter tweak / non-breaking upgrade / typo / docs / config value tweak | ✅ Direct PR |

Principle: **process ceremony scales with risk**. External contracts / schema / cross-system integration / compliance → opsx. Otherwise → direct PR.

### Verbal brainstorm → opsx promotion criteria

All 5 must hold before promoting (any missing → keep brainstorming, **never** write to `docs/superpowers/specs/`):

1. **Scope locked** — one sentence describes what's in / out
2. **Major design forks resolved** — alternatives weighed; remaining TBDs have an owner and impact-scope statement
3. **Cross-system dependencies mapped** — ready / mockable / genuinely unknown — pick one per dep
4. **Acceptance criteria stateable** — concrete pass conditions (e.g., `npm test` passes + N deliverables)
5. **Conversation converging** — recent turns are confirmations, not new alternatives

When all 5 hold → proactively suggest "ready to `/opsx:propose`?" — wait for user ack. Never auto-trigger.

### Front-door anti-patterns (don't do)

-   Letting brainstorming write to `docs/superpowers/specs/`
-   Letting writing-plans write to `docs/superpowers/plans/`
-   Promoting to opsx with unresolved blocking TBDs
-   Opening a change for bug fix / typo

Full detail: [superpowers-bridge README §Entry & exit gates](https://github.com/JiangWay/openspec-schemas/blob/main/superpowers-bridge/README.md#entry--exit-gates).

# custom:template

<!-- Copy this file when scaffolding a new operation from _template/. -->

## Purpose

<!-- One paragraph: what this operation does and when workflows invoke it. -->

## Command

`custom:template`

## Input

| Field | Required | Description |
|---|---|---|
| `exampleField` | No | <!-- describe --> |

## Output (persisted)

Persist keys use the `{slug}:` prefix where `slug` is the command name without `custom:` (e.g. `custom:my-op` → `my-op:result`).

`OperationSignature.output` lists **only** attributes written via `ctx.persist`. Never put invoke rollup counters here — those belong under `response`.

| Field | Required | Description |
|---|---|---|
| `template:result` | Yes | <!-- describe --> |
| `template:detail` | No | <!-- describe --> |

## Response (invoke envelope)

Return rollups with `ctx.respond(summary)` (not raw `ctx.res.send`). The framework builds:

| Field | Source |
|---|---|
| `name` | Command name (e.g. `custom:template`) |
| `type` | Always `custom` |
| `status` | Defaults to `success` |
| `responses` | Native identities persisted this invoke |
| `summary` | Your `OperationSignature.response` fields |

| Summary field | Required | Description |
|---|---|---|
| `itemsProcessed` | No | <!-- example rollup — not persisted, not on account schema --> |

## Invoke examples

<!-- Reference payloads under payloads/ — local and workflow-ready (*-workflow.json). -->

| Payload | Use |
|---|---|
| `payloads/...` | Local `npm run call:op` |
| `payloads/...-workflow.json` | ISC workflow HTTP invoke |

## Workflow integration

<!-- Numbered steps when this operation participates in a multi-step workflow. Write N/A for standalone ops. -->

_N/A_

## Local development

Auto-discovered operations (with a `command` literal on `OperationSignature`) are registered in the codegen `OPERATION_HANDLERS` map after `npm run build` — no manual edits to `scripts/call-op.ts`.

```bash
npm run call:op -- payloads/<your-offline-payload>.json
```

<!-- Offline behavior, testMode notes, experimental API headers, etc. -->

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

| Field | Required | Description |
|---|---|---|
| `template:result` | Yes | <!-- describe --> |
| `template:detail` | No | <!-- describe --> |

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

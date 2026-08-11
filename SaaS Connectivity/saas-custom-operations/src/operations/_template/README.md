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

| Field | Required | Description |
|---|---|---|
| `result` | Yes | <!-- describe --> |
| `detail` | No | <!-- describe --> |

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

```bash
npm run call:op -- payloads/<your-offline-payload>.json
```

<!-- Offline behavior, testMode notes, experimental API headers, etc. -->

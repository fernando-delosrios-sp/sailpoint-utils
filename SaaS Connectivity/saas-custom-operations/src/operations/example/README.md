# custom:example

## Purpose

Reference custom operation demonstrating typed `ctx.persist` with a parent identity and a child identity (`{requestId}:detail`). Used by the **SaaS Custom Operations Call** workflow export to show invoke → persist → **Get Accounts** read-back.

## Command

`custom:example`

## Input

| Field | Required | Description |
|---|---|---|
| `message` | No | Optional greeting; defaults to `completed` in the persisted `summary` |

## Output (persisted)

| Field | Identity | Description |
|---|---|---|
| `summary` | `{requestId}` and `{requestId}:detail` | Result text from input message or default |
| `step` | `{requestId}` only | Literal `1` on the parent account |

## Invoke examples

| Payload | Use |
|---|---|
| [`payloads/custom-example-offline.json`](../../../payloads/custom-example-offline.json) | Offline local invoke (no `config`; persist inhibited) |
| [`payloads/custom-example.json`](../../../payloads/custom-example.json) | Connected local invoke (requires token in `config`) |
| [`workflows/SaaS Custom Operations.json`](../../../workflows/SaaS%20Custom%20Operations.json) | Reference workflow export |

Offline example:

```json
{
  "type": "custom:example",
  "input": { "requestId": "offline-001", "message": "hello" }
}
```

## Workflow integration

1. Invoke `custom:example` with `requestId` and optional `message`.
2. Read persisted output via **Get Accounts** filtered by `nativeIdentity eq "{requestId}"`.
3. Optionally read the child account with `nativeIdentity eq "{requestId}:detail"`.

See the root [README](../../../README.md) for generic invoke envelope, persist inhibition, and **Get Accounts** filtering.

## Local development

```bash
npm run call:op -- payloads/custom-example-offline.json
npm run call:op -- payloads/custom-example.json
```

Register the handler in `scripts/call-op.ts` `OPERATION_HANDLERS` when adding new operations (example is pre-registered).

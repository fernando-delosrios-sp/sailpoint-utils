# saas-custom-operations

Foundation template for SailPoint ISC **custom operations**. This connector is **not** an aggregation source — it provides a runtime for custom commands that loop back into ISC via the API and persist results as accounts on a pre-provisioned dummy source.

## How it works

```
Workflow / API invoke
        │
        ▼
  Custom operation handler  ──►  ctx.sdk (ISC loopback)
        │
        ▼
  ctx.persist(...)  ──►  Dummy result source (account create / upsert)
        │
        ▼
  ctx.res.send(...)  ──►  Command response to caller
```

Each invocation receives a standard envelope (`config` + `input`), builds a volatile `RequestContext`, runs your handler, and optionally writes structured output to the dummy source so downstream workflow steps can read results with **Get Accounts**.

## Prerequisites

### Dummy result source (per tenant)

Provision a source in ISC with the account schema below before using custom operations. The source must allow account create (upsert on duplicate `id`).

| Attribute | Description |
|---|---|
| `id` | Identity attribute — native account identity |
| `date` | Timestamp (set automatically by the framework) |
| `status` | Operation outcome (defaults to `success`) |
| _operation attrs_ | Whatever your operation persists via `ctx.persist` — configure matching names on the dummy source |

### ISC tenant setup

You need:

1. **Dummy result source** — Delimited File (or any source that supports account create) with the schema above.
2. **SaaS custom connector** — this project, built and uploaded to ISC (`npm run pack-zip`).
3. **OAuth client credentials** — PAT or client with scopes to invoke the connector and call ISC APIs used by your operations.
4. **Workflow (optional)** — to orchestrate invoke → read result.

## exportedObjects artefact

The `exportedObjects/` directory contains an ISC **Export Job** snapshot you can import into another tenant to bootstrap the reference setup:

| File | Contents |
|---|---|
| `exportedObjects/SaaS Custom Operations.json` | Dummy **SOURCE** (`SaaS Custom Operations`) and example **WORKFLOW** (`SaaS Custom Operations Call`) |

The export includes:

- **Source** — Delimited File dummy result source with `id`, `date`, `status`, and operation-specific attributes on the account schema.
- **Workflow** — end-to-end example: configuration variables → OAuth token → connector invoke → **Get Accounts** filtered by `requestId`.

### Importing the export

1. In ISC Admin, open **Global → Import / Export → Import**.
2. Upload `exportedObjects/SaaS Custom Operations.json`.
3. Review and confirm the import of the source and workflow objects.
4. Update workflow **Configuration** step variables for your tenant:
   - **API URL** — e.g. `https://your-tenant.api.identitynow.com`
   - **SaaS Custom Operations Source ID** — imported dummy source ID
   - **SaaS Custom Operations Connector ID** — your deployed custom connector ID
5. Configure the **Get Access Token** step with a valid OAuth client (Basic auth reference).
6. Enable the workflow and trigger it (external HTTP trigger) or run steps manually while testing.

> **Note:** Export files are tenant-specific snapshots. Object IDs, owners, and OAuth references in the JSON will differ after import — treat the workflow as a template and re-point configuration to your connector and credentials.

## Build and deploy

```bash
npm install
npm test
npm run build
npm run pack-zip    # produces a deployable connector package via spcx
```

Upload the packaged connector to ISC and note the connector ID for workflow configuration and invoke calls.

## Usage

### Invoke payload

Custom operations use the standard SaaS connector invoke shape. See `invoke-payload.json` for a workflow-ready example:

```json
{
    "connectorRef": "{{$.defineVariable.saaSCustomOperationsConnectorID}}",
    "tag": "latest",
    "type": "custom:example",
    "input": {
        "requestId": "req-123",
        "message": "Hello, world!"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.hTTPRequest.body.accessToken}}",
        "sourceId": "{{$.defineVariable.saaSCustomOperationsSourceID}}"
    }
}
```

| Section | Fields | Description |
|---|---|---|
| `type` | command name | Must match a command in `connector-spec.json` (e.g. `custom:example`) |
| `config` | `apiUrl`, `token`, `sourceId` | ISC loopback credentials and dummy result source ID |
| `input` | `requestId` + operation params | Per-invocation data; `requestId` correlates persisted accounts |

The framework strips `requestId` from operation input and exposes it on `ctx.requestId`. All other `input` fields are passed to your handler.

### Local development

```bash
npm run build && npm run dev
```

Post a test payload to the local connector runtime:

```bash
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d @invoke-payload.json
```

Replace template variables in `invoke-payload.json` with real values when testing locally (`connectorRef` is ignored by `spcx run`; `config` and `input` must be concrete).

### Invoke against a deployed connector

With the SailPoint CLI:

```bash
sail conn invoke raw -c {connectorId} -f invoke-payload.json
```

Or from a workflow HTTP action (as in the exported workflow):

```
POST {apiUrl}/beta/platform-connectors/{connectorId}/invoke
Authorization: Bearer {access_token}
Content-Type: application/json

{ ... invoke payload ... }
```

### Reading results in a workflow

After invoke, read persisted output from the dummy source using **Get Accounts** filtered by native identity:

- Filter: `nativeIdentity eq "{requestId}"` (or a child id such as `{requestId}:detail`)
- Map operation output attributes, `status`, and `date` from account attributes

The exported workflow demonstrates this pattern in the **Read SaaS Custom Operation Result** step.

## Extending the connector

### 1. Add an operation handler

Copy `src/operations/_template.ts` to a new file under `src/operations/` and implement your handler:

```typescript
import { customOperation, OperationSignature } from '../framework'

export interface MyOperation extends OperationSignature {
    input: {
        accountId?: string
    }
    output: {
        result: string
        detail?: string
    }
}

export const myOperation = customOperation<MyOperation>(async (ctx, input) => {
    console.log(`[${ctx.requestId}] starting`, input)

    await ctx.persist(ctx.requestId, { result: 'result-value' })
    await ctx.persist(`${ctx.requestId}:detail`, { detail: 'step-output' }, 'success')

    ctx.res.send({ status: 'success' })
})
```

### 2. Register the command

In `src/operations/index.ts`:

```typescript
import { myOperation } from './my-operation'

export function registerCommands(connector: Connector): Connector {
    return connector
        .command('custom:example', exampleOperation)
        .command('custom:my-operation', myOperation)
}
```

### 3. Declare the command in the manifest

Add the command name to `connector-spec.json`:

```json
{
    "commands": [
        "custom:example",
        "custom:my-operation"
    ]
}
```

Rebuild, repackage, and redeploy. Invoke with `"type": "custom:my-operation"` and any additional fields in `input`.

### RequestContext API

| Member | Description |
|---|---|
| `ctx.requestId` | Correlation id from invoke `input` |
| `ctx.sourceId` | Dummy result source ID from `config` |
| `ctx.sdk` | SailPoint API client (`sailpoint-api-client`) for loopback calls |
| `ctx.persist(...)` | Write results to the dummy source |
| `ctx.verifyPersisted(...)` | Batch verify deferred writes |
| `ctx.res` | Connector SDK response object — call `ctx.res.send(...)` |

### Persist API

```typescript
interface MyOperation extends OperationSignature {
    input: { ... }
    output: { fieldName: string, ... }
}

customOperation<MyOperation>(async (ctx, input) => { ... })
ctx.persist(id, attributes?, status?, options?)
ctx.verifyPersisted(ids)
```

- **`OperationSignature`** — one interface with `input` and `output` using normal TypeScript types
- **`customOperation<T>(handler)`** — types `input` and `ctx.persist` from `T`; no separate output config
- **`ctx.persist`** — framework serializes values for ISC storage (strings as-is, arrays/objects as JSON)
- **`id`** — native account identity (often `ctx.requestId` or a derived child id like `` `${ctx.requestId}:detail` ``)
- **`attributes`** — only keys declared in the operation output schema; arrays/objects use `'json'` type (stored as JSON string)
- **`status`** — optional, defaults to `"success"`
- **`date`** — always set automatically to the current timestamp
- **`options.verify`** — optional, defaults to `true`; set to `false` to skip inline read-back verification

By default, `persist` reads the account back from ISC and verifies attributes before resolving. Pass `{ verify: false }` to defer verification, then call `verifyPersisted([...ids])` before the handler completes. Unknown attribute keys are rejected before account create.

Account create is used for persistence (upsert on duplicate identity).

## Development

```bash
npm install          # install dependencies
npm test             # run Vitest suite with coverage
npm run build        # compile to dist/ via ncc
npm run dev          # run locally with spcx
npm run pack-zip     # build deployable connector package
npm run templates    # generate operator artifacts (see below)
```

### Operator templates

Run `npm run templates` after adding or modifying registered operations in `src/operations/index.ts`. The generator introspects implemented handlers and writes local-only artifacts to `./templates/` (gitignored). Markdown guides follow the step structure in `workflows/Workflow - SaaS Custom Operations Call.json`:

| File | Purpose |
|---|---|
| `account-schema.json` | ISC account schema with core attrs (`id`, `status`, `date`) plus union of operation output fields |
| `access-token.md` | Shared OAuth client-credentials guide with tenant placeholders |
| `workflow-invocation.md` | Per-operation invoke body, read-result, and child-identity steps |

Re-run whenever you register a new operation or change an operation's `OperationSignature` or `ctx.persist` patterns. Commands declared in `connector-spec.json` but not registered in `src/operations/index.ts` are not included.

## Project structure

```
src/
  framework/          # RequestContext, persist helper, SDK factory, customOperation wrapper
  operations/         # Custom operation handlers (add yours here)
    _template.ts      # Authoring template — copy when adding operations
    example-operation.ts
    index.ts          # Command registration
  index.ts            # Connector entry point
connector-spec.json   # Declared commands and sourceConfig (ISC loopback settings)
invoke-payload.json   # Example invoke body for local / CLI testing
exportedObjects/      # ISC export snapshot (dummy source + example workflow)
```


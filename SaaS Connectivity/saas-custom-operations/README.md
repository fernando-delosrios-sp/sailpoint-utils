# saas-custom-operations

<p align="center">
  <img src="./assets/custom-workflow-actions-promo.png" alt="Custom Workflow Actions - Bridging Workflows and SaaS Connectivity" width="100%" />
</p>

## Purpose

Foundation template for SailPoint ISC **custom operations**: invoke commands from workflows, call back into ISC APIs, and persist typed results to an auto-provisioned DelimitedFile source for downstream **Get Accounts** steps. This connector is **not** an aggregation source—it is a runtime for workflow-driven custom logic.

## How it works

```
Workflow / API invoke
        │
        ▼
  Resolve sourceName → sourceId (create DelimitedFile if missing)
        │
        ▼
  Custom operation handler  ──►  ctx.sdk (ISC loopback)
        │
        ▼
  ctx.persist(...)  ──►  Reconcile schema → account create / upsert
        │
        ▼
  ctx.res.send(...)  ──►  Command response to caller
```

Each invocation receives a standard envelope (`config` + `input`), resolves the result source by name, builds a volatile `RequestContext`, runs your handler, and optionally writes typed output to the result source so downstream workflow steps can read results with **Get Accounts**.

## Prerequisites

### Result source (auto-provisioned)

Configure a **source name** in connector config (`sourceName`). On each invocation the framework:

1. Looks up an ISC source with that name
2. Creates a DelimitedFile source with CSV provisioning if missing (owner = token identity)
3. Reconciles the account schema before each `ctx.persist` for the current operation's output fields

Core attributes are always ensured on the schema: `id` (identity), `status`, and `date`.

**Token scopes:** The access token must allow source read/create/update and account create on the result source. PAT or OAuth client credentials used in workflows need `sp:manage:source`, `sp:manage:source-schema`, and account provisioning scopes for the tenant.

Manual source setup is not required. `npm run templates` generates `account-schema.json` as reference documentation for the attributes operations persist; the framework reconciles the live schema at runtime.

## Workflow export

The `workflows/` directory contains an ISC **Export Job** snapshot you can import for the reference **SaaS Custom Operations Call** workflow:

| File | Contents |
|---|---|
| `workflows/SaaS Custom Operations.json` | Example **WORKFLOW** — invoke `custom:example`, then read results with **Get Accounts** |

The workflow demonstrates:

- Configuration variables → OAuth token → connector invoke → **Get Accounts** filtered by `requestId`
- `config.sourceName` passed on invoke (the connector creates the DelimitedFile result source on first use)

No separate result source import is required. The framework resolves `sourceName` at runtime, creates the DelimitedFile source when missing, and reconciles account schema on each `ctx.persist`.

### Importing the workflow

1. In ISC Admin, open **Global → Import / Export → Import**.
2. Upload `workflows/SaaS Custom Operations.json`.
3. Review and confirm import of the workflow object.
4. Update workflow **Configuration** step variables for your tenant:
   - **API URL** — e.g. `https://your-tenant.api.identitynow.com`
   - **SaaS Custom Operations Source Name** — name for the auto-provisioned result source (e.g. `SaaS Custom Operations`; passed as invoke `config.sourceName`)
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
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

| Section | Fields | Description |
|---|---|---|
| `type` | command name | Must match a command in `connector-spec.json` (e.g. `custom:example`) |
| `config` | `apiUrl`, `token`, `sourceName` | ISC loopback credentials and result source name (auto-provisioned at runtime) |
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

The POST body uses three top-level fields — `type` (command name), `config` (connection settings), and `input` (per-invocation payload including `requestId`):

```json
{
    "type": "custom:example",
    "config": {
        "apiUrl": "https://your-tenant.api.identitynow.com",
        "token": "<access-token>",
        "sourceName": "SaaS Custom Operations",
        "testMode": true
    },
    "input": {
        "requestId": "local-dev-001",
        "message": "Hello from spcx"
    }
}
```

#### Default request logging

Every invoke during `npm run debug` logs an **Incoming request** section to stdout before the handler runs. The output matches the readable format used by `npm run test:operation` (section headers and spread JSON). The log includes `command`, `input`, and resolved `config` when available. **`config.token` is always redacted** as `[REDACTED]` — other config fields are shown as received.

### Test mode (dry run)

Set `config.testMode: true` (or export `SPCX_TEST_MODE=1` for config-less runs) to run handler logic without writing accounts or mutating source schema on ISC. `ctx.res.send` behaves normally; each inhibited `ctx.persist` / `ctx.verifyPersisted` call is logged to the console with a `[test-mode]` prefix.

| Config provided | ISC behavior | Writes |
|---|---|---|
| Yes (full `apiUrl`, `token`, `sourceName`) | Read-only status check + list-only source lookup; fails on missing/invalid token | Inhibited (logged) |
| No | All ISC calls skipped | Inhibited (logged) |

Run from a JSON fixture:

```bash
npm run test:operation -- fixtures/custom-example-offline.json
npm run test:operation -- fixtures/custom-example.json   # requires valid token in config
```

Offline fixtures (no `config` block) automatically enable test mode in the fixture runner. You can also export `SPCX_TEST_MODE=1` when invoking handlers outside the runner.

```json
{
  "command": "custom:example",
  "input": { "requestId": "offline-001", "message": "hello" }
}
```

Config-present dry-run fixture:

```json
{
  "command": "custom:example",
  "config": {
    "apiUrl": "https://your-tenant.api.identitynow.com",
    "token": "<access-token>",
    "sourceName": "SaaS Custom Operations",
    "testMode": true
  },
  "input": { "requestId": "fixture-001", "message": "dry run" }
}
```

Partial config (e.g. `{ "testMode": true }` only) is rejected — provide full connection fields or omit config entirely.

The fixture runner resolves commands from a static registry in `scripts/run-operation-fixture.ts`. When you add a new custom operation, register its handler in `COMMAND_HANDLERS` alongside `custom:example`.

```bash
npm run test:operation -- fixtures/sod-remediation-offline.json
```

### `custom:sod-remediation`

Launch-only operation that fetches an SOD violation, ensures a named form definition exists, creates a standalone remediation form for the violation owner (or override recipient), and persists `formUrl` plus `situationSummary` for downstream workflow steps.

**Invoke payload:**

```json
{
    "connectorRef": "{{$.defineVariable.saaSCustomOperationsConnectorID}}",
    "tag": "latest",
    "type": "custom:sod-remediation",
    "input": {
        "requestId": "req-sod-001",
        "violationId": "00000000-0000-0000-0000-000000000001",
        "formName": "SOD Violation Remediation",
        "owner": "optional-recipient-identity-id"
    },
    "config": {
        "apiUrl": "{{$.defineVariable.aPIURL}}",
        "token": "{{$.getAccessToken.body.access_token}}",
        "sourceName": "{{$.defineVariable.saaSCustomOperationsSourceName}}"
    }
}
```

| Input field | Required | Description |
|---|---|---|
| `violationId` | Yes | SOD violation ID (`GET /violations/v1/:id`, experimental API) |
| `formName` | Yes | Tenant form definition name — created from bundled seed on first use |
| `owner` | No | Recipient identity ID override; defaults to violation owner |

| Output field (persisted) | Description |
|---|---|
| `formUrl` | Standalone form URL (`standAloneFormUrl`) for email deep links |
| `situationSummary` | Plain-text summary for notification workflows |

**Workflow integration pattern:**

1. Invoke `custom:sod-remediation` with violation ID and form name.
2. Read persisted output via **Get Accounts** filtered by `requestId`.
3. Send email to recipient with `situationSummary` and link to `formUrl`.
4. Wait for form submission; read `formData` keys:
   - User keys: `action`, `remediationSide`, `policyControl`, `comments`
   - Hidden keys: `violationId`, `targetIdentityId`, `groupARevokePayload`, `groupBRevokePayload`
5. Execute corrective revoke or apply compensating control in separate workflow HTTP actions (not handled by the connector).

Experimental APIs require header `X-SailPoint-Experimental: true` (handled internally). Offline fixture runs use canned violation data when no `config` is provided.

### Invoke against a deployed connector

With the SailPoint CLI:

```bash
sail conn invoke raw -c {connectorId} -f invoke-payload.json
```

Or from a workflow HTTP action (as in the reference workflow export):

```
POST {apiUrl}/beta/platform-connectors/{connectorId}/invoke
Authorization: Bearer {access_token}
Content-Type: application/json

{ ... invoke payload ... }
```

### Reading results in a workflow

After invoke, read persisted output from the result source using **Get Accounts** filtered by native identity:

- Filter: `nativeIdentity eq "{requestId}"` (or a child id such as `{requestId}:detail`)
- Map operation output attributes, `status`, and `date` from account attributes

The reference workflow export demonstrates this pattern in the **Read SaaS Custom Operation Result** step.

## Extending the connector

### 1. Add an operation handler

Copy `src/operations/_template.ts` to a new file under `src/operations/` and implement your handler. Declare `input` and `output` on an `OperationSignature` interface — the build generates a matching schema sidecar.

**Auto-discovery (recommended):** add a `command` string literal to your interface. Codegen registers the handler, syncs `connector-spec.json`, and wires the schema registry — no manual `index.ts` entry required.

```typescript
import { customOperation, OperationSignature } from '../framework'

export interface MyOperation extends OperationSignature {
    command: 'custom:my-operation'
    input: {
        accountId?: string
    }
    output: {
        result: string
        detail?: string
    }
}

export const myOperation = customOperation<MyOperation>(
    async (ctx, input) => {
        console.log(`[${ctx.requestId}] starting`, input)

        await ctx.persist(ctx.requestId, { result: 'result-value' })
        await ctx.persist(`${ctx.requestId}:detail`, { detail: 'step-output' }, 'success')

        ctx.res.send({ status: 'success' })
    }
)
```

Run `npm run codegen:schemas` (also runs on `npm run build`) to generate `my-operation.schema.ts`, update `auto-registry.ts`, and sync `connector-spec.json`.

**Manual registration:** omit `command` from the interface, register in `index.ts`, import the generated sidecar, and pass it explicitly:

```typescript
import { myOperationSchema } from './my-operation.schema'

export const myOperation = customOperation<MyOperation>(
    async (ctx, input) => { /* ... */ },
    { operationSchema: myOperationSchema }
)
```

```typescript
// src/operations/index.ts
export function registerCommands(connector: Connector): Connector {
    return registerAutoOperations(connector).command('custom:my-operation', myOperation)
}
```

Add the command to `connector-spec.json` manually when using the manual path (auto-discovery syncs it for you).

### 2. Rebuild and deploy

Rebuild, repackage, and redeploy. Invoke with `"type": "custom:my-operation"` and any additional fields in `input`.

### RequestContext API

| Member | Description |
|---|---|
| `ctx.requestId` | Correlation id from invoke `input` |
| `ctx.sourceName` | Configured result source name (resolved/created at runtime) |
| `ctx.sourceId` | Resolved ISC source ID after sourceName lookup |
| `ctx.sdk.accounts` | ISC loopback client for account create/read used by `ctx.persist` |
| `ctx.sdk.sources` | ISC loopback client for result source lookup, creation, and schema management |
| `ctx.sdk.forms` | ISC Custom Forms API for form definition search/create and form instance create |
| `ctx.persist(...)` | Write results to the result source (auto-provisioned DelimitedFile) |
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

- **`OperationSignature`** — one interface with `input` and `output` using inline TypeScript type literals (aliases and imported types are not parsed by codegen)
- **`customOperation<T>(handler, options?)`** — types `input` and `ctx.persist` from `T`; pass the generated `{handler}Schema` sidecar for schema reconciliation
- **`ctx.persist`** — formats values using typed inference (numbers/booleans native, objects JSON-serialized); reconciles schema before write
- **`id`** — native account identity (often `ctx.requestId` or a derived child id like `` `${ctx.requestId}:detail` ``)
- **`attributes`** — only keys declared in the operation output schema; typed per `OperationSignature.output`
- **`status`** — optional, defaults to `"success"`
- **`date`** — always set automatically to the current timestamp
- **`options.verify`** — optional, defaults to `true`; set to `false` to skip inline read-back verification

By default, `persist` reads the account back from ISC and verifies attributes before resolving. Pass `{ verify: false }` to defer verification, then call `verifyPersisted([...ids])` before the handler completes. Unknown attribute keys are rejected before account create.

Account create is used for persistence (upsert on duplicate identity).

## Development

```bash
npm install          # install dependencies
npm test             # run Vitest suite with coverage
npm run build        # codegen sidecars, then compile to dist/ via ncc
npm run codegen:schemas  # regenerate *.schema.ts sidecars from OperationSignature
npm run dev          # run locally with spcx
npm run pack-zip     # build deployable connector package
npm run templates    # generate operator artifacts (see below)
```

### Operator templates

Run `npm run templates` after adding or modifying operations under `src/operations/`. The generator introspects auto-discovered and manually registered handlers and writes local-only artifacts to `./templates/` (gitignored). Markdown guides follow the step structure of the **SaaS Custom Operations Call** workflow embedded in `workflows/SaaS Custom Operations.json`:

| File | Purpose |
|---|---|
| `account-schema.json` | Reference account schema — core attrs (`id`, `status`, `date`) plus union of operation output fields |
| `access-token.md` | Shared OAuth client-credentials guide with tenant placeholders |
| `workflow-invocation.md` | Per-operation invoke body, read-result, and child-identity steps |

Re-run whenever you add an operation or change an operation's `OperationSignature` or `ctx.persist` patterns. Discovery includes auto-registered ops (`command` literal on the interface) and manual index.ts registrations.

## Project structure

```
src/
  framework/          # RequestContext, persist, source provisioning, schema inference, SDK factory
  operations/         # Custom operation handlers (add yours here)
    _template.ts      # Authoring template — copy when adding operations
    example-operation.ts
    example-operation.schema.ts  # Auto-generated — do not edit manually
    auto-registry.ts        # Auto-generated command + schema registration
    index.ts          # Calls registerAutoOperations; append manual .command() as needed
  index.ts            # Connector entry point
scripts/
  generate-templates.ts       # Operator artifact generator (`npm run templates`)
  generate-operation-schemas.ts
  templates/                  # Generator modules (account-schema, workflow-invocation, …)
connector-spec.json   # Declared commands and sourceConfig (ISC loopback settings)
invoke-payload.json   # Example invoke body for local / CLI testing
workflows/
  SaaS Custom Operations.json # ISC export (example workflow only)
templates/            # Generated operator artifacts (gitignored; output of npm run templates)
```




# Changelog

All notable changes to **saas-custom-operations** are documented here.

## [Unreleased] — 0.1.0

### New features

- **Custom operation foundation** — Build ISC custom commands without reimplementing SDK setup, logging, or result persistence. Copy `_template.ts`, register your handler, and deploy.
- **Result persistence to a dummy source** — Write flat, workflow-readable output via `ctx.persist()`. Downstream steps read results with **Get Accounts** filtered by `requestId`.
- **ISC loopback SDK** — `ctx.sdk` exposes SailPoint API clients for in-connector calls.
- **Operator template generator** — Run `npm run templates` to generate an account schema, OAuth setup guide, and per-operation workflow invoke instructions from your registered handlers.
- **Example operation** — `custom:example` demonstrates invoke → persist → read-back, with an exportable ISC workflow under `workflows/`.
- **Tenant bootstrap export** — Import `source/SaaS Custom Operations.json` to provision a dummy result source and sample workflow in a new tenant.

### Improvements

- **Typed operation signatures** — `customOperation<T>()` ties handler input and `ctx.persist` output to a single `OperationSignature` interface.
- **Persist verification** — Writes are read back from ISC by default; use `{ verify: false }` and `verifyPersisted()` for deferred multi-write flows.
- **Correlated logging** — Operation logs include `requestId` with token redaction.
- **Vitest coverage** — Tests scoped to `src/` and the templates generator scripts.

### Breaking changes

- **No longer an aggregation connector** — Standard commands (`std:test-connection`, `std:account:list`, `std:account:read`) and the mock `MyClient` scaffold are removed. This project is a custom-operation runtime only.
- **`customOperation<T>()` API** — Replaces earlier positional handler params and separate output config. Define one interface with `input` and `output` types.

### Removed

- Standard command handlers and mock aggregation client.

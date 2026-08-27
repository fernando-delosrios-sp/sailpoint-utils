# Brainstorm: Base schema on result source create

## Background

The custom-operation framework auto-provisions a DelimitedFile result source when `sourceName` is not found. Source create enables `DISCOVER_SCHEMA`, so ISC may materialize an account schema before the connector applies its own.

Today `createDelimitedFileResultSource` calls `createAccountSchema` with `DEFAULT_RESULT_ACCOUNT_SCHEMA` — only core attributes (`id`, `status`, `date`). Operation output fields are added later, one operation at a time, via `ensureSourceSchema` on each `ctx.persist`.

The templates generator (`npm run templates`) already builds a **base account schema**: core attributes plus the union of all registered operation output fields, with typed inference matching runtime. That artifact is documentation-only; runtime source create does not use it.

## Problem

First-run persist on a newly auto-created result source starts with a minimal or ISC-discovered schema instead of the connector's intended base schema. Operators see incomplete schemas in ISC admin until every operation has persisted at least once. This diverges from the generated `account-schema.json` reference and adds unnecessary persist-time patch churn.

## Decision chain

### Q1: What is the "base schema"?

- **Agreed:** Same shape as templates `buildAccountSchema` — core attrs (`id`, `status`, `date`) plus union of all registered custom operation output fields (excluding reserved framework keys), with typed inference from `OperationSignature.output`
- **Rejected:** Only the current operation's output fields at invoke time (that remains persist-time reconciliation scope)

### Q2: When does base schema apply?

- **Agreed:** Only when the framework **creates** a new result source (`createDelimitedFileResultSource`)
- **Rejected:** Re-baseline existing tenant sources on every invoke (breaking / surprising)

### Q3: What does "replace the current account schema" mean?

- **Agreed:** After `createSourceV1`, read the account schema if present (ISC auto-discovered or partial). Bring it to the base schema:
  - If no account schema → `createSourceSchemaV1` with full base payload
  - If account schema exists → patch/replace attributes and metadata (`identityAttribute`, `displayAttribute`, etc.) to match base schema; add missing attrs; do not remove extra attrs from manual operator edits (add-only alignment, same conflict policy as persist reconciliation)
- **Rejected:** Delete source and recreate on schema mismatch

### Q4: Where does base schema data come from at runtime?

- **Agreed:** All entries in the operation schema registry (auto-discovered sidecars loaded at module init)
- **Agreed:** Add registry helper to list registered schemas for union build
- **Rejected:** Re-parse operation modules at runtime (duplicates codegen path)

### Q5: Share logic with templates generator?

- **Agreed:** Extract a shared `buildBaseAccountSchema(outputFields[])` in framework (or shared module) consumed by templates and `createDelimitedFileResultSource`
- **Reason:** Single inference path; templates stay parity-checked with runtime

### Q6: Impact on persist-time reconciliation?

- **Agreed:** Unchanged — `ensureSourceSchema` remains add-only per current operation + attribute keys
- **Reason:** Handles dynamic keys and ops added after source create; base schema is best-effort union at create time

## Trade-offs

| Choice | Pro | Con |
|--------|-----|-----|
| Base schema at create (union of all ops) | ISC admin shows complete schema immediately; matches templates | New ops added after source exists still need persist reconcile |
| Patch existing ISC schema vs always create | Handles DISCOVER_SCHEMA race | Slightly more API logic |
| Shared builder with templates | Parity | Small refactor of templates import path |

## Non-goals

- Re-baseline schemas on existing sources when connector version changes
- Remove attributes from schemas (still add-only)
- Change connector-spec.json or operation I/O contracts
- Union schema at every invoke (deferred in original dynamic-result-source design)

## Open questions (resolved)

All resolved — no blocking TBDs for proposal.

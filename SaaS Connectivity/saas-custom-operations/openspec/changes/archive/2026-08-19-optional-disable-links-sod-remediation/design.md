## Context

Both SOD launch operations derive UI origin from `ctx.apiUrl` via `resolveUiOrigin` and pass it into shared `sod-form-html` builders. When `uiOrigin` is set, context panels and group/access-path lines wrap display names in ISC admin anchors; when undefined (offline or unresolvable apiUrl), names stay plain escaped text. Callers need the same plain rendering on live invokes without removing loopback config.

## Goals / Non-Goals

**Goals:**

- Add optional `disableLinks?: boolean` to `custom:access-model-sod-remediation` and `custom:sod-remediation` inputs
- When `disableLinks === true`, omit UI origin for HTML assembly so ISC UI links are not rendered
- Keep default (omit / false) identical to today’s linked behavior when UI origin resolves
- Sync schemas/manifest via existing codegen

**Non-Goals:**

- Changing email remediation-form CTA links or `*:form-url` / email header/body field contracts
- New sod-form-html APIs or a global connector-level config flag
- Applying the flag to `access-model-sod-remediation-apply` or other commands
- Altering offline behavior beyond accepting a redundant `disableLinks: true`

## Decisions

### D1: Gate at handler uiOrigin assignment

- **Choice**: Compute `uiOrigin = offline || input.disableLinks ? undefined : resolveUiOrigin(ctx.apiUrl)` (or equivalent) in each operation handler before HTML assembly
- **Reason**: Existing builders already treat missing `uiOrigin` as “no links”; no library churn
- **Considered alternatives**: New `linksEnabled` option threaded through every renderer — rejected as broader API surface for the same effect

### D2: Opt-in disable only (default links on)

- **Choice**: Only explicit `true` disables; omit and `false` keep current linking
- **Reason**: Additive, non-breaking for existing workflows
- **Considered alternatives**: Invert to `enableLinks` default false — rejected; would break current UX

### D3: Scope is ISC UI links only

- **Choice**: Flag does not remove remediation form URL from outputs or the email “Remediate here” CTA
- **Reason**: Those are workflow delivery hooks, not admin deep links; discovery locked this boundary
- **Considered alternatives**: Suppress all `<a>` tags including form CTA — rejected as breaking email remediation flows

### D4: Schema / manifest via OperationSignature

- **Choice**: Add `disableLinks?: boolean` on both OperationSignature `input` types; rely on prebuild codegen for `*.schema.ts` and connector-spec.json
- **Reason**: Matches project convention for custom command inputs
- **Considered alternatives**: Manual connector-spec-only edit — rejected; drifts from codegen source of truth

## Risks / Trade-offs

- [Risk] Callers confuse `disableLinks` with “no form URL” → Mitigation: docs/README state clearly that form URL and email CTA remain; specs cover CTA still present
- [Trade-off] Duplicated one-liner in two handlers → Reason for acceptance: tiny, mirrors existing offline `uiOrigin` gating; shared helper optional only if a third caller appears
- [Risk] Schema codegen/manifest miss → Mitigation: tasks include `npm run codegen:schemas` / prebuild and assert connector-spec input property

## Migration Plan

Non-breaking additive input. Existing payloads omit the field and keep current behavior. Rollback: remove the optional field from signatures and redeploy; no persist/schema migration. Acceptance: unit tests for omit/false/true on both ops; `npm run typecheck` and `npm test` pass.

## Open Questions

None.

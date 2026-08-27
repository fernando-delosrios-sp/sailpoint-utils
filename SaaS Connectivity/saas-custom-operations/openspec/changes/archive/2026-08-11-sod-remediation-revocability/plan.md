# Plan: sod-remediation-revocability

**Goal:** Show revocable vs not-revocable access paths with UTF-8 emojis in form and email HTML; extend revoke payloads.

**Test command:** `npm test`

## Steps

1. Extend `access-path-resolver.ts` with revocability fields and recommended-revoke filtering
2. Add `revocability-labels.ts` with emoji constants and HTML line builder
3. Update `context.ts` to render structured paths in summary and group HTML formInput
4. Update `form-service.ts` types and seed JSON (TEXTAREA → DESCRIPTION)
5. Update specs/tests; run `npm test`; update CHANGELOG

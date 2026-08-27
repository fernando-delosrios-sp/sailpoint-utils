# Retrospective — add-isc-accounts-module

**Date**: 2026-08-11

## What went well

- Completing the ISC layout rule by adding `src/isc/accounts/` alongside existing per-API folders; spec tree now mirrors code for AccountsApi vs SourcesApi schema split.
- Extracting lookup/CRUD without changing persist behavior — full test suite stayed green (283 tests).
- Verification caught a minor gap (backslash OData escape test); fixed before archive.

## What was harder than expected

- `request-context.spec.ts` create-path test timed out until mocks returned a provisioning task id — upsert always runs post-create resolution retries when no task is returned.

## Misses / follow-ups

- None blocking.

## Process notes

- Archive sync promoted `target-client/accounts` sub-capability and layout updates to main specs.

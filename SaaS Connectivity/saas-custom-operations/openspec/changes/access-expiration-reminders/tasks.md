## 1. ISC identities module

- [x] 1.1 Add `src/isc/identities/` with search helper for identities that have ACCESS_PROFILE assignments with `removeDate`, manager id extraction, and `index.ts` barrel
- [x] 1.2 Add `offline-data.ts` fixtures with at least one identity+manager+expiring ACCESS_PROFILE suitable for UTC day matching
- [x] 1.3 Add unit tests for search mapping, manager absence, and offline path (`src/isc/identities/*.spec.ts`)

## 2. Forms expire contract tests

- [x] 2.1 Extend forms create-instance tests so caller-supplied `expire` is passed through (and default TTL still applies when omitted)

## 3. Operation scaffold and form seed

- [x] 3.1 Copy `_template` to `src/operations/access-expiration-reminders/` with `command: 'custom:access-expiration-reminders'`, OperationSignature input (`formName` required, `expirationDays?`), and prefixed output fields
- [x] 3.2 Add form seed JSON (situation context + required `newExpirationDate` DATE) and form-service ensure/create helpers wrapping `ensureFormDefinitionByName` / `createStandaloneFormInstance` with `expire = removeDate`
- [x] 3.3 Add form-email header/body builders (≤256 chars) and constants (`MAX_FORMS_PER_RUN = 25`, `childPersistIdentity`, default `expirationDays = 1`)
- [x] 3.4 Implement UTC calendar-day matching helper and unit tests (exact match / non-match)

## 4. Operation handler

- [x] 4.1 Implement scan loop: discover sunset assignments → match `expirationDays` → resolve manager + email → idempotent account check → form launch → child persist (`verify: false`) → reminder scan summary on `ctx.res.send`
- [x] 4.2 Enforce skips for missing manager/email and existing notice accounts; enforce 25-form cap with overflow counter and warning log
- [x] 4.3 Persist notice fields: identityId, managerId, accessProfileId, removeDate, daysRemaining, form-url, form-email-*
- [x] 4.4 Pass formInput `responseAccountId`, `identityId`, `accessProfileId`, plus friendly display context
- [x] 4.5 Run `npm run codegen:schemas` / build so auto-registry and `connector-spec.json` include the command

## 5. Operation tests and payloads

- [ ] 5.1 Add `index.spec.ts` covering: happy path persist + res.send summary; default expirationDays; missing formName failure; idempotent skip; missing manager/email skip; multi-AP accounts; form cap/overflow; zero matches; offline path
- [ ] 5.2 Add offline payload under `payloads/` and wire local invoke as needed for `call:op`

## 6. Workflows

- [ ] 6.1 Add `workflows/Access Expiration Reminders - Analysis.json` (daily 00:00 UTC, stable `requestId`, `formName`, `expirationDays: 1`) modeled on Access Model SOD Analysis
- [ ] 6.2 Add `workflows/Access Expiration Reminders - Notification.json` (`idn:account-created`, filter `operationName` = `custom:access-expiration-reminders`, Send Email from form-email fields)

## 7. Verification

- [ ] 7.1 Confirm canonical test command: `npm test`
- [ ] 7.2 Run `npm run typecheck`
- [ ] 7.3 All delta spec scenarios covered by named automated tests
- [ ] 7.4 Run `npm run call:op` against the offline payload and confirm summary on `res.send`
- [ ] 7.5 Run `npm run build` (or pack-zip) so codegen/registry/manifest stay in sync

## 8. Documentation

- [ ] 8.1 Write `src/operations/access-expiration-reminders/README.md` (command, inputs/outputs, matching, idempotency/`requestId` stability, workflows, local invoke)
- [ ] 8.2 Update root `README.md` supported-commands / workflow list for the new operation
- [ ] 8.3 Update `openspec/config.yaml` context supported-commands list if it enumerates commands

## 9. Changelog

- [ ] 9.1 Create changelog entry via changelog-generator skill during apply
- [ ] 9.2 Confirm entry documents new `custom:access-expiration-reminders`, notice-account contract, and importable workflows

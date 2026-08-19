## 1. Form notification module

- [x] 1.1 Create `src/lib/form-notification/` with `FormNotification` type and `toPersistAttributes(prefix, envelope)`
- [x] 1.2 Add unit tests for sod-remediation, access-model-sod-remediation, and access-expiration-reminders prefix mapping; recipients as `string[]`; no ISC calls

## 2. Migrate handlers

- [x] 2.1 Wire `custom:sod-remediation` persist (and logging helper if applicable) through the envelope mapper
- [x] 2.2 Wire `custom:access-model-sod-remediation` child persist through the envelope mapper
- [x] 2.3 Wire `custom:access-expiration-reminders` child persist through the envelope mapper — **N/A on main** (operation folder absent; prefix mapping covered in lib unit tests only)
- [x] 2.4 Keep existing handler tests green (same persist keys/values)

## 3. Verification

- [x] 3.1 Confirm canonical test command: `npm test`
- [x] 3.2 Run `npm run typecheck`
- [x] 3.3 All delta spec scenarios covered by named automated tests

## 4. Documentation

- [x] 4.1 Add `src/lib/form-notification/README.md` describing envelope fields and prefix mapping
- [x] 4.2 Optionally note envelope-backed outputs in the three operation READMEs (one line each) — noted on the two ops present on main; access-expiration-reminders N/A

## 5. Changelog

- [x] 5.1 Create or update changelog entry via changelog-generator during apply
- [x] 5.2 Confirm entry notes non-breaking internal envelope extraction

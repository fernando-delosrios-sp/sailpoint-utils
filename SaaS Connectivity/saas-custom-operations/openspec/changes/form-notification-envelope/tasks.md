## 1. Form notification module

- [ ] 1.1 Create `src/lib/form-notification/` with `FormNotification` type and `toPersistAttributes(prefix, envelope)`
- [ ] 1.2 Add unit tests for sod-remediation, access-model-sod-remediation, and access-expiration-reminders prefix mapping; recipients as `string[]`; no ISC calls

## 2. Migrate handlers

- [ ] 2.1 Wire `custom:sod-remediation` persist (and logging helper if applicable) through the envelope mapper
- [ ] 2.2 Wire `custom:access-model-sod-remediation` child persist through the envelope mapper
- [ ] 2.3 Wire `custom:access-expiration-reminders` child persist through the envelope mapper
- [ ] 2.4 Keep existing handler tests green (same persist keys/values)

## 3. Verification

- [ ] 3.1 Confirm canonical test command: `npm test`
- [ ] 3.2 Run `npm run typecheck`
- [ ] 3.3 All delta spec scenarios covered by named automated tests

## 4. Documentation

- [ ] 4.1 Add `src/lib/form-notification/README.md` describing envelope fields and prefix mapping
- [ ] 4.2 Optionally note envelope-backed outputs in the three operation READMEs (one line each)

## 5. Changelog

- [ ] 5.1 Create or update changelog entry via changelog-generator during apply
- [ ] 5.2 Confirm entry notes non-breaking internal envelope extraction

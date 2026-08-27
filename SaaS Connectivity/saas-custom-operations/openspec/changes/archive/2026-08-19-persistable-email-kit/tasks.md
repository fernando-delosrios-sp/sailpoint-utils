## 1. Persistable email kit

- [x] 1.1 Create `src/lib/persistable-email/` with `escapeHtml`, truncate-with-ellipsis, `renderUnquotedHrefCta`, and fit-to-budget helper supporting optional suffixes
- [x] 1.2 Add unit tests named after delta scenarios (escape, truncate, unquoted CTA, fit within STRING max, optional suffix dropped, no ISC side effects)
- [x] 1.3 Re-export or delegate `sod-form-html` `escapeHtml` from persistable-email; update sod-form-html tests if needed

## 2. Migrate callers

- [x] 2.1 Migrate `access-expiration-reminders/form-email.ts` to the kit; keep domain copy local; preserve existing tests — N/A on main (operation not present; deferred to abb/sibling branch)
- [x] 2.2 Migrate `access-model-sod-remediation/form-email.ts` to the kit
- [x] 2.3 Migrate sod-remediation persistable email body helpers in `context.ts` (truncate/fit/CTA) to the kit; keep situation header/copy local
- [x] 2.4 Migrate `access-request-status/email-templates.ts` to the kit — N/A on main (operation not present; deferred to abb/sibling branch)

## 3. Verification

- [x] 3.1 Confirm canonical test command: `npm test`
- [x] 3.2 Run `npm run typecheck`
- [x] 3.3 All delta spec scenarios covered by named automated tests

## 4. Documentation

- [x] 4.1 Add `src/lib/persistable-email/README.md` describing purpose, STRING limit, unquoted href, and boundary vs sod-form-html
- [x] 4.2 Update `src/lib/sod-form-html/README.md` with one-line pointer to persistable-email for workflow email bodies

## 5. Changelog

- [x] 5.1 Create or update changelog entry via changelog-generator during apply
- [x] 5.2 Confirm entry covers shared kit extraction (non-breaking)

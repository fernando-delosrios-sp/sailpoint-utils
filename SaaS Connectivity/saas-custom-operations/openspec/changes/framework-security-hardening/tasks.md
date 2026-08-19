## 1. Logger redaction

- [x] 1.1 Sanitize `detail` in `createFrameworkLogger` emit before console and POST paths
- [x] 1.2 Extend `logger.spec.ts` — assert stdout redacts token in detail; logUrl parity test

## 2. Caller-safe errors

- [x] 2.1 Update `toConnectorError` to omit raw API response bodies from caller message
- [x] 2.2 Log sanitized full context at error level with requestId
- [x] 2.3 Extend `connector-error.spec.ts` for API body exclusion and log correlation

## 3. OData escaping

- [x] 3.1 Use `escapeODataString` in `ensureFormDefinitionByName` filter construction
- [x] 3.2 Add forms spec cases for quoted form names
- [x] 3.3 Grep audit other OData string interpolations; fix trivial sites or document deferral in PR
  - Audit (deferred follow-up): `source-client.ts` (`sourceName`), `resolve-identity-email.ts` (UUID `identityId`), `access-model-sod-remediation/form-service.ts` (UUID `formDefinitionId`), `list-active-policy-names.ts` (UUID `identityId`). UUID/id fields are low injection risk; source-name escape is the next candidate.

## 4. Offline context helper

- [x] 4.1 Add shared `isOfflineContext` / partial-config guard under `src/framework/`
- [x] 4.2 Migrate all operations to shared helper (access-model, sod-remediation, preventive, governance, apply)
- [x] 4.3 Add framework spec for offline and partial-config scenarios

## 5. Verification

- [x] 5.1 Confirm canonical test command: `npm test`
- [x] 5.2 All delta spec scenarios covered by named automated tests

## 6. Documentation

- [x] 6.1 Update README if partial-config rejection needs explicit mention
- [x] 6.2 Update inline JSDoc on offline helper and connector-error behavior

## 7. Changelog

- [x] 7.1 Create or update changelog entry for this change
- [x] 7.2 Confirm entry covers logging, error, OData, and offline context changes

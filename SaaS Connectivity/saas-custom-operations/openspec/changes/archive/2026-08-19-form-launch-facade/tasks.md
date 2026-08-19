## 1. Form launch facade

- [x] 1.1 Create `src/lib/form-launch/` orchestrating ensure + createStandaloneFormInstance + form notification envelope assembly
- [x] 1.2 Support optional `expire` passthrough and post-create body builders that receive `formUrl`
- [x] 1.3 Add unit tests with mocked `FormsApiLike` covering ensure/create, notification pairing, expire passthrough, and no persist

## 2. Migrate operations

- [x] 2.1 Migrate `sod-remediation` form-service / handler onto the facade; thin or remove redundant wrappers
- [x] 2.2 Migrate `access-model-sod-remediation` onto the facade
- [x] 2.3 N/A — `access-expiration-reminders` is absent on `main`; facade expire passthrough is covered with a mock
- [x] 2.4 Keep operation seeds, serializers, recipient resolution, and persist/skip logic operation-local

## 3. Verification

- [x] 3.1 Confirm canonical test command: `npm test`
- [x] 3.2 Run `npm run typecheck`
- [x] 3.3 All delta spec scenarios covered by named automated tests

## 4. Documentation

- [x] 4.1 Add `src/lib/form-launch/README.md` describing config, return shape, and what stays op-local
- [x] 4.2 Update the three operation READMEs only if they document internal form-service module layout

## 5. Changelog

- [x] 5.1 Create or update changelog entry via changelog-generator during apply
- [x] 5.2 Confirm entry notes non-breaking form-launch extraction

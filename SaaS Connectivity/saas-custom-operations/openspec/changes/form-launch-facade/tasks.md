## 1. Form launch facade

- [ ] 1.1 Create `src/lib/form-launch/` orchestrating ensure + createStandaloneFormInstance + form notification envelope assembly
- [ ] 1.2 Support optional `expire` passthrough and post-create body builders that receive `formUrl`
- [ ] 1.3 Add unit tests with mocked `FormsApiLike` covering ensure/create, notification pairing, expire passthrough, and no persist

## 2. Migrate operations

- [ ] 2.1 Migrate `sod-remediation` form-service / handler onto the facade; thin or remove redundant wrappers
- [ ] 2.2 Migrate `access-model-sod-remediation` onto the facade
- [ ] 2.3 Migrate `access-expiration-reminders` onto the facade (including expire = removeDate)
- [ ] 2.4 Keep operation seeds, serializers, recipient resolution, and persist/skip logic operation-local

## 3. Verification

- [ ] 3.1 Confirm canonical test command: `npm test`
- [ ] 3.2 Run `npm run typecheck`
- [ ] 3.3 All delta spec scenarios covered by named automated tests

## 4. Documentation

- [ ] 4.1 Add `src/lib/form-launch/README.md` describing config, return shape, and what stays op-local
- [ ] 4.2 Update the three operation READMEs only if they document internal form-service module layout

## 5. Changelog

- [ ] 5.1 Create or update changelog entry via changelog-generator during apply
- [ ] 5.2 Confirm entry notes non-breaking form-launch extraction

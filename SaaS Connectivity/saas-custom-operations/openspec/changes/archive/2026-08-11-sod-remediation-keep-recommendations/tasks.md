## 1. ISC recommendations client

- [x] 1.1 Add `src/isc/recommendations/` batch fetch with offline canned data
- [x] 1.2 Add unit tests for recommendations client (live + offline + error)

## 2. Path expansion and metadata

- [x] 2.1 Add `grantedVia` tracking during access-path expansion
- [x] 2.2 Add entitlement history fetch for privileged flag; offline canned entitlements
- [x] 2.3 Merge keep recommendations onto `AccessPathLine`; stop UI use of connector `recommended` star

## 3. Side correction and HTML display

- [x] 3.1 Implement side correction algorithm (`recommendedSideToCorrect`)
- [x] 3.2 Update label module: “Not directly revocable”, named grantor, keep star, privileged badge
- [x] 3.3 Update `context.ts` for side hint in summary and form columns; extend hidden payload fields

## 4. Operation wiring and tests

- [x] 4.1 Wire recommendations + entitlement fetch in sod-remediation launch flow with silent degradation
- [x] 4.2 Update access-path-resolver, context, and operation unit tests for all spec scenarios
- [x] 4.3 Run `npm test` and update CHANGELOG

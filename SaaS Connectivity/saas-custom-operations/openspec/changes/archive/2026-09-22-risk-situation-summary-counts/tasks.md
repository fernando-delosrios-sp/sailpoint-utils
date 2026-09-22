## 1. Deciding rule in entitlement scoring

- [x] 1.1 Add a `DecidingRule` type to `src/operations/evaluate-access-request-risk/tiers.ts` with the two values rendered as `effective privilege` and `Risk metadata`
- [x] 1.2 Change `tierFromEntitlement` to return `{ tier, rule }`, omitting `rule` for a `Low` tier, keeping the tier values it computes today unchanged (D2)
- [x] 1.3 Attribute an entitlement matching both conditions to effective privilege, at High and at Medium (D3)
- [x] 1.4 Return no rule attribution for effective privilege when `considerPrivilege` is false
- [x] 1.5 Extend `tiers.spec.ts` with deciding-rule cases: privilege-only, metadata-only, both, neither, and `considerPrivilege` false

## 2. Risk drivers carry their rule

- [x] 2.1 Add the optional `rule` field to `RiskDriver` in `src/operations/evaluate-access-request-risk/evaluate.ts`
- [x] 2.2 Update `scoreEntitlement` to push the rule returned by `tierFromEntitlement`
- [x] 2.3 Push `Risk metadata` as the rule for role and access-profile drivers scoring above `Low`, leaving the existing pre-expansion push point untouched so a clean container stays a `Low` driver (D6)

## 3. Summary builder

- [x] 3.1 Rewrite `summarize` to count distinct `type:id` pairs rather than render labels (D5)
- [x] 3.2 Build the tally sentence: fixed order role, access profile, entitlement; omit zero counts; pluralize (D1)
- [x] 3.3 Build the Medium and High verdict sentence with per-type winning counts and the parenthesized rule split, omitting zero-count rules and ordering effective privilege first (D1, D4)
- [x] 3.4 Build the Low verdict sentence stating nothing scored Medium or High, replacing the bare `Low` constant
- [x] 3.5 Keep `contributingIds` behavior exactly as it is today, including empty for `Low`
- [x] 3.6 Keep the `fit()` call as a truncation backstop (D7)

## 4. Tests

- [x] 4.1 Replace the two `evaluate.spec.ts` assertions on `ENTITLEMENT:ent-high` and `ENTITLEMENT:ent-wrapped`, which the new format removes by design
- [x] 4.2 Assert the exact High summary string from the delta spec scenario, including both rules in the split
- [x] 4.3 Assert the exact Low summary string, and that it is never the bare `Low`
- [x] 4.4 Assert the single-rule split omits the zero-count rule
- [x] 4.5 Assert a role requested twice counts once, and an entitlement shared by two access profiles counts once
- [x] 4.6 Assert an absent type is omitted from the tally, and that counts are pluralized at 1 and above
- [x] 4.7 Assert a clean role holding a High entitlement appears in the tally but not in the winning counts
- [x] 4.8 Assert no name and no id appears in the summary, while `contributing-ids` still carries the driver ids
- [x] 4.9 Assert a fifty-driver evaluation stays within 256 characters and reports a count rather than a list

## 5. Verification

- [x] 5.1 Confirm canonical test command: `npm test`
- [x] 5.2 Run `npm run typecheck` to catch any other caller of the changed `tierFromEntitlement` signature
- [x] 5.3 All delta spec scenarios covered by named automated tests
- [x] 5.4 Run `npm run call:op -- payloads/evaluate-access-request-risk.json` and confirm the offline invoke prints the new summary shape

No `connector-spec.json` or codegen work: the command list, the `OperationSignature` output literal, and the persisted attribute keys are unchanged, so `index.schema.ts` and the manifest do not move. No spcx packaging validation: the change is pure string formatting inside an existing handler with no runtime or dependency surface.

## 6. Documentation

- [x] 6.1 Update the Output section of `src/operations/evaluate-access-request-risk/README.md` to describe the new summary format and show both the High and Low examples
- [x] 6.2 State in that README that the summary carries no names or ids, and that `contributing-ids` is the machine-readable path
- [x] 6.3 Update the JSDoc on `summarize` and `tierFromEntitlement` to describe the returned rule

## 7. Changelog

- [x] 7.1 Create the changelog entry for this change via the `changelog-generator` skill
- [x] 7.2 Confirm the entry covers the user-visible summary format change and notes that existing result accounts keep their old text

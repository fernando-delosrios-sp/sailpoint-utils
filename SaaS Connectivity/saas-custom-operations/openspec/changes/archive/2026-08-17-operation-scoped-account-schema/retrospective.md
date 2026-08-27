# Retrospective: operation-scoped-account-schema

> Written: 2026-08-17 (after verify PASS)

---

## 0. Evidence

- **Tests:** 401 passing (`npm test`)
- **Tasks done:** 16/16
- **OpenSpec validate:** 27/27 pass

---

## 1. Wins

- Minimal diff: thread `outputFields` through existing provisioning path; removed registry union helper
- Create-time and persist-time schema semantics now aligned
- Templates generator union preserved as operator reference without runtime coupling

## 2. Misses

- None blocking archive

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| Verify warning follow-up | Added `auto-creates core-only base schema when operationSchema is absent` integration test | Closed scenario coverage gap before archive |

## 4. Skill / workflow compliance

Apply → verify → sync → archive cycle completed; delta spec synced to main spec before move.

## 5. Surprises

- `example/index.spec.ts` needed fourth-arg assertion update for `resolveSourceByName(outputFields)`

## 6. Promote candidates

- Document operation-scoped vs templates union distinction in operator onboarding (README updated)

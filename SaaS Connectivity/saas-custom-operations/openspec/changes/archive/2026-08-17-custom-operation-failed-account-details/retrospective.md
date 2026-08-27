# Retrospective: custom-operation-failed-account-details

> Written: 2026-08-17 (after verify PASS)

---

## 0. Evidence

- **Tests:** 392 passing (`npm test`)
- **Tasks done:** 18/18
- **OpenSpec validate:** 27/27 pass
- **New files:** `failure-persist.ts`, `failure-persist.spec.ts`

---

## 1. Wins

- Uniform Get Accounts read path for failures via mandatory `details` + automatic failed-account persist
- Failure persist centralized in `customOperation` without handler changes
- Warning follow-up added targeted tests for verification-failure account, non-fatal persist, and exit code 1

## 2. Misses

- 📌 Init failures before `RequestContext` creation intentionally skip failure persist (design D4); spec scenario is conditional on persist availability

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| Catch-block direct persist | Failure persist only via `trackedRes.send` | Avoid double persist on catch + send path |

## 4. Skill / workflow compliance

All apply-phase steps followed; verify warnings addressed before archive.

## 5. Surprises

- Duplicate invoke path attempts failure persist against real ISC when not in test mode (logged warning only)

## 6. Promote candidates

- [ ] 📌 Document init-failure no-persist in design Open Questions closure → **One-off** (already noted in verify suggestions)

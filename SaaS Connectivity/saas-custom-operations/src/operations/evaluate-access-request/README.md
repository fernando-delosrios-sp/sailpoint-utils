# custom:evaluate-access-request

## Purpose

Scores access-request risk and/or preventive SoD in one invoke. Risk is on by default; SoD is off unless `evaluateSod` is true. When both run, they overlap and share an entitlement expansion cache. Enabled verdicts are persisted on one audit account (and mirrored in the HTTP `summary` for non-workflow callers). Workflows read the indexed account — `waitForPersist` defaults to true.

Risk scoring rules live in [`src/lib/access-request-risk/`](../../lib/access-request-risk/README.md). `custom:preventive-sod-check` remains for callers that are not scoring an access request.

## Command

`custom:evaluate-access-request`

## Input

| Field               | Required | Description                                                                                    |
| ------------------- | -------- | ---------------------------------------------------------------------------------------------- |
| `identityId`        | SoD      | Required when `evaluateSod` is true                                                            |
| `accessRequestId`   | No       | Selects request-mode SoD differential when set; risk fallback when `requestedItems` is omitted |
| `requestedItems`    | No\*     | Trigger items for risk scoring and as the SoD target request set                               |
| `considerPrivilege` | No       | Passed through to risk scoring (default `true`)                                                |
| `inflightOnly`      | No       | Passed through to preventive SoD (default `false`)                                             |
| `evaluateRisk`      | No       | Run risk scoring (default `true`). `false` omits risk from the summary and audit account       |
| `evaluateSod`       | No       | Run preventive SoD (default `false`). `true` requires `identityId`                             |
| `waitForPersist`    | No       | Defaults to `true`. Set `false` to submit the audit account write without verification polling |

\* Required in practice for deadline-bound wrappers; without it risk falls back to access-request status.

Setting both `evaluateRisk` and `evaluateSod` to `false` fails the invoke.

Wrapper `requestId` conventions (unchanged so Get Accounts filters stay stable):

| Wrapper                   | `requestId`                                                       | Flags               |
| ------------------------- | ----------------------------------------------------------------- | ------------------- |
| Access Request Pre-Check  | `access-request-precheck:{accessRequestId}:submitted`             | `evaluateSod: true` |
| Dynamic Approver          | `evaluate-access-request-risk:{accessRequestId}:dynamic`          | risk only (default) |
| Dynamic Approval Workflow | `evaluate-access-request-risk:{accessRequestId}:dynamic-approval` | risk only (default) |

## Output

Persisted on the invoke `requestId` (present only for the checks that ran):

| Field                                            | Source |
| ------------------------------------------------ | ------ |
| `evaluate-access-request-risk:tier`              | Risk   |
| `evaluate-access-request-risk:situation-summary` | Risk   |
| `evaluate-access-request-risk:contributing-ids`  | Risk   |
| `preventive-sod-check:has-violation`             | SoD    |
| `preventive-sod-check:situation-summary`         | SoD    |
| `preventive-sod-check:violated-policy-names`     | SoD    |

Response `summary` keys, present only for the checks that ran: `tier`, `situationSummary`, `contributingIds`, `hasViolation`, `sodSituationSummary`, `violatedPolicyNames`.

## Local invoke

```bash
npm run call:op -- payloads/evaluate-access-request.json
```

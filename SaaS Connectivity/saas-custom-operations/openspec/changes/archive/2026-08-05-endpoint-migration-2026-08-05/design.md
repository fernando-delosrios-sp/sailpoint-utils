## SDK strategy

All ISC loopback calls use typed `sailpoint-api-client` APIs on `ctx.sdk`. Experimental endpoints (outliers, recommendations) pass `xSailPointExperimental: 'true'`.

| Legacy fetch path | SDK API |
|---|---|
| access-request-status/v1 | `AccessRequestsApi.listAccessRequestStatusV1` |
| outliers/v1 | `IAIOutliersApi.getIdentityOutliersV1` |
| entitlements, roles, access-profiles | `EntitlementsApi`, `RolesApi`, `AccessProfilesApi` |
| sod-policies, sod-violations/predict | `SODPoliciesApi`, `SODViolationsApi` |
| recommendations/request | `IAIRecommendationsApi.getRecommendationsV1` |
| workgroups | `GovernanceGroupsApi` |
| identity entitlements | `IdentitiesApi.listEntitlementsByIdentityV1` |

## Persist contracts

### custom:access-request-status

| outputProfile | persisted attributes |
|---|---|
| approval-email | emailRoute, emailBodyHtml, bccEmails, accessOwnerId |
| ets-comment | preApprovalComment |

### custom:govgroup-emails

emails = governance group member email list (`string[]`)

### custom:access-request-threshold

thresholdHit, foundCount, sourceName, thresholdValue, requestedCount, pendingCount, grantedCount

### Deferred (invoke response only)

- `custom:check-sod-pending`

## Email length risk

**Deferred:** If `emailBodyHtml` exceeds dummy-source attribute limits, split to child persist id `${requestId}:email`. Not implemented in this change — monitor attribute size in POV; add split logic if limits are hit.


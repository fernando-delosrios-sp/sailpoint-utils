export {
    createEntitlementExpansionCache,
    expandAccessItemsToEntitlementIds,
    parseViolatedPolicies,
    parseViolatedPolicyNames,
    predictSodViolationsForIdentity,
} from './predict-violations'
export type { EntitlementExpansionClients, ExpandAccessItemsOptions } from './predict-violations'
export type { SodViolationPrediction } from './types'
export {
    OFFLINE_ROLE_ENTITLEMENT_IDS,
    OFFLINE_VIOLATION_PREDICTION,
    predictSodViolationsForIdentityOffline,
} from './offline-data'

/**
 * Risk scoring library used by `custom:evaluate-access-request`.
 * This module does not register a connector command.
 */
export { createAccessRiskCatalog, createLiveAccessRiskCatalog, createOfflineAccessRiskCatalog } from './catalog'
export type { AccessRiskCatalogOptions } from './catalog'
export { evaluateAccessRisk, normalizeRequestedItem } from './evaluate'
export type {
    AccessRiskCatalog,
    AccessRiskResult,
    EvaluateAccessRiskOptions,
    RequestedAccessItem,
    RequestedItemType,
    RiskDriver,
} from './evaluate'
export { resolveRequestedItems, toRequestedItemArray } from './resolve-items'
export type { EvaluateAccessRequestRiskInput, RequestedItemLike } from './resolve-items'
export { maxTier, parseConsiderPrivilege, tierFromEntitlement, tierFromRiskMetadata } from './tiers'
export type { DecidingRule, RiskTier } from './tiers'

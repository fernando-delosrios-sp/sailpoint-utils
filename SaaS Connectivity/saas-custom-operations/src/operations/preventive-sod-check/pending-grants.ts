import type { AccessRequestStatusItem } from '../../isc/access-requests/types'
import {
    listExecutingGrantAccessRequestsForIdentity,
    listExecutingGrantAccessRequestsForIdentityOffline,
    matchesAccessRequestId,
    resolveAccessRequestTrackingNumber,
} from '../../isc/access-requests'
import {
    extractAccessItemsFromEvents,
    searchEventsByTrackingNumberOffline,
    searchEventsByTrackingNumberWithRetry,
    type AccessItemRef,
} from '../../isc/events-search'
import {
    createEntitlementExpansionCache,
    expandAccessItemsToEntitlementIds,
    parseViolatedPolicies,
    predictSodViolationsForIdentity,
    predictSodViolationsForIdentityOffline,
    OFFLINE_ROLE_ENTITLEMENT_IDS,
    type ExpandAccessItemsOptions,
} from '../../isc/sod-prediction'
import { attachSodPolicyLevels } from '../../isc/sod-policies'
import {
    listActiveViolationPoliciesForIdentity,
    listActiveViolationPoliciesForIdentityOffline,
} from '../../isc/violations/list-active-policy-names'
import { deltaPolicies, unionPolicies, type PolicyNameRef } from '../../isc/violations/policy-name-sets'
import { type IscClientConfig } from '../../isc/http'
import { DEFAULT_ISC_CONCURRENCY, mapWithConcurrency } from '../../framework/concurrency'
import { SailPointClients } from '../../framework/types'

export interface ResolvePendingGrantEntitlementsOptions {
    sleep?: (ms: number) => Promise<void>
    onSkippedTrackingNumber?: (trackingNumber: string) => void
    /** Trigger-supplied items for the target request, avoiding mutable request status/event indexing. */
    requestedItems?: AccessItemRef[]
    concurrency?: number
    expansion?: ExpandAccessItemsOptions
}

export interface PreventiveSodEvaluation {
    hasViolation: boolean
    violatedPolicyNames: string[]
    violatedPolicies: PolicyNameRef[]
}

async function listExecutingGrantRequests(
    sdk: SailPointClients,
    identityId: string,
    offline: boolean
): Promise<AccessRequestStatusItem[]> {
    if (offline) {
        return listExecutingGrantAccessRequestsForIdentityOffline(identityId)
    }
    return listExecutingGrantAccessRequestsForIdentity(sdk.accessRequests, identityId)
}

async function resolveAccessItemsForTrackingNumber(
    sdk: SailPointClients,
    trackingNumber: string,
    offline: boolean,
    options: ResolvePendingGrantEntitlementsOptions
): Promise<AccessItemRef[]> {
    if (offline) {
        return extractAccessItemsFromEvents(searchEventsByTrackingNumberOffline(trackingNumber))
    }

    const events = await searchEventsByTrackingNumberWithRetry(sdk.search, trackingNumber, {
        sleep: options.sleep,
    })
    if (events.length === 0) {
        options.onSkippedTrackingNumber?.(trackingNumber)
    }
    return extractAccessItemsFromEvents(events)
}

async function resolveAccessItemsForGrantRequests(
    sdk: SailPointClients,
    requests: AccessRequestStatusItem[],
    offline: boolean,
    options: ResolvePendingGrantEntitlementsOptions
): Promise<AccessItemRef[]> {
    const concurrency = options.concurrency ?? DEFAULT_ISC_CONCURRENCY
    const perRequestItems = await mapWithConcurrency(requests, concurrency, async (request) => {
        const trackingNumber = resolveAccessRequestTrackingNumber(request)
        if (!trackingNumber) {
            return [] as AccessItemRef[]
        }
        return resolveAccessItemsForTrackingNumber(sdk, trackingNumber, offline, options)
    })

    const accessItems: AccessItemRef[] = []
    const seenItems = new Set<string>()
    for (const items of perRequestItems) {
        for (const item of items) {
            const key = `${item.type}:${item.id}`
            if (seenItems.has(key)) {
                continue
            }
            seenItems.add(key)
            accessItems.push(item)
        }
    }

    return accessItems
}

function unionAccessItems(left: AccessItemRef[], right: AccessItemRef[]): AccessItemRef[] {
    const items = new Map<string, AccessItemRef>()
    for (const item of [...left, ...right]) {
        items.set(`${item.type}:${item.id}`, item)
    }
    return [...items.values()]
}

function resolveExpansionOptions(
    sdk: SailPointClients,
    offline: boolean,
    options: ResolvePendingGrantEntitlementsOptions
): ExpandAccessItemsOptions {
    if (options.expansion) {
        return { concurrency: options.concurrency, ...options.expansion }
    }
    if (offline) {
        return { concurrency: options.concurrency }
    }
    return {
        concurrency: options.concurrency,
        ...createEntitlementExpansionCache(sdk),
    }
}

async function predictViolatedPoliciesForAccessItems(
    sdk: SailPointClients,
    identityId: string,
    accessItems: AccessItemRef[],
    offline: boolean,
    options: ResolvePendingGrantEntitlementsOptions = {}
): Promise<PolicyNameRef[]> {
    const expansion = resolveExpansionOptions(sdk, offline, options)
    const entitlementIds = offline
        ? accessItems.length > 0
            ? OFFLINE_ROLE_ENTITLEMENT_IDS
            : []
        : await expandAccessItemsToEntitlementIds(sdk, accessItems, expansion)

    const prediction = offline
        ? entitlementIds.length > 0
            ? predictSodViolationsForIdentityOffline(identityId)
            : { violationContexts: [] }
        : await predictSodViolationsForIdentity(sdk.sodViolations, identityId, entitlementIds)

    return parseViolatedPolicies(prediction)
}

async function predictViolatedPoliciesForEntitlementIds(
    sdk: SailPointClients,
    identityId: string,
    entitlementIds: string[],
    offline: boolean
): Promise<PolicyNameRef[]> {
    const prediction = offline
        ? entitlementIds.length > 0
            ? predictSodViolationsForIdentityOffline(identityId)
            : { violationContexts: [] }
        : await predictSodViolationsForIdentity(sdk.sodViolations, identityId, entitlementIds)

    return parseViolatedPolicies(prediction)
}

async function predictViolatedPoliciesForGrantRequests(
    sdk: SailPointClients,
    identityId: string,
    requests: AccessRequestStatusItem[],
    offline: boolean,
    options: ResolvePendingGrantEntitlementsOptions
): Promise<PolicyNameRef[]> {
    const accessItems = await resolveAccessItemsForGrantRequests(sdk, requests, offline, options)
    return predictViolatedPoliciesForAccessItems(sdk, identityId, accessItems, offline, options)
}

function toEvaluation(violatedPolicies: PolicyNameRef[]): PreventiveSodEvaluation {
    return {
        hasViolation: violatedPolicies.length > 0,
        violatedPolicyNames: violatedPolicies.map((policy) => policy.name),
        violatedPolicies,
    }
}

/** Evaluates preventive SoD — identity-wide or access-request-scoped depending on accessRequestId. */
export async function evaluatePreventiveSod(
    sdk: SailPointClients,
    identityId: string,
    accessRequestId: string | undefined,
    offline: boolean,
    clientConfig: IscClientConfig | null,
    options: ResolvePendingGrantEntitlementsOptions & { inflightOnly?: boolean } = {}
): Promise<PreventiveSodEvaluation> {
    const inflightOnly = options.inflightOnly === true
    const expansion = resolveExpansionOptions(sdk, offline, options)
    const optionsWithExpansion: ResolvePendingGrantEntitlementsOptions = { ...options, expansion }

    const [executingGrants, existingPolicies] = await Promise.all([
        listExecutingGrantRequests(sdk, identityId, offline),
        inflightOnly
            ? Promise.resolve([] as PolicyNameRef[])
            : offline
              ? Promise.resolve(listActiveViolationPoliciesForIdentityOffline(identityId))
              : clientConfig
                ? listActiveViolationPoliciesForIdentity(clientConfig, identityId)
                : Promise.resolve([] as PolicyNameRef[]),
    ])

    let violatedPolicies: PolicyNameRef[]

    if (accessRequestId) {
        const otherGrants = executingGrants.filter((request) => !matchesAccessRequestId(request, accessRequestId))
        const suppliedRequestItems = options.requestedItems ?? []
        let baselinePolicies: PolicyNameRef[]
        let fullPolicies: PolicyNameRef[]
        if (suppliedRequestItems.length > 0) {
            const baselineItems = await resolveAccessItemsForGrantRequests(
                sdk,
                otherGrants,
                offline,
                optionsWithExpansion
            )
            const baselineEntitlementIds = offline
                ? baselineItems.length > 0
                    ? OFFLINE_ROLE_ENTITLEMENT_IDS
                    : []
                : await expandAccessItemsToEntitlementIds(sdk, baselineItems, expansion)
            const fullItems = unionAccessItems(baselineItems, suppliedRequestItems)
            const fullEntitlementIds = offline
                ? fullItems.length > 0
                    ? OFFLINE_ROLE_ENTITLEMENT_IDS
                    : []
                : await expandAccessItemsToEntitlementIds(sdk, fullItems, expansion)

            ;[baselinePolicies, fullPolicies] = await Promise.all([
                predictViolatedPoliciesForEntitlementIds(sdk, identityId, baselineEntitlementIds, offline),
                predictViolatedPoliciesForEntitlementIds(sdk, identityId, fullEntitlementIds, offline),
            ])
        } else {
            ;[baselinePolicies, fullPolicies] = await Promise.all([
                predictViolatedPoliciesForGrantRequests(
                    sdk,
                    identityId,
                    otherGrants,
                    offline,
                    optionsWithExpansion
                ),
                predictViolatedPoliciesForGrantRequests(
                    sdk,
                    identityId,
                    executingGrants,
                    offline,
                    optionsWithExpansion
                ),
            ])
        }
        const requestDelta = deltaPolicies(fullPolicies, baselinePolicies)
        violatedPolicies = inflightOnly ? requestDelta : unionPolicies(existingPolicies, requestDelta)
    } else {
        const predictivePolicies = await predictViolatedPoliciesForGrantRequests(
            sdk,
            identityId,
            executingGrants,
            offline,
            optionsWithExpansion
        )
        violatedPolicies = unionPolicies(existingPolicies, predictivePolicies)
    }

    return toEvaluation(
        await attachSodPolicyLevels(sdk, violatedPolicies, offline, { concurrency: options.concurrency })
    )
}

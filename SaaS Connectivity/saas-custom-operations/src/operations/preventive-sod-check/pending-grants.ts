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
    expandAccessItemsToEntitlementIds,
    parseViolatedPolicies,
    predictSodViolationsForIdentity,
    predictSodViolationsForIdentityOffline,
    OFFLINE_ROLE_ENTITLEMENT_IDS,
} from '../../isc/sod-prediction'
import { attachSodPolicyLevels } from '../../isc/sod-policies'
import {
    listActiveViolationPoliciesForIdentity,
    listActiveViolationPoliciesForIdentityOffline,
} from '../../isc/violations/list-active-policy-names'
import { deltaPolicies, unionPolicies, type PolicyNameRef } from '../../isc/violations/policy-name-sets'
import { type IscClientConfig } from '../../isc/http'
import { SailPointClients } from '../../framework/types'

export interface ResolvePendingGrantEntitlementsOptions {
    sleep?: (ms: number) => Promise<void>
    onSkippedTrackingNumber?: (trackingNumber: string) => void
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
    const accessItems: AccessItemRef[] = []
    const seenItems = new Set<string>()

    for (const request of requests) {
        const trackingNumber = resolveAccessRequestTrackingNumber(request)
        if (!trackingNumber) {
            continue
        }

        const items = await resolveAccessItemsForTrackingNumber(sdk, trackingNumber, offline, options)
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

async function predictViolatedPoliciesForAccessItems(
    sdk: SailPointClients,
    identityId: string,
    accessItems: AccessItemRef[],
    offline: boolean
): Promise<PolicyNameRef[]> {
    const entitlementIds = offline
        ? accessItems.length > 0
            ? OFFLINE_ROLE_ENTITLEMENT_IDS
            : []
        : await expandAccessItemsToEntitlementIds(sdk, accessItems)

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
    return predictViolatedPoliciesForAccessItems(sdk, identityId, accessItems, offline)
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
    const executingGrants = await listExecutingGrantRequests(sdk, identityId, offline)

    const existingPolicies =
        inflightOnly
            ? []
            : offline
              ? listActiveViolationPoliciesForIdentityOffline(identityId)
              : clientConfig
                ? await listActiveViolationPoliciesForIdentity(clientConfig, identityId)
                : []

    let violatedPolicies: PolicyNameRef[]

    if (accessRequestId) {
        const otherGrants = executingGrants.filter((request) => !matchesAccessRequestId(request, accessRequestId))
        const baselinePolicies = await predictViolatedPoliciesForGrantRequests(
            sdk,
            identityId,
            otherGrants,
            offline,
            options
        )
        const fullPolicies = await predictViolatedPoliciesForGrantRequests(
            sdk,
            identityId,
            executingGrants,
            offline,
            options
        )
        const requestDelta = deltaPolicies(fullPolicies, baselinePolicies)
        violatedPolicies = inflightOnly ? requestDelta : unionPolicies(existingPolicies, requestDelta)
    } else {
        const predictivePolicies = await predictViolatedPoliciesForGrantRequests(
            sdk,
            identityId,
            executingGrants,
            offline,
            options
        )
        violatedPolicies = unionPolicies(existingPolicies, predictivePolicies)
    }

    return toEvaluation(await attachSodPolicyLevels(sdk, violatedPolicies, offline))
}

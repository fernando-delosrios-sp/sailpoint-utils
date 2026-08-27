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
    parseViolatedPolicyNames,
    predictSodViolationsForIdentity,
    predictSodViolationsForIdentityOffline,
    OFFLINE_ROLE_ENTITLEMENT_IDS,
} from '../../isc/sod-prediction'
import {
    listActiveViolationPolicyNamesForIdentity,
    listActiveViolationPolicyNamesForIdentityOffline,
} from '../../isc/violations/list-active-policy-names'
import { deltaPolicyNames, unionPolicyNames } from '../../isc/violations/policy-name-sets'
import { type IscClientConfig } from '../../isc/http'
import { SailPointClients } from '../../framework/types'

export interface ResolvePendingGrantEntitlementsOptions {
    sleep?: (ms: number) => Promise<void>
    onSkippedTrackingNumber?: (trackingNumber: string) => void
}

export interface PreventiveSodEvaluation {
    hasViolation: boolean
    violatedPolicyNames: string[]
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

async function predictViolatedPolicyNamesForAccessItems(
    sdk: SailPointClients,
    identityId: string,
    accessItems: AccessItemRef[],
    offline: boolean
): Promise<string[]> {
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

    return parseViolatedPolicyNames(prediction)
}

async function predictViolatedPolicyNamesForGrantRequests(
    sdk: SailPointClients,
    identityId: string,
    requests: AccessRequestStatusItem[],
    offline: boolean,
    options: ResolvePendingGrantEntitlementsOptions
): Promise<string[]> {
    const accessItems = await resolveAccessItemsForGrantRequests(sdk, requests, offline, options)
    return predictViolatedPolicyNamesForAccessItems(sdk, identityId, accessItems, offline)
}

/** Evaluates preventive SoD — identity-wide or access-request-scoped depending on accessRequestId. */
export async function evaluatePreventiveSod(
    sdk: SailPointClients,
    identityId: string,
    accessRequestId: string | undefined,
    offline: boolean,
    clientConfig: IscClientConfig | null,
    options: ResolvePendingGrantEntitlementsOptions = {}
): Promise<PreventiveSodEvaluation> {
    const executingGrants = await listExecutingGrantRequests(sdk, identityId, offline)

    if (accessRequestId) {
        const otherGrants = executingGrants.filter((request) => !matchesAccessRequestId(request, accessRequestId))
        const baselinePolicyNames = await predictViolatedPolicyNamesForGrantRequests(
            sdk,
            identityId,
            otherGrants,
            offline,
            options
        )
        const fullPolicyNames = await predictViolatedPolicyNamesForGrantRequests(
            sdk,
            identityId,
            executingGrants,
            offline,
            options
        )
        const violatedPolicyNames = deltaPolicyNames(fullPolicyNames, baselinePolicyNames)
        return {
            hasViolation: violatedPolicyNames.length > 0,
            violatedPolicyNames,
        }
    }

    const existingPolicyNames = offline
        ? listActiveViolationPolicyNamesForIdentityOffline(identityId)
        : clientConfig
          ? await listActiveViolationPolicyNamesForIdentity(clientConfig, identityId)
          : []

    const predictivePolicyNames = await predictViolatedPolicyNamesForGrantRequests(
        sdk,
        identityId,
        executingGrants,
        offline,
        options
    )
    const violatedPolicyNames = unionPolicyNames(existingPolicyNames, predictivePolicyNames)

    return {
        hasViolation: violatedPolicyNames.length > 0,
        violatedPolicyNames,
    }
}

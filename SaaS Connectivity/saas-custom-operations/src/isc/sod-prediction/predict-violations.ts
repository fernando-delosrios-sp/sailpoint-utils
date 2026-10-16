import { AccessProfilesApi, RolesApi, SODViolationsApi } from 'sailpoint-api-client'
import type { SodViolationPrediction } from './types'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { toConnectorError } from '../../framework/connector-error'
import { DEFAULT_ISC_CONCURRENCY, mapWithConcurrency, memoizeAsync } from '../../framework/concurrency'
import { listAccessProfileEntitlementIds } from '../access-profiles/access-profile-entitlements'
import { listRoleEntitlementIds } from '../roles/role-entitlements'
import { AccessItemRef } from '../events-search/types'

/** Predicts SoD violations for an identity with additional entitlement access. */
export async function predictSodViolationsForIdentity(
    sodViolations: SODViolationsApi,
    identityId: string,
    entitlementIds: string[]
): Promise<SodViolationPrediction> {
    if (entitlementIds.length === 0) {
        return { violationContexts: [] }
    }

    try {
        const response = await sodViolations.startPredictSodViolationsV1({
            identityWithNewAccess: {
                identityId,
                accessRefs: entitlementIds.map((id) => ({
                    id,
                    type: 'ENTITLEMENT',
                })),
            },
        })
        return response.data ?? { violationContexts: [] }
    } catch (error) {
        throw toConnectorError(error, 'SoD predict API failed')
    }
}

/** Extracts violated policies from a predict response, preserving API order. */
export function parseViolatedPolicies(prediction: SodViolationPrediction): Array<{
    id?: string
    name: string
    level?: string
}> {
    const policies: Array<{ id?: string; name: string; level?: string }> = []
    const seen = new Set<string>()

    for (const context of prediction.violationContexts ?? []) {
        const name = context.policy?.name
        if (!name || seen.has(name)) {
            continue
        }
        seen.add(name)
        const policy: { id?: string; name: string; level?: string } = { name }
        if (context.policy?.id) {
            policy.id = context.policy.id
        }
        if (context.policy?.level) {
            policy.level = context.policy.level
        }
        policies.push(policy)
    }

    return policies
}

/** Extracts violated policy names from a predict response, preserving API order. */
export function parseViolatedPolicyNames(prediction: SodViolationPrediction): string[] {
    return parseViolatedPolicies(prediction).map((policy) => policy.name)
}

export interface EntitlementExpansionClients {
    roles: RolesApi
    accessProfiles: AccessProfilesApi
}

export interface ExpandAccessItemsOptions {
    concurrency?: number
    listRoleEntitlementIds?: (roleId: string) => Promise<string[]>
    listAccessProfileEntitlementIds?: (accessProfileId: string) => Promise<string[]>
}

/**
 * Builds request-scoped memoized role/access-profile entitlement expanders for sharing
 * across risk scoring and SoD prediction in one invocation.
 */
export function createEntitlementExpansionCache(clients: EntitlementExpansionClients): {
    listRoleEntitlementIds: (roleId: string) => Promise<string[]>
    listAccessProfileEntitlementIds: (accessProfileId: string) => Promise<string[]>
} {
    return {
        listRoleEntitlementIds: memoizeAsync((roleId) => listRoleEntitlementIds(clients.roles, roleId)),
        listAccessProfileEntitlementIds: memoizeAsync((accessProfileId) =>
            listAccessProfileEntitlementIds(clients.accessProfiles, accessProfileId)
        ),
    }
}

/** Expands access item refs to deduplicated entitlement ids suitable for predict. */
export async function expandAccessItemsToEntitlementIds(
    clients: EntitlementExpansionClients,
    items: AccessItemRef[],
    options: ExpandAccessItemsOptions = {}
): Promise<string[]> {
    const concurrency = options.concurrency ?? DEFAULT_ISC_CONCURRENCY
    const listRoleIds =
        options.listRoleEntitlementIds ?? ((id: string) => listRoleEntitlementIds(clients.roles, id))
    const listProfileIds =
        options.listAccessProfileEntitlementIds ??
        ((id: string) => listAccessProfileEntitlementIds(clients.accessProfiles, id))

    const resolvedPerItem = await mapWithConcurrency(items, concurrency, async (item) => {
        switch (item.type) {
            case 'ENTITLEMENT':
                return [item.id]
            case 'ROLE':
                return listRoleIds(item.id)
            case 'ACCESS_PROFILE':
                return listProfileIds(item.id)
            default:
                throw new ConnectorError(`Unsupported access item type: ${String(item.type)}`)
        }
    })

    const entitlementIds: string[] = []
    const seen = new Set<string>()
    for (const resolved of resolvedPerItem) {
        for (const id of resolved) {
            if (!seen.has(id)) {
                seen.add(id)
                entitlementIds.push(id)
            }
        }
    }

    return entitlementIds
}

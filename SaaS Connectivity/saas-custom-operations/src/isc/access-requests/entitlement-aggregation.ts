import {
    AccessProfilesApi,
    AccessRequestsApi,
    EntitlementsApi,
    IdentitiesApi,
    RolesApi,
} from 'sailpoint-api-client'
import type {
    EntitlementDetail,
    EntitlementRef,
    GetAccessRequestStatus,
    RequestedItemType,
    RoleDetail,
} from './entitlement-types'

export interface EntitlementAggregationClients {
    accessRequests: AccessRequestsApi
    entitlements: EntitlementsApi
    accessProfiles: AccessProfilesApi
    roles: RolesApi
    identities: IdentitiesApi
}

function deduplicateEntitlements(entitlements: EntitlementRef[]): EntitlementRef[] {
    const map = new Map<string, EntitlementRef>()
    for (const ent of entitlements) {
        if (ent?.id) {
            map.set(ent.id, ent)
        }
    }
    return Array.from(map.values())
}

async function resolveEntitlement(
    entitlements: EntitlementsApi,
    id: string
): Promise<EntitlementRef[]> {
    if (!id) {
        return []
    }

    try {
        const response = await entitlements.getEntitlementV1({ id })
        const detail = response.data as EntitlementDetail | undefined
        if (!detail?.id) {
            return []
        }

        return [
            {
                type: 'ENTITLEMENT',
                id: detail.id,
                ...(detail.name !== undefined && { name: detail.name }),
                ...(detail.source?.id && {
                    source: {
                        id: detail.source.id,
                        ...(detail.source.name !== undefined && { name: detail.source.name }),
                    },
                }),
            },
        ]
    } catch (error) {
        console.error(`[entitlement-aggregation] Error resolving entitlement ${id}:`, error)
        return []
    }
}

async function resolveAccessProfile(
    clients: Pick<EntitlementAggregationClients, 'accessProfiles' | 'entitlements'>,
    id: string
): Promise<EntitlementRef[]> {
    try {
        const response = await clients.accessProfiles.getAccessProfileEntitlementsV1({ id })
        const entitlementsRaw = response.data ?? []
        return entitlementsRaw
            .filter((item) => item.id)
            .map((item) => ({
                type: 'ENTITLEMENT' as const,
                id: item.id!,
                name: item.name,
                ...(item.source?.id && {
                    source: {
                        id: item.source.id,
                        name: item.source.name,
                    },
                }),
            }))
    } catch (error) {
        console.error(`[entitlement-aggregation] Error resolving access profile ${id}:`, error)
        return []
    }
}

async function resolveRole(
    clients: Pick<EntitlementAggregationClients, 'accessProfiles' | 'entitlements' | 'roles'>,
    id: string
): Promise<EntitlementRef[]> {
    try {
        const [detailResponse, entitlementsResponse] = await Promise.all([
            clients.roles.getRoleV1({ id }),
            clients.roles.getRoleEntitlementsV1({ id }),
        ])

        const detail = detailResponse.data as RoleDetail | undefined
        const directEntitlementsRaw = entitlementsResponse.data ?? []
        const allEntitlements: EntitlementRef[] = directEntitlementsRaw
            .filter((item) => item.id)
            .map((item) => ({
                type: 'ENTITLEMENT' as const,
                id: item.id!,
                name: item.name,
                ...(item.source?.id && {
                    source: {
                        id: item.source.id,
                        name: item.source.name,
                    },
                }),
            }))

        if (detail?.accessProfiles?.length) {
            const profileEntitlements = await Promise.all(
                detail.accessProfiles.map((profile) => resolveAccessProfile(clients, profile.id))
            )
            allEntitlements.push(...profileEntitlements.flat())
        }

        return deduplicateEntitlements(allEntitlements)
    } catch (error) {
        console.error(`[entitlement-aggregation] Error resolving role ${id}:`, error)
        return []
    }
}

async function resolveRequestedItemEntitlements(
    clients: EntitlementAggregationClients,
    id: string,
    type: RequestedItemType
): Promise<EntitlementRef[]> {
    switch (type) {
        case 'ENTITLEMENT':
            return resolveEntitlement(clients.entitlements, id)
        case 'ACCESS_PROFILE':
            return resolveAccessProfile(clients, id)
        case 'ROLE':
            return resolveRole(clients, id)
        default:
            return []
    }
}

/** Resolves underlying entitlements for a requested access item. */
export async function getUnderlyingEntitlements(
    clients: EntitlementAggregationClients,
    status: GetAccessRequestStatus
): Promise<EntitlementRef[]> {
    if (!status?.type || !status.id) {
        return []
    }
    return resolveRequestedItemEntitlements(clients, status.id, status.type)
}

/** Lists entitlements from other EXECUTING access requests for the same identity. */
export async function getPendingEntitlements(
    clients: EntitlementAggregationClients,
    identityId: string,
    currentAccessRequestId: string
): Promise<EntitlementRef[]> {
    if (!identityId) {
        return []
    }

    try {
        const response = await clients.accessRequests.listAccessRequestStatusV1({
            requestState: 'EXECUTING',
            requestedFor: identityId,
        })
        const openRequests = response.data ?? []
        const excludeId = currentAccessRequestId === 'none' ? null : currentAccessRequestId
        const otherPending = excludeId
            ? openRequests.filter((item) => item.accessRequestId !== excludeId)
            : openRequests

        if (otherPending.length === 0) {
            return []
        }

        const entitlementLists = await Promise.all(
            otherPending.map((item) => {
                const type = item.type as RequestedItemType | undefined
                if (!type || !item.id) {
                    return Promise.resolve([] as EntitlementRef[])
                }
                return resolveRequestedItemEntitlements(clients, item.id, type)
            })
        )

        return deduplicateEntitlements(entitlementLists.flat())
    } catch (error) {
        console.error(`[entitlement-aggregation] Error fetching pending access for identity ${identityId}:`, error)
        return []
    }
}

/** Lists entitlements currently granted to an identity. */
export async function getGrantedEntitlements(
    clients: Pick<EntitlementAggregationClients, 'identities' | 'entitlements' | 'accessProfiles' | 'roles'>,
    identityId: string
): Promise<EntitlementRef[]> {
    if (!identityId) {
        return []
    }

    try {
        const response = await clients.identities.listEntitlementsByIdentityV1({ id: identityId })
        const grantedItems = response.data ?? []
        if (grantedItems.length === 0) {
            return []
        }

        const entitlementLists = await Promise.all(
            grantedItems
                .map((item) => item.objectRef?.id ?? '')
                .filter(Boolean)
                .map((id) => resolveEntitlement(clients.entitlements, id))
        )
        return deduplicateEntitlements(entitlementLists.flat())
    } catch (error) {
        console.error(`[entitlement-aggregation] Error fetching granted entitlements for identity ${identityId}:`, error)
        return []
    }
}

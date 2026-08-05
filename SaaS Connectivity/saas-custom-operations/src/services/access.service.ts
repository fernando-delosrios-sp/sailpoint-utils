import { SAILPOINT_EXPERIMENTAL } from '../framework/sdk-factory'
import type { SailPointClients } from '../framework/types'
import type {
    AccessRequestStatusPayload,
    EntitlementDetail,
    EntitlementRef,
    GetAccessRequestStatus,
    RequestedItemType,
    RoleDetail,
    XdrData,
} from './types'

export class AccessService {
    constructor(private sdk: SailPointClients) {}

    async fetchAccessRequestById(accessRequestId: string): Promise<GetAccessRequestStatus | null> {
        try {
            const response = await this.sdk.accessRequests.listAccessRequestStatusV1({
                filters: `accessRequestId eq "${accessRequestId}"`,
            })
            const items = response.data ?? []
            return (items[0] as GetAccessRequestStatus | undefined) ?? null
        } catch (error) {
            console.error(`[AccessService] Error fetching access request ${accessRequestId}:`, error)
            return null
        }
    }

    async fetchOutlierByIdentityId(identityId: string): Promise<XdrData | null> {
        try {
            const response = await this.sdk.iaiOutliers.getIdentityOutliersV1({
                filters: `identityId eq "${identityId}"`,
                xSailPointExperimental: SAILPOINT_EXPERIMENTAL,
            })
            const items = response.data ?? []
            return (items[0] as XdrData | undefined) ?? null
        } catch (error) {
            console.error(`[AccessService] Error fetching outlier for identity ${identityId}:`, error)
            return null
        }
    }

    async getRequestedItemMetadata(id: string, type: RequestedItemType): Promise<Record<string, unknown> | null> {
        try {
            if (type === 'ROLE') {
                const response = await this.sdk.roles.getRoleV1({ id })
                return (response.data?.accessModelMetadata as Record<string, unknown> | undefined) ?? null
            }
            if (type === 'ACCESS_PROFILE') {
                const response = await this.sdk.accessProfiles.getAccessProfileV1({ id })
                return (response.data?.accessModelMetadata as Record<string, unknown> | undefined) ?? null
            }
            const response = await this.sdk.entitlements.getEntitlementV1({ id })
            return (response.data?.accessModelMetadata as Record<string, unknown> | undefined) ?? null
        } catch (error) {
            console.error(`[AccessService] Error fetching metadata for ${type} ${id}:`, error)
            return null
        }
    }

    async getRequestedItemOwnerId(id: string, type: RequestedItemType): Promise<string> {
        try {
            if (type === 'ROLE') {
                const response = await this.sdk.roles.getRoleV1({ id })
                return response.data?.owner?.id ?? 'N/A'
            }
            if (type === 'ACCESS_PROFILE') {
                const response = await this.sdk.accessProfiles.getAccessProfileV1({ id })
                return response.data?.owner?.id ?? 'N/A'
            }
            const response = await this.sdk.entitlements.getEntitlementV1({ id })
            return response.data?.owner?.id ?? 'N/A'
        } catch (error) {
            console.error(`[AccessService] Error fetching owner for ${type} ${id}:`, error)
            return 'N/A'
        }
    }

    buildPayload(status: GetAccessRequestStatus, xdrData: XdrData | null): AccessRequestStatusPayload {
        return {
            getAccessRequestStatus: status,
            getXdrData: xdrData,
        }
    }

    async getUnderlyingEntitlements(payload: AccessRequestStatusPayload): Promise<EntitlementRef[]> {
        const status = payload.getAccessRequestStatus
        if (!status?.type || !status.id) {
            return []
        }

        switch (status.type) {
            case 'ENTITLEMENT':
                return this.resolveEntitlement(status.id)
            case 'ACCESS_PROFILE':
                return this.resolveAccessProfile(status.id)
            case 'ROLE':
                return this.resolveRole(status.id)
            default:
                return []
        }
    }

    async getPendingEntitlements(identityId: string, currentAccessRequestId: string): Promise<EntitlementRef[]> {
        if (!identityId) {
            return []
        }

        try {
            const response = await this.sdk.accessRequests.listAccessRequestStatusV1({
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
                    switch (type) {
                        case 'ENTITLEMENT':
                            return this.resolveEntitlement(item.id)
                        case 'ACCESS_PROFILE':
                            return this.resolveAccessProfile(item.id)
                        case 'ROLE':
                            return this.resolveRole(item.id)
                        default:
                            return Promise.resolve([] as EntitlementRef[])
                    }
                })
            )

            return this.deduplicateEntitlements(entitlementLists.flat())
        } catch (error) {
            console.error(`[AccessService] Error fetching pending access for identity ${identityId}:`, error)
            return []
        }
    }

    async getGrantedEntitlements(identityId: string): Promise<EntitlementRef[]> {
        if (!identityId) {
            return []
        }

        try {
            const response = await this.sdk.identities.listEntitlementsByIdentityV1({ id: identityId })
            const grantedItems = response.data ?? []
            if (grantedItems.length === 0) {
                return []
            }

            const entitlementLists = await Promise.all(
                grantedItems
                    .map((item) => item.objectRef?.id ?? '')
                    .filter(Boolean)
                    .map((id) => this.resolveEntitlement(id))
            )
            return this.deduplicateEntitlements(entitlementLists.flat())
        } catch (error) {
            console.error(`[AccessService] Error fetching granted entitlements for identity ${identityId}:`, error)
            return []
        }
    }

    private async resolveEntitlement(id: string): Promise<EntitlementRef[]> {
        if (!id) {
            return []
        }

        try {
            const response = await this.sdk.entitlements.getEntitlementV1({ id })
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
            console.error(`[AccessService] Error resolving entitlement ${id}:`, error)
            return []
        }
    }

    private async resolveAccessProfile(id: string): Promise<EntitlementRef[]> {
        try {
            const response = await this.sdk.accessProfiles.getAccessProfileEntitlementsV1({ id })
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
            console.error(`[AccessService] Error resolving access profile ${id}:`, error)
            return []
        }
    }

    private async resolveRole(id: string): Promise<EntitlementRef[]> {
        try {
            const [detailResponse, entitlementsResponse] = await Promise.all([
                this.sdk.roles.getRoleV1({ id }),
                this.sdk.roles.getRoleEntitlementsV1({ id }),
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
                    detail.accessProfiles.map((profile) => this.resolveAccessProfile(profile.id))
                )
                allEntitlements.push(...profileEntitlements.flat())
            }

            return this.deduplicateEntitlements(allEntitlements)
        } catch (error) {
            console.error(`[AccessService] Error resolving role ${id}:`, error)
            return []
        }
    }

    private deduplicateEntitlements(entitlements: EntitlementRef[]): EntitlementRef[] {
        const map = new Map<string, EntitlementRef>()
        for (const ent of entitlements) {
            if (ent?.id) {
                map.set(ent.id, ent)
            }
        }
        return Array.from(map.values())
    }
}

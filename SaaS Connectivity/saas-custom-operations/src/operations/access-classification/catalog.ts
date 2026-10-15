import { AccessProfilesApi, EntitlementsApi, RolesApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../../isc/debug/log-isc-request'
import type { PrivilegeLevel } from './classify'

const PAGE_SIZE = 250

export interface EntitlementCatalogItem {
    id: string
    privilegeLevel?: PrivilegeLevel
    metadata?: unknown
}

export interface AccessProfileCatalogItem {
    id: string
    entitlementIds: string[]
    metadata?: unknown
}

export interface RoleCatalogItem {
    id: string
    accessProfileIds: string[]
    entitlementIds: string[]
    metadata?: unknown
}

function refIds(items: Array<{ id?: string } | undefined> | null | undefined): string[] {
    if (!items) {
        return []
    }
    const ids: string[] = []
    for (const item of items) {
        if (item?.id) {
            ids.push(item.id)
        }
    }
    return ids
}

/**
 * Pages every entitlement with privilege and access-model metadata.
 * Uses id sort plus searchAfter. Offset paging stops at 10,000 rows, and this tenant has more entitlements than that.
 */
export async function listEntitlementCatalog(entitlements: EntitlementsApi): Promise<EntitlementCatalogItem[]> {
    const items: EntitlementCatalogItem[] = []
    let searchAfter: string | undefined
    try {
        while (true) {
            const request: { limit: number; sorters: string; searchAfter?: string } = {
                limit: PAGE_SIZE,
                sorters: 'id',
            }
            if (searchAfter) {
                request.searchAfter = searchAfter
            }
            logIscDebug('listEntitlementCatalog listEntitlementsV1 request', request)
            const response = await entitlements.listEntitlementsV1(request)
            const page = response.data ?? []
            for (const row of page) {
                if (!row.id) {
                    continue
                }
                items.push({
                    id: row.id,
                    privilegeLevel: row.privilegeLevel
                        ? {
                              effective: row.privilegeLevel.effective,
                              direct: row.privilegeLevel.direct,
                          }
                        : undefined,
                    metadata: row.accessModelMetadata,
                })
            }
            if (page.length < PAGE_SIZE) {
                break
            }
            const lastId = page[page.length - 1]?.id
            if (!lastId || lastId === searchAfter) {
                break
            }
            searchAfter = lastId
        }
        return items
    } catch (error) {
        logIscRequestFailure('listEntitlementCatalog listEntitlementsV1', error)
        throw toConnectorError(error, 'Failed to list entitlements')
    }
}

/** Pages all access profiles with entitlement refs and metadata. */
export async function listAccessProfileCatalog(
    accessProfiles: AccessProfilesApi
): Promise<AccessProfileCatalogItem[]> {
    const items: AccessProfileCatalogItem[] = []
    let offset = 0
    try {
        while (true) {
            const request = { offset, limit: PAGE_SIZE }
            logIscDebug('listAccessProfileCatalog listAccessProfilesV1 request', request)
            const response = await accessProfiles.listAccessProfilesV1(request)
            const page = response.data ?? []
            for (const row of page) {
                if (!row.id) {
                    continue
                }
                items.push({
                    id: row.id,
                    entitlementIds: refIds(row.entitlements),
                    metadata: row.accessModelMetadata,
                })
            }
            if (page.length < PAGE_SIZE) {
                break
            }
            offset += PAGE_SIZE
        }
        return items
    } catch (error) {
        logIscRequestFailure('listAccessProfileCatalog listAccessProfilesV1', error)
        throw toConnectorError(error, 'Failed to list access profiles')
    }
}

/** Pages all roles with access-profile refs, entitlement refs, and metadata. */
export async function listRoleCatalog(roles: RolesApi): Promise<RoleCatalogItem[]> {
    const items: RoleCatalogItem[] = []
    let offset = 0
    try {
        while (true) {
            const request = { offset, limit: PAGE_SIZE }
            logIscDebug('listRoleCatalog listRolesV1 request', request)
            const response = await roles.listRolesV1(request)
            const page = response.data ?? []
            for (const row of page) {
                if (!row.id) {
                    continue
                }
                items.push({
                    id: row.id,
                    accessProfileIds: refIds(row.accessProfiles),
                    entitlementIds: refIds(row.entitlements),
                    metadata: row.accessModelMetadata,
                })
            }
            if (page.length < PAGE_SIZE) {
                break
            }
            offset += PAGE_SIZE
        }
        return items
    } catch (error) {
        logIscRequestFailure('listRoleCatalog listRolesV1', error)
        throw toConnectorError(error, 'Failed to list roles')
    }
}

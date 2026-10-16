import { AccessProfilesApi, RolesApi } from 'sailpoint-api-client'
import { DEFAULT_ISC_CONCURRENCY, mapWithConcurrency } from '../../framework/concurrency'
import { listAccessProfileEntitlements } from '../../isc/access-profiles/access-profile-entitlements'
import { CatalogAccessItem } from '../../isc/roles/list-enabled-roles'
import { listRoleEntitlements } from '../../isc/roles/role-entitlements'

export interface EntitlementRef {
    id: string
    name?: string
}

export interface NestedAccessProfileBundle {
    id: string
    name: string
    entitlements: EntitlementRef[]
}

export interface ExpandedAccessItemEntitlements {
    entitlementIds: Set<string>
    entitlements: EntitlementRef[]
    nestedProfiles: NestedAccessProfileBundle[]
}

export interface EntitlementExpansionClients {
    roles: RolesApi
    accessProfiles: AccessProfilesApi
}

function addEntitlement(entitlementIds: Set<string>, entitlements: EntitlementRef[], id: string, name?: string): void {
    if (!entitlementIds.has(id)) {
        entitlementIds.add(id)
        entitlements.push({ id, name })
        return
    }

    if (!name) {
        return
    }

    const existing = entitlements.find((entitlement) => entitlement.id === id)
    if (existing && !existing.name) {
        existing.name = name
    }
}

/** Expands a catalog access item to flat entitlement ids plus nested AP metadata for roles. */
export async function expandAccessItemEntitlements(
    clients: EntitlementExpansionClients,
    item: CatalogAccessItem
): Promise<ExpandedAccessItemEntitlements> {
    const entitlementIds = new Set<string>()
    const entitlements: EntitlementRef[] = []
    const nestedProfiles: NestedAccessProfileBundle[] = []

    if (item.type === 'ACCESS_PROFILE') {
        const profileEntitlements = await listAccessProfileEntitlements(clients.accessProfiles, item.id)
        for (const entitlement of profileEntitlements) {
            addEntitlement(entitlementIds, entitlements, entitlement.id, entitlement.name)
        }
        return { entitlementIds, entitlements, nestedProfiles }
    }

    const directEntitlements = await listRoleEntitlements(clients.roles, item.id)
    for (const entitlement of directEntitlements) {
        addEntitlement(entitlementIds, entitlements, entitlement.id, entitlement.name)
    }

    const roleResponse = await clients.roles.getRoleV1({ id: item.id })
    const accessProfiles = (roleResponse.data?.accessProfiles ?? []).filter(
        (profileRef): profileRef is { id: string; name?: string } => Boolean(profileRef.id)
    )

    const nestedBundles = await mapWithConcurrency(accessProfiles, DEFAULT_ISC_CONCURRENCY, async (profileRef) => {
        const profileEntitlements = await listAccessProfileEntitlements(clients.accessProfiles, profileRef.id)
        const nestedEntitlements: EntitlementRef[] = []
        for (const entitlement of profileEntitlements) {
            nestedEntitlements.push({ id: entitlement.id, name: entitlement.name })
        }

        if (nestedEntitlements.length === 0) {
            return undefined
        }

        return {
            id: profileRef.id,
            name: profileRef.name ?? profileRef.id,
            entitlements: nestedEntitlements,
        } satisfies NestedAccessProfileBundle
    })

    for (const bundle of nestedBundles) {
        if (!bundle) {
            continue
        }
        for (const entitlement of bundle.entitlements) {
            addEntitlement(entitlementIds, entitlements, entitlement.id, entitlement.name)
        }
        nestedProfiles.push(bundle)
    }

    return { entitlementIds, entitlements, nestedProfiles }
}

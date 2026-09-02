import { IdentityAccessItem } from '../../isc/identity-access'
import type { KeepRecommendation } from '../../isc/recommendations'

export type AccessPathType = IdentityAccessItem['type']

export type RevokeReason = 'direct-assignment' | 'granted-via-role' | 'granted-via-access-profile'

export interface GrantedViaRef {
    type: 'ROLE' | 'ACCESS_PROFILE'
    id: string
    name: string
}

export interface RevokeTarget {
    type: AccessPathType
    id: string
    name: string
    revocable: boolean
    recommended: boolean
    reason?: RevokeReason
    grantedVia?: GrantedViaRef
    keepRecommendation?: KeepRecommendation
    privileged?: boolean
}

export interface AccessPathLine extends RevokeTarget {}

export interface SideRevokePayload {
    items: RevokeTarget[]
    recommendedRevoke: RevokeTarget
}

export interface ResolvedAccessSide {
    accessPaths: AccessPathLine[]
    displayLines: string[]
    warningText: string
    revokePayload: SideRevokePayload
}

const STANDARD_WARNING =
    'Select the side whose access should be removed to resolve this violation.'
const ELEVATED_WARNING =
    'Removing role-level access may affect other functions of the user.'

export { ELEVATED_WARNING }

/** Builds an ISC access-item search filter from resolved path item ids (`id:a OR id:b`). */
export function buildAccessSearchString(items: Array<{ id: string }>): string {
    return items.map((item) => `id:${item.id}`).join(' OR ')
}

/** Builds an access-item search filter from revocable path items only. */
export function buildRevocableAccessSearchString(accessPaths: AccessPathLine[]): string {
    return buildAccessSearchString(accessPaths.filter((item) => item.revocable))
}

const TYPE_PRIORITY: Record<AccessPathType, number> = {
    ROLE: 3,
    ACCESS_PROFILE: 2,
    ENTITLEMENT: 1,
}

function formatLine(type: AccessPathType, name: string): string {
    switch (type) {
        case 'ROLE':
            return `Role: ${name}`
        case 'ACCESS_PROFILE':
            return `Access Profile: ${name}`
        default:
            return `Entitlement: ${name}`
    }
}

function pickRecommendedRevoke(items: RevokeTarget[]): RevokeTarget {
    const revocable = items.filter((item) => item.revocable)
    const candidates = revocable.length > 0 ? revocable : items
    return [...candidates].sort((a, b) => TYPE_PRIORITY[b.type] - TYPE_PRIORITY[a.type])[0]
}

function pickGrantor(
    grantors: GrantedViaRef[]
): GrantedViaRef | undefined {
    if (grantors.length === 0) {
        return undefined
    }
    const roleGrantor = grantors.find((grantor) => grantor.type === 'ROLE')
    return roleGrantor ?? grantors[0]
}

function annotateRevocability(
    items: Array<{ type: AccessPathType; id: string; name: string; grantedVia?: GrantedViaRef }>
): AccessPathLine[] {
    return items.map((item) => {
        if (item.type === 'ROLE') {
            return { ...item, revocable: true, recommended: false }
        }

        if (item.type === 'ENTITLEMENT' && item.grantedVia?.type === 'ROLE') {
            return {
                ...item,
                revocable: false,
                recommended: false,
                reason: 'granted-via-role',
            }
        }

        return { ...item, revocable: true, recommended: false, reason: 'direct-assignment' }
    })
}

/** Expands conflicting entitlements into display lines and a structured revoke payload. */
export function resolveAccessSide(
    entitlements: Array<{ id: string; name: string }>,
    identityAccess: IdentityAccessItem[]
): ResolvedAccessSide {
    const items: Array<{ type: AccessPathType; id: string; name: string; grantedVia?: GrantedViaRef }> = []
    const entitlementGrantors = new Map<string, GrantedViaRef[]>()
    let hasElevatedPath = false

    for (const entitlement of entitlements) {
        items.push({ type: 'ENTITLEMENT', id: entitlement.id, name: entitlement.name })

        for (const access of identityAccess) {
            if (access.type !== 'ROLE') {
                continue
            }
            const grants = access.grantedEntitlementIds ?? []
            if (grants.includes(entitlement.id)) {
                items.push({ type: access.type, id: access.id, name: access.name })
                hasElevatedPath = true

                const grantor: GrantedViaRef = {
                    type: 'ROLE',
                    id: access.id,
                    name: access.name,
                }
                const existing = entitlementGrantors.get(entitlement.id) ?? []
                existing.push(grantor)
                entitlementGrantors.set(entitlement.id, existing)
            }
        }
    }

    const uniqueItems = items.filter(
        (item, index, array) => array.findIndex((candidate) => candidate.id === item.id) === index
    )

    const itemsWithGrantors = uniqueItems.map((item) => {
        if (item.type !== 'ENTITLEMENT') {
            return item
        }
        const grantedVia = pickGrantor(entitlementGrantors.get(item.id) ?? [])
        return grantedVia ? { ...item, grantedVia } : item
    })

    const accessPaths = annotateRevocability(itemsWithGrantors)
    const recommendedRevoke = pickRecommendedRevoke(accessPaths)

    return {
        accessPaths,
        displayLines: accessPaths.map((item) => formatLine(item.type, item.name)),
        warningText: hasElevatedPath ? ELEVATED_WARNING : STANDARD_WARNING,
        revokePayload: {
            items: accessPaths,
            recommendedRevoke,
        },
    }
}

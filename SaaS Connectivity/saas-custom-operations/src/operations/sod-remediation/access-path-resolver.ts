import { IdentityAccessItem } from '../../isc/identity-access'

export type AccessPathType = IdentityAccessItem['type']

export interface RevokeTarget {
    type: AccessPathType
    id: string
    name: string
}

export interface SideRevokePayload {
    items: RevokeTarget[]
    recommendedRevoke: RevokeTarget
}

export interface ResolvedAccessSide {
    displayLines: string[]
    warningText: string
    revokePayload: SideRevokePayload
}

const STANDARD_WARNING =
    'Select the side whose access should be removed to resolve this violation.'
const ELEVATED_WARNING =
    'Removing access profile- or role-level access may affect other functions of the user.'

export { ELEVATED_WARNING }

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
    return [...items].sort((a, b) => TYPE_PRIORITY[b.type] - TYPE_PRIORITY[a.type])[0]
}

/** Expands conflicting entitlements into display lines and a structured revoke payload. */
export function resolveAccessSide(
    entitlements: Array<{ id: string; name: string }>,
    identityAccess: IdentityAccessItem[]
): ResolvedAccessSide {
    const items: RevokeTarget[] = []
    let hasElevatedPath = false

    for (const entitlement of entitlements) {
        items.push({ type: 'ENTITLEMENT', id: entitlement.id, name: entitlement.name })

        for (const access of identityAccess) {
            if (access.type === 'ENTITLEMENT') {
                continue
            }
            const grants = access.grantedEntitlementIds ?? []
            if (grants.includes(entitlement.id)) {
                items.push({ type: access.type, id: access.id, name: access.name })
                hasElevatedPath = true
            }
        }
    }

    const uniqueItems = items.filter(
        (item, index, array) => array.findIndex((candidate) => candidate.id === item.id) === index
    )

    return {
        displayLines: uniqueItems.map((item) => formatLine(item.type, item.name)),
        warningText: hasElevatedPath ? ELEVATED_WARNING : STANDARD_WARNING,
        revokePayload: {
            items: uniqueItems,
            recommendedRevoke: pickRecommendedRevoke(uniqueItems),
        },
    }
}


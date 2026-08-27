import { keepRecommendationKey, type KeepRecommendationMap } from '../../isc/recommendations'
import { AccessPathLine, AccessPathType, ResolvedAccessSide } from './access-path-resolver'

export type RecommendedSideToCorrect = 'groupA' | 'groupB' | null

export interface PrivilegedEntitlementMap {
    get(entitlementId: string): boolean | undefined
}

export function createPrivilegedEntitlementMap(
    entitlements: Array<{ id: string; privileged: boolean }>
): PrivilegedEntitlementMap {
    const map = new Map(entitlements.map((item) => [item.id, item.privileged]))
    return {
        get: (entitlementId: string) => map.get(entitlementId),
    }
}

function recommendationKeyForLine(line: AccessPathLine): string {
    return keepRecommendationKey(line.id, line.type as AccessPathType)
}

function enrichAccessPathLine(
    line: AccessPathLine,
    keepRecommendations: KeepRecommendationMap,
    privilegedEntitlements: PrivilegedEntitlementMap
): AccessPathLine {
    const keepRecommendation = keepRecommendations.get(recommendationKeyForLine(line))
    const privileged =
        line.type === 'ENTITLEMENT' ? privilegedEntitlements.get(line.id) === true : undefined
    const { keepRecommendation: _existingKeep, privileged: _existingPrivileged, recommended: _existingRecommended, ...rest } =
        line

    return {
        ...rest,
        recommended: false,
        ...(keepRecommendation !== undefined ? { keepRecommendation } : {}),
        ...(privileged ? { privileged: true } : {}),
    }
}

function enrichSide(
    side: ResolvedAccessSide,
    keepRecommendations: KeepRecommendationMap,
    privilegedEntitlements: PrivilegedEntitlementMap
): ResolvedAccessSide {
    const accessPaths = side.accessPaths.map((line) =>
        enrichAccessPathLine(line, keepRecommendations, privilegedEntitlements)
    )

    return {
        ...side,
        accessPaths,
        revokePayload: {
            ...side.revokePayload,
            items: accessPaths,
            recommendedRevoke: {
                ...side.revokePayload.recommendedRevoke,
                recommended: false,
            },
        },
    }
}

/** Merges keep recommendations and privileged flags onto resolved access sides. */
export function enrichResolvedAccessSides(
    groupA: ResolvedAccessSide,
    groupB: ResolvedAccessSide,
    keepRecommendations: KeepRecommendationMap,
    privilegedEntitlements: PrivilegedEntitlementMap
): { groupA: ResolvedAccessSide; groupB: ResolvedAccessSide } {
    return {
        groupA: enrichSide(groupA, keepRecommendations, privilegedEntitlements),
        groupB: enrichSide(groupB, keepRecommendations, privilegedEntitlements),
    }
}

function sideHasKeepRecommendation(side: ResolvedAccessSide): boolean {
    return side.accessPaths.some((line) => line.keepRecommendation === 'YES')
}

/** Computes which violation side to correct when keep recommendations are asymmetric. */
export function computeRecommendedSideToCorrect(
    groupA: ResolvedAccessSide,
    groupB: ResolvedAccessSide
): RecommendedSideToCorrect {
    const aHasKeep = sideHasKeepRecommendation(groupA)
    const bHasKeep = sideHasKeepRecommendation(groupB)

    if (!aHasKeep && bHasKeep) {
        return 'groupA'
    }
    if (aHasKeep && !bHasKeep) {
        return 'groupB'
    }
    return null
}

export function sideCorrectionLabel(side: RecommendedSideToCorrect): string | null {
    switch (side) {
        case 'groupA':
            return 'Group A'
        case 'groupB':
            return 'Group B'
        default:
            return null
    }
}

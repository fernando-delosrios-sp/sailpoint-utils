import { describe, expect, it } from 'vitest'
import { keepRecommendationKey } from '../../isc/recommendations'
import {
    computeRecommendedSideToCorrect,
    createPrivilegedEntitlementMap,
    enrichResolvedAccessSides,
} from './access-path-enrichment'
import { ResolvedAccessSide } from './access-path-resolver'

function sideWithKeep(group: 'A' | 'B', keepOnFirst: boolean): ResolvedAccessSide {
    const id = group === 'A' ? 'ent-a' : 'ent-b'
    return {
        accessPaths: [
            {
                type: 'ENTITLEMENT',
                id,
                name: `Ent ${group}`,
                revocable: true,
                recommended: false,
                keepRecommendation: keepOnFirst ? 'YES' : 'NO',
            },
        ],
        displayLines: [],
        warningText: 'standard',
        revokePayload: {
            items: [],
            recommendedRevoke: {
                type: 'ENTITLEMENT',
                id,
                name: `Ent ${group}`,
                revocable: true,
                recommended: false,
            },
        },
    }
}

describe('access-path-enrichment', () => {
    it('computeRecommendedSideToCorrect recommends Group A when only B has keep YES', () => {
        expect(computeRecommendedSideToCorrect(sideWithKeep('A', false), sideWithKeep('B', true))).toBe('groupA')
    })

    it('computeRecommendedSideToCorrect recommends Group B when only A has keep YES', () => {
        expect(computeRecommendedSideToCorrect(sideWithKeep('A', true), sideWithKeep('B', false))).toBe('groupB')
    })

    it('computeRecommendedSideToCorrect returns null when both or neither have keep YES', () => {
        expect(computeRecommendedSideToCorrect(sideWithKeep('A', true), sideWithKeep('B', true))).toBeNull()
        expect(computeRecommendedSideToCorrect(sideWithKeep('A', false), sideWithKeep('B', false))).toBeNull()
    })

    it('MAYBE does not count toward side correction', () => {
        const groupA = sideWithKeep('A', false)
        const groupB = {
            ...sideWithKeep('B', false),
            accessPaths: [
                {
                    ...sideWithKeep('B', false).accessPaths[0],
                    keepRecommendation: 'MAYBE' as const,
                },
            ],
        }

        expect(computeRecommendedSideToCorrect(groupA, groupB)).toBeNull()
    })

    it('enrichResolvedAccessSides merges keep recommendations and privileged flags', () => {
        const baseA = sideWithKeep('A', false)
        const baseB = sideWithKeep('B', false)
        const keepMap = new Map([[keepRecommendationKey('ent-b', 'ENTITLEMENT'), 'YES' as const]])
        const privilegedMap = createPrivilegedEntitlementMap([{ id: 'ent-a', privileged: true }])

        const { groupA, groupB } = enrichResolvedAccessSides(baseA, baseB, keepMap, privilegedMap)

        expect(groupA.accessPaths[0]).toMatchObject({ privileged: true })
        expect(groupA.accessPaths[0].keepRecommendation).toBeUndefined()
        expect(groupB.accessPaths[0]).toMatchObject({ keepRecommendation: 'YES', recommended: false })
    })
})

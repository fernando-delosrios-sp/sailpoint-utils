import { describe, expect, it } from 'vitest'
import {
    collectSodTagsForAccessProfile,
    collectSodTagsForRole,
    hasRiskMetadata,
    isPrivilegedEntitlement,
    isPrivilegedAccessProfile,
    isPrivilegedRole,
} from './classify'

describe('isPrivilegedEntitlement', () => {
    it('treats MEDIUM and HIGH effective privilege as privileged', () => {
        expect(isPrivilegedEntitlement({ effective: 'HIGH' })).toBe(true)
        expect(isPrivilegedEntitlement({ effective: 'MEDIUM' })).toBe(true)
        expect(isPrivilegedEntitlement({ effective: 'LOW' })).toBe(false)
    })

    it('falls back to direct when effective is absent', () => {
        expect(isPrivilegedEntitlement({ direct: 'HIGH' })).toBe(true)
        expect(isPrivilegedEntitlement({ effective: null, direct: 'MEDIUM' })).toBe(true)
        expect(isPrivilegedEntitlement({})).toBe(false)
    })
})

describe('hasRiskMetadata', () => {
    it('returns false when Risk metadata is missing or empty', () => {
        expect(hasRiskMetadata(undefined)).toBe(false)
        expect(hasRiskMetadata({ attributes: [] })).toBe(false)
        expect(
            hasRiskMetadata({
                attributes: [{ key: 'iscRisk', name: 'Risk', values: [] }],
            })
        ).toBe(false)
    })

    it('returns true for any non-empty Risk value including low', () => {
        expect(
            hasRiskMetadata({
                attributes: [{ key: 'iscRisk', name: 'Risk', values: [{ value: 'low' }] }],
            })
        ).toBe(true)
        expect(
            hasRiskMetadata({
                attributes: [{ name: 'Risk', values: ['medium'] }],
            })
        ).toBe(true)
    })

    it('stops at the first non-empty Risk value', () => {
        const examined: string[] = []
        const metadata = {
            attributes: [
                {
                    key: 'iscRisk',
                    name: 'Risk',
                    values: [
                        {
                            get value() {
                                examined.push('first')
                                return 'low'
                            },
                        },
                        {
                            get value() {
                                examined.push('second')
                                return 'high'
                            },
                        },
                    ],
                },
            ],
        }
        expect(hasRiskMetadata(metadata)).toBe(true)
        expect(examined).toEqual(['first'])
    })
})

describe('isPrivilegedAccessProfile', () => {
    it('stops at the first privileged entitlement', () => {
        const { privileged: isPriv, examinedCount } = isPrivilegedAccessProfile(
            ['ent-a', 'ent-priv', 'ent-b'],
            new Set(['ent-priv'])
        )
        expect(isPriv).toBe(true)
        expect(examinedCount).toBe(2)
    })

    it('returns false when no entitlement is privileged', () => {
        const { privileged: isPriv, examinedCount } = isPrivilegedAccessProfile(
            ['ent-a', 'ent-b'],
            new Set(['ent-other'])
        )
        expect(isPriv).toBe(false)
        expect(examinedCount).toBe(2)
    })
})

describe('isPrivilegedRole', () => {
    it('stops at the first privileged access profile and skips direct entitlements', () => {
        const result = isPrivilegedRole(
            ['ap-a', 'ap-priv', 'ap-b'],
            ['ent-priv', 'ent-other'],
            new Set(['ap-priv']),
            new Set(['ent-priv'])
        )
        expect(result.privileged).toBe(true)
        expect(result.examinedAccessProfiles).toBe(2)
        expect(result.examinedEntitlements).toBe(0)
    })

    it('walks direct entitlements only when no access profile is privileged', () => {
        const result = isPrivilegedRole(
            ['ap-a', 'ap-b'],
            ['ent-a', 'ent-priv', 'ent-b'],
            new Set(),
            new Set(['ent-priv'])
        )
        expect(result.privileged).toBe(true)
        expect(result.examinedAccessProfiles).toBe(2)
        expect(result.examinedEntitlements).toBe(2)
    })
})

describe('collectSodTagsForAccessProfile', () => {
    it('stops looking for a tag once acquired and still collects a second tag', () => {
        const tagsByEntitlement = new Map<string, string[]>([
            ['ent-1', ['SOD_A', 'SOD_B']],
            ['ent-2', ['SOD_A', 'SOD_C']],
            ['ent-3', ['SOD_A']],
        ])
        const result = collectSodTagsForAccessProfile(['ent-1', 'ent-2', 'ent-3'], tagsByEntitlement)
        expect([...result.tags].sort()).toEqual(['SOD_A', 'SOD_B', 'SOD_C'])
        // After ent-1, SOD_A and SOD_B are done; ent-2 is still examined for SOD_C; ent-3 skipped (no pending tags)
        expect(result.examinedEntitlements).toBe(2)
    })

    it('skips entitlements that carry no pending tag', () => {
        const tagsByEntitlement = new Map<string, string[]>([
            ['ent-empty', []],
            ['ent-1', ['SOD_A']],
        ])
        const result = collectSodTagsForAccessProfile(['ent-empty', 'ent-1'], tagsByEntitlement)
        expect([...result.tags]).toEqual(['SOD_A'])
        expect(result.examinedEntitlements).toBe(2)
    })
})

describe('collectSodTagsForRole', () => {
    it('inherits tags from privileged access profiles and stops per tag', () => {
        const tagsByAccessProfile = new Map<string, string[]>([
            ['ap-1', ['SOD_A']],
            ['ap-2', ['SOD_A', 'SOD_B']],
        ])
        const tagsByEntitlement = new Map<string, string[]>([['ent-1', ['SOD_A', 'SOD_C']]])
        const result = collectSodTagsForRole(
            ['ap-1', 'ap-2'],
            ['ent-1'],
            tagsByAccessProfile,
            tagsByEntitlement
        )
        expect([...result.tags].sort()).toEqual(['SOD_A', 'SOD_B', 'SOD_C'])
        expect(result.examinedAccessProfiles).toBe(2)
        expect(result.examinedEntitlements).toBe(1)
    })
})

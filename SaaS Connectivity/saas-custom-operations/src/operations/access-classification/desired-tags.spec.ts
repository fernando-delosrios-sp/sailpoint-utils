import { describe, expect, it } from 'vitest'
import { PRIVILEGED_TAG, RISK_TAG } from './constants'
import { addViolatingIdentities, buildDesiredClassification, buildSodTagsByEntitlement } from './desired-tags'
import {
    OFFLINE_ACCESS_PROFILES,
    OFFLINE_ENTITLEMENTS,
    OFFLINE_ROLES,
    OFFLINE_SOD_POLICIES,
} from './offline-data'

describe('buildSodTagsByEntitlement', () => {
    it('promotes tags from enforced policies with tags and skips untagged policies', () => {
        const { tagsByEntitlement, managedSodTags, policiesWithTags } =
            buildSodTagsByEntitlement(OFFLINE_SOD_POLICIES)

        expect(policiesWithTags.map((policy) => policy.id)).toEqual(['pol-1'])
        expect([...managedSodTags]).toEqual(['SOD_FINANCE'])
        expect(tagsByEntitlement.get('ent-sod-a')).toEqual(['SOD_FINANCE'])
        expect(tagsByEntitlement.get('ent-sod-b')).toEqual(['SOD_FINANCE'])
        expect(tagsByEntitlement.has('ent-low')).toBe(false)
    })
})

describe('buildDesiredClassification', () => {
    it('classifies privileged, risk, and SOD tags across the offline catalog', () => {
        const result = buildDesiredClassification(
            {
                entitlements: OFFLINE_ENTITLEMENTS,
                accessProfiles: OFFLINE_ACCESS_PROFILES,
                roles: OFFLINE_ROLES,
            },
            OFFLINE_SOD_POLICIES
        )

        const privileged = result.desired.get(PRIVILEGED_TAG) ?? new Set()
        expect(privileged.has('ENTITLEMENT:ent-high')).toBe(true)
        expect(privileged.has('ENTITLEMENT:ent-medium')).toBe(true)
        expect(privileged.has('ACCESS_PROFILE:ap-priv')).toBe(true)
        expect(privileged.has('ROLE:role-priv')).toBe(true)
        expect(privileged.has('ACCESS_PROFILE:ap-plain')).toBe(false)

        const risk = result.desired.get(RISK_TAG) ?? new Set()
        expect(risk.has('ENTITLEMENT:ent-medium')).toBe(true)
        expect(risk.has('ACCESS_PROFILE:ap-risk')).toBe(true)
        expect(risk.has('ROLE:role-plain')).toBe(false)

        const sod = result.desired.get('SOD_FINANCE') ?? new Set()
        expect(sod.has('ENTITLEMENT:ent-sod-a')).toBe(true)
        expect(sod.has('ENTITLEMENT:ent-sod-b')).toBe(true)
        expect(sod.has('ACCESS_PROFILE:ap-sod')).toBe(true)
        expect(sod.has('ROLE:role-sod')).toBe(true)
    })
})

describe('addViolatingIdentities', () => {
    it('adds identity holders for each policy tag', () => {
        const desired = new Map<string, Set<string>>()
        const scanned = addViolatingIdentities(desired, ['SOD_FINANCE'], ['ident-a', 'ident-b'])

        expect(scanned).toBe(2)
        expect(desired.get('SOD_FINANCE')?.has('IDENTITY:ident-a')).toBe(true)
        expect(desired.get('SOD_FINANCE')?.has('IDENTITY:ident-b')).toBe(true)
    })
})

import { describe, expect, it } from 'vitest'
import { maxTier, parseConsiderPrivilege, tierFromEntitlement, tierFromRiskMetadata } from './tiers'

const risk = (value: string) => ({
    attributes: [{ key: 'iscRisk', name: 'Risk', values: [{ value, name: value }] }],
})

describe('tierFromRiskMetadata', () => {
    it('maps critical and high to High and medium to Medium', () => {
        expect(tierFromRiskMetadata(risk('critical'))).toBe('High')
        expect(tierFromRiskMetadata(risk('High'))).toBe('High')
        expect(tierFromRiskMetadata(risk('medium'))).toBe('Medium')
    })

    it('treats missing or unrecognized risk as Low', () => {
        expect(tierFromRiskMetadata(undefined)).toBe('Low')
        expect(tierFromRiskMetadata(risk('low'))).toBe('Low')
        expect(
            tierFromRiskMetadata({
                attributes: [{ key: 'iscPrivacy', values: [{ value: 'secret' }] }],
            })
        ).toBe('Low')
    })
})

describe('tierFromEntitlement', () => {
    it('attributes privilege-only risk to effective privilege', () => {
        expect(tierFromEntitlement({ effectivePrivilege: 'HIGH', metadata: undefined })).toEqual({
            tier: 'High',
            rule: 'effective privilege',
        })
    })

    it('attributes metadata-only risk to Risk metadata', () => {
        expect(tierFromEntitlement({ effectivePrivilege: 'LOW', metadata: risk('critical') })).toEqual({
            tier: 'High',
            rule: 'Risk metadata',
        })
    })

    it('Entitlement matching both rules is attributed to effective privilege', () => {
        expect(tierFromEntitlement({ effectivePrivilege: 'HIGH', metadata: risk('critical') })).toEqual({
            tier: 'High',
            rule: 'effective privilege',
        })
        expect(tierFromEntitlement({ effectivePrivilege: 'MEDIUM', metadata: risk('medium') })).toEqual({
            tier: 'Medium',
            rule: 'effective privilege',
        })
    })

    it('omits the deciding rule when neither rule raises the tier', () => {
        expect(tierFromEntitlement({ effectivePrivilege: null, metadata: undefined })).toEqual({ tier: 'Low' })
    })

    it('ignores effective privilege when considerPrivilege is false', () => {
        expect(
            tierFromEntitlement({
                effectivePrivilege: 'HIGH',
                metadata: undefined,
                considerPrivilege: false,
            })
        ).toEqual({ tier: 'Low' })
        expect(
            tierFromEntitlement({
                effectivePrivilege: 'HIGH',
                metadata: risk('medium'),
                considerPrivilege: false,
            })
        ).toEqual({ tier: 'Medium', rule: 'Risk metadata' })
    })
})

describe('parseConsiderPrivilege', () => {
    it('defaults to true when omitted', () => {
        expect(parseConsiderPrivilege(undefined)).toBe(true)
        expect(parseConsiderPrivilege(null)).toBe(true)
        expect(parseConsiderPrivilege('')).toBe(true)
        expect(parseConsiderPrivilege('true')).toBe(true)
        expect(parseConsiderPrivilege(true)).toBe(true)
    })

    it('treats false-like values as off', () => {
        expect(parseConsiderPrivilege(false)).toBe(false)
        expect(parseConsiderPrivilege('false')).toBe(false)
        expect(parseConsiderPrivilege('FALSE')).toBe(false)
        expect(parseConsiderPrivilege('0')).toBe(false)
        expect(parseConsiderPrivilege('no')).toBe(false)
        expect(parseConsiderPrivilege(0)).toBe(false)
    })
})

describe('maxTier', () => {
    it('keeps the higher tier', () => {
        expect(maxTier('Low', 'Medium')).toBe('Medium')
        expect(maxTier('High', 'Medium')).toBe('High')
    })
})

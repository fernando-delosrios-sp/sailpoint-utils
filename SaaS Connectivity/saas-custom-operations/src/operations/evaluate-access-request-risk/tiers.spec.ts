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
    it('is High when effective privilege is High even if metadata is lower', () => {
        expect(tierFromEntitlement({ effectivePrivilege: 'HIGH', metadata: risk('medium') })).toBe('High')
    })

    it('is High when metadata is critical and privilege is not', () => {
        expect(tierFromEntitlement({ effectivePrivilege: 'LOW', metadata: risk('critical') })).toBe('High')
    })

    it('is Medium when privilege or metadata is medium and neither is high', () => {
        expect(tierFromEntitlement({ effectivePrivilege: 'MEDIUM', metadata: undefined })).toBe('Medium')
        expect(tierFromEntitlement({ effectivePrivilege: 'LOW', metadata: risk('medium') })).toBe('Medium')
    })

    it('is Low otherwise', () => {
        expect(tierFromEntitlement({ effectivePrivilege: null, metadata: undefined })).toBe('Low')
    })

    it('ignores effective privilege when considerPrivilege is false', () => {
        expect(
            tierFromEntitlement({
                effectivePrivilege: 'HIGH',
                metadata: undefined,
                considerPrivilege: false,
            })
        ).toBe('Low')
        expect(
            tierFromEntitlement({
                effectivePrivilege: 'HIGH',
                metadata: risk('medium'),
                considerPrivilege: false,
            })
        ).toBe('Medium')
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

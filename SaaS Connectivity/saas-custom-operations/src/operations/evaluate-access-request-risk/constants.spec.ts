import { describe, expect, it } from 'vitest'
import { riskPersistIdentity } from './constants'

describe('riskPersistIdentity', () => {
    it('prefixes a request id with no wrapper discriminator', () => {
        expect(riskPersistIdentity('manual-001')).toBe('evaluate-access-request-risk:manual-001')
    })

    it('keeps the submitted wrapper discriminator inside the prefixed identity', () => {
        expect(riskPersistIdentity('req-abc:submitted')).toBe('evaluate-access-request-risk:req-abc:submitted')
    })

    it('keeps the dynamic wrapper discriminator inside the prefixed identity', () => {
        expect(riskPersistIdentity('req-abc:dynamic')).toBe('evaluate-access-request-risk:req-abc:dynamic')
    })

    it('keeps the dynamic-approval wrapper discriminator inside the prefixed identity', () => {
        expect(riskPersistIdentity('req-abc:dynamic-approval')).toBe(
            'evaluate-access-request-risk:req-abc:dynamic-approval'
        )
    })

    it('does not prefix an already-prefixed request id twice', () => {
        expect(riskPersistIdentity('evaluate-access-request-risk:req-abc:dynamic')).toBe(
            'evaluate-access-request-risk:req-abc:dynamic'
        )
    })
})

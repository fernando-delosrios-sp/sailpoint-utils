import { describe, expect, it } from 'vitest'
import { applyPersistIdentity, legacyPrefixedApplyPersistIdentity } from './constants'

describe('applyPersistIdentity', () => {
    it('joins request id and form instance id', () => {
        expect(applyPersistIdentity('access-model-sod-remediation-apply', 'fi-1')).toBe(
            'access-model-sod-remediation-apply:fi-1'
        )
    })
})

describe('legacyPrefixedApplyPersistIdentity', () => {
    it('spells the pre-requestId persist identity', () => {
        expect(legacyPrefixedApplyPersistIdentity('fi-1')).toBe('access-model-sod-remediation-apply:fi-1')
    })
})

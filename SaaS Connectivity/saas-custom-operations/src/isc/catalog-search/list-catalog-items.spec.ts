import { describe, expect, it } from 'vitest'
import {
    buildEnabledSearchQuery,
    isListApiScopeFilter,
    isWildcardScope,
} from './list-catalog-items'

describe('catalog search scope routing', () => {
    it('treats wildcard scopes as search queries', () => {
        expect(isWildcardScope('*')).toBe(true)
        expect(isWildcardScope('  *  ')).toBe(true)
        expect(isListApiScopeFilter('*')).toBe(false)
        expect(buildEnabledSearchQuery('*')).toBe('enabled:true')
    })

    it('detects V3 list filter scopes', () => {
        expect(isListApiScopeFilter('name sw "Finance-"')).toBe(true)
        expect(isListApiScopeFilter('name:Finance*')).toBe(false)
    })

    it('combines custom search scope with enabled constraint', () => {
        expect(buildEnabledSearchQuery('name:Finance*')).toBe('enabled:true AND (name:Finance*)')
    })
})

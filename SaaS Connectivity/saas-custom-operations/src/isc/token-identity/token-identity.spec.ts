import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it } from 'vitest'
import { resolveTokenIdentity } from './token-identity'

function createMockJwt(payload: Record<string, unknown>): string {
    const header = Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url')
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url')
    return `${header}.${body}.signature`
}

describe('resolveTokenIdentity', () => {
    it('extracts identity_id from JWT payload', () => {
        const token = createMockJwt({ identity_id: 'abc-123', sub: 'other' })
        expect(resolveTokenIdentity(token)).toBe('abc-123')
    })

    it('falls back to sub when identity_id is absent', () => {
        const token = createMockJwt({ sub: 'identity-sub' })
        expect(resolveTokenIdentity(token)).toBe('identity-sub')
    })

    it('throws when token cannot be decoded', () => {
        expect(() => resolveTokenIdentity('not-a-jwt')).toThrow(ConnectorError)
    })
})

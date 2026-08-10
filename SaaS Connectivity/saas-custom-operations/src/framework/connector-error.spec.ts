import { ConnectorError, ConnectorErrorType } from '@sailpoint/connector-sdk'
import { describe, expect, it } from 'vitest'
import { PersistVerificationError } from './persist-result'
import { toConnectorError } from './connector-error'

describe('toConnectorError', () => {
    it('converts plain Error to generic ConnectorError', () => {
        const result = toConnectorError(new Error('operation failed'))

        expect(result).toBeInstanceOf(ConnectorError)
        expect(result.type).toBe(ConnectorErrorType.Generic)
        expect(result.message).toBe('operation failed')
    })

    it('maps axios-like 404 to NotFound type', () => {
        const result = toConnectorError({
            message: 'Request failed with status code 404',
            response: { status: 404 },
        })

        expect(result).toBeInstanceOf(ConnectorError)
        expect(result.type).toBe(ConnectorErrorType.NotFound)
        expect(result.message).toContain('404')
    })

    it('returns existing ConnectorError unchanged', () => {
        const original = new ConnectorError('missing field', ConnectorErrorType.NotFound)

        expect(toConnectorError(original)).toBe(original)
    })

    it('converts PersistVerificationError to generic ConnectorError', () => {
        const result = toConnectorError(
            new PersistVerificationError('req-001', 'Verification failed for identity req-001: account not found after retries')
        )

        expect(result).toBeInstanceOf(ConnectorError)
        expect(result.type).toBe(ConnectorErrorType.Generic)
        expect(result.message).toContain('account not found after retries')
    })

    it('prefixes context when provided', () => {
        const result = toConnectorError(new Error('boom'), 'custom:example')

        expect(result.message).toBe('custom:example: boom')
    })
})

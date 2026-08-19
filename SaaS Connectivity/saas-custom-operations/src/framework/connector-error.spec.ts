import { ConnectorError, ConnectorErrorType } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { PersistVerificationError } from './persist-result'
import { buildErrorLogDetail, toConnectorError } from './connector-error'
import { createFrameworkLogger } from './logger'

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

    it('omits API response body from caller message', () => {
        const apiData = { detailCode: '400.1 Bad Request', message: 'Invalid filter field enabled' }
        const result = toConnectorError(
            {
                message: 'Request failed with status code 400',
                status: 400,
                data: apiData,
            },
            'Failed to list roles'
        )

        expect(result.message).toBe('Failed to list roles: Request failed with status code 400 (HTTP 400)')
        expect(result.message).not.toContain('Invalid filter field enabled')
        expect(result.message).not.toContain(JSON.stringify(apiData))
    })

    it('includes HTTP status when available', () => {
        const result = toConnectorError({
            message: 'Request failed with status code 400',
            status: 400,
            data: { message: 'Invalid filter field enabled' },
        })

        expect(result.message).toContain('(HTTP 400)')
    })
})

describe('buildErrorLogDetail', () => {
    it('includes response data for operator diagnostics', () => {
        const apiData = { detailCode: '400.1 Bad Request', message: 'Invalid filter field enabled' }
        const detail = buildErrorLogDetail({
            message: 'Request failed with status code 400',
            status: 400,
            data: apiData,
        })

        expect(detail.status).toBe(400)
        expect(detail.responseData).toEqual(apiData)
        expect(detail.message).toBe('Request failed with status code 400')
    })

    it('correlates API failures to requestId via framework logger', () => {
        const consoleError = vi.fn()
        const apiData = { message: 'Invalid filter field enabled', token: 'secret-token-value' }
        const err = {
            message: 'Request failed with status code 400',
            status: 400,
            data: apiData,
        }
        const connectorError = toConnectorError(err, 'custom:example')
        const logger = createFrameworkLogger({
            requestId: 'req-api-fail',
            consoleImpl: { log: vi.fn(), warn: vi.fn(), error: consoleError },
        })

        logger.error(connectorError.message, buildErrorLogDetail(err))

        expect(consoleError).toHaveBeenCalledOnce()
        const line = String(consoleError.mock.calls[0]?.[0])
        expect(line).toContain('[req-api-fail]')
        expect(line).toContain('Invalid filter field enabled')
        expect(line).not.toContain('secret-token-value')
    })
})

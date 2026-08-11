import { describe, expect, it, vi } from 'vitest'
import { escapeODataString, findAccountOnSource } from './find-account'

describe('escapeODataString', () => {
    it('escapes double quotes for OData filters', () => {
        expect(escapeODataString('say "hello"')).toBe('say ""hello""')
    })

    it('escapes backslashes for OData filters', () => {
        expect(escapeODataString('path\\to\\value')).toBe('path\\\\to\\\\value')
    })
})

describe('findAccountOnSource', () => {
    it('skips unsupported attributes.id filters when listAccounts returns HTTP 400', async () => {
        const listAccountsV1 = vi.fn().mockImplementation(async ({ filters }) => {
            const filterText = String(filters ?? '')
            if (filterText.includes('attributes.id eq')) {
                const error = new Error('Request failed with status code 400') as Error & {
                    response?: { status?: number }
                }
                error.response = { status: 400 }
                throw error
            }
            if (filterText.includes('nativeIdentity eq')) {
                return {
                    data: [
                        {
                            id: 'isc-account-6',
                            sourceId: 'source-1',
                            nativeIdentity: '9d372c5365e447a3b979d046184f97b3',
                            attributes: { id: '9d372c5365e447a3b979d046184f97b3' },
                        },
                    ],
                }
            }
            return { data: [] }
        })

        const found = await findAccountOnSource(
            { listAccountsV1 } as never,
            'source-1',
            '9d372c5365e447a3b979d046184f97b3'
        )

        expect(found?.id).toBe('isc-account-6')
    })

    it('does not use id eq filters (ISC id is account UUID, not native identity)', async () => {
        const violationId = '9d372c5365e447a3b979d046184f97b3'
        const listAccountsV1 = vi.fn().mockImplementation(async ({ filters, offset }) => {
            const filterText = String(filters ?? '')
            expect(filterText).not.toMatch(/^id eq /)
            if (filterText.includes('sourceId eq') && offset == null) {
                return {
                    data: [
                        {
                            id: violationId,
                            sourceId: 'source-1',
                            attributes: { id: 'unrelated-native-id' },
                        },
                    ],
                }
            }
            return { data: [] }
        })

        const found = await findAccountOnSource({ listAccountsV1 } as never, 'source-1', violationId)

        expect(found).toBeUndefined()
    })

    it('ignores list rows whose stored identity does not match the requested native identity', async () => {
        const listAccountsV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    id: 'isc-account-1',
                    sourceId: 'source-1',
                    nativeIdentity: 'other-id',
                    attributes: { id: 'other-id' },
                },
            ],
        })

        const found = await findAccountOnSource({ listAccountsV1 } as never, 'source-1', 'req-001')

        expect(found).toBeUndefined()
    })

    it('matches by attributes.id during source scan when nativeIdentity is unset', async () => {
        const listAccountsV1 = vi.fn().mockImplementation(async ({ filters, offset }) => {
            if (String(filters).includes('nativeIdentity eq') || String(filters).includes('name eq')) {
                return { data: [] }
            }
            if (String(filters).includes('sourceId eq') && offset === 0) {
                return {
                    data: [
                        {
                            id: 'isc-account-5',
                            sourceId: 'source-1',
                            attributes: { id: 'sod-remediation:9d372c5365e447a3b979d046184f97b3' },
                        },
                    ],
                }
            }
            return { data: [] }
        })

        const found = await findAccountOnSource(
            { listAccountsV1 } as never,
            'source-1',
            'sod-remediation:9d372c5365e447a3b979d046184f97b3'
        )

        expect(found).toEqual({
            id: 'isc-account-5',
            attributes: { id: 'sod-remediation:9d372c5365e447a3b979d046184f97b3' },
        })
    })

    it('falls back to source scan when indexed filters miss', async () => {
        const listAccountsV1 = vi.fn().mockImplementation(async ({ filters, offset }) => {
            if (String(filters).includes('nativeIdentity eq') || String(filters).includes('name eq')) {
                return { data: [] }
            }
            if (String(filters).includes('sourceId eq') && offset === 0) {
                return {
                    data: [
                        {
                            id: 'isc-account-3',
                            sourceId: 'source-1',
                            nativeIdentity: 'other',
                            attributes: { id: 'req-003' },
                        },
                        {
                            id: 'isc-account-4',
                            sourceId: 'source-1',
                            attributes: { id: 'req-004', outcome: 'stored' },
                        },
                    ],
                }
            }
            return { data: [] }
        })

        const found = await findAccountOnSource({ listAccountsV1 } as never, 'source-1', 'req-004')

        expect(found).toEqual({
            id: 'isc-account-4',
            attributes: { id: 'req-004', outcome: 'stored' },
        })
    })
})

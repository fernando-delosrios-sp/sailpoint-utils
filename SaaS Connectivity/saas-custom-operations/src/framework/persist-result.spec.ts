import { describe, expect, it, vi } from 'vitest'
import {
    buildAccountAttributes,
    createPersist,
    createVerifyPersisted,
    PersistVerificationError,
    readWithRetry,
    verifyPersistedAccount,
} from './persist-result'

describe('buildAccountAttributes', () => {
    const fixedDate = new Date('2026-08-03T10:00:00.000Z')
    const now = () => fixedDate

    it('maps params positionally to param1..param9', () => {
        const attributes = buildAccountAttributes('source-1', 'req-001', ['a', 'b', 'c'], undefined, now)

        expect(attributes.param1).toBe('a')
        expect(attributes.param2).toBe('b')
        expect(attributes.param3).toBe('c')
        expect(attributes.param4).toBeUndefined()
    })

    it('defaults status to success and sets date', () => {
        const attributes = buildAccountAttributes('source-1', 'req-001', undefined, undefined, now)

        expect(attributes.status).toBe('success')
        expect(attributes.date).toBe('2026-08-03T10:00:00.000Z')
        expect(attributes.id).toBe('req-001')
        expect(attributes.sourceId).toBe('source-1')
    })

    it('accepts explicit status override', () => {
        const attributes = buildAccountAttributes('source-1', 'req-001', ['timeout'], 'failed', now)

        expect(attributes.status).toBe('failed')
        expect(attributes.param1).toBe('timeout')
    })

    it('omits unset param attributes for sparse arrays', () => {
        const attributes = buildAccountAttributes('source-1', 'req-001', ['only-one'], undefined, now)

        expect(attributes.param1).toBe('only-one')
        expect(attributes.param2).toBeUndefined()
    })
})

describe('verifyPersistedAccount', () => {
    it('returns empty array when attributes match', () => {
        const expected = { status: 'success', date: '2026-08-03T10:00:00.000Z', param1: 'a' }
        const actual = { status: 'success', date: '2026-08-03T10:00:00.000Z', param1: 'a', extra: 'ignored' }

        expect(verifyPersistedAccount(expected, actual)).toEqual([])
    })

    it('reports mismatched attributes', () => {
        const expected = { status: 'success', param1: 'expected' }
        const actual = { status: 'failed', param1: 'other' }

        expect(verifyPersistedAccount(expected, actual)).toEqual([
            'status: expected "success", got "failed"',
            'param1: expected "expected", got "other"',
        ])
    })

    it('ignores date differences on upsert read-back', () => {
        const expected = { status: 'success', date: '2026-08-03T11:40:08.957Z', param1: 'Hello' }
        const actual = { status: 'success', date: '2026-08-03T11:39:27.259Z', param1: 'Hello' }

        expect(verifyPersistedAccount(expected, actual)).toEqual([])
    })
})

describe('readWithRetry', () => {
    it('retries until account is returned', async () => {
        const readAccount = vi
            .fn()
            .mockResolvedValueOnce(undefined)
            .mockResolvedValueOnce({ status: 'success' })
        const sleep = vi.fn().mockResolvedValue(undefined)

        const result = await readWithRetry(readAccount, 'req-001', 5, 200, sleep)

        expect(result).toEqual({ status: 'success' })
        expect(readAccount).toHaveBeenCalledTimes(2)
        expect(sleep).toHaveBeenCalledWith(200)
    })
})

function createTestDeps(overrides: Partial<Parameters<typeof createPersist>[0]> = {}) {
    let lastWritten: Record<string, string> | undefined

    const base = {
        sourceId: 'source-1',
        createAccount: vi.fn().mockImplementation(async (attributes: Record<string, string>) => {
            lastWritten = attributes
        }),
        readAccount: vi.fn().mockImplementation(async () => lastWritten),
        sleep: vi.fn().mockResolvedValue(undefined),
        ...overrides,
    }

    return base
}

describe('createPersist', () => {
    it('calls account create and verifies matching attributes by default', async () => {
        const deps = createTestDeps()
        const registry = new Map()
        const persist = createPersist(deps, registry)

        await persist('req-001:child', ['value'], 'failed')

        expect(deps.createAccount).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'source-1',
                id: 'req-001:child',
                status: 'failed',
                param1: 'value',
            })
        )
        expect(deps.readAccount).toHaveBeenCalledWith('req-001:child')
        expect(registry.get('req-001:child')).toMatchObject({ param1: 'value', status: 'failed' })
    })

    it('skips inline read when verify is false', async () => {
        const deps = createTestDeps()
        const registry = new Map()
        const persist = createPersist(deps, registry)

        await persist('req-001', ['value'], undefined, { verify: false })

        expect(deps.readAccount).not.toHaveBeenCalled()
        expect(registry.get('req-001')).toMatchObject({ param1: 'value', status: 'success' })
    })

    it('rejects when account cannot be read back', async () => {
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue(undefined),
        })
        const persist = createPersist(deps, new Map())

        await expect(persist('req-001', ['value'])).rejects.toThrow(PersistVerificationError)
        await expect(persist('req-001', ['value'])).rejects.toThrow(/account not found after retries/)
    })

    it('rejects on attribute mismatch', async () => {
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue({
                status: 'failed',
                date: '2026-08-03T10:00:00.000Z',
                param1: 'wrong',
            }),
        })
        const persist = createPersist(deps, new Map())

        await expect(persist('req-001', ['expected'], 'success')).rejects.toThrow(/status: expected/)
    })

    it('verifies sparse params without requiring unset param attributes', async () => {
        const deps = createTestDeps()
        const persist = createPersist(deps, new Map())

        await expect(persist('req-001')).resolves.toBeUndefined()
    })

    it('retries read when account is not immediately available', async () => {
        let lastWritten: Record<string, string> | undefined
        const deps = createTestDeps({
            createAccount: vi.fn().mockImplementation(async (attributes: Record<string, string>) => {
                lastWritten = attributes
            }),
            readAccount: vi
                .fn()
                .mockResolvedValueOnce(undefined)
                .mockImplementation(async () => lastWritten),
        })
        const persist = createPersist(deps, new Map())

        await persist('req-001', ['value'])

        expect(deps.readAccount).toHaveBeenCalledTimes(2)
        expect(deps.sleep).toHaveBeenCalledWith(500)
    })
})

describe('createVerifyPersisted', () => {
    const fixedDate = new Date('2026-08-03T10:00:00.000Z')

    it('verifies all ids against registry expectations', async () => {
        const registry = new Map<string, Record<string, string>>([
            [
                'req-001',
                { status: 'success', date: fixedDate.toISOString(), param1: 'a', sourceId: 'source-1', id: 'req-001' },
            ],
            [
                'req-001:child',
                {
                    status: 'success',
                    date: fixedDate.toISOString(),
                    param1: 'b',
                    sourceId: 'source-1',
                    id: 'req-001:child',
                },
            ],
        ])
        const deps = createTestDeps({
            readAccount: vi
                .fn()
                .mockResolvedValueOnce({ status: 'success', date: fixedDate.toISOString(), param1: 'a' })
                .mockResolvedValueOnce({ status: 'success', date: fixedDate.toISOString(), param1: 'b' }),
        })
        const verifyPersisted = createVerifyPersisted(deps, registry)

        await verifyPersisted(['req-001', 'req-001:child'])

        expect(deps.readAccount).toHaveBeenCalledTimes(2)
    })

    it('rejects unknown identity not in registry', async () => {
        const verifyPersisted = createVerifyPersisted(createTestDeps(), new Map())

        await expect(verifyPersisted(['req-999'])).rejects.toThrow(/was not persisted in this invocation/)
    })

    it('rejects on attribute mismatch during batch verify', async () => {
        const registry = new Map<string, Record<string, string>>([
            ['req-001', { status: 'success', date: fixedDate.toISOString(), param1: 'expected', sourceId: 'source-1', id: 'req-001' }],
        ])
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue({
                status: 'success',
                date: fixedDate.toISOString(),
                param1: 'wrong',
            }),
        })
        const verifyPersisted = createVerifyPersisted(deps, registry)

        await expect(verifyPersisted(['req-001'])).rejects.toThrow(/param1: expected/)
    })

    it('rejects when account missing after retries during batch verify', async () => {
        const registry = new Map<string, Record<string, string>>([
            ['req-001', { status: 'success', date: fixedDate.toISOString(), sourceId: 'source-1', id: 'req-001' }],
        ])
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue(undefined),
        })
        const verifyPersisted = createVerifyPersisted(deps, registry)

        await expect(verifyPersisted(['req-001'])).rejects.toThrow(/account not found after retries/)
    })
})

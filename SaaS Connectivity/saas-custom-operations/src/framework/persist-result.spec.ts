import { describe, expect, it, vi } from 'vitest'
import {
    buildAccountAttributes,
    createPersist,
    createVerifyPersisted,
    PersistVerificationError,
    readWithRetry,
    serializeAttributeValue,
    verifyPersistedAccount,
} from './persist-result'

describe('serializeAttributeValue', () => {
    it('passes strings through', () => {
        expect(serializeAttributeValue('hello')).toBe('hello')
    })

    it('passes string arrays through for multi-valued attributes', () => {
        expect(serializeAttributeValue(['a', 'b'])).toEqual(['a', 'b'])
    })

    it('JSON-stringifies non-string arrays and objects', () => {
        expect(serializeAttributeValue([1, 2])).toBe('[1,2]')
        expect(serializeAttributeValue({ a: 1 })).toBe('{"a":1}')
    })

    it('returns undefined for null and undefined', () => {
        expect(serializeAttributeValue(null)).toBeUndefined()
        expect(serializeAttributeValue(undefined)).toBeUndefined()
    })

    it('coerces numbers to strings', () => {
        expect(serializeAttributeValue(42)).toBe('42')
    })
})

describe('buildAccountAttributes', () => {
    const fixedDate = new Date('2026-08-03T10:00:00.000Z')
    const now = () => fixedDate

    it('maps record keys to account attributes', () => {
        const attributes = buildAccountAttributes('source-1', 'req-001', { outcome: 'processed', count: 42 }, undefined, now)

        expect(attributes.outcome).toBe('processed')
        expect(attributes.count).toBe('42')
        expect(attributes.status).toBe('success')
        expect(attributes.date).toBe('2026-08-03T10:00:00.000Z')
        expect(attributes.id).toBe('req-001')
        expect(attributes.sourceId).toBe('source-1')
    })

    it('accepts explicit status override', () => {
        const attributes = buildAccountAttributes('source-1', 'req-001:err', { errorCode: 'timeout' }, 'failed', now)

        expect(attributes.status).toBe('failed')
        expect(attributes.errorCode).toBe('timeout')
    })

    it('preserves string array values for multi-valued attributes', () => {
        const attributes = buildAccountAttributes(
            'source-1',
            'req-001',
            { name: 'Fernando', emails: ['dfas', 'fasdfas'] },
            undefined,
            now
        )

        expect(attributes.name).toBe('Fernando')
        expect(attributes.emails).toEqual(['dfas', 'fasdfas'])
    })

    it('ignores reserved keys from author attributes', () => {
        const attributes = buildAccountAttributes(
            'source-1',
            'req-001',
            { outcome: 'ok', id: 'override', status: 'override' },
            undefined,
            now
        )

        expect(attributes.id).toBe('req-001')
        expect(attributes.status).toBe('success')
        expect(attributes.outcome).toBe('ok')
    })
})

describe('verifyPersistedAccount', () => {
    it('returns empty array when attributes match', () => {
        const expected = { status: 'success', date: '2026-08-03T10:00:00.000Z', outcome: 'a' }
        const actual = { status: 'success', date: '2026-08-03T10:00:00.000Z', outcome: 'a', extra: 'ignored' }

        expect(verifyPersistedAccount(expected, actual)).toEqual([])
    })

    it('reports mismatched attributes', () => {
        const expected = { status: 'success', outcome: 'expected' }
        const actual = { status: 'failed', outcome: 'other' }

        expect(verifyPersistedAccount(expected, actual)).toEqual([
            'status: expected "success", got "failed"',
            'outcome: expected "expected", got "other"',
        ])
    })

    it('ignores date differences on upsert read-back', () => {
        const expected = { status: 'success', date: '2026-08-03T11:40:08.957Z', outcome: 'Hello' }
        const actual = { status: 'success', date: '2026-08-03T11:39:27.259Z', outcome: 'Hello' }

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
    let lastWritten: Record<string, string | string[]> | undefined

    const base = {
        sourceId: 'source-1',
        createAccount: vi.fn().mockImplementation(async (attributes: Record<string, string | string[]>) => {
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
        const persist = createPersist<{ errorCode: string }>(deps, registry)

        await persist('req-001:child', { errorCode: 'value' }, 'failed')

        expect(deps.createAccount).toHaveBeenCalledWith(
            expect.objectContaining({
                sourceId: 'source-1',
                id: 'req-001:child',
                status: 'failed',
                errorCode: 'value',
            })
        )
        expect(deps.readAccount).toHaveBeenCalledWith('req-001:child')
        expect(registry.get('req-001:child')).toMatchObject({ errorCode: 'value', status: 'failed' })
    })

    it('skips inline read when verify is false', async () => {
        const deps = createTestDeps()
        const registry = new Map()
        const persist = createPersist<{ outcome: string }>(deps, registry)

        await persist('req-001', { outcome: 'value' }, undefined, { verify: false })

        expect(deps.readAccount).not.toHaveBeenCalled()
        expect(registry.get('req-001')).toMatchObject({ outcome: 'value', status: 'success' })
    })

    it('rejects when account cannot be read back', async () => {
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue(undefined),
        })
        const persist = createPersist<{ outcome: string }>(deps, new Map())

        await expect(persist('req-001', { outcome: 'value' })).rejects.toThrow(PersistVerificationError)
        await expect(persist('req-001', { outcome: 'value' })).rejects.toThrow(/account not found after retries/)
    })

    it('rejects on attribute mismatch', async () => {
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue({
                status: 'failed',
                date: '2026-08-03T10:00:00.000Z',
                outcome: 'wrong',
            }),
        })
        const persist = createPersist<{ outcome: string }>(deps, new Map())

        await expect(persist('req-001', { outcome: 'expected' }, 'success')).rejects.toThrow(/status: expected/)
    })

    it('verifies sparse attributes without requiring unset fields', async () => {
        const deps = createTestDeps()
        const persist = createPersist(deps, new Map())

        await expect(persist('req-001')).resolves.toBeUndefined()
    })

    it('retries read when account is not immediately available', async () => {
        let lastWritten: Record<string, string | string[]> | undefined
        const deps = createTestDeps({
            createAccount: vi.fn().mockImplementation(async (attributes: Record<string, string | string[]>) => {
                lastWritten = attributes
            }),
            readAccount: vi
                .fn()
                .mockResolvedValueOnce(undefined)
                .mockImplementation(async () => lastWritten),
        })
        const persist = createPersist<{ outcome: string }>(deps, new Map())

        await persist('req-001', { outcome: 'value' })

        expect(deps.readAccount).toHaveBeenCalledTimes(2)
        expect(deps.sleep).toHaveBeenCalledWith(500)
    })

    it('preserves string array attributes on persist', async () => {
        const deps = createTestDeps()
        const persist = createPersist<{ name: string; emails: string[] }>(deps, new Map())

        await persist('req-001', { name: 'Fernando', emails: ['dfas', 'fasdfas'] })

        expect(deps.createAccount).toHaveBeenCalledWith(
            expect.objectContaining({
                name: 'Fernando',
                emails: ['dfas', 'fasdfas'],
            })
        )
    })
})

describe('createVerifyPersisted', () => {
    const fixedDate = new Date('2026-08-03T10:00:00.000Z')

    it('verifies all ids against registry expectations', async () => {
        const registry = new Map<string, Record<string, string | string[]>>([
            [
                'req-001',
                { status: 'success', date: fixedDate.toISOString(), outcome: 'a', sourceId: 'source-1', id: 'req-001' },
            ],
            [
                'req-001:child',
                {
                    status: 'success',
                    date: fixedDate.toISOString(),
                    outcome: 'b',
                    sourceId: 'source-1',
                    id: 'req-001:child',
                },
            ],
        ])
        const deps = createTestDeps({
            readAccount: vi
                .fn()
                .mockResolvedValueOnce({ status: 'success', date: fixedDate.toISOString(), outcome: 'a' })
                .mockResolvedValueOnce({ status: 'success', date: fixedDate.toISOString(), outcome: 'b' }),
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
        const registry = new Map<string, Record<string, string | string[]>>([
            ['req-001', { status: 'success', date: fixedDate.toISOString(), outcome: 'expected', sourceId: 'source-1', id: 'req-001' }],
        ])
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue({
                status: 'success',
                date: fixedDate.toISOString(),
                outcome: 'wrong',
            }),
        })
        const verifyPersisted = createVerifyPersisted(deps, registry)

        await expect(verifyPersisted(['req-001'])).rejects.toThrow(/outcome: expected/)
    })

    it('rejects when account missing after retries during batch verify', async () => {
        const registry = new Map<string, Record<string, string | string[]>>([
            ['req-001', { status: 'success', date: fixedDate.toISOString(), sourceId: 'source-1', id: 'req-001' }],
        ])
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue(undefined),
        })
        const verifyPersisted = createVerifyPersisted(deps, registry)

        await expect(verifyPersisted(['req-001'])).rejects.toThrow(/account not found after retries/)
    })
})


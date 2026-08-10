import { describe, expect, it, vi } from 'vitest'
import {
    buildAccountAttributes,
    createPersist,
    createVerifyPersisted,
    formatAttributeValue,
    PersistVerificationError,
    readWithRetry,
    upsertSourceAccount,
    verifyAccountWrite,
    verifyPersistedAccount,
} from './persist-result'

describe('formatAttributeValue', () => {
    it('passes strings through', () => {
        expect(formatAttributeValue('hello')).toBe('hello')
    })

    it('keeps numbers as numbers', () => {
        expect(formatAttributeValue(42, 'number')).toBe(42)
    })

    it('keeps booleans as booleans', () => {
        expect(formatAttributeValue(true, 'boolean')).toBe(true)
    })

    it('JSON-stringifies objects', () => {
        expect(formatAttributeValue({ key: 'value' }, 'Record<string, unknown>')).toBe('{"key":"value"}')
    })

    it('returns undefined for null and undefined', () => {
        expect(formatAttributeValue(null)).toBeUndefined()
        expect(formatAttributeValue(undefined)).toBeUndefined()
    })

    it('formats string arrays', () => {
        expect(formatAttributeValue(['a', 'b'], 'string[]')).toEqual(['a', 'b'])
    })
})

describe('buildAccountAttributes', () => {
    const fixedDate = new Date('2026-08-03T10:00:00.000Z')
    const now = () => fixedDate
    const outputFields = [{ name: 'outcome', type: 'string' }, { name: 'count', type: 'number' }]

    it('maps record keys to account attributes with typed values', () => {
        const attributes = buildAccountAttributes(
            'source-1',
            'req-001',
            { outcome: 'processed', count: 42 },
            undefined,
            outputFields,
            now
        )

        expect(attributes.outcome).toBe('processed')
        expect(attributes.count).toBe(42)
        expect(attributes.status).toBe('success')
        expect(attributes.date).toBe('2026-08-03T10:00:00.000Z')
        expect(attributes.id).toBe('req-001')
        expect(attributes.sourceId).toBe('source-1')
    })

    it('accepts explicit status override', () => {
        const attributes = buildAccountAttributes(
            'source-1',
            'req-001:err',
            { errorCode: 'timeout' },
            'failed',
            [{ name: 'errorCode', type: 'string' }],
            now
        )

        expect(attributes.status).toBe('failed')
        expect(attributes.errorCode).toBe('timeout')
    })

    it('formats array values per element type', () => {
        const attributes = buildAccountAttributes(
            'source-1',
            'req-001',
            { name: 'Fernando', emails: ['dfas', 'fasdfas'] },
            undefined,
            [
                { name: 'name', type: 'string' },
                { name: 'emails', type: 'string[]' },
            ],
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
            [{ name: 'outcome', type: 'string' }],
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

    it('coerces string read-back for numeric values', () => {
        const expected = { status: 'success', count: 42 }
        const actual = { status: 'success', count: '42' }

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

describe('verifyAccountWrite', () => {
    it('retries until persisted attributes match', async () => {
        const readAccount = vi
            .fn()
            .mockResolvedValueOnce({ formUrl: 'https://old.example/form/1' })
            .mockResolvedValueOnce({ formUrl: 'https://new.example/form/2' })
        const sleep = vi.fn().mockResolvedValue(undefined)

        await verifyAccountWrite(
            {
                sourceId: 'source-1',
                upsertAccount: vi.fn(),
                readAccount,
                sleep,
            },
            'req-001',
            { formUrl: 'https://new.example/form/2' }
        )

        expect(readAccount).toHaveBeenCalledTimes(2)
        expect(sleep).toHaveBeenCalledWith(500)
    })
})

describe('upsertSourceAccount', () => {
    it('creates when no account exists for native identity', async () => {
        const createAccountV1 = vi.fn().mockResolvedValue({})
        const putAccountV1 = vi.fn().mockResolvedValue({})
        const listAccountsV1 = vi.fn().mockResolvedValue({ data: [] })
        const accounts = { createAccountV1, putAccountV1, listAccountsV1 }

        await upsertSourceAccount(accounts as never, 'source-1', {
            sourceId: 'source-1',
            id: 'req-001',
            formUrl: 'https://example.com/form/1',
        })

        expect(createAccountV1).toHaveBeenCalled()
        expect(putAccountV1).not.toHaveBeenCalled()
    })

    it('puts when account already exists for native identity', async () => {
        const createAccountV1 = vi.fn().mockResolvedValue({})
        const putAccountV1 = vi.fn().mockResolvedValue({})
        const listAccountsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'isc-account-1', attributes: { id: 'req-001', formUrl: 'https://old.example/form/1' } }],
        })
        const accounts = { createAccountV1, putAccountV1, listAccountsV1 }

        await upsertSourceAccount(accounts as never, 'source-1', {
            sourceId: 'source-1',
            id: 'req-001',
            formUrl: 'https://new.example/form/2',
        })

        expect(putAccountV1).toHaveBeenCalledWith(
            expect.objectContaining({
                id: 'isc-account-1',
                accountAttributes: expect.objectContaining({
                    attributes: expect.objectContaining({ formUrl: 'https://new.example/form/2' }),
                }),
            })
        )
        expect(createAccountV1).not.toHaveBeenCalled()
    })

    it('rejects when list returns account without ISC id', async () => {
        const accounts = {
            createAccountV1: vi.fn(),
            putAccountV1: vi.fn(),
            listAccountsV1: vi.fn().mockResolvedValue({
                data: [{ attributes: { id: 'req-001' } }],
            }),
        }

        await expect(
            upsertSourceAccount(accounts as never, 'source-1', {
                sourceId: 'source-1',
                id: 'req-001',
                outcome: 'new',
            })
        ).rejects.toThrow(/missing ISC account id/)

        expect(accounts.createAccountV1).not.toHaveBeenCalled()
        expect(accounts.putAccountV1).not.toHaveBeenCalled()
    })
})

function createTestDeps(overrides: Partial<Parameters<typeof createPersist>[0]> = {}) {
    let lastWritten: Record<string, unknown> | undefined

    const base = {
        sourceId: 'source-1',
        ensureSourceSchema: vi.fn().mockResolvedValue(undefined),
        upsertAccount: vi.fn().mockImplementation(async (attributes: Record<string, unknown>) => {
            lastWritten = attributes
        }),
        readAccount: vi.fn().mockImplementation(async () => lastWritten),
        sleep: vi.fn().mockResolvedValue(undefined),
        ...overrides,
    }

    return base
}

describe('createPersist', () => {
    it('calls ensureSourceSchema before account create', async () => {
        const deps = createTestDeps()
        const persist = createPersist<{ errorCode: string }>(deps, new Map())

        await persist('req-001:child', { errorCode: 'value' }, 'failed')

        expect(deps.ensureSourceSchema).toHaveBeenCalledWith(['errorCode'])
    })

    it('calls account create and verifies matching attributes by default', async () => {
        const deps = createTestDeps()
        const registry = new Map()
        const persist = createPersist<{ errorCode: string }>(deps, registry)

        await persist('req-001:child', { errorCode: 'value' }, 'failed')

        expect(deps.upsertAccount).toHaveBeenCalledWith(
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

    it('stores typed number values', async () => {
        const deps = createTestDeps({
            operationSchema: { outputFields: [{ name: 'count', type: 'number' }] },
        })
        const persist = createPersist<{ count: number }>(deps, new Map())

        await persist('req-001', { count: 42 })

        expect(deps.upsertAccount).toHaveBeenCalledWith(expect.objectContaining({ count: 42 }))
    })

    it('stores boolean values and verifies read-back', async () => {
        const deps = createTestDeps({
            operationSchema: { outputFields: [{ name: 'active', type: 'boolean' }] },
        })
        const persist = createPersist<{ active: boolean }>(deps, new Map())

        await persist('req-001', { active: true })

        expect(deps.upsertAccount).toHaveBeenCalledWith(expect.objectContaining({ active: true }))
        expect(deps.readAccount).toHaveBeenCalledWith('req-001')
    })

    it('serializes object values and verifies read-back', async () => {
        const deps = createTestDeps({
            operationSchema: { outputFields: [{ name: 'meta', type: 'Record<string, unknown>' }] },
        })
        const persist = createPersist<{ meta: Record<string, unknown> }>(deps, new Map())

        await persist('req-001', { meta: { key: 'value' } })

        expect(deps.upsertAccount).toHaveBeenCalledWith(
            expect.objectContaining({ meta: '{"key":"value"}' })
        )
        expect(deps.readAccount).toHaveBeenCalledWith('req-001')
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
        let lastWritten: Record<string, unknown> | undefined
        const deps = createTestDeps({
            upsertAccount: vi.fn().mockImplementation(async (attributes: Record<string, unknown>) => {
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

    it('upserts duplicate identity and verifies updated read-back', async () => {
        let lastWritten: Record<string, unknown> | undefined = {
            status: 'success',
            outcome: 'original',
            sourceId: 'source-1',
            id: 'req-001',
        }
        const deps = createTestDeps({
            upsertAccount: vi.fn().mockImplementation(async (attributes: Record<string, unknown>) => {
                lastWritten = attributes
            }),
            readAccount: vi.fn().mockImplementation(async () => lastWritten),
        })
        const persist = createPersist<{ outcome: string }>(deps, new Map())

        await persist('req-001', { outcome: 'updated' })

        expect(deps.upsertAccount).toHaveBeenCalledWith(
            expect.objectContaining({ id: 'req-001', outcome: 'updated' })
        )
        expect(deps.readAccount).toHaveBeenCalledWith('req-001')
    })

    it('formats array attributes on persist', async () => {
        const deps = createTestDeps({
            operationSchema: {
                outputFields: [
                    { name: 'name', type: 'string' },
                    { name: 'emails', type: 'string[]' },
                ],
            },
        })
        const persist = createPersist<{ name: string; emails: string[] }>(deps, new Map())

        await persist('req-001', { name: 'Fernando', emails: ['dfas', 'fasdfas'] })

        expect(deps.upsertAccount).toHaveBeenCalledWith(
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
        const registry = new Map<string, Record<string, unknown>>([
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
        const registry = new Map<string, Record<string, unknown>>([
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
        const registry = new Map<string, Record<string, unknown>>([
            ['req-001', { status: 'success', date: fixedDate.toISOString(), sourceId: 'source-1', id: 'req-001' }],
        ])
        const deps = createTestDeps({
            readAccount: vi.fn().mockResolvedValue(undefined),
        })
        const verifyPersisted = createVerifyPersisted(deps, registry)

        await expect(verifyPersisted(['req-001'])).rejects.toThrow(/account not found after retries/)
    })
})

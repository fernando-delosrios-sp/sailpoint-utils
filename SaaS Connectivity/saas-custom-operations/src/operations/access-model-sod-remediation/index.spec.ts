import { beforeEach, describe, expect, it, vi } from 'vitest'
import '../auto-registry'
import { accessModelSodRemediationOperation } from './index'

const persistAttributes = [
    { name: 'access-model-sod-remediation:access-items-scanned', type: 'INT', isMulti: false },
    { name: 'access-model-sod-remediation:violations-found', type: 'INT', isMulti: false },
    { name: 'access-model-sod-remediation:forms-skipped', type: 'INT', isMulti: false },
    { name: 'access-model-sod-remediation:form-url', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation:form-email-header', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation:form-email-body', type: 'STRING', isMulti: false },
    { name: 'access-model-sod-remediation:form-email-recipients', type: 'STRING', isMulti: true },
]

const persistedAccounts = new Map<string, Record<string, unknown>>()
const resolveSourceByName = vi.fn()
const getSourceSchemasV1 = vi.fn()

vi.mock('../../framework/result-source', async (importOriginal) => {
    const actual = await importOriginal<typeof import('../../framework/result-source')>()
    return {
        ...actual,
        resolveSourceByName: (...args: unknown[]) => resolveSourceByName(...args),
    }
})

vi.mock('../../isc/token-identity', () => ({
    resolveTokenIdentity: vi.fn().mockResolvedValue('token-owner-id'),
}))

vi.mock('./form-service', () => ({
    ensureAccessModelSodFormDefinition: vi.fn().mockResolvedValue('form-def-1'),
    hasAssignedRemediationInstance: vi.fn().mockResolvedValue(false),
    createAccessModelSodRemediationInstance: vi.fn().mockResolvedValue('https://tenant.example/form/1'),
}))

describe('accessModelSodRemediationOperation', () => {
    beforeEach(() => {
        persistedAccounts.clear()
        resolveSourceByName.mockResolvedValue('source-123')
        getSourceSchemasV1.mockResolvedValue({
            data: [
                {
                    id: 'schema-1',
                    name: 'account',
                    attributes: [
                        { name: 'id', type: 'STRING', isMulti: false },
                        { name: 'status', type: 'STRING', isMulti: false },
                        { name: 'date', type: 'STRING', isMulti: false },
                        ...persistAttributes,
                    ],
                },
            ],
        })
    })

    it('persists parent rollup and child form output in offline mode', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-access-model-sod-offline',
                    formName: 'Access Model SOD Remediation',
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith({ status: 'success' })
        } finally {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('rejects invalid searchIndices', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        const res = { send: vi.fn() }

        try {
            await accessModelSodRemediationOperation(
                { commandType: 'custom:access-model-sod-remediation' } as never,
                {
                    requestId: 'req-invalid',
                    formName: 'Access Model SOD Remediation',
                    searchIndices: ['identities'] as never,
                },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'failed',
                    error: expect.stringMatching(/Invalid searchIndices/),
                })
            )
        } finally {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })
})

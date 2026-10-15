import { beforeEach, describe, expect, it, vi } from 'vitest'
import { accessClassificationOperation } from './index'

vi.mock('../../framework/sdk-factory', () => ({
    createSailPointClients: vi.fn(() => ({
        sources: {
            getSourceSchemasV1: vi.fn(),
            updateSourceSchemaV1: vi.fn(),
            createSourceSchemaV1: vi.fn(),
        },
        accounts: {
            createAccountV1: vi.fn(),
            deleteAccountAsyncV1: vi.fn(),
            listAccountsV1: vi.fn(),
            putAccountV1: vi.fn(),
            getAccountV1: vi.fn(),
        },
        tasks: {
            getTaskStatusV1: vi.fn().mockResolvedValue({
                data: { completed: '2026-08-11T10:00:00Z', completionStatus: 'SUCCESS', messages: [] },
            }),
        },
        tags: { listTagsV1: vi.fn(), createTagV1: vi.fn() },
        taggedObjects: {
            listTaggedObjectsV1: vi.fn(),
            setTagsToManyObjectsV1: vi.fn(),
            deleteTagsToManyObjectV1: vi.fn(),
        },
        entitlements: { listEntitlementsV1: vi.fn() },
        accessProfiles: { listAccessProfilesV1: vi.fn() },
        roles: { listRolesV1: vi.fn() },
        sodPolicies: { listSodPoliciesV1: vi.fn() },
    })),
}))

describe('custom:access-classification', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('Offline invoke reconciles canned desired tags without live HTTP', async () => {
        const previousTestMode = process.env.SPCX_TEST_MODE
        process.env.SPCX_TEST_MODE = '1'
        try {
            const res = { send: vi.fn() }
            await accessClassificationOperation(
                { commandType: 'custom:access-classification' } as never,
                { requestId: 'access-classification:offline' },
                res as never
            )

            expect(res.send).toHaveBeenCalledWith(
                expect.objectContaining({
                    status: 'success',
                    responses: ['access-classification:offline'],
                    summary: expect.objectContaining({
                        entitlementsScanned: 5,
                        accessProfilesScanned: 4,
                        rolesScanned: 3,
                        identitiesScanned: 2,
                        tagsAdded: expect.any(Number),
                        tagsRemoved: expect.any(Number),
                        objectsFailed: 0,
                    }),
                })
            )
            const summary = res.send.mock.calls[0][0].summary
            expect(summary.tagsAdded).toBeGreaterThan(0)
            expect(summary.tagsRemoved).toBeGreaterThan(0)
        } finally {
            if (previousTestMode === undefined) {
                delete process.env.SPCX_TEST_MODE
            } else {
                process.env.SPCX_TEST_MODE = previousTestMode
            }
        }
    })

    it('Auto-discovery registration', async () => {
        const { OPERATION_HANDLERS } = await import('../auto-registry')
        const spec = await import('../../../connector-spec.json')
        expect(OPERATION_HANDLERS['custom:access-classification']).toBeDefined()
        expect(spec.default.commands).toContain('custom:access-classification')
    })

    it('Follows namespacing convention', async () => {
        const { accessClassificationOperationSchema } = await import('./index.schema')
        const names = accessClassificationOperationSchema.outputFields.map((field) => field.name)
        expect(names).toEqual(
            expect.arrayContaining([
                'access-classification:entitlements-scanned',
                'access-classification:access-profiles-scanned',
                'access-classification:roles-scanned',
                'access-classification:identities-scanned',
                'access-classification:tags-added',
                'access-classification:tags-removed',
                'access-classification:objects-failed',
                'access-classification:failure-details',
            ])
        )
    })
})

import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { FORM_INSTANCE_LIST_PAGE_SIZE, getFormInstanceByDefinitionAndId } from './find-form-instance'

describe('isc/forms getFormInstanceByDefinitionAndId', () => {
    it('Filter and pick', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    id: 'fi-other',
                    state: 'ASSIGNED',
                    formInput: { accessItemId: 'other' },
                    formData: {},
                },
                {
                    id: 'fi-1',
                    state: 'COMPLETED',
                    formInput: { accessItemId: 'role-1', groupAIds: '["ent-a"]' },
                    formData: { remediationSide: 'groupA' },
                },
            ],
        })

        const result = await getFormInstanceByDefinitionAndId(
            { searchFormInstancesByTenantV1 } as never,
            'fd-1',
            'fi-1'
        )

        expect(searchFormInstancesByTenantV1).toHaveBeenCalledWith({
            offset: 0,
            limit: FORM_INSTANCE_LIST_PAGE_SIZE,
            filters: 'formDefinitionId eq "fd-1"',
        })
        expect(result.id).toBe('fi-1')
        expect(result.formInput.accessItemId).toBe('role-1')
        expect(result.formData.remediationSide).toBe('groupA')
    })

    it('Pagination continues until match or exhaustion', async () => {
        const firstPage = Array.from({ length: FORM_INSTANCE_LIST_PAGE_SIZE }, (_, index) => ({
            id: `fi-other-${index}`,
            state: 'ASSIGNED',
            formInput: {},
            formData: {},
        }))
        const searchFormInstancesByTenantV1 = vi
            .fn()
            .mockResolvedValueOnce({ data: firstPage })
            .mockResolvedValueOnce({
                data: [
                    {
                        id: 'fi-1',
                        state: 'COMPLETED',
                        formInput: { accessItemId: 'role-1' },
                        formData: { remediationSide: 'groupA' },
                    },
                ],
            })

        const result = await getFormInstanceByDefinitionAndId(
            { searchFormInstancesByTenantV1 } as never,
            'fd-1',
            'fi-1'
        )

        expect(searchFormInstancesByTenantV1).toHaveBeenNthCalledWith(2, {
            offset: FORM_INSTANCE_LIST_PAGE_SIZE,
            limit: FORM_INSTANCE_LIST_PAGE_SIZE,
            filters: 'formDefinitionId eq "fd-1"',
        })
        expect(result.id).toBe('fi-1')
        expect(searchFormInstancesByTenantV1).toHaveBeenCalledTimes(2)
    })

    it('Missing instance surfaced as ConnectorError', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({ data: [] })

        await expect(
            getFormInstanceByDefinitionAndId({ searchFormInstancesByTenantV1 } as never, 'fd-1', 'fi-missing')
        ).rejects.toBeInstanceOf(ConnectorError)
        await expect(
            getFormInstanceByDefinitionAndId({ searchFormInstancesByTenantV1 } as never, 'fd-1', 'fi-missing')
        ).rejects.toThrow(/not found/)
    })

    it('shared formInput and formData normalization including formInstanceInputs', async () => {
        const searchFormInstancesByTenantV1 = vi.fn().mockResolvedValue({
            data: [
                {
                    id: 'fi-2',
                    state: 'COMPLETED',
                    formInput: {
                        accessItemType: {
                            id: 'accessItemType',
                            type: 'STRING',
                            label: 'Access Item Type',
                            value: 'ROLE',
                        },
                    },
                    formInstanceInputs: [
                        { id: 'accessItemId', value: 'role-2' },
                        { id: 'groupAIds', value: '["ent-a"]' },
                    ],
                    formData: { remediationSide: 'groupB' },
                    recipients: [{ id: 'owner-1' }],
                },
            ],
        })

        const result = await getFormInstanceByDefinitionAndId(
            { searchFormInstancesByTenantV1 } as never,
            'fd-quote""id',
            'fi-2'
        )

        expect(searchFormInstancesByTenantV1).toHaveBeenCalledWith({
            offset: 0,
            limit: FORM_INSTANCE_LIST_PAGE_SIZE,
            filters: 'formDefinitionId eq "fd-quote""""id"',
        })
        expect(result.formInput.accessItemType).toBe('ROLE')
        expect(result.formInput.accessItemId).toBe('role-2')
        expect(result.formInput.groupAIds).toBe('["ent-a"]')
        expect(result.formData.remediationSide).toBe('groupB')
        expect(result.submitterId).toBe('owner-1')
    })
})

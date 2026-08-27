import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it, vi } from 'vitest'
import { getFormInstanceById } from './get-form-instance'

describe('isc/forms getFormInstanceById', () => {
    it('Flat formInput returned', async () => {
        const getFormInstanceByKeyV1 = vi.fn().mockResolvedValue({
            data: {
                id: 'fi-1',
                state: 'COMPLETED',
                formInput: { accessItemId: 'role-1', groupAIds: '["ent-a"]' },
                formData: { remediationSide: 'groupA' },
            },
        })

        const result = await getFormInstanceById({ getFormInstanceByKeyV1 } as never, 'fi-1')

        expect(getFormInstanceByKeyV1).toHaveBeenCalledWith({ formInstanceID: 'fi-1' })
        expect(result.formInput.accessItemId).toBe('role-1')
        expect(result.formData.remediationSide).toBe('groupA')
    })

    it('unwraps ISC formInput field objects to their value', async () => {
        const getFormInstanceByKeyV1 = vi.fn().mockResolvedValue({
            data: {
                id: 'fi-3',
                state: 'COMPLETED',
                formInput: {
                    accessItemType: {
                        id: 'accessItemType',
                        type: 'STRING',
                        label: 'Access Item Type',
                        description: 'ROLE or ACCESS_PROFILE',
                        value: 'ROLE',
                    },
                    accessItemId: 'role-3',
                },
                formData: { remediationSide: 'groupA' },
            },
        })

        const result = await getFormInstanceById({ getFormInstanceByKeyV1 } as never, 'fi-3')

        expect(result.formInput.accessItemType).toBe('ROLE')
        expect(result.formInput.accessItemId).toBe('role-3')
    })

    it('formInstanceInputs normalized when present', async () => {
        const getFormInstanceByKeyV1 = vi.fn().mockResolvedValue({
            data: {
                id: 'fi-2',
                state: 'COMPLETED',
                formInstanceInputs: [
                    { id: 'accessItemId', value: 'role-2' },
                    { id: 'groupAIds', value: '["ent-a"]' },
                ],
                formData: { remediationSide: 'groupB' },
            },
        })

        const result = await getFormInstanceById({ getFormInstanceByKeyV1 } as never, 'fi-2')

        expect(result.formInput.accessItemId).toBe('role-2')
        expect(result.formInput.groupAIds).toBe('["ent-a"]')
    })

    it('API errors surfaced as ConnectorError', async () => {
        const getFormInstanceByKeyV1 = vi.fn().mockRejectedValue({
            status: 404,
            data: { messages: [{ text: 'not found' }] },
        })

        await expect(getFormInstanceById({ getFormInstanceByKeyV1 } as never, 'missing')).rejects.toBeInstanceOf(
            ConnectorError
        )
    })

    it('throws ConnectorError when instance id is missing', async () => {
        const getFormInstanceByKeyV1 = vi.fn().mockResolvedValue({ data: {} })

        await expect(getFormInstanceById({ getFormInstanceByKeyV1 } as never, 'missing')).rejects.toThrow(
            /not found/
        )
    })
})

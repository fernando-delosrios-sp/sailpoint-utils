import { ConnectorError } from '@sailpoint/connector-sdk'
import { GovernanceGroupsApi } from 'sailpoint-api-client'
import { describe, expect, it, vi } from 'vitest'
import { findWorkgroupByName } from './find-workgroup-by-name'

describe('findWorkgroupByName', () => {
    it('calls listWorkgroupsV1 with OData name filter and returns first exact match', async () => {
        const listWorkgroupsV1 = vi.fn().mockResolvedValue({
            data: [
                { id: 'wg-other', name: 'Other Group' },
                { id: 'wg-1', name: 'My Group' },
            ],
        })
        const governanceGroups = { listWorkgroupsV1 } as unknown as GovernanceGroupsApi

        await expect(findWorkgroupByName(governanceGroups, 'My Group')).resolves.toEqual({
            id: 'wg-1',
            name: 'My Group',
        })
        expect(listWorkgroupsV1).toHaveBeenCalledWith({ filters: 'name eq "My Group"' })
    })

    it('escapes double quotes in group name for OData filter', async () => {
        const listWorkgroupsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'wg-1', name: 'Team "Alpha"' }],
        })
        const governanceGroups = { listWorkgroupsV1 } as unknown as GovernanceGroupsApi

        await findWorkgroupByName(governanceGroups, 'Team "Alpha"')
        expect(listWorkgroupsV1).toHaveBeenCalledWith({ filters: 'name eq "Team ""Alpha"""' })
    })

    it('throws ConnectorError when no workgroup matches', async () => {
        const governanceGroups = {
            listWorkgroupsV1: vi.fn().mockResolvedValue({ data: [] }),
        } as unknown as GovernanceGroupsApi

        await expect(findWorkgroupByName(governanceGroups, 'Missing Group')).rejects.toBeInstanceOf(
            ConnectorError
        )
        await expect(findWorkgroupByName(governanceGroups, 'Missing Group')).rejects.toThrow(
            'Governance group not found: "Missing Group"'
        )
    })

    it('throws ConnectorError with HTTP status when listWorkgroupsV1 fails', async () => {
        const governanceGroups = {
            listWorkgroupsV1: vi.fn().mockRejectedValue({ status: 403, message: 'Forbidden' }),
        } as unknown as GovernanceGroupsApi

        await expect(findWorkgroupByName(governanceGroups, 'My Group')).rejects.toThrow(
            'Failed to lookup governance group "My Group" with status 403'
        )
    })
})

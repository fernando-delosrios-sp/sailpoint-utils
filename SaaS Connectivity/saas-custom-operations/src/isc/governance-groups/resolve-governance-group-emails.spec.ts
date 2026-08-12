import { ConnectorError } from '@sailpoint/connector-sdk'
import { GovernanceGroupsApi } from 'sailpoint-api-client'
import { describe, expect, it, vi } from 'vitest'
import { resolveGovernanceGroupEmails } from './resolve-governance-group-emails'

describe('resolveGovernanceGroupEmails', () => {
    it('chains workgroup lookup and member email listing', async () => {
        const listWorkgroupsV1 = vi.fn().mockResolvedValue({
            data: [{ id: 'wg-1', name: 'Approvers' }],
        })
        const listWorkgroupMembersV1 = vi.fn().mockResolvedValue({
            data: [{ email: 'a@example.com' }, { email: 'b@example.com' }],
        })
        const governanceGroups = { listWorkgroupsV1, listWorkgroupMembersV1 } as unknown as GovernanceGroupsApi

        await expect(resolveGovernanceGroupEmails(governanceGroups, 'Approvers')).resolves.toEqual([
            'a@example.com',
            'b@example.com',
        ])
        expect(listWorkgroupMembersV1).toHaveBeenCalledWith(
            expect.objectContaining({ workgroupId: 'wg-1' })
        )
    })

    it('propagates ConnectorError when group is missing', async () => {
        const governanceGroups = {
            listWorkgroupsV1: vi.fn().mockResolvedValue({ data: [] }),
        } as unknown as GovernanceGroupsApi

        await expect(resolveGovernanceGroupEmails(governanceGroups, 'Missing Group')).rejects.toBeInstanceOf(
            ConnectorError
        )
    })
})

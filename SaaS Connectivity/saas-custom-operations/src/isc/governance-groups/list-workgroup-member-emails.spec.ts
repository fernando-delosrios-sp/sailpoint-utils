import { GovernanceGroupsApi } from 'sailpoint-api-client'
import { describe, expect, it, vi } from 'vitest'
import { listWorkgroupMemberEmails } from './list-workgroup-member-emails'

describe('listWorkgroupMemberEmails', () => {
    it('extracts non-empty email fields from member response', async () => {
        const listWorkgroupMembersV1 = vi.fn().mockResolvedValue({
            data: [{ email: 'a@example.com' }, { email: 'b@example.com' }],
        })
        const governanceGroups = { listWorkgroupMembersV1 } as unknown as GovernanceGroupsApi

        await expect(listWorkgroupMemberEmails(governanceGroups, 'wg-1')).resolves.toEqual([
            'a@example.com',
            'b@example.com',
        ])
    })

    it('omits members with blank or missing email', async () => {
        const listWorkgroupMembersV1 = vi.fn().mockResolvedValue({
            data: [{ email: 'a@example.com' }, { email: '' }, { email: '   ' }, {}],
        })
        const governanceGroups = { listWorkgroupMembersV1 } as unknown as GovernanceGroupsApi

        await expect(listWorkgroupMemberEmails(governanceGroups, 'wg-1')).resolves.toEqual([
            'a@example.com',
        ])
    })

    it('paginates when multiple pages are returned', async () => {
        const pageOne = Array.from({ length: 250 }, (_, index) => ({ email: `page1-${index}@example.com` }))
        const pageTwo = [{ email: 'page2-0@example.com' }]
        const listWorkgroupMembersV1 = vi
            .fn()
            .mockResolvedValueOnce({ data: pageOne })
            .mockResolvedValueOnce({ data: pageTwo })
        const governanceGroups = { listWorkgroupMembersV1 } as unknown as GovernanceGroupsApi

        const emails = await listWorkgroupMemberEmails(governanceGroups, 'wg-1')

        expect(listWorkgroupMembersV1).toHaveBeenCalledTimes(2)
        expect(listWorkgroupMembersV1).toHaveBeenNthCalledWith(1, {
            workgroupId: 'wg-1',
            offset: 0,
            limit: 250,
        })
        expect(listWorkgroupMembersV1).toHaveBeenNthCalledWith(2, {
            workgroupId: 'wg-1',
            offset: 250,
            limit: 250,
        })
        expect(emails).toHaveLength(251)
        expect(emails[250]).toBe('page2-0@example.com')
    })

    it('throws ConnectorError with HTTP status when listWorkgroupMembersV1 fails', async () => {
        const governanceGroups = {
            listWorkgroupMembersV1: vi.fn().mockRejectedValue({ status: 500, message: 'Server error' }),
        } as unknown as GovernanceGroupsApi

        await expect(listWorkgroupMemberEmails(governanceGroups, 'wg-1')).rejects.toThrow(
            'Failed to list members for governance group wg-1 with status 500'
        )
    })
})

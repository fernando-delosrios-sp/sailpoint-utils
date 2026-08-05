import { describe, expect, it, vi } from 'vitest'
import { WorkgroupService } from './workgroup.service'
import type { SailPointClients } from '../framework/types'

describe('WorkgroupService', () => {
    it('joins member emails as comma-separated string', async () => {
        const sdk = {
            governanceGroups: {
                listWorkgroupsV1: vi.fn().mockResolvedValue({ data: [{ id: 'wg-1' }] }),
                listWorkgroupMembersV1: vi.fn().mockResolvedValue({
                    data: [{ email: 'a@example.com' }, { email: 'b@example.com' }],
                }),
            },
        } as unknown as SailPointClients

        const service = new WorkgroupService(sdk)
        await expect(service.resolveGroupEmails('SOD Governance Group')).resolves.toBe(
            'a@example.com, b@example.com'
        )
    })

    it('returns N/A when group is not found', async () => {
        const sdk = {
            governanceGroups: {
                listWorkgroupsV1: vi.fn().mockResolvedValue({ data: [] }),
            },
        } as unknown as SailPointClients

        const service = new WorkgroupService(sdk)
        await expect(service.resolveGroupEmails('Missing Group')).resolves.toBe('N/A')
    })
})

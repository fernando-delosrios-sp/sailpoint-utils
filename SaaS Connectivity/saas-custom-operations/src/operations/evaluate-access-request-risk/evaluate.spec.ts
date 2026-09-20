import { describe, expect, it, vi } from 'vitest'
import { AccessRiskCatalog, evaluateAccessRisk, RequestedAccessItem } from './evaluate'

function catalog(partial: Partial<AccessRiskCatalog> = {}): AccessRiskCatalog {
    return {
        getRole: vi.fn(),
        getAccessProfile: vi.fn(),
        getEntitlement: vi.fn(),
        ...partial,
    }
}

describe('evaluateAccessRisk', () => {
    it('scores a direct entitlement from privilege and metadata', async () => {
        const items: RequestedAccessItem[] = [{ id: 'ent-1', type: 'ENTITLEMENT' }]
        const result = await evaluateAccessRisk(
            items,
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'HIGH',
                    metadata: undefined,
                }),
            })
        )

        expect(result.tier).toBe('High')
        expect(result.contributingIds).toContain('ent-1')
    })

    it('keeps the highest tier inside an access profile', async () => {
        const getEntitlement = vi.fn().mockImplementation(async (id: string) => {
            if (id === 'ent-high') {
                return { effectivePrivilege: 'HIGH', metadata: undefined }
            }
            return { effectivePrivilege: 'LOW', metadata: undefined }
        })
        const result = await evaluateAccessRisk([{ id: 'ap-1', type: 'ACCESS_PROFILE' }], catalog({
            getAccessProfile: vi.fn().mockResolvedValue({
                metadata: { attributes: [{ key: 'iscRisk', values: [{ value: 'low' }] }] },
                entitlementIds: ['ent-low', 'ent-high'],
            }),
            getEntitlement,
        }))

        expect(result.tier).toBe('High')
        expect(result.situationSummary).toContain('ENTITLEMENT:ent-high')
    })

    it('evaluates a role, its access profiles, and direct entitlements without dimensions', async () => {
        const getRole = vi.fn().mockResolvedValue({
            metadata: undefined,
            accessProfileIds: ['ap-1'],
            entitlementIds: ['ent-direct'],
        })
        const getAccessProfile = vi.fn().mockResolvedValue({
            metadata: { attributes: [{ key: 'iscRisk', values: [{ value: 'medium' }] }] },
            entitlementIds: ['ent-wrapped'],
        })
        const getEntitlement = vi.fn().mockImplementation(async (id: string) => {
            if (id === 'ent-direct') {
                return { effectivePrivilege: 'LOW', metadata: undefined }
            }
            return {
                effectivePrivilege: 'LOW',
                metadata: { attributes: [{ key: 'iscRisk', values: [{ value: 'high' }] }] },
            }
        })

        const result = await evaluateAccessRisk([{ id: 'role-1', type: 'ROLE' }], catalog({
            getRole,
            getAccessProfile,
            getEntitlement,
        }))

        expect(getRole).toHaveBeenCalledTimes(1)
        expect(getAccessProfile).toHaveBeenCalledWith('ap-1')
        expect(result.tier).toBe('High')
        expect(result.situationSummary).toContain('ENTITLEMENT:ent-wrapped')
        expect(result.situationSummary).not.toContain('DIMENSION')
    })

    it('uses the highest tier across mixed requested items', async () => {
        const result = await evaluateAccessRisk(
            [
                { id: 'ent-low', type: 'ENTITLEMENT' },
                { id: 'ap-1', type: 'ACCESS_PROFILE' },
            ],
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({ effectivePrivilege: 'LOW', metadata: undefined }),
                getAccessProfile: vi.fn().mockResolvedValue({
                    metadata: { attributes: [{ name: 'Risk', values: ['medium'] }] },
                    entitlementIds: [],
                }),
            })
        )

        expect(result.tier).toBe('Medium')
    })

    it('does not fetch the same entitlement twice', async () => {
        const getEntitlement = vi.fn().mockResolvedValue({ effectivePrivilege: 'MEDIUM', metadata: undefined })
        await evaluateAccessRisk(
            [
                { id: 'ent-1', type: 'ENTITLEMENT' },
                { id: 'ent-1', type: 'ENTITLEMENT' },
            ],
            catalog({ getEntitlement })
        )
        expect(getEntitlement).toHaveBeenCalledTimes(1)
    })

    it('ignores effective privilege when considerPrivilege is false', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'ent-1', type: 'ENTITLEMENT' }],
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'HIGH',
                    metadata: undefined,
                }),
            }),
            { considerPrivilege: false }
        )

        expect(result.tier).toBe('Low')
    })
})

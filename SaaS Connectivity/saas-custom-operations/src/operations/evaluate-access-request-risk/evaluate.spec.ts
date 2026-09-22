import { describe, expect, it, vi } from 'vitest'
import { AccessRiskCatalog, evaluateAccessRisk, RequestedAccessItem } from './evaluate'

const risk = (value: string) => ({
    attributes: [{ key: 'iscRisk', name: 'Risk', values: [{ value, name: value }] }],
})

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
        expect(result.situationSummary).toBe(
            'High: 1 of 1 entitlement scored High (1 by effective privilege). Evaluated 1 entitlement.'
        )
    })

    it('keeps the highest tier inside an access profile', async () => {
        const getEntitlement = vi.fn().mockImplementation(async (id: string) => {
            if (id === 'ent-high') {
                return { effectivePrivilege: 'HIGH', metadata: undefined }
            }
            return { effectivePrivilege: 'LOW', metadata: undefined }
        })
        const result = await evaluateAccessRisk(
            [{ id: 'ap-1', type: 'ACCESS_PROFILE' }],
            catalog({
                getAccessProfile: vi.fn().mockResolvedValue({
                    metadata: { attributes: [{ key: 'iscRisk', values: [{ value: 'low' }] }] },
                    entitlementIds: ['ent-low', 'ent-high'],
                }),
                getEntitlement,
            })
        )

        expect(result.tier).toBe('High')
        expect(result.situationSummary).toBe(
            'High: 1 of 2 entitlements scored High (1 by effective privilege). ' +
                'Evaluated 1 access profile, 2 entitlements.'
        )
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

        const result = await evaluateAccessRisk(
            [{ id: 'role-1', type: 'ROLE' }],
            catalog({
                getRole,
                getAccessProfile,
                getEntitlement,
            })
        )

        expect(getRole).toHaveBeenCalledTimes(1)
        expect(getAccessProfile).toHaveBeenCalledWith('ap-1')
        expect(result.tier).toBe('High')
        expect(result.situationSummary).toBe(
            'High: 1 of 2 entitlements scored High (1 by Risk metadata). ' +
                'Evaluated 1 role, 1 access profile, 2 entitlements.'
        )
        expect(result.situationSummary).not.toContain('ent-wrapped')
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

    it('Privilege is not credited when considerPrivilege is false', async () => {
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
        expect(result.situationSummary).toBe('Low: nothing scored Medium or High. Evaluated 1 entitlement.')
        expect(result.situationSummary).not.toContain('effective privilege')
        expect(result.contributingIds).toBe('')
    })

    it('High result splits drivers across both rules', async () => {
        const entitlementIds = ['ent-privilege', 'ent-metadata', 'ent-low-1', 'ent-low-2', 'ent-low-3', 'ent-low-4']
        const result = await evaluateAccessRisk(
            [{ id: 'role-1', type: 'ROLE' }],
            catalog({
                getRole: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    accessProfileIds: ['ap-1', 'ap-2'],
                    entitlementIds: [],
                }),
                getAccessProfile: vi.fn().mockImplementation(async (id: string) => ({
                    metadata: undefined,
                    entitlementIds: id === 'ap-1' ? entitlementIds.slice(0, 3) : entitlementIds.slice(3),
                })),
                getEntitlement: vi.fn().mockImplementation(async (id: string) => {
                    if (id === 'ent-privilege') {
                        return { effectivePrivilege: 'HIGH', metadata: undefined }
                    }
                    if (id === 'ent-metadata') {
                        return { effectivePrivilege: 'LOW', metadata: risk('high') }
                    }
                    return { effectivePrivilege: 'LOW', metadata: undefined }
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'High: 2 of 6 entitlements scored High (1 by effective privilege, 1 by Risk metadata). ' +
                'Evaluated 1 role, 2 access profiles, 6 entitlements.'
        )
    })

    it('counts an entitlement matching both rules under effective privilege only', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'ent-both', type: 'ENTITLEMENT' }],
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'HIGH',
                    metadata: risk('critical'),
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'High: 1 of 1 entitlement scored High (1 by effective privilege). Evaluated 1 entitlement.'
        )
        expect(result.situationSummary).not.toContain('Risk metadata')
    })

    it('Single deciding rule omits the zero-count rule', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'ap-1', type: 'ACCESS_PROFILE' }],
            catalog({
                getAccessProfile: vi.fn().mockResolvedValue({
                    metadata: risk('medium'),
                    entitlementIds: [],
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'Medium: 1 of 1 access profile scored Medium (1 by Risk metadata). Evaluated 1 access profile.'
        )
        expect(result.situationSummary).not.toContain('effective privilege')
    })

    it('Role requested twice is counted once', async () => {
        const result = await evaluateAccessRisk(
            [
                { id: 'role-1', type: 'ROLE' },
                { id: 'role-1', type: 'ROLE' },
            ],
            catalog({
                getRole: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    accessProfileIds: [],
                    entitlementIds: [],
                }),
            })
        )

        expect(result.situationSummary).toBe('Low: nothing scored Medium or High. Evaluated 1 role.')
    })

    it('Entitlement shared by two access profiles is counted once', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'role-1', type: 'ROLE' }],
            catalog({
                getRole: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    accessProfileIds: ['ap-1', 'ap-2'],
                    entitlementIds: [],
                }),
                getAccessProfile: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    entitlementIds: ['ent-shared'],
                }),
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'HIGH',
                    metadata: undefined,
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'High: 1 of 1 entitlement scored High (1 by effective privilege). ' +
                'Evaluated 1 role, 2 access profiles, 1 entitlement.'
        )
    })

    it('Absent type is omitted from the tally', async () => {
        const result = await evaluateAccessRisk(
            [
                { id: 'ent-1', type: 'ENTITLEMENT' },
                { id: 'ent-2', type: 'ENTITLEMENT' },
            ],
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'LOW',
                    metadata: undefined,
                }),
            })
        )

        expect(result.situationSummary).toBe('Low: nothing scored Medium or High. Evaluated 2 entitlements.')
    })

    it('Summary omits names and identifiers', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'role-1', type: 'ROLE', name: 'Business Process Users' }],
            catalog({
                getRole: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    accessProfileIds: [],
                    entitlementIds: ['ent-9'],
                }),
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'HIGH',
                    metadata: undefined,
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'High: 1 of 1 entitlement scored High (1 by effective privilege). Evaluated 1 role, 1 entitlement.'
        )
        expect(result.situationSummary).not.toContain('Business Process Users')
        expect(result.situationSummary).not.toContain('role-1')
        expect(result.situationSummary).not.toContain('ent-9')
        expect(result.contributingIds).toBe('ent-9')
    })

    it('Summary length does not grow with request size', async () => {
        const items = Array.from(
            { length: 50 },
            (_, index): RequestedAccessItem => ({
                id: `ent-${index}`,
                type: 'ENTITLEMENT',
            })
        )
        const result = await evaluateAccessRisk(
            items,
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'HIGH',
                    metadata: undefined,
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'High: 50 of 50 entitlements scored High (50 by effective privilege). Evaluated 50 entitlements.'
        )
        expect(result.situationSummary.length).toBeLessThanOrEqual(256)
        expect(result.situationSummary).not.toContain('ent-')
    })

    it('Low result reports the tally', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'role-1', type: 'ROLE' }],
            catalog({
                getRole: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    accessProfileIds: ['ap-1', 'ap-2'],
                    entitlementIds: [],
                }),
                getAccessProfile: vi.fn().mockImplementation(async (id: string) => ({
                    metadata: undefined,
                    entitlementIds: id === 'ap-1' ? ['ent-1', 'ent-2', 'ent-3'] : ['ent-4', 'ent-5', 'ent-6'],
                })),
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'LOW',
                    metadata: undefined,
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'Low: nothing scored Medium or High. Evaluated 1 role, 2 access profiles, 6 entitlements.'
        )
        expect(result.situationSummary).not.toBe('Low')
    })

    it('Low result still writes no contributing ids', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'ent-low', type: 'ENTITLEMENT' }],
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'LOW',
                    metadata: undefined,
                }),
            })
        )

        expect(result.contributingIds).toBe('')
    })

    it('Clean role holding a High entitlement is not a driver', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'role-1', type: 'ROLE' }],
            catalog({
                getRole: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    accessProfileIds: [],
                    entitlementIds: ['ent-high'],
                }),
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'HIGH',
                    metadata: undefined,
                }),
            })
        )

        expect(result.situationSummary).toBe(
            'High: 1 of 1 entitlement scored High (1 by effective privilege). Evaluated 1 role, 1 entitlement.'
        )
        expect(result.situationSummary).not.toContain('1 of 1 role scored High')
    })

    it('Counts are pluralized', async () => {
        const result = await evaluateAccessRisk(
            [{ id: 'role-1', type: 'ROLE' }],
            catalog({
                getRole: vi.fn().mockResolvedValue({
                    metadata: undefined,
                    accessProfileIds: [],
                    entitlementIds: ['ent-low'],
                }),
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'LOW',
                    metadata: undefined,
                }),
            })
        )

        expect(result.situationSummary).toBe('Low: nothing scored Medium or High. Evaluated 1 role, 1 entitlement.')

        const plurals = await evaluateAccessRisk(
            [
                { id: 'ent-1', type: 'ENTITLEMENT' },
                { id: 'ent-2', type: 'ENTITLEMENT' },
            ],
            catalog({
                getEntitlement: vi.fn().mockResolvedValue({
                    effectivePrivilege: 'LOW',
                    metadata: undefined,
                }),
            })
        )
        expect(plurals.situationSummary).toContain('2 entitlements')
    })
})

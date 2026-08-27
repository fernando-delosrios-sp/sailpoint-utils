import { describe, expect, it, vi } from 'vitest'
import { patchAccessProfileComposition } from '../../isc/access-profiles/access-profile-patch'
import { patchRoleComposition } from '../../isc/roles/role-patch'
import { applyCorrection, buildAuditLineForPlan } from './apply-correction'
import { buildCorrectionPlan } from './build-correction-plan'
import { ParsedFormInstance } from './parse-form-instance'

vi.mock('../../isc/roles/role-patch', () => ({
    patchRoleComposition: vi.fn(),
}))

vi.mock('../../isc/access-profiles/access-profile-patch', () => ({
    patchAccessProfileComposition: vi.fn(),
}))

const parsed: ParsedFormInstance = {
    formInstanceId: 'fi-1',
    accessItemId: 'role-r',
    accessItemType: 'ROLE',
    policyId: 'pol-1',
    policyName: 'Finance vs AP',
    remediationSide: 'groupB',
    groupAIds: ['ent-a'],
    groupBIds: ['ent-c'],
}

const expanded = {
    entitlementIds: new Set(['ent-a', 'ent-c']),
    entitlements: [
        { id: 'ent-a', name: 'A' },
        { id: 'ent-c', name: 'C' },
    ],
    nestedProfiles: [
        {
            id: 'ap-x',
            name: 'AP',
            entitlements: [{ id: 'ent-c', name: 'C' }],
        },
    ],
}

describe('applyCorrection', () => {
    it('patches role composition for nested access profile detach', async () => {
        vi.mocked(patchRoleComposition).mockResolvedValue(undefined)
        const plan = buildCorrectionPlan(parsed, expanded)
        const auditLine = buildAuditLineForPlan(parsed, plan)

        await applyCorrection({ roles: {} as never, accessProfiles: {} as never }, parsed, plan, auditLine)

        expect(patchRoleComposition).toHaveBeenCalledWith({} as never, 'role-r', {
            detachAccessProfileIds: ['ap-x'],
            removeEntitlementIds: [],
            descriptionAppend: auditLine,
        })
    })

    it('patches access profile entitlements for ACCESS_PROFILE access item', async () => {
        vi.mocked(patchAccessProfileComposition).mockResolvedValue(undefined)
        const apParsed: ParsedFormInstance = {
            ...parsed,
            accessItemId: 'ap-v',
            accessItemType: 'ACCESS_PROFILE',
            remediationSide: 'groupA',
            groupAIds: ['ent-x'],
            groupBIds: ['ent-y'],
        }
        const apExpanded = {
            entitlementIds: new Set(['ent-x']),
            entitlements: [{ id: 'ent-x', name: 'X' }],
            nestedProfiles: [],
        }
        const plan = buildCorrectionPlan(apParsed, apExpanded)
        const auditLine = buildAuditLineForPlan(apParsed, plan)

        await applyCorrection({ roles: {} as never, accessProfiles: {} as never }, apParsed, plan, auditLine)

        expect(patchAccessProfileComposition).toHaveBeenCalledWith({} as never, 'ap-v', {
            removeEntitlementIds: ['ent-x'],
            descriptionAppend: auditLine,
        })
    })
})

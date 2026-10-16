import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it } from 'vitest'
import { parseFormInstance } from './parse-form-instance'

const completedInstance = {
    id: 'fi-1',
    state: 'COMPLETED',
    formInput: {
        accessItemId: 'role-r',
        accessItemType: 'ROLE',
        policyId: 'pol-1',
        policyName: 'Finance vs AP',
        groupAIds: '["ent-a"]',
        groupBIds: '["ent-c"]',
    },
    formData: { remediationSide: 'groupA', comments: 'fix it' },
    submitterId: 'owner-1',
}

describe('parseFormInstance', () => {
    it('Required launch and submit fields', () => {
        const parsed = parseFormInstance(completedInstance)

        expect(parsed.accessItemId).toBe('role-r')
        expect(parsed.accessItemType).toBe('ROLE')
        expect(parsed.policyId).toBe('pol-1')
        expect(parsed.policyName).toBe('Finance vs AP')
        expect(parsed.groupAIds).toEqual(['ent-a'])
        expect(parsed.groupBIds).toEqual(['ent-c'])
        expect(parsed.comments).toBe('fix it')
        expect(parsed.submitterId).toBe('owner-1')
    })

    it('Completed form required', () => {
        expect(() =>
            parseFormInstance({ ...completedInstance, state: 'IN_PROGRESS' })
        ).toThrow(/must be COMPLETED/)
    })

    it('fails when remediationSide is invalid', () => {
        expect(() =>
            parseFormInstance({
                ...completedInstance,
                formData: { remediationSide: 'invalid' },
            })
        ).toThrow(/remediationSide/)
    })

    it('fails when launch keys are missing', () => {
        expect(() =>
            parseFormInstance({
                ...completedInstance,
                formInput: { ...completedInstance.formInput, groupAIds: '' },
            })
        ).toThrow(/groupAIds/)
    })

    it('fails when group ids are invalid JSON', () => {
        expect(() =>
            parseFormInstance({
                ...completedInstance,
                formInput: { ...completedInstance.formInput, groupAIds: 'not-json' },
            })
        ).toThrow(/invalid JSON/)
    })

    it('throws ConnectorError for validation failures', () => {
        expect(() => parseFormInstance({ ...completedInstance, state: 'ASSIGNED' })).toThrow(ConnectorError)
    })
})

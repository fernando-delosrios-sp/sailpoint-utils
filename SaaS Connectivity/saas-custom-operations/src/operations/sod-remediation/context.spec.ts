import { describe, expect, it } from 'vitest'
import { assembleFormInput, buildAccessContentsText, buildControlOptions, formSideWarningText } from './context'
import { ELEVATED_WARNING } from './access-path-resolver'

describe('sod-remediation context', () => {
    it('buildAccessContentsText joins display lines with dash prefixes', () => {
        expect(
            buildAccessContentsText({
                displayLines: ['Entitlement: Ent A', 'Role: Finance Role'],
                warningText: 'elevated',
                revokePayload: {
                    items: [
                        { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' },
                        { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
                    ],
                    recommendedRevoke: { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
                },
            })
        ).toBe('- Entitlement: Ent A\n- Role: Finance Role')
    })

    it('buildControlOptions maps tenant controls to select options', () => {
        expect(
            buildControlOptions([
                { id: 'ctrl-1', name: 'Segregation Review', description: 'Quarterly review' },
                { id: 'ctrl-2', name: 'Manager Attestation' },
            ])
        ).toEqual([
            { label: 'Segregation Review', value: 'ctrl-1', sublabel: 'Quarterly review' },
            { label: 'Manager Attestation', value: 'ctrl-2', sublabel: undefined },
        ])
    })

    it('assembleFormInput includes group contents text and hidden revoke payloads', () => {
        const formInput = assembleFormInput({
            violation: {
                id: 'vio-1',
                owner: { id: 'owner-1' },
                identity: { id: 'ident-1', name: 'Alice' },
                policy: { id: 'pol-1', name: 'AP vs AP' },
                leftSide: { entitlements: [{ id: 'ent-a', name: 'Ent A' }] },
                rightSide: { entitlements: [{ id: 'ent-b', name: 'Ent B' }] },
            },
            groupA: {
                displayLines: ['Entitlement: Ent A'],
                warningText: 'standard',
                revokePayload: {
                    items: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' }],
                    recommendedRevoke: { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' },
                },
            },
            groupB: {
                displayLines: ['Entitlement: Ent B', 'Role: Finance Role'],
                warningText: ELEVATED_WARNING,
                revokePayload: {
                    items: [
                        { type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B' },
                        { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
                    ],
                    recommendedRevoke: { type: 'ROLE', id: 'role-1', name: 'Finance Role' },
                },
            },
            controls: [{ id: 'ctrl-1', name: 'Control 1' }],
        })

        expect(formInput.hasControls).toBe(true)
        expect(formInput.violationId).toBe('vio-1')
        expect(formInput.targetIdentityId).toBe('ident-1')
        expect(formInput.groupAContents).toBe('- Entitlement: Ent A')
        expect(formInput.groupBContents).toBe('- Entitlement: Ent B\n- Role: Finance Role')
        expect(formInput.groupAWarning).toBe('')
        expect(formInput.groupBWarning).toBe(ELEVATED_WARNING)
        expect(formInput.controlOptions).toEqual([{ id: 'ctrl-1', name: 'Control 1' }].map((c) => ({
            label: c.name,
            value: c.id,
            sublabel: undefined,
        })))
        expect(formSideWarningText({
            displayLines: ['Entitlement: Ent A'],
            warningText: 'Select the side whose access should be removed to resolve this violation.',
            revokePayload: {
                items: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' }],
                recommendedRevoke: { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' },
            },
        })).toBe('')
        expect(JSON.parse(formInput.groupARevokePayload)).toEqual({
            items: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' }],
            recommendedRevoke: { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A' },
        })
        expect(JSON.parse(formInput.groupBRevokePayload).recommendedRevoke.type).toBe('ROLE')
    })
})

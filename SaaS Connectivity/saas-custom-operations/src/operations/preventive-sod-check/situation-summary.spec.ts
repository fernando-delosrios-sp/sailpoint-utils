import { describe, expect, it } from 'vitest'
import { buildPreventiveSituationSummary } from './situation-summary'

describe('preventive-sod-check/situation-summary', () => {
    it('returns No violations found when policy list is empty', () => {
        expect(buildPreventiveSituationSummary({ violatedPolicies: [] })).toBe('No violations found')
        expect(
            buildPreventiveSituationSummary({ violatedPolicies: [], accessRequestId: 'req-123' })
        ).toBe('No violations found')
    })

    it('lists policy names with levels when accessRequestId is omitted', () => {
        expect(
            buildPreventiveSituationSummary({
                violatedPolicies: [
                    { name: 'Finance Control', level: 'HIGH' },
                    { name: 'Procurement Control', level: 'MEDIUM' },
                ],
            })
        ).toBe('SoD policy violations found: Finance Control (High), Procurement Control (Medium)')
    })

    it('omits the level suffix when a policy has no level', () => {
        expect(
            buildPreventiveSituationSummary({
                violatedPolicies: [{ name: 'Finance Control' }],
            })
        ).toBe('SoD policy violations found: Finance Control')
    })

    it('attributes violations to accessRequestId when provided', () => {
        expect(
            buildPreventiveSituationSummary({
                violatedPolicies: [{ name: 'Finance Control', level: 'CRITICAL' }],
                accessRequestId: 'req-456',
            })
        ).toBe(
            'Access request req-456 would violate SoD policies if completed: Finance Control (Critical)'
        )
    })
})

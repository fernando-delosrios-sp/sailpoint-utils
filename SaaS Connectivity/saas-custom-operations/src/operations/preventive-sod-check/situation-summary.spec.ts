import { describe, expect, it } from 'vitest'
import { buildPreventiveSituationSummary } from './situation-summary'

describe('preventive-sod-check/situation-summary', () => {
    it('returns No violations found when policy list is empty', () => {
        expect(buildPreventiveSituationSummary({ violatedPolicyNames: [] })).toBe('No violations found')
        expect(
            buildPreventiveSituationSummary({ violatedPolicyNames: [], accessRequestId: 'req-123' })
        ).toBe('No violations found')
    })

    it('lists all policy names when accessRequestId is omitted', () => {
        expect(
            buildPreventiveSituationSummary({
                violatedPolicyNames: ['Finance Control', 'Procurement Control'],
            })
        ).toBe('SoD policy violations found: Finance Control, Procurement Control')
    })

    it('attributes violations to accessRequestId when provided', () => {
        expect(
            buildPreventiveSituationSummary({
                violatedPolicyNames: ['Finance Control'],
                accessRequestId: 'req-456',
            })
        ).toBe('Access request req-456 would violate SoD policies if completed: Finance Control')
    })
})

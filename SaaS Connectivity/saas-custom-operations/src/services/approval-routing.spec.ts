import { describe, expect, it } from 'vitest'
import { buildEtsPreApprovalComment, resolveEmailRoute } from './approval-routing'
import type { AccessRequestAnalytics } from './types'

function analytics(partial: Partial<AccessRequestAnalytics>): AccessRequestAnalytics {
    return {
        iscRiskName: 'Low',
        xdrScore: '10.00%',
        sodPrediction: 'N/A',
        violatedPolicyNames: 'N/A',
        recommendationsDecision: 'YES',
        recommendationsInterpretations: 'ok',
        accessRequestStatus: {},
        xdrData: null,
        ...partial,
    }
}

describe('resolveEmailRoute', () => {
    it('routes N/A and Low risk to manager', () => {
        expect(resolveEmailRoute(analytics({ iscRiskName: 'N/A' }))).toBe('manager')
        expect(resolveEmailRoute(analytics({ iscRiskName: 'Low' }))).toBe('manager')
    })

    it('routes Medium preApproval comment and High risk to manager-owner', () => {
        expect(
            resolveEmailRoute(
                analytics({
                    iscRiskName: 'Medium',
                    accessRequestStatus: {
                        preApprovalTriggerDetails: {
                            comment: 'This access has passed preliminary approval with Medium Risk.',
                        },
                    },
                })
            )
        ).toBe('manager-owner')

        expect(resolveEmailRoute(analytics({ iscRiskName: 'High' }))).toBe('manager-owner')
    })

    it('routes Critical risk to manager-owner-bcc', () => {
        expect(resolveEmailRoute(analytics({ iscRiskName: 'Critical' }))).toBe('manager-owner-bcc')
    })

    it('returns failure when route cannot be resolved', () => {
        expect(resolveEmailRoute(analytics({ iscRiskName: 'Unknown' }))).toBe('failure')
    })
})

describe('buildEtsPreApprovalComment', () => {
    it('builds a single workflow-safe comment string', () => {
        const comment = buildEtsPreApprovalComment(
            analytics({
                iscRiskName: 'Low',
                xdrScore: '12.50%',
                sodPrediction: 'Policy A',
                violatedPolicyNames: 'Policy B',
                recommendationsDecision: 'YES',
                recommendationsInterpretations: 'Looks good',
            })
        )

        expect(comment).toContain('Low Risk')
        expect(comment).toContain('Outlier score: 12.50%')
        expect(comment).toContain('Violated policies: Policy A')
        expect(comment).toContain('[Looks good]')
    })
})

import type { SailPointClients } from '../framework/types'
import type { DetectedViolation, EntitlementRef, SodPolicy } from './types'

export class SodService {
    constructor(private sdk: SailPointClients) {}

    async fetchSodPolicies(): Promise<SodPolicy[]> {
        try {
            const response = await this.sdk.sodPolicies.listSodPoliciesV1({
                limit: 250,
                filters: 'state eq "ENFORCED"',
            })
            return (response.data ?? []) as SodPolicy[]
        } catch (error) {
            console.error('[SodService] Error fetching SoD policies:', error)
            return []
        }
    }

    checkPoliciesAgainstEntitlements(entitlements: EntitlementRef[], policies: SodPolicy[]): DetectedViolation[] {
        const violations: DetectedViolation[] = []
        const entitlementIds = new Set(entitlements.map((entry) => entry.id))

        for (const policy of policies) {
            const criteria = policy.conflictingAccessCriteria
            if (!criteria) {
                continue
            }

            const leftIds = criteria.leftCriteria.criteriaList.map((entry) => entry.id)
            const rightIds = criteria.rightCriteria.criteriaList.map((entry) => entry.id)
            const matchedLeft = leftIds.filter((id) => entitlementIds.has(id))
            const matchedRight = rightIds.filter((id) => entitlementIds.has(id))

            if (matchedLeft.length > 0 && matchedRight.length > 0) {
                violations.push({
                    policyId: policy.id,
                    policyName: policy.name,
                    matchedLeft,
                    matchedRight,
                })
            }
        }

        return violations
    }

    async predictSodViolations(
        identityId: string,
        accessRefs: Array<{ id: string; type: 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE' }>
    ): Promise<unknown> {
        try {
            const response = await this.sdk.sodViolations.startPredictSodViolationsV1({
                identityWithNewAccess: {
                    identityId,
                    accessRefs: accessRefs.map((ref) => ({
                        id: ref.id,
                        type: 'ENTITLEMENT' as const,
                    })),
                },
            })
            return response.data ?? null
        } catch (error) {
            console.error(`[SodService] Error predicting SoD violations for identity ${identityId}:`, error)
            return null
        }
    }
}

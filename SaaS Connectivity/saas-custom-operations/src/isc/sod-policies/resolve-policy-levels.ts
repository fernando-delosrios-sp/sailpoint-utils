import { getSodPolicy } from './get-policy'
import { listSodPolicies } from './list-policies'
import { OFFLINE_SOD_POLICY_LEVELS } from './offline-data'
import { type PolicyNameRef } from '../violations/policy-name-sets'
import { DEFAULT_ISC_CONCURRENCY, mapWithConcurrency } from '../../framework/concurrency'
import { SailPointClients } from '../../framework/types'

function quoteFilterValue(value: string): string {
    return value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')
}

function applyKnownLevel(policy: PolicyNameRef, level?: string): PolicyNameRef {
    if (policy.level || !level) {
        return policy
    }
    return { ...policy, level }
}

async function lookupPolicyLevel(sdk: SailPointClients, policy: PolicyNameRef): Promise<string | undefined> {
    try {
        if (policy.id) {
            const fetched = await getSodPolicy(sdk.sodPolicies, policy.id)
            return fetched.level
        }

        const listed = await listSodPolicies(sdk.sodPolicies, `name eq "${quoteFilterValue(policy.name)}"`)
        return listed.find((item) => item.name === policy.name)?.level
    } catch {
        return undefined
    }
}

/** Fills missing SoD policy levels from the policy catalog. Lookup failures leave level unset. */
export async function attachSodPolicyLevels(
    sdk: SailPointClients,
    policies: PolicyNameRef[],
    offline: boolean,
    options: { concurrency?: number } = {}
): Promise<PolicyNameRef[]> {
    if (policies.length === 0) {
        return policies
    }

    if (offline) {
        return policies.map((policy) => applyKnownLevel(policy, OFFLINE_SOD_POLICY_LEVELS[policy.name]))
    }

    const concurrency = options.concurrency ?? DEFAULT_ISC_CONCURRENCY
    return mapWithConcurrency(policies, concurrency, async (policy) => {
        if (policy.level) {
            return policy
        }
        return applyKnownLevel(policy, await lookupPolicyLevel(sdk, policy))
    })
}

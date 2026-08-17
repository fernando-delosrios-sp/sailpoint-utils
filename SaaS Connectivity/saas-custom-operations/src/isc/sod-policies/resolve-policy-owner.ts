import { ConnectorError } from '@sailpoint/connector-sdk'
import { SodPolicySummary } from './types'

/** Returns policy owner identity id when ownerRef.type is IDENTITY. */
export function resolvePolicyOwnerId(policy: SodPolicySummary): string {
    const ownerRef = policy.ownerRef
    if (!ownerRef?.id) {
        throw new ConnectorError(`Policy ${policy.id} has no ownerRef.id`)
    }

    if (ownerRef.type && ownerRef.type.toUpperCase() !== 'IDENTITY') {
        throw new ConnectorError(
            `Policy ${policy.id} ownerRef type ${ownerRef.type} is not supported for form recipient (IDENTITY required)`
        )
    }

    return ownerRef.id
}

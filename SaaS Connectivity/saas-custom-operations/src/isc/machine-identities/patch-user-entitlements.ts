import { MachineIdentitiesApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { UserEntitlementRef } from './types'

const EXPERIMENTAL_HEADER = 'true'

function refKey(ref: UserEntitlementRef): string {
    return `${ref.sourceId}\u0000${ref.entitlementId}`
}

/** Unions existing refs with additions, preserving existing order and dropping duplicates. */
export function unionUserEntitlements(
    existing: readonly UserEntitlementRef[],
    additions: readonly UserEntitlementRef[]
): UserEntitlementRef[] {
    const union: UserEntitlementRef[] = []
    const seen = new Set<string>()
    for (const ref of [...existing, ...additions]) {
        const key = refKey(ref)
        if (seen.has(key)) {
            continue
        }
        seen.add(key)
        union.push({ sourceId: ref.sourceId, entitlementId: ref.entitlementId })
    }
    return union
}

/** Replaces `userEntitlements` on one machine identity with the caller-supplied refs. */
export async function patchUserEntitlements(
    machineIdentities: MachineIdentitiesApi,
    id: string,
    userEntitlements: readonly UserEntitlementRef[]
): Promise<void> {
    const requestBody = [
        {
            op: 'replace',
            path: '/userEntitlements',
            value: userEntitlements.map((ref) => ({
                sourceId: ref.sourceId,
                entitlementId: ref.entitlementId,
            })),
        },
    ]

    logIscDebug('patchUserEntitlements start', { id, count: userEntitlements.length })

    try {
        await machineIdentities.updateMachineIdentityV1({
            id,
            requestBody,
            xSailPointExperimental: EXPERIMENTAL_HEADER,
        })
    } catch (error) {
        logIscRequestFailure('patchUserEntitlements updateMachineIdentityV1', error)
        throw toConnectorError(error, `Failed to patch userEntitlements on machine identity ${id}`)
    }
}

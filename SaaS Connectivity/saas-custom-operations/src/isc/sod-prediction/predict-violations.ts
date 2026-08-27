import { AccessProfilesApi, RolesApi, SODViolationsApi } from 'sailpoint-api-client'
import type { SodViolationPrediction } from './types'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { toConnectorError } from '../../framework/connector-error'
import { listAccessProfileEntitlementIds } from '../access-profiles/access-profile-entitlements'
import { listRoleEntitlementIds } from '../roles/role-entitlements'
import { AccessItemRef } from '../events-search/types'

/** Predicts SoD violations for an identity with additional entitlement access. */
export async function predictSodViolationsForIdentity(
    sodViolations: SODViolationsApi,
    identityId: string,
    entitlementIds: string[]
): Promise<SodViolationPrediction> {
    if (entitlementIds.length === 0) {
        return { violationContexts: [] }
    }

    try {
        const response = await sodViolations.startPredictSodViolationsV1({
            identityWithNewAccess: {
                identityId,
                accessRefs: entitlementIds.map((id) => ({
                    id,
                    type: 'ENTITLEMENT',
                })),
            },
        })
        return response.data ?? { violationContexts: [] }
    } catch (error) {
        throw toConnectorError(error, 'SoD predict API failed')
    }
}

/** Extracts violated policy names from a predict response, preserving API order. */
export function parseViolatedPolicyNames(prediction: SodViolationPrediction): string[] {
    const names: string[] = []
    const seen = new Set<string>()

    for (const context of prediction.violationContexts ?? []) {
        const name = context.policy?.name
        if (!name || seen.has(name)) {
            continue
        }
        seen.add(name)
        names.push(name)
    }

    return names
}

export interface EntitlementExpansionClients {
    roles: RolesApi
    accessProfiles: AccessProfilesApi
}

/** Expands access item refs to deduplicated entitlement ids suitable for predict. */
export async function expandAccessItemsToEntitlementIds(
    clients: EntitlementExpansionClients,
    items: AccessItemRef[]
): Promise<string[]> {
    const entitlementIds: string[] = []
    const seen = new Set<string>()

    for (const item of items) {
        let resolved: string[] = []
        switch (item.type) {
            case 'ENTITLEMENT':
                resolved = [item.id]
                break
            case 'ROLE':
                resolved = await listRoleEntitlementIds(clients.roles, item.id)
                break
            case 'ACCESS_PROFILE':
                resolved = await listAccessProfileEntitlementIds(clients.accessProfiles, item.id)
                break
            default:
                throw new ConnectorError(`Unsupported access item type: ${String(item.type)}`)
        }

        for (const id of resolved) {
            if (!seen.has(id)) {
                seen.add(id)
                entitlementIds.push(id)
            }
        }
    }

    return entitlementIds
}

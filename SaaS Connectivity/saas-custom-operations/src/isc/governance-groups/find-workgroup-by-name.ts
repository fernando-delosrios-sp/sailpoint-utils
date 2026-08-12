import { ConnectorError } from '@sailpoint/connector-sdk'
import { GovernanceGroupsApi } from 'sailpoint-api-client'
import { escapeODataString } from '../accounts'
import { toGovernanceGroupsConnectorError } from './governance-groups-error'

export interface WorkgroupMatch {
    id: string
    name: string
}

/** Resolves a governance group (workgroup) by exact display name. */
export async function findWorkgroupByName(
    governanceGroups: GovernanceGroupsApi,
    groupName: string
): Promise<WorkgroupMatch> {
    const escapedName = escapeODataString(groupName)

    try {
        const response = await governanceGroups.listWorkgroupsV1({
            filters: `name eq "${escapedName}"`,
        })
        const groups = response.data ?? []
        const match = groups.find((group) => group.name === groupName && group.id)

        if (!match?.id) {
            throw new ConnectorError(`Governance group not found: "${groupName}"`)
        }

        return { id: match.id, name: match.name ?? groupName }
    } catch (error) {
        if (error instanceof ConnectorError) {
            throw error
        }
        throw toGovernanceGroupsConnectorError(`Failed to lookup governance group "${groupName}"`, error)
    }
}

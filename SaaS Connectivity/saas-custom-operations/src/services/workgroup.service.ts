import { ConnectorError } from '@sailpoint/connector-sdk'
import type { SailPointClients } from '../framework/types'

function toConnectorError(action: string, error: unknown): ConnectorError {
    const detail = error instanceof Error ? error.message : String(error)
    return new ConnectorError(`${action}: ${detail}`)
}

export class WorkgroupService {
    constructor(private sdk: SailPointClients) {}

    async getWorkgroupIdByName(groupName: string): Promise<string | null> {
        try {
            const response = await this.sdk.governanceGroups.listWorkgroupsV1({
                filters: `name eq "${groupName}"`,
            })
            const groups = response.data ?? []
            return groups[0]?.id ?? null
        } catch (error) {
            console.error(`[WorkgroupService] Error fetching workgroup ID for name "${groupName}":`, error)
            throw toConnectorError(`Failed to lookup governance group "${groupName}"`, error)
        }
    }

    async getWorkgroupMembersEmails(workgroupId: string): Promise<string[]> {
        try {
            const response = await this.sdk.governanceGroups.listWorkgroupMembersV1({ workgroupId })
            const members = response.data ?? []
            return members
                .map((member) => member.email)
                .filter((email): email is string => !!email && email.trim() !== '')
        } catch (error) {
            console.error(`[WorkgroupService] Error fetching members for workgroup ID ${workgroupId}:`, error)
            throw toConnectorError(`Failed to list members for governance group ${workgroupId}`, error)
        }
    }

    async resolveGroupMemberEmails(groupName: string): Promise<string[]> {
        const workgroupId = await this.getWorkgroupIdByName(groupName)
        if (!workgroupId) {
            return []
        }

        return this.getWorkgroupMembersEmails(workgroupId)
    }
}



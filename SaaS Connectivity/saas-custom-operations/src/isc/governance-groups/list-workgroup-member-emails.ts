import { GovernanceGroupsApi } from 'sailpoint-api-client'
import { toGovernanceGroupsConnectorError } from './governance-groups-error'

const MEMBER_PAGE_SIZE = 250

function extractMemberEmail(member: { email?: string | null }): string | undefined {
    const email = member.email?.trim()
    return email ? email : undefined
}

/** Lists non-empty member email addresses for a workgroup, paginating through all results. */
export async function listWorkgroupMemberEmails(
    governanceGroups: GovernanceGroupsApi,
    workgroupId: string
): Promise<string[]> {
    const emails: string[] = []
    let offset = 0

    try {
        while (true) {
            const response = await governanceGroups.listWorkgroupMembersV1({
                workgroupId,
                offset,
                limit: MEMBER_PAGE_SIZE,
            })
            const members = response.data ?? []

            for (const member of members) {
                const email = extractMemberEmail(member)
                if (email) {
                    emails.push(email)
                }
            }

            if (members.length < MEMBER_PAGE_SIZE) {
                break
            }

            offset += MEMBER_PAGE_SIZE
        }

        return emails
    } catch (error) {
        throw toGovernanceGroupsConnectorError(
            `Failed to list members for governance group ${workgroupId}`,
            error
        )
    }
}

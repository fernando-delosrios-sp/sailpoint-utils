import { GovernanceGroupsApi } from 'sailpoint-api-client'
import { findWorkgroupByName } from './find-workgroup-by-name'
import { listWorkgroupMemberEmails } from './list-workgroup-member-emails'

/** Resolves member email addresses for a governance group identified by display name. */
export async function resolveGovernanceGroupEmails(
    governanceGroups: GovernanceGroupsApi,
    groupName: string
): Promise<string[]> {
    const workgroup = await findWorkgroupByName(governanceGroups, groupName)
    return listWorkgroupMemberEmails(governanceGroups, workgroup.id)
}

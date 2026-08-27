import { ConnectorError } from '@sailpoint/connector-sdk'

const OFFLINE_GROUP_EMAILS: Record<string, string[]> = {
    'Offline Approvers': ['a@example.com', 'b@example.com'],
}

/** Returns canned member emails for offline/test-mode invocations keyed by group name. */
export function resolveGovernanceGroupEmailsOffline(groupName: string): string[] {
    const emails = OFFLINE_GROUP_EMAILS[groupName]
    if (!emails) {
        throw new ConnectorError(`Governance group not found: "${groupName}"`)
    }
    return emails
}

import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import {
    resolveGovernanceGroupEmails,
    resolveGovernanceGroupEmailsOffline,
} from '../../isc/governance-groups'
import { governanceGroupEmailsOperationSchema } from './index.schema'

export interface GovernanceGroupEmailsOperation extends OperationSignature {
    command: 'custom:governance-group-emails'
    input: {
        groupName: string
    }
    output: {
        'governance-group-emails:emails': string[]
    }
}

/** Resolves governance group member emails by group display name for workflow BCC/distribution use. */
export const governanceGroupEmailsOperation = customOperation<GovernanceGroupEmailsOperation>(
    async (ctx, input) => {
        const groupName = input.groupName?.trim()
        if (!groupName) {
            throw new ConnectorError('Missing required input field: groupName')
        }

        const offline = isOfflineContext(ctx)
        const emails = offline
            ? resolveGovernanceGroupEmailsOffline(groupName)
            : await resolveGovernanceGroupEmails(ctx.sdk.governanceGroups, groupName)

        await ctx.persist(ctx.requestId, { 'governance-group-emails:emails': emails })
        ctx.res.send({ status: 'success' })
    },
    { operationSchema: governanceGroupEmailsOperationSchema }
)

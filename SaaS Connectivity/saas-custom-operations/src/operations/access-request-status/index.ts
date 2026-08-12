import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, OperationSignature } from '../../framework'
import { fetchIdentityDisplayContext } from '../../isc/identities/fetch-identity-display-context'
import { resolveGovernanceGroupEmails } from '../../isc/governance-groups'
import { getRequestedItemOwnerId } from '../../isc/access-requests/requested-item'
import { buildEtsPreApprovalComment, getRequestedItemName, resolveEmailRoute } from './approval-routing'
import { computeAccessRequestAnalytics, type OutputProfile } from './compute-analytics'
import { buildApprovalEmailBody } from './email-templates'
import { accessRequestStatusOperationSchema } from './index.schema'

const DEFAULT_GOV_GROUP_NAME = 'SOD Governance Group'

export interface AccessRequestStatusOperation extends OperationSignature {
    command: 'custom:access-request-status'
    input: {
        outputProfile?: OutputProfile
        accessRequestId?: string
        govGroupName?: string
    }
    output: {
        preApprovalComment?: string
        emailRoute?: string
        emailBodyHtml?: string
        bccEmails?: string[]
        accessOwnerId?: string
    }
}

/** Builds approval email or ETS comment outputs for an access request. */
export const accessRequestStatusOperation = customOperation<AccessRequestStatusOperation>(
    async (ctx, input) => {
        const outputProfile = input.outputProfile
        const accessRequestId = input.accessRequestId

        if (!outputProfile || (outputProfile !== 'approval-email' && outputProfile !== 'ets-comment')) {
            throw new ConnectorError('Missing or invalid outputProfile (approval-email | ets-comment)')
        }
        if (!accessRequestId) {
            throw new ConnectorError('Missing required input field: accessRequestId')
        }

        const analytics = await computeAccessRequestAnalytics(ctx.sdk, accessRequestId)
        if (!analytics) {
            throw new ConnectorError(`Unable to resolve access request ${accessRequestId}`)
        }

        if (outputProfile === 'ets-comment') {
            const comment = buildEtsPreApprovalComment(analytics)
            await ctx.persist(ctx.requestId, { preApprovalComment: comment })
            ctx.res.send({ status: 'success', outputProfile, preApprovalComment: comment })
            return
        }

        const emailRoute = resolveEmailRoute(analytics)
        if (emailRoute === 'failure') {
            throw new ConnectorError('Unable to resolve approval email route for access request')
        }

        const identityId = analytics.accessRequestStatus.requestedFor!.id
        const requestedItemId = analytics.accessRequestStatus.id!
        const requestedType = analytics.accessRequestStatus.type!

        const [{ displayName, managerRefName }, accessOwnerId] = await Promise.all([
            fetchIdentityDisplayContext(ctx.sdk.identities, identityId),
            getRequestedItemOwnerId(ctx.sdk, requestedItemId, requestedType),
        ])

        const emailBodyHtml = buildApprovalEmailBody(analytics, {
            managerRefName,
            displayName,
            accessRequestId,
            requestedItemName: getRequestedItemName(analytics.accessRequestStatus),
        })

        const govGroupName = input.govGroupName ?? DEFAULT_GOV_GROUP_NAME
        const bccEmails =
            emailRoute === 'manager-owner-bcc'
                ? await resolveGovernanceGroupEmails(ctx.sdk.governanceGroups, govGroupName)
                : []

        await ctx.persist(ctx.requestId, {
            emailRoute,
            emailBodyHtml,
            bccEmails,
            accessOwnerId,
        })
        ctx.res.send({
            status: 'success',
            outputProfile,
            emailRoute,
            accessOwnerId,
        })
    },
    { operationSchema: accessRequestStatusOperationSchema }
)

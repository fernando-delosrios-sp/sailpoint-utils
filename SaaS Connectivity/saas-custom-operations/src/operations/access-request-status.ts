import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, OperationSignature } from '../framework'
import {
    computeAccessRequestAnalytics,
    fetchIdentityDisplayContext,
} from '../services/access-request-analytics'
import { AccessService } from '../services/access.service'
import { buildEtsPreApprovalComment, getRequestedItemName, resolveEmailRoute } from '../services/approval-routing'
import { buildApprovalEmailBody } from '../services/email-templates'
import type { OutputProfile } from '../services/types'
import { WorkgroupService } from '../services/workgroup.service'

const DEFAULT_GOV_GROUP_NAME = 'SOD Governance Group'

export interface AccessRequestStatusOperation extends OperationSignature {
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

        const accessService = new AccessService(ctx.sdk)
        const workgroupService = new WorkgroupService(ctx.sdk)
        const [{ displayName, managerRefName }, accessOwnerId] = await Promise.all([
            fetchIdentityDisplayContext(ctx.sdk, identityId),
            accessService.getRequestedItemOwnerId(requestedItemId, requestedType),
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
                ? await workgroupService.resolveGroupMemberEmails(govGroupName)
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
    }
)

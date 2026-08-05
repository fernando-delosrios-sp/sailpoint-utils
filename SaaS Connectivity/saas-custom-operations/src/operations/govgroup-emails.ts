import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, OperationSignature } from '../framework'
import { WorkgroupService } from '../services/workgroup.service'

export interface GovgroupEmailsOperation extends OperationSignature {
    input: {
        groupName?: string
    }
    output: {
        emails: string[]
    }
}

export const govgroupEmailsOperation = customOperation<GovgroupEmailsOperation>(async (ctx, input) => {
    const groupName = input.groupName
    if (!groupName) {
        throw new ConnectorError('Missing required input field: groupName')
    }

    const workgroupService = new WorkgroupService(ctx.sdk)
    const workgroupId = await workgroupService.getWorkgroupIdByName(groupName)
    if (!workgroupId) {
        throw new ConnectorError(`Workgroup with name "${groupName}" not found`)
    }

    const emails = await workgroupService.resolveGroupMemberEmails(groupName)
    await ctx.persist(ctx.requestId, { emails })
    ctx.res.send({ status: 'success', emails })
})

import { ConnectorError } from '@sailpoint/connector-sdk'
import { withCustomOperation } from '../framework'
import { WorkgroupService } from '../services/workgroup.service'

interface GovgroupEmailsInput extends Record<string, unknown> {
    groupName?: string
}

export const govgroupEmailsOperation = withCustomOperation<GovgroupEmailsInput>(async (ctx, input) => {
    const groupName = input.groupName
    if (!groupName) {
        throw new ConnectorError('Missing required input field: groupName')
    }

    const workgroupService = new WorkgroupService(ctx.sdk)
    const workgroupId = await workgroupService.getWorkgroupIdByName(groupName)
    if (!workgroupId) {
        throw new ConnectorError(`Workgroup with name "${groupName}" not found`)
    }

    const emails = await workgroupService.resolveGroupEmails(groupName)
    await ctx.persist(ctx.requestId, [emails])
    ctx.res.send({ status: 'success', emails })
})

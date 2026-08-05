import { ConnectorError } from '@sailpoint/connector-sdk'
import { withCustomOperation } from '../framework'
import { AccessService } from '../services/access.service'

interface AccessRequestThresholdInput extends Record<string, unknown> {
    accessRequestId?: string
    sourceName?: string
    thresholdValue?: number | string
}

export const accessRequestThresholdOperation = withCustomOperation<AccessRequestThresholdInput>(
    async (ctx, input) => {
        const accessRequestId = input.accessRequestId
        const sourceName = input.sourceName
        const thresholdValue =
            typeof input.thresholdValue === 'string'
                ? Number.parseInt(input.thresholdValue, 10)
                : input.thresholdValue

        if (!accessRequestId || !sourceName || thresholdValue === undefined || Number.isNaN(thresholdValue)) {
            throw new ConnectorError('Missing required input: accessRequestId, sourceName, thresholdValue')
        }

        const accessService = new AccessService(ctx.sdk)
        const accessRequestStatus = await accessService.fetchAccessRequestById(accessRequestId)
        const identityId = accessRequestStatus?.requestedFor?.id

        if (!accessRequestStatus || !identityId) {
            throw new ConnectorError(`Unable to resolve access request ${accessRequestId}`)
        }

        const payload = accessService.buildPayload(accessRequestStatus, null)
        const [requestedEntitlements, pendingEntitlements, grantedEntitlements] = await Promise.all([
            accessService.getUnderlyingEntitlements(payload),
            accessService.getPendingEntitlements(identityId, accessRequestId),
            accessService.getGrantedEntitlements(identityId),
        ])

        const allEntitlementsMap = new Map<string, (typeof requestedEntitlements)[number]>()
        grantedEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
        pendingEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))
        requestedEntitlements.forEach((ent) => allEntitlementsMap.set(ent.id, ent))

        const thresholdSourceEntitlements = Array.from(allEntitlementsMap.values()).filter(
            (ent) => ent.source?.name?.toLowerCase() === sourceName.toLowerCase()
        )

        const foundCount = thresholdSourceEntitlements.length
        const thresholdHit = foundCount > thresholdValue

        await ctx.persist(ctx.requestId, [
            String(thresholdHit),
            String(foundCount),
            sourceName,
            String(thresholdValue),
            String(requestedEntitlements.length),
            String(pendingEntitlements.length),
            String(grantedEntitlements.length),
        ])

        ctx.res.send({
            status: 'success',
            thresholdHit,
            details: {
                identityId,
                source: sourceName,
                threshold: thresholdValue,
                foundCount,
                breakdown: {
                    requested: requestedEntitlements.length,
                    pending: pendingEntitlements.length,
                    granted: grantedEntitlements.length,
                },
            },
        })
    }
)

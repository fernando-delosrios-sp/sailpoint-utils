import { RequestContext } from './types'

/** Upserts a failed result account for workflow Get Accounts read-back. Errors are logged, not thrown. */
export async function persistFailedResult(
    requestId: string | undefined,
    message: string,
    ctx: RequestContext | undefined
): Promise<void> {
    if (!requestId || !ctx) {
        return
    }

    try {
        await ctx.persist(requestId, undefined, 'failed', { verify: false, details: message })
    } catch (error) {
        const detail = error instanceof Error ? error.message : String(error)
        ctx.log.warn(`[persist] failed to write failure account for ${requestId}: ${detail}`)
    }
}

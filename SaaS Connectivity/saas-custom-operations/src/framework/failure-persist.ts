import { RequestContext } from './types'

/** Upserts a failed result account for workflow Get Accounts read-back. Errors are logged, not thrown. */
export async function persistFailedResult(
    resultIdentity: string | undefined,
    message: string,
    ctx: Pick<RequestContext, 'persist' | 'log'> | undefined
): Promise<void> {
    if (!resultIdentity || !ctx) {
        return
    }

    try {
        await ctx.persist(resultIdentity, undefined, 'failed', { verify: false, details: message })
    } catch (error) {
        const detail = error instanceof Error ? error.message : String(error)
        ctx.log.warn(`[persist] failed to write failure account for ${resultIdentity}: ${detail}`)
    }
}

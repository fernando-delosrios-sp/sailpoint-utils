import { withCustomOperation } from '../framework'

/**
 * Copy this file when adding a new custom operation.
 * Register the command in index.ts.
 */
export const templateOperation = withCustomOperation(async (ctx, input) => {
    console.log(`[${ctx.requestId}] template operation invoked`, input)

    // Example: persist with inline verification (default)
    await ctx.persist(ctx.requestId, ['example-value'])

    // Example: defer verification for multiple writes, then batch verify
    // await ctx.persist(ctx.requestId, ['summary'], undefined, { verify: false })
    // await ctx.persist(`${ctx.requestId}:detail`, ['step-output'], undefined, { verify: false })
    // await ctx.verifyPersisted([ctx.requestId, `${ctx.requestId}:detail`])

    ctx.res.send({ status: 'success' })

    // Example: loopback call into ISC (uncomment when needed)
    // const accounts = await ctx.sdk.accounts.listAccountsV1({ filters: 'sourceId eq "' + ctx.sourceId + '"' })
})

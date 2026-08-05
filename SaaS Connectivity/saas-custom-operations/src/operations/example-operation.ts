import { withCustomOperation } from '../framework'

interface ExampleOperationInput extends Record<string, unknown> {
    message?: string
}

/** Example custom operation demonstrating persist with a child identity. */
export const exampleOperation = withCustomOperation<ExampleOperationInput>(async (ctx, input) => {
    console.log(`[${ctx.requestId}] example operation started`, { message: input.message })

    const summary = input.message ?? 'completed'
    await ctx.persist(`${ctx.requestId}:detail`, [summary])
    await ctx.persist(ctx.requestId, [summary, '1'])

    console.log(`[${ctx.requestId}] example operation finished`)
    ctx.res.send({ status: 'success' })
})

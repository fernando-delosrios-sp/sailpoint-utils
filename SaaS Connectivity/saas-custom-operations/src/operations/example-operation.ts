import { customOperation, OperationSignature } from '../framework'

export interface ExampleOperation extends OperationSignature {
    command: 'custom:example'
    input: {
        message?: string
    }
    output: {
        summary: string
        step?: string
    }
}

/** Example custom operation demonstrating typed persist with a child identity. */
export const exampleOperation = customOperation<ExampleOperation>(
    async (ctx, input) => {
        console.log(`[${ctx.requestId}] example operation started`, { message: input.message })

        const summary = input.message ?? 'completed'
        await ctx.persist(`${ctx.requestId}:detail`, { summary })
        await ctx.persist(ctx.requestId, { summary, step: '1' })

        console.log(`[${ctx.requestId}] example operation finished`)
        ctx.res.send({ status: 'success' })
    }
)

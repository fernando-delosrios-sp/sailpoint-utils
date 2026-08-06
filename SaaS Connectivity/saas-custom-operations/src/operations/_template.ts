import { customOperation, OperationSignature } from '../framework'
// After registering in index.ts, run `npm run codegen:schemas`, then import the sidecar:
// import { templateOperationSchema } from './template-operation.schema'

/**
 * Copy this file when adding a new custom operation.
 * Register the command in index.ts.
 */

export interface TemplateOperation extends OperationSignature {
    input: {
        exampleField?: string
    }
    output: {
        result: string
        detail?: string
    }
}

export const templateOperation = customOperation<TemplateOperation>(
    async (ctx, input) => {
        console.log(`[${ctx.requestId}] template operation invoked`, input)

        await ctx.persist(ctx.requestId, { result: 'example-value' })

        // await ctx.persist(ctx.requestId, { result: 'summary' }, undefined, { verify: false })
        // await ctx.persist(`${ctx.requestId}:detail`, { detail: 'step-output' }, undefined, { verify: false })
        // await ctx.verifyPersisted([ctx.requestId, `${ctx.requestId}:detail`])

        ctx.res.send({ status: 'success' })
    }
    // Pass the generated sidecar for schema reconciliation at persist time:
    // , { operationSchema: templateOperationSchema }
)

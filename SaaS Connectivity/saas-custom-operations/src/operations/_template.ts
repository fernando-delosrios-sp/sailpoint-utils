import { customOperation, OperationSignature } from '../framework'
// Manual path: register in index.ts and pass the generated sidecar:
// import { templateOperationSchema } from './template-operation.schema'

/**
 * Copy this file when adding a new custom operation.
 *
 * Auto-discovery (recommended): add `command: 'custom:your-command'` to the interface below.
 * Codegen registers the handler in auto-registry.ts and syncs connector-spec.json.
 *
 * Manual registration: omit `command`, register in index.ts, import the generated sidecar,
 * and pass `{ operationSchema: templateOperationSchema }` to customOperation.
 */

export interface TemplateOperation extends OperationSignature {
    command: 'custom:template'
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
)

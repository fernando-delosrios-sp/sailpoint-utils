import { customOperation, OperationSignature } from '../../framework'
// Manual path: register in index.ts and pass the generated sidecar:
// import { templateOperationSchema } from './index.schema'

/**
 * Copy this directory when adding a new custom operation.
 *
 * Layout: `src/operations/<slug>/index.ts` (this file) is the auto-discovered entry.
 * Add domain modules, seeds, and tests alongside index.ts inside the same folder.
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

        ctx.res.send({ status: 'success' })
    }
)

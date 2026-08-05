#!/usr/bin/env node
/**
 * Template generator for ISC operator artifacts.
 *
 * Discovery rules:
 * - Parses `src/operations/index.ts` for `.command('custom:…', handler)` registrations
 * - Resolves handler modules and extracts `OperationSignature` input/output via TypeScript compiler API
 * - Scans operation sources for `ctx.persist(...)` child identity patterns (non-`ctx.requestId` first args)
 * - Only registered operations are included; connector-spec declarations without handlers are ignored
 *
 * Output (gitignored `./templates/`):
 * - account-schema.json — ISC create-source-schema shape
 * - access-token.md — shared OAuth guide with placeholders
 * - workflow-invocation.md — per-operation invoke and read-result sections
 */
import * as fs from 'fs'
import * as path from 'path'
import { buildAccountSchema } from './templates/account-schema'
import { renderAccessTokenGuide } from './templates/access-token'
import { loadOperationMeta } from './templates/operation-introspection'
import { renderWorkflowInvocationGuide } from './templates/workflow-invocation'

const PROJECT_ROOT = path.resolve(__dirname, '..')
const INDEX_PATH = path.join(PROJECT_ROOT, 'src/operations/index.ts')
const OUTPUT_DIR = path.join(PROJECT_ROOT, 'templates')

export function generateTemplates(options?: { outputDir?: string; indexPath?: string }): void {
    const outputDir = options?.outputDir ?? OUTPUT_DIR
    const indexPath = options?.indexPath ?? INDEX_PATH

    const operations = loadOperationMeta(indexPath)
    const schema = buildAccountSchema(operations)
    const accessToken = renderAccessTokenGuide()
    const workflowInvocation = renderWorkflowInvocationGuide(operations)

    fs.mkdirSync(outputDir, { recursive: true })
    fs.writeFileSync(path.join(outputDir, 'account-schema.json'), JSON.stringify(schema, null, 2) + '\n')
    fs.writeFileSync(path.join(outputDir, 'access-token.md'), accessToken)
    fs.writeFileSync(path.join(outputDir, 'workflow-invocation.md'), workflowInvocation)

    console.log(`[templates] Wrote 3 files to ${outputDir} (${operations.length} operation(s))`)
}

if (require.main === module) {
    generateTemplates()
}

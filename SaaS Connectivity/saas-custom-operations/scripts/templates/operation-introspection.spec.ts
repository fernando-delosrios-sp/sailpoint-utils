import * as fs from 'fs'
import * as os from 'os'
import * as path from 'path'
import { afterEach, describe, expect, it } from 'vitest'
import {
    discoverAllOperations,
    discoverAutoOperations,
    extractCommandLiteral,
    findCustomOperationExport,
    findCustomOperationExports,
    scanOperationModules,
} from './operation-introspection'

describe('scanOperationModules', () => {
    let tempDir: string

    afterEach(() => {
        if (tempDir && fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true })
        }
    })

    it('excludes _template.ts, index.ts, schema sidecars, and auto-registry.ts', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-scan-'))
        fs.writeFileSync(path.join(tempDir, 'example-operation.ts'), 'export const x = 1')
        fs.writeFileSync(path.join(tempDir, '_template.ts'), 'export const x = 1')
        fs.writeFileSync(path.join(tempDir, 'index.ts'), 'export const x = 1')
        fs.writeFileSync(path.join(tempDir, 'example-operation.schema.ts'), 'export const x = 1')
        fs.writeFileSync(path.join(tempDir, 'auto-registry.ts'), 'export const x = 1')

        const modules = scanOperationModules(tempDir)
        expect(modules).toHaveLength(1)
        expect(path.basename(modules[0])).toBe('example-operation.ts')
    })
})

describe('extractCommandLiteral', () => {
    let tempDir: string

    afterEach(() => {
        if (tempDir && fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true })
        }
    })

    it('returns the command string literal from OperationSignature', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-cmd-'))
        const filePath = path.join(tempDir, 'example-operation.ts')
        fs.writeFileSync(
            filePath,
            `import { OperationSignature } from '../framework'

export interface ExampleOperation extends OperationSignature {
    command: 'custom:example'
    input: { message?: string }
    output: { summary: string }
}
`
        )

        expect(extractCommandLiteral(filePath)).toBe('custom:example')
    })

    it('returns undefined when no command property is declared', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-cmd-'))
        const filePath = path.join(tempDir, 'manual-operation.ts')
        fs.writeFileSync(
            filePath,
            `import { OperationSignature } from '../framework'

export interface ManualOperation extends OperationSignature {
    input: { message?: string }
    output: { summary: string }
}
`
        )

        expect(extractCommandLiteral(filePath)).toBeUndefined()
    })
})

describe('findCustomOperationExport', () => {
    let tempDir: string

    afterEach(() => {
        if (tempDir && fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true })
        }
    })

    it('returns the handler name when exactly one customOperation export exists', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-export-'))
        const filePath = path.join(tempDir, 'example-operation.ts')
        fs.writeFileSync(
            filePath,
            `import { customOperation } from '../framework'

export const exampleOperation = customOperation(async () => {})
`
        )

        expect(findCustomOperationExport(filePath)).toBe('exampleOperation')
        expect(findCustomOperationExports(filePath)).toEqual(['exampleOperation'])
    })

    it('returns undefined when there are zero or multiple customOperation exports', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-export-'))
        const nonePath = path.join(tempDir, 'none-operation.ts')
        fs.writeFileSync(nonePath, `export const noop = async () => {}`)
        expect(findCustomOperationExport(nonePath)).toBeUndefined()

        const multiPath = path.join(tempDir, 'multi-operation.ts')
        fs.writeFileSync(
            multiPath,
            `import { customOperation } from '../framework'

export const firstOperation = customOperation(async () => {})
export const secondOperation = customOperation(async () => {})
`
        )
        expect(findCustomOperationExport(multiPath)).toBeUndefined()
        expect(findCustomOperationExports(multiPath)).toEqual(['firstOperation', 'secondOperation'])
    })
})

describe('discoverAutoOperations', () => {
    let tempDir: string

    afterEach(() => {
        if (tempDir && fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true })
        }
    })

    it('discovers auto operations with command literal and single export', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-discover-'))
        fs.writeFileSync(
            path.join(tempDir, 'example-operation.ts'),
            `import { customOperation, OperationSignature } from '../framework'

export interface ExampleOperation extends OperationSignature {
    command: 'custom:example'
    input: { message?: string }
    output: { summary: string }
}

export const exampleOperation = customOperation<ExampleOperation>(async () => {})
`
        )
        fs.writeFileSync(path.join(tempDir, '_template.ts'), 'export const template = 1')

        const discoveries = discoverAutoOperations(tempDir)
        expect(discoveries).toHaveLength(1)
        expect(discoveries[0]).toMatchObject({
            command: 'custom:example',
            handlerName: 'exampleOperation',
        })
    })

    it('throws on duplicate commands across auto modules', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-discover-'))
        const moduleBody = `import { customOperation, OperationSignature } from '../framework'

export interface ExampleOperation extends OperationSignature {
    command: 'custom:duplicate'
    input: {}
    output: { summary: string }
}

export const exampleOperation = customOperation<ExampleOperation>(async () => {})
`
        fs.writeFileSync(path.join(tempDir, 'first-operation.ts'), moduleBody)
        fs.writeFileSync(path.join(tempDir, 'second-operation.ts'), moduleBody)

        expect(() => discoverAutoOperations(tempDir)).toThrow(/Duplicate command "custom:duplicate"/)
    })

    it('throws when command prefix is not custom:', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-discover-'))
        fs.writeFileSync(
            path.join(tempDir, 'bad-operation.ts'),
            `import { customOperation, OperationSignature } from '../framework'

export interface BadOperation extends OperationSignature {
    command: 'std:bad'
    input: {}
    output: { summary: string }
}

export const badOperation = customOperation<BadOperation>(async () => {})
`
        )

        expect(() => discoverAutoOperations(tempDir)).toThrow(/Invalid command prefix/)
    })

    it('throws when command is declared but module has no customOperation export', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-discover-'))
        fs.writeFileSync(
            path.join(tempDir, 'orphan-operation.ts'),
            `import { OperationSignature } from '../framework'

export interface OrphanOperation extends OperationSignature {
    command: 'custom:orphan'
    input: {}
    output: { summary: string }
}
`
        )

        expect(() => discoverAutoOperations(tempDir)).toThrow(/has no customOperation export/)
    })
})

describe('discoverAllOperations', () => {
    let tempDir: string

    afterEach(() => {
        if (tempDir && fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true })
        }
    })

    it('merges auto and manual registrations without collisions', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-all-'))
        fs.writeFileSync(
            path.join(tempDir, 'example-operation.ts'),
            `import { customOperation, OperationSignature } from '../framework'

export interface ExampleOperation extends OperationSignature {
    command: 'custom:example'
    input: {}
    output: { summary: string }
}

export const exampleOperation = customOperation<ExampleOperation>(async () => {})
`
        )
        fs.writeFileSync(
            path.join(tempDir, 'manual-operation.ts'),
            `import { customOperation, OperationSignature } from '../framework'

export interface ManualOperation extends OperationSignature {
    input: {}
    output: { detail: string }
}

export const manualOperation = customOperation<ManualOperation>(async () => {})
`
        )
        fs.writeFileSync(
            path.join(tempDir, 'index.ts'),
            `import { manualOperation } from './manual-operation'

export function registerCommands(connector: unknown) {
    return connector.command('custom:manual', manualOperation)
}
`
        )

        const discoveries = discoverAllOperations(tempDir, path.join(tempDir, 'index.ts'))
        expect(discoveries.map((operation) => operation.command)).toEqual(['custom:example', 'custom:manual'])
        expect(discoveries.find((operation) => operation.command === 'custom:example')?.source).toBe('auto')
        expect(discoveries.find((operation) => operation.command === 'custom:manual')?.source).toBe('manual')
    })

    it('throws when the same command is auto-discovered and manually registered', () => {
        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'op-all-'))
        fs.writeFileSync(
            path.join(tempDir, 'example-operation.ts'),
            `import { customOperation, OperationSignature } from '../framework'

export interface ExampleOperation extends OperationSignature {
    command: 'custom:example'
    input: {}
    output: { summary: string }
}

export const exampleOperation = customOperation<ExampleOperation>(async () => {})
`
        )
        fs.writeFileSync(
            path.join(tempDir, 'index.ts'),
            `import { exampleOperation } from './example-operation'

export function registerCommands(connector: unknown) {
    return connector.command('custom:example', exampleOperation)
}
`
        )

        expect(() => discoverAllOperations(tempDir, path.join(tempDir, 'index.ts'))).toThrow(
            /both auto-discovered and manually registered/
        )
    })
})


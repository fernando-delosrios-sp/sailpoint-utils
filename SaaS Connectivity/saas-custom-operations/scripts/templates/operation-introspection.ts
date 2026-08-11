import * as fs from 'fs'
import * as path from 'path'
import ts from 'typescript'
import {
    AutoOperationDiscovery,
    DiscoveredOperation,
    OperationField,
    OperationMeta,
    OperationRegistration,
} from './types'

const COMMAND_PATTERN = /\.command\s*\(\s*['"](custom:[^'"]+)['"]\s*,\s*(\w+)\s*\)/g
const IMPORT_PATTERN = /import\s+\{([^}]+)\}\s+from\s+['"](\.[^'"]+)['"]/g
const CUSTOM_COMMAND_PREFIX = 'custom:'

const EXCLUDED_OPERATION_DIRS = new Set(['_template'])

export class DiscoveryError extends Error {
    constructor(message: string) {
        super(message)
        this.name = 'DiscoveryError'
    }
}

/** Parses handler imports from operations/index.ts. */
export function parseHandlerImports(source: string): Map<string, string> {
    const handlers = new Map<string, string>()
    for (const match of source.matchAll(IMPORT_PATTERN)) {
        const names = match[1].split(',').map((n) => n.trim())
        const modulePath = match[2]
        for (const name of names) {
            if (name) {
                handlers.set(name, modulePath)
            }
        }
    }
    return handlers
}

/** Extracts custom:* command → handler module mappings from index.ts source. */
export function parseRegistrationsFromSource(source: string, indexDir: string): OperationRegistration[] {
    const handlers = parseHandlerImports(source)
    const registrations: OperationRegistration[] = []

    for (const match of source.matchAll(COMMAND_PATTERN)) {
        const command = match[1]
        const handlerName = match[2]
        const relativeModule = handlers.get(handlerName)
        if (!relativeModule) {
            console.warn(`[templates] No import found for handler "${handlerName}" (${command})`)
            continue
        }
        registrations.push({
            command,
            handlerName,
            modulePath: path.resolve(indexDir, `${relativeModule}.ts`),
        })
    }

    return registrations
}

/** Parses src/operations/index.ts for registered custom operations. */
export function parseRegistrations(indexPath: string): OperationRegistration[] {
    const source = fs.readFileSync(indexPath, 'utf-8')
    return parseRegistrationsFromSource(source, path.dirname(indexPath))
}

function propertyNameFromSignature(member: ts.PropertySignature, sourceFile: ts.SourceFile): string | undefined {
    if (!member.name) {
        return undefined
    }
    if (ts.isIdentifier(member.name)) {
        return member.name.text
    }
    if (ts.isStringLiteral(member.name)) {
        return member.name.text
    }
    return undefined
}

function extractFieldsFromTypeLiteral(sourceFile: ts.SourceFile, typeNode: ts.TypeNode | undefined): OperationField[] {
    if (!typeNode || !ts.isTypeLiteralNode(typeNode)) {
        return []
    }

    const fields: OperationField[] = []
    for (const member of typeNode.members) {
        if (!ts.isPropertySignature(member)) {
            continue
        }
        const name = propertyNameFromSignature(member, sourceFile)
        if (!name) {
            continue
        }
        const optional = Boolean(member.questionToken)
        const type = member.type ? member.type.getText(sourceFile) : 'unknown'
        fields.push({ name, optional, type })
    }
    return fields
}

function findOperationSignatureInterface(sourceFile: ts.SourceFile): ts.InterfaceDeclaration | undefined {
    for (const statement of sourceFile.statements) {
        if (!ts.isInterfaceDeclaration(statement)) {
            continue
        }
        for (const clause of statement.heritageClauses ?? []) {
            if (clause.token !== ts.SyntaxKind.ExtendsKeyword) {
                continue
            }
            for (const type of clause.types) {
                if (type.expression.getText(sourceFile) === 'OperationSignature') {
                    return statement
                }
            }
        }
    }
    return undefined
}

/** Returns true when the module declares an interface extending OperationSignature. */
export function hasOperationSignature(filePath: string): boolean {
    const source = fs.readFileSync(filePath, 'utf-8')
    const sourceFile = ts.createSourceFile(filePath, source, ts.ScriptTarget.Latest, true)
    return findOperationSignatureInterface(sourceFile) !== undefined
}

/** Extracts input/output fields from an operation module's OperationSignature interface. */
export function extractOperationSignature(filePath: string): { input: OperationField[]; output: OperationField[] } {
    const source = fs.readFileSync(filePath, 'utf-8')
    const sourceFile = ts.createSourceFile(filePath, source, ts.ScriptTarget.Latest, true)

    const iface = findOperationSignatureInterface(sourceFile)
    if (!iface) {
        console.warn(`[templates] No OperationSignature interface found in ${filePath}`)
        return { input: [], output: [] }
    }

    let input: OperationField[] = []
    let output: OperationField[] = []

    for (const member of iface.members) {
        if (!ts.isPropertySignature(member)) {
            continue
        }
        const memberName = propertyNameFromSignature(member, sourceFile)
        if (memberName === 'input') {
            input = extractFieldsFromTypeLiteral(sourceFile, member.type)
        } else if (memberName === 'output') {
            output = extractFieldsFromTypeLiteral(sourceFile, member.type)
        }
    }

    return { input, output }
}

const PERSIST_PATTERN = /ctx\.persist\s*\(\s*([^,)]+)/g

function normalizePersistArg(arg: string): string | undefined {
    const trimmed = arg.trim()
    if (trimmed === 'ctx.requestId') {
        return undefined
    }
    const templateMatch = trimmed.match(/^`([^`]+)`$/)
    if (templateMatch) {
        return templateMatch[1]
    }
    if (trimmed.startsWith('`') && trimmed.endsWith('`')) {
        return trimmed.slice(1, -1)
    }
    return trimmed
}

/** Detects non-primary ctx.persist identity patterns in an operation source file. */
export function detectChildIdentities(filePath: string): string[] {
    const source = fs.readFileSync(filePath, 'utf-8')
    const patterns = new Set<string>()

    for (const match of source.matchAll(PERSIST_PATTERN)) {
        const pattern = normalizePersistArg(match[1])
        if (pattern) {
            patterns.add(pattern)
        }
    }

    return [...patterns]
}

/** Loads full metadata for all registered operations. */
export function loadOperationMeta(indexPath: string): OperationMeta[] {
    const operationsDir = path.dirname(indexPath)
    const discoveries = discoverAllOperations(operationsDir, indexPath)
    return discoveries.map((discovery) => {
        const { input, output } = extractOperationSignature(discovery.modulePath)
        const childIdentities = detectChildIdentities(discovery.modulePath)
        return {
            command: discovery.command,
            modulePath: discovery.modulePath,
            input,
            output,
            childIdentities,
        }
    })
}

/** Returns absolute paths to operation entry modules eligible for auto-discovery scanning. */
export function scanOperationModules(operationsDir: string): string[] {
    const modules: string[] = []

    for (const entry of fs.readdirSync(operationsDir, { withFileTypes: true })) {
        if (!entry.isDirectory()) {
            continue
        }
        if (EXCLUDED_OPERATION_DIRS.has(entry.name)) {
            continue
        }

        const indexPath = path.join(operationsDir, entry.name, 'index.ts')
        if (fs.existsSync(indexPath)) {
            modules.push(indexPath)
        }
    }

    return modules.sort((a, b) => a.localeCompare(b))
}

/** Throws when a scanned operation subdirectory is missing README.md. */
export function assertOperationReadmesExist(operationsDir: string): void {
    for (const modulePath of scanOperationModules(operationsDir)) {
        const slug = path.basename(path.dirname(modulePath))
        const readmePath = path.join(operationsDir, slug, 'README.md')
        if (!fs.existsSync(readmePath)) {
            throw new DiscoveryError(
                `Missing README.md for operation "${slug}": expected ${readmePath}`
            )
        }
    }
}

function extractStringLiteralFromType(typeNode: ts.TypeNode | undefined): string | undefined {
    if (!typeNode) {
        return undefined
    }
    if (ts.isLiteralTypeNode(typeNode) && ts.isStringLiteral(typeNode.literal)) {
        return typeNode.literal.text
    }
    if (ts.isStringLiteral(typeNode)) {
        return typeNode.text
    }
    return undefined
}

/** Extracts the `command` string literal from an OperationSignature interface, if present. */
export function extractCommandLiteral(filePath: string): string | undefined {
    const source = fs.readFileSync(filePath, 'utf-8')
    const sourceFile = ts.createSourceFile(filePath, source, ts.ScriptTarget.Latest, true)
    const iface = findOperationSignatureInterface(sourceFile)
    if (!iface) {
        return undefined
    }

    for (const member of iface.members) {
        if (!ts.isPropertySignature(member) || !member.name || !ts.isIdentifier(member.name)) {
            continue
        }
        if (member.name.text === 'command') {
            return extractStringLiteralFromType(member.type)
        }
    }

    return undefined
}

/** Returns exported handler names created via `customOperation(...)` in a module. */
export function findCustomOperationExports(filePath: string): string[] {
    const source = fs.readFileSync(filePath, 'utf-8')
    const sourceFile = ts.createSourceFile(filePath, source, ts.ScriptTarget.Latest, true)
    const exports: string[] = []

    for (const statement of sourceFile.statements) {
        if (!ts.isVariableStatement(statement)) {
            continue
        }
        const isExported = statement.modifiers?.some((modifier) => modifier.kind === ts.SyntaxKind.ExportKeyword)
        if (!isExported) {
            continue
        }

        for (const declaration of statement.declarationList.declarations) {
            if (!ts.isIdentifier(declaration.name)) {
                continue
            }
            const initializer = declaration.initializer
            if (!initializer || !ts.isCallExpression(initializer)) {
                continue
            }
            const callee = initializer.expression
            if (ts.isIdentifier(callee) && callee.text === 'customOperation') {
                exports.push(declaration.name.text)
            }
        }
    }

    return exports
}

/** Alias for a single customOperation export (returns undefined when count !== 1). */
export function findCustomOperationExport(filePath: string): string | undefined {
    const exports = findCustomOperationExports(filePath)
    return exports.length === 1 ? exports[0] : undefined
}

function validateAutoModule(modulePath: string, command: string, exports: string[]): void {
    if (!command.startsWith(CUSTOM_COMMAND_PREFIX)) {
        throw new DiscoveryError(`Invalid command prefix in ${modulePath}: "${command}" (expected custom:*)`)
    }

    if (exports.length === 0) {
        throw new DiscoveryError(
            `Auto operation ${modulePath} declares command "${command}" but has no customOperation export`
        )
    }

    if (exports.length > 1) {
        throw new DiscoveryError(
            `Auto operation ${modulePath} declares command "${command}" but has ${exports.length} customOperation exports (expected 1)`
        )
    }
}

/** Discovers operations with a `command` literal and exactly one customOperation export per module. */
export function discoverAutoOperations(operationsDir: string): AutoOperationDiscovery[] {
    const discoveries: AutoOperationDiscovery[] = []
    const commands = new Set<string>()

    for (const modulePath of scanOperationModules(operationsDir)) {
        const command = extractCommandLiteral(modulePath)
        if (!command) {
            continue
        }

        const exports = findCustomOperationExports(modulePath)
        validateAutoModule(modulePath, command, exports)

        if (commands.has(command)) {
            throw new DiscoveryError(`Duplicate command "${command}" across auto-discovered modules`)
        }
        commands.add(command)

        discoveries.push({
            command,
            handlerName: exports[0],
            modulePath,
        })
    }

    return discoveries.sort((a, b) => a.command.localeCompare(b.command))
}

/** Returns auto- and manually registered operations with collision validation. */
export function discoverAllOperations(operationsDir: string, indexPath: string): DiscoveredOperation[] {
    const autoOps = discoverAutoOperations(operationsDir)
    const autoCommands = new Set(autoOps.map((operation) => operation.command))
    const result: DiscoveredOperation[] = autoOps.map((operation) => ({ ...operation, source: 'auto' }))

    const indexRegistrations = parseRegistrations(indexPath)

    for (const registration of indexRegistrations) {
        if (autoCommands.has(registration.command)) {
            throw new DiscoveryError(
                `Command "${registration.command}" is both auto-discovered and manually registered in index.ts`
            )
        }
    }

    const manualRegistrations = indexRegistrations.filter(
        (registration) => !extractCommandLiteral(registration.modulePath)
    )

    for (const registration of manualRegistrations) {
        if (result.some((operation) => operation.command === registration.command)) {
            throw new DiscoveryError(`Duplicate command "${registration.command}" in manual registrations`)
        }

        result.push({
            command: registration.command,
            handlerName: registration.handlerName,
            modulePath: registration.modulePath,
            source: 'manual',
        })
    }

    return result.sort((a, b) => a.command.localeCompare(b.command))
}


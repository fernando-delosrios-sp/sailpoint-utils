/** ISC account schema attribute types supported by schema inference. */
export type IscAttributeType = 'STRING' | 'INT' | 'BOOLEAN' | 'LONG' | 'DATE'

/** A field from an operation output contract used for schema inference. */
export interface OperationField {
    name: string
    type: string
    optional?: boolean
}

/** Inferred ISC schema attribute definition. */
export interface InferredSchemaAttribute {
    name: string
    type: IscAttributeType
    isMulti: boolean
}

const ARRAY_TYPE_PATTERN = /^(.+)\[\]$|^Array<(.+)>$/

function normalizeTypeText(typeText: string): string {
    return typeText.trim()
}

function isObjectLikeType(typeText: string): boolean {
    const normalized = normalizeTypeText(typeText)
    return (
        normalized === 'object' ||
        normalized === 'unknown' ||
        normalized.startsWith('Record<') ||
        normalized.endsWith('Record<string, unknown>') ||
        normalized.includes('Record<string,')
    )
}

/** Maps a TypeScript type string to an ISC attribute type and isMulti flag. */
export function inferFromTsType(typeText: string): { type: IscAttributeType; isMulti: boolean } {
    const normalized = normalizeTypeText(typeText)

    const arrayMatch = normalized.match(ARRAY_TYPE_PATTERN)
    if (arrayMatch) {
        const elementType = arrayMatch[1] ?? arrayMatch[2] ?? 'string'
        const element = inferFromTsType(elementType)
        return { type: element.type, isMulti: true }
    }

    switch (normalized) {
        case 'string':
            return { type: 'STRING', isMulti: false }
        case 'number':
            return { type: 'INT', isMulti: false }
        case 'boolean':
            return { type: 'BOOLEAN', isMulti: false }
        case 'bigint':
            return { type: 'LONG', isMulti: false }
        case 'Date':
            return { type: 'DATE', isMulti: false }
        default:
            if (isObjectLikeType(normalized)) {
                return { type: 'STRING', isMulti: false }
            }
            return { type: 'STRING', isMulti: false }
    }
}

/** Infers an ISC schema attribute from an operation output field. */
export function inferSchemaAttribute(field: OperationField): InferredSchemaAttribute {
    const { type, isMulti } = inferFromTsType(field.type)
    return { name: field.name, type, isMulti }
}

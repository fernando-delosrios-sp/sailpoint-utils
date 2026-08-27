/** A field extracted from an operation's OperationSignature interface. */
export interface OperationField {
    name: string
    optional: boolean
    type: string
}

/** Metadata for a registered custom operation, used by schema and MD generators. */
export interface OperationMeta {
    command: string
    modulePath: string
    input: OperationField[]
    output: OperationField[]
    childIdentities: string[]
}

/** Registration mapping from index.ts. */
export interface OperationRegistration {
    command: string
    handlerName: string
    modulePath: string
}

/** Auto-discovered operation from a module with `command` literal and one customOperation export. */
export interface AutoOperationDiscovery {
    command: string
    handlerName: string
    modulePath: string
}

/** Unified discovery result for auto- and manually registered operations. */
export interface DiscoveredOperation extends AutoOperationDiscovery {
    source: 'auto' | 'manual'
}

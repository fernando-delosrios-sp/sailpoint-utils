export interface MachineAccountIdentityRef {
    id: string
    name?: string
}

export interface MachineAccountSourceRef {
    id: string
    name?: string
}

export interface MachineAccountRecord {
    id: string
    machineIdentity: MachineAccountIdentityRef
    source: MachineAccountSourceRef
    connectorAttributes: Record<string, unknown>
}

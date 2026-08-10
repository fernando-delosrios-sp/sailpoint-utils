export interface InhibitedPersistRecord {
    identity: string
    status: string
    attributes: Record<string, unknown>
}

let capturing = false
let records: InhibitedPersistRecord[] = []

/** Starts collecting inhibited persist records for local invoke summaries. */
export function beginPayloadOutputCapture(): void {
    capturing = true
    records = []
}

/** Stops capture and returns collected records. */
export function endPayloadOutputCapture(): InhibitedPersistRecord[] {
    capturing = false
    const collected = records
    records = []
    return collected
}

/** Records an inhibited persist when payload output capture is active. */
export function recordInhibitedPersist(record: InhibitedPersistRecord): void {
    if (!capturing) {
        return
    }
    records.push(record)
}

export interface InhibitedPersistRecord {
    identity: string
    status: string
    attributes: Record<string, unknown>
}

let capturing = false
let records: InhibitedPersistRecord[] = []

/** Starts collecting inhibited persist records for fixture runner summaries. */
export function beginFixtureOutputCapture(): void {
    capturing = true
    records = []
}

/** Stops capture and returns collected records. */
export function endFixtureOutputCapture(): InhibitedPersistRecord[] {
    capturing = false
    const collected = records
    records = []
    return collected
}

/** Records an inhibited persist when fixture capture is active. */
export function recordInhibitedPersist(record: InhibitedPersistRecord): void {
    if (!capturing) {
        return
    }
    records.push(record)
}

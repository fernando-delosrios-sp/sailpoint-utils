import { SearchApi } from 'sailpoint-api-client'
import { EventSearchDocument } from './types'

export interface EventsSearchRetryOptions {
    maxAttempts?: number
    delayMs?: number
    sleep?: (ms: number) => Promise<void>
}

const DEFAULT_RETRY_OPTIONS: Required<Pick<EventsSearchRetryOptions, 'maxAttempts' | 'delayMs'>> = {
    maxAttempts: 5,
    delayMs: 2000,
}

/** Searches the events index for provisioning events matching a tracking number. */
export async function searchEventsByTrackingNumber(
    search: SearchApi,
    trackingNumber: string
): Promise<EventSearchDocument[]> {
    const response = await search.searchPostV1({
        search: {
            indices: ['events'],
            query: {
                query: `trackingNumber:${trackingNumber} AND status:STARTED`,
            },
            includeNested: true,
        },
    })

    return (response.data ?? []) as EventSearchDocument[]
}

/** Retries events search until events appear or attempts are exhausted. */
export async function searchEventsByTrackingNumberWithRetry(
    search: SearchApi,
    trackingNumber: string,
    options: EventsSearchRetryOptions = {}
): Promise<EventSearchDocument[]> {
    const maxAttempts = options.maxAttempts ?? DEFAULT_RETRY_OPTIONS.maxAttempts
    const delayMs = options.delayMs ?? DEFAULT_RETRY_OPTIONS.delayMs
    const sleep = options.sleep ?? ((ms: number) => new Promise((resolve) => setTimeout(resolve, ms)))

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        const events = await searchEventsByTrackingNumber(search, trackingNumber)
        if (events.length > 0) {
            return events
        }
        if (attempt < maxAttempts) {
            await sleep(delayMs)
        }
    }

    return []
}

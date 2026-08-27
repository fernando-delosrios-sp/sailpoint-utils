import { createConnector } from '@sailpoint/connector-sdk'
import { registerCommands } from './operations'

// Connector must be exported as module property named connector
export const connector = async () => {
    return registerCommands(createConnector())
}

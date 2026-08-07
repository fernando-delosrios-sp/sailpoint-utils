import { Connector } from '@sailpoint/connector-sdk'
import { registerAutoOperations } from './auto-registry'

/** Registers all custom operation command handlers on the connector. */
export function registerCommands(connector: Connector): Connector {
    return registerAutoOperations(connector)
}

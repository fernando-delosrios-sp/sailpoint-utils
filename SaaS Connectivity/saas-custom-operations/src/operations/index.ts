import { Connector } from '@sailpoint/connector-sdk'
import { exampleOperation } from './example-operation'

/** Registers all custom operation command handlers on the connector. */
export function registerCommands(connector: Connector): Connector {
    return connector
        .command('custom:example', exampleOperation)
}

import { Connector } from '@sailpoint/connector-sdk'
import { accessRequestStatusOperation } from './access-request-status'
import { accessRequestThresholdOperation } from './access-request-threshold'
import { checkSodPendingOperation } from './check-sod-pending'
import { exampleOperation } from './example-operation'
import { govgroupEmailsOperation } from './govgroup-emails'

/** Registers all custom operation command handlers on the connector. */
export function registerCommands(connector: Connector): Connector {
    return connector
        .command('custom:example', exampleOperation)
        .command('custom:access-request-status', accessRequestStatusOperation)
        .command('custom:govgroup-emails', govgroupEmailsOperation)
        .command('custom:access-request-threshold', accessRequestThresholdOperation)
        .command('custom:check-sod-pending', checkSodPendingOperation)
}

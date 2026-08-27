## REMOVED Requirements

### Requirement: Configuration validation

**Reason**: Mock MyClient is removed. Configuration validation moves to the custom-operation framework (apiUrl, token from operation input).

**Migration**: Delete src/my-client.ts. Framework validates standard input envelope per invocation.

### Requirement: Account retrieval

**Reason**: Connector no longer retrieves accounts from an external mock source.

**Migration**: Remove getAllAccounts and getAccount methods.

### Requirement: Connection testing

**Reason**: Mock client connection testing is replaced by SDK loopback in custom operations.

**Migration**: Remove testConnection from MyClient.

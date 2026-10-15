# IAI Peer Group Strategies

1 endpoints. Paths are relative to the environment API host.

## Identity outliers list

`GET /peer-group-strategies/v1/:strategy/identity-outliers`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

-- Deprecated : See 'IAI Outliers' This API will be used by Identity Governance systems to identify identities that are not included in an organization's peer groups. By default, 250 identities are returned. You can specify between 1 and 1000 number of identities that can be returned.

Query:

- standard: `limit`, `offset`, `count`

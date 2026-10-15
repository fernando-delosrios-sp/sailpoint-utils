# Search

Use this API to implement search functionality.

4 endpoints. Paths are relative to the environment API host.

## Perform search

`POST /search/v1`

Success: 200.

Perform a search with the provided query and return a matching result collection. To page past 10,000 records, you can use `searchAfter` paging.  Refer to Paginating Search Queries for more information about how to implement `searchAfter` paging. The search query itself has a size limitation of approximately 800 objects when filtering by large lists of IDs or values (e.g., using `terms` filters with extensive lists).
**Note:** Response fields with an underscore (`_`) prefix, such as `_type` and `_index`, are internal metadata fields. These fields are for SailPoint internal use only and are subject to change without notice. Do not rely on them in your integrations.

Query:

- standard: `limit`, `offset`, `count`

Body:

```json
{
  "indices": [
    "accessprofiles"
  ],
  "query": {
    "query": "requestable:true"
  }
}
```

## Count documents satisfying a query

`POST /search/v1/count`

Success: 204.

Performs a search with a provided query and returns the count of results in the X-Total-Count header.

Body:

```json
{
  "indices": [
    "identities"
  ],
  "query": {
    "query": "created: [2022-05-19T19:26:03.351Z TO now]",
    "timeZone": "America/Los_Angeles"
  }
}
```

## Perform a search query aggregation

`POST /search/v1/aggregate`

Success: 200.

Performs a search query aggregation and returns the aggregation result. By default, you can page a maximum of 10,000 search result records.  To page past 10,000 records, you can use searchAfter paging.  Refer to Paginating Search Queries for more information about how to implement searchAfter paging.

Query:

- standard: `limit`, `offset`, `count`

Body:

```json
{
  "indices": [
    "identities"
  ],
  "aggregationType": "SAILPOINT",
  "aggregations": {
    "metric": {
      "name": "How Many Locations",
      "type": "UNIQUE_COUNT",
      "field": "attributes.city"
    }
  }
}
```

## Get a document by id

`GET /search/v1/:index/:id`

Success: 200.

Fetches a single document from the specified index, using the specified document ID.
**Note:** Response fields with an underscore (`_`) prefix, such as `_type` and `_index`, are internal metadata fields. These fields are for SailPoint internal use only and are subject to change without notice. Do not rely on them in your integrations.

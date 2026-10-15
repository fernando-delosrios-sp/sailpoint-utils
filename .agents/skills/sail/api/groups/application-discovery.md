# Application Discovery

Use this API to implement application discovery functionality.

4 endpoints. Paths are relative to the environment API host.

## Start Application Discovery

`POST /sources/v1/:sourceId/discover-applications`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to discover applications.

Body:

```json
{
  "datasetIds": [
    "source:datasetId12345",
    "source:datasetId12345"
  ]
}
```

## Get discovered applications for tenant

`GET /discovered-applications/v1`

Success: 200.

Get a list of applications that have been identified within the environment. This includes details such as application names, discovery dates, potential correlated saas_vendors and related suggested connectors.

Query:

- standard: `limit`, `offset`
- `detail`: Determines whether slim, or increased level of detail is provided for each discovered application in the returned list. SLIM is the default behavior. (This can only be one of SLIM,FULL)
- `filter`: Filter results using the standard syntax described in V3 API Standard Collection Parameters Filtering is supported for the following fields and operators: **name**: *eq, sw, co* **description**: *eq, sw, co* **createdAtStart**: *eq, le,…
- sorters: name, description, discoveredAt, discoverySource, discoverySourceName, discoverySourceCategory

## Download csv template for discovery

`GET /manual-discover-applications-template/v1`

Success: 200.

Download an example CSV file with two columns `application_name` and `description`.  The CSV file contains a single row with the values 'Example Application' and 'Example Description'.

The downloaded template is specifically designed for use with the `/manual-discover-applications` endpoint.

## Upload csv to discover applications

`POST /manual-discover-applications/v1`

Success: 200.

Uploading a CSV file with application data for manual correlation to specific ISC connectors.
If a suitable ISC connector is unavailable, the system will recommend generic connectors instead.

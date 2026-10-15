# IAI Outliers

9 endpoints. Paths are relative to the environment API host.

## Iai identity outliers summary

`GET /outlier-summaries/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200, 202.

This API returns a summary containing the number of identities that customer has, the number of outliers, and the type of outlier.

Query:

- standard: `limit`, `offset`
- `type`: Type of the identity outliers snapshot to filter on (This can only be one of LOW_SIMILARITY,STRUCTURAL)
- filters: snapshotDate (ge, le)
- sorters: snapshotDate

## Iai identity outliers latest summary

`GET /outlier-summaries/v1/latest`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200, 202.

This API returns a most recent snapshot of each outlier type, each containing the number of identities that customer has, the number of outliers, and the type of outlier.

Query:

- `type`: Type of the identity outliers snapshot to filter on (This can only be one of LOW_SIMILARITY,STRUCTURAL)

## Iai get identity outliers

`GET /outliers/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a list of outliers, containing data such as identity ID, outlier type, detection dates, identity attributes, if identity is ignored, and certification information.

Query:

- standard: `limit`, `offset`, `count`
- `type`: Type of the identity outliers snapshot to filter on (This can only be one of LOW_SIMILARITY,STRUCTURAL)
- filters: attributes (eq, sw, co, in); firstDetectionDate (ge, le); certStatus (eq); ignored (eq); score (ge, le)
- sorters: firstDetectionDate, attributes, score

## Get identity outlier's contibuting features

`GET /outliers/v1/:outlierId/contributing-features`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a list of contributing feature objects for a single outlier.

The object contains: feature name, feature value type, value, importance, display name (translated text or message key), description (translated text or message key), translation messages object.

Query:

- standard: `limit`, `offset`, `count`
- `include-translation-messages`: Whether or not to include translation messages object in returned response
- sorters: importance

## Gets a list of access items associated with each identity outlier contributing feature

`GET /outliers/v1/:outlierId/feature-details/:contributingFeatureName/access-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a list of the enriched access items associated with each feature filtered by the access item type.

The object contains: accessItemId, display name (translated text or message key), description (translated text or message key), accessType, sourceName, extremelyRare.

Query:

- standard: `limit`, `offset`, `count`
- `accessType`: The type of access item for the identity outlier contributing feature. If not provided, it returns all.
- sorters: displayName

## Iai identity outliers ignore

`POST /outliers/v1/ignore`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This API receives a list of identity IDs in the request, changes the outliers to be ignored.

Body:

```json
[
  "897ef96559df40e1baa6bae6b53e7340",
  "2c918085837fbfb4018384420dac60c3"
]
```

## Iai identity outliers unignore

`POST /outliers/v1/unignore`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This API receives a list of identity IDs in the request, changes the outliers to be un-ignored.

Body:

```json
[
  "897ef96559df40e1baa6bae6b53e7340",
  "2c918085837fbfb4018384420dac60c3"
]
```

## Iai identity outliers export

`GET /outliers/v1/export`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API exports a list of ignored outliers to a CSV as well as list of non-ignored outliers to a CSV. These two CSVs will be zipped and exported.

Columns will include: identityId, type, firstDetectionDate, latestDetectionDate, ignored, & attributes (defined set of identity attributes).

Query:

- `type`: Type of the identity outliers snapshot to filter on (This can only be one of LOW_SIMILARITY,STRUCTURAL)

## Get identity outlier contibuting feature summary

`GET /outlier-feature-summaries/v1/:outlierFeatureId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a summary of a contributing feature for an identity outlier.

The object contains: contributing feature name (translated text or message key), identity outlier display name, feature values, feature definition and explanation (translated text or message key), peer display name and identityId, access item reference, translation messages object.

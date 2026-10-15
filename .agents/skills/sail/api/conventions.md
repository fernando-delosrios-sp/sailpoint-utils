# API conventions

Rules that sit across the collection. The group file still names the path and the fields that endpoint accepts.

## Paths

The current contract versions each service on its own: `/service/vN/...`, as written in the group file (`/identities/v1/`, `/sources/v1/:id`). Build the path from that file. That prefix is primary.

`/v2026` is the secondary option in front of `/service/vN`. It is not legacy. Use it when the operator names that generation, or when the group file has no `/service/vN` path for the call.

The developer site may say SailPoint Human Fabric. That is this same tenant API.

Beta, v3, and the older yearly generations (`/v2024`, `/v2025`) are legacy. Support tickets for them run through Q2 2028; the endpoints stop in Q1 2029. Use one only when the operator names that generation, or when a domain command's own default endpoint still points there.

A response header `X-Deprecated: true` means that path is on a two-year retirement clock. Prefer the successor path when the group file lists one.

## Experimental

Endpoints marked Experimental in the group file require `-H "X-SailPoint-Experimental: true"`. A call without it returns an error. Sending the header on a public endpoint is harmless. Experimental paths can change without notice.

## Auth and limits

`sail` sends the bearer token from the environment. A 401 goes back to [`env.md`](../env.md).

The gateway allows 100 requests per `client_id` and API version per 10 seconds. A 429 carries `Retry-After` in seconds. Wait that long, then retry. A group file that states a tighter limit wins for that endpoint.

## Standard collection parameters

A collection endpoint is a GET whose last path segment is a plural noun and whose success body is a JSON array (possibly empty).

| Param | Role | Default |
| --- | --- | --- |
| `limit` | Max records in this page | 250 (10,000 for search) |
| `offset` | Record index of the first row, from 0 | 0 |
| `count` | When `true`, total matching rows in `X-Total-Count` | `false` |
| `filters` | Keep rows where the expression is true | none |
| `sorters` | Comma-separated fields; prefix `-` for descending | none |

`limit` maxes at 250 on list endpoints and 10,000 on search. Skip `count=true` when the total will not be used. Page with `limit` and `offset` until a page is shorter than `limit`.

`sorters=type,-modified` sorts by type ascending, then modified descending.

### Filters

Operators are lowercase. `EQ` is rejected.

| Operator | True when |
| --- | --- |
| `eq` `ne` | Field equals / does not equal the value |
| `sw` `co` | String starts with / contains |
| `gt` `ge` `lt` `le` | Numeric, string, or ISO-8601 date-time ordering |
| `in` | Field value is one of the list |
| `ca` | Collection field contains every listed value |
| `pr` | Field is present |
| `isnull` | Field is null |
| `and` `or` `not` | Both true / either true / operand false |

`not` binds tighter than `and`, which binds tighter than `or`. Parentheses override that. Strings compare lexicographically and are usually case-insensitive. Date-times compare in time order.

The group file lists the fields and operators that endpoint accepts. Any other combination returns 400.

Escape these characters inside a filter value: `#` → `%23`, `%` → `%25`, `&` → `%26`, `\` → `\\`, `"` → `\"`. If a query still fails on a space or quote, encode the space as `%20` and the quote as `%22`.

## Search

`POST /search/v1` with `limit` (default 10,000). The body carries `indices` and `query`. `POST /search/v1/count` puts the total in `X-Total-Count`. A terms-style query is limited to about 800 values.

Offset paging stops at 10,000 rows. To go further, set `sort` to `["id"]` and pass `searchAfter` as the previous page's last sort values. Repeat until a page comes back empty.

```json
{
  "indices": ["identities"],
  "query": { "query": "*" },
  "sort": ["id"],
  "searchAfter": ["2c9180835d38ca0c015d606b50851b1e"]
}
```

`sail search` is the CLI wrapper. A custom body or `searchAfter` goes through `sail api post /search/v1`.

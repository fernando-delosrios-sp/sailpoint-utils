Smart API Rate Limiting and Backoff Behavior | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/getting-started/smart-api-rate-limiting-and-backoff-behavior.md).
### Overview[#overview](#overview)

The platform is designed to operate safely within the rate limits imposed by upstream systems. All integrations dynamically adjust to the usage constraints of the external service, ensuring stable performance and preventing disruptions to customer environments.
GitBook Assistant

When rate limits are reached, the platform automatically initiates a controlled backoff and retry mechanism. If repeated attempts continue to fail, the system progressively increases the backoff interval, slowing the scan cycle to remain compliant with the provider's requirements.
GitBook Assistant

An upcoming release will surface integration health and rate-limit details directly in the UI, allowing administrators to diagnose and optimize connector performance more easily.
GitBook Assistant
### Rate Limit Awareness[#rate-limit-awareness](#rate-limit-awareness)

Each integration monitors responses from the target platform for correct rate-limit indicators, including HTTP status codes, throttling headers, and provider-specific quota signals. Once detected, the system adjusts behavior in real time.
GitBook Assistant

Key characteristics:
GitBook Assistant

- 

Automatically identifies when an external API enforces a throttle.
GitBook Assistant
- 

Respects per-platform quota rules with no additional configuration from the user.
GitBook Assistant
- 

Maintains scan stability by avoiding unnecessary retries or aggressive requests.
GitBook Assistant

### Backoff and Retry Logic[#backoff-and-retry-logic](#backoff-and-retry-logic)

When a rate limit is hit, the system triggers a standardized recovery workflow.
GitBook Assistant
#### Initial Retry Sequence[#initial-retry-sequence](#initial-retry-sequence)

1. 

Detect rate-limit or throttling response. 
GitBook Assistant
1. 

Pause requests for the provider-defined cool-down window or a default minimum interval. 
GitBook Assistant
1. 

Retry the request.
GitBook Assistant

If the retry succeeds, scanning resumes as normal with no user intervention required.
GitBook Assistant
#### Progressive Backoff[#progressive-backoff](#progressive-backoff)

If retries continue to return rate-limit or similar transient errors, the platform escalates to a progressive backoff model.
GitBook Assistant

This includes:
GitBook Assistant

- 

Increasing wait intervals between request batches. 
GitBook Assistant
- 

Dynamically adjusting concurrency to reduce pressure on the API. 
GitBook Assistant
- 

Extending the overall scan cycle to prevent further throttling events. 
GitBook Assistant

The result is a slower but stable scan cadence that self-corrects once the provider restores quota.
GitBook Assistant
### Recovery and Resumption[#recovery-and-resumption](#recovery-and-resumption)

Once rate limits reset, the platform automatically:
GitBook Assistant

- 

Returns to normal request intervals. 
GitBook Assistant
- 

Restores standard concurrency settings. 
GitBook Assistant
- 

Re-aligns scan timing to the expected cycle. 
GitBook Assistant

No manual action is required unless the upstream platform continues to enforce persistent throttling.
GitBook Assistant
### Upcoming Visibility in the UI[#upcoming-visibility-in-the-ui](#upcoming-visibility-in-the-ui)

Future releases will introduce detailed integration health metrics that highlight:
GitBook Assistant

- 

Rate-limit events detected during scans. 
GitBook Assistant
- 

Backoff intervals currently applied. 
GitBook Assistant
- 

Retry counts and error response patterns. 
GitBook Assistant
- 

Overall impact on scan duration.
GitBook Assistant

 
[PreviousData Flow](/getting-started/data-flow)[NextDeployment](/getting-started/deployment)

Last updated 8 months ago

- [Overview](#overview)
- [Rate Limit Awareness](#rate-limit-awareness)
- [Backoff and Retry Logic](#backoff-and-retry-logic)
- [Recovery and Resumption](#recovery-and-resumption)
- [Upcoming Visibility in the UI](#upcoming-visibility-in-the-ui)

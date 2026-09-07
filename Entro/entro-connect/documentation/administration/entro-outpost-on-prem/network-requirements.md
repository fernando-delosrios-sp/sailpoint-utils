Network Requirements | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/entro-outpost-on-prem/network-requirements.md).
### **External Access**[#external-access](#external-access)

The Entro Outpost requires access to various external URLs in order for the Outpost to communicate with the Entro Platform:
GitBook Assistant
#### Entro SaaS[#entro-saas](#entro-saas)

- 

`*api.entro.security` - Entro's own API endpoint
GitBook Assistant

The Outpost **does not **communicate directly with Entro's UI (app.entro.security)
GitBook Assistant
#### AWS:[#aws](#aws)

- 

`*.s3.amazonaws.com`
GitBook Assistant
- 

`*.s3.{region}.amazonaws.com`
GitBook Assistant
- 

`iam.amazonaws.com`
GitBook Assistant
- 

`logs.{region}.amazonaws.com`
GitBook Assistant
- 

`secretsmanager.{region}.amazonaws.com`
GitBook Assistant
- 

`sqs.{region}.amazonaws.com`
GitBook Assistant
- 

`sts.{region}.amazonaws.com`
GitBook Assistant
- 

`s3express-control.{region}.amazonaws.com`
GitBook Assistant
- 

`monitoring.us-east-1.amazonaws.com`
GitBook Assistant

Default region is `us-east-1` unless specified otherwise. Replace `{region}` accordingly.
GitBook Assistant

More about AWS service endpoints can be found here:
GitBook Assistant

- 

[https://docs.aws.amazon.com/general/latest/gr/rande.html](https://docs.aws.amazon.com/general/latest/gr/rande.html)
GitBook Assistant
- 

[https://docs.aws.amazon.com/general/latest/gr/aws-service-information.html](https://docs.aws.amazon.com/general/latest/gr/aws-service-information.html)
GitBook Assistant

### Firewall / proxy notes[#firewall-proxy-notes](#firewall-proxy-notes)

**Do not perform SSL stripping or MITM on Entro traffic.**
GitBook Assistant

- 

Allow outbound HTTPS to Entro API hosts and required AWS endpoints above.
GitBook Assistant
- 

If using Entro SaaS perimeter static IPs, see the [IP list on the SaaS-perimeter page](https://docs.entro.security/integrations/entro-connector/entro-connector/entro-saas-perimeter-ips).
GitBook Assistant
- 

If a proxy is required, make sure the proxy is configured in the `.env-connector` file. 
GitBook Assistant

### **Local Access**[#local-access](#local-access)

Allow connectivity between the Outpost and any integrated services. For example -
GitBook Assistant

- 

To onboard your local BitBucket server - Allow the Outpost to access it
GitBook Assistant
- 

To onboard SMB File Shares - Allow the Outpost to access them
GitBook Assistant

The Entro Outpost **must** have network connectivity to any onboarded integration.
GitBook Assistant

## Exposure Validation Checks[#exposure-validation-checks](#exposure-validation-checks)

When token and secret exposures are found by the Outpost scanner, the Entro Outpost will connect to the service that secret belongs to to determine the validity status of the token or secret. Please allow the Outpost(s) to connect following URLs to determine the current validity of the exposure:
GitBook Assistantorigin_typeendpointspurpose

AIVEN_API_KEY
GitBook Assistant

https://api.aiven.io/v1/account
GitBook Assistant

Validate Aiven API key and fetch user info
GitBook Assistant

AKEYLESS_ACCESS_KEY
GitBook Assistant

https://api.akeyless.io/auth
GitBook Assistant

Validate Akeyless Access Key
GitBook Assistant

ALGOLIA
GitBook Assistant

https://*-dsn.algolia.net/1/*
GitBook Assistant

Validate Algolia API key
GitBook Assistant

ARTIFACTORY_JFROG_CREDS_JWT
GitBook Assistant

https://*.jfrog.io/artifactory/api/storageinfo, https:///artifactory/api/users
GitBook Assistant

Validate JFrog Artifactory JWT credentials
GitBook Assistant

ARTIFACTORY_JFROG_TOKEN
GitBook Assistant

https://*.jfrog.io/artifactory/api/storageinfo, https:///artifactory/api/users
GitBook Assistant

Validate JFrog Artifactory token
GitBook Assistant

ASANA_ACCESS_TOKEN
GitBook Assistant

https://app.asana.com/api/1.0/users/me
GitBook Assistant

Validate Asana Personal Access Token and fetch user info
GitBook Assistant

AWS
GitBook Assistant

sts:GetCallerIdentity; iam:GetAccessKeyInfo (AWS Servers)
GitBook Assistant

Validate AWS credentials and fetch account/resource info
GitBook Assistant

AZURE_APP_REGISTRATION_CLIENT_SECRET
GitBook Assistant

https://login.microsoftonline.com/*/oauth2/v2.0/token
GitBook Assistant

Validate Azure App Registration Client Secret
GitBook Assistant

AZURE_COSMOS_DB_KEY
GitBook Assistant

*.azure.com/*
GitBook Assistant

Validate Azure Cosmos DB Key
GitBook Assistant

AZURE_DEVOPS_PAT_V2
GitBook Assistant

https://app.vssps.visualstudio.com/_apis/accounts
GitBook Assistant

Validate Azure DevOps token and fetch accounts
GitBook Assistant

AZURE_DEVOPS_TOKEN
GitBook Assistant

https://app.vssps.visualstudio.com/_apis/accounts
GitBook Assistant

Validate Azure DevOps token and fetch accounts
GitBook Assistant

AZURE_STORAGE_ACCESS_KEY
GitBook Assistant

https://*.blob.core.windows.net/?comp=list
GitBook Assistant

Validate Azure Storage Access Key
GitBook Assistant

BITBUCKET_OAUTH_CREDS
GitBook Assistant

https://bitbucket.org/site/oauth2/access_token
GitBook Assistant

Validate Bitbucket OAuth credentials and fetch token info
GitBook Assistant

BOX_OAUTH
GitBook Assistant

https://api.box.com/oauth2/token
GitBook Assistant

Validate Box OAuth token
GitBook Assistant

BUILDKITE
GitBook Assistant

https://api.buildkite.com/v2/access-token
GitBook Assistant

Validate Buildkite API token
GitBook Assistant

CONTENTFUL
GitBook Assistant

https://api.contentful.com/organizations
GitBook Assistant

Validate Contentful API key
GitBook Assistant

DATABRICKS_PAT
GitBook Assistant

https://*.databricks.com/api/2.0/token/create https://*azurewebsites.net/api/2.0/token/create https://*azuredatabricks.net/api/2.0/token/create
GitBook Assistant

Validate Databricks Personal Access Token
GitBook Assistant

DATADOG_API_KEY
GitBook Assistant

https://us5.datadoghq.com/api/v1/validate,https://app.datadoghq.com/api/v1/validate,https://us3.datadoghq.com/api/v1/validate,https://app.datadoghq.eu/api/v1/validate,https://app.ddog-gov.com/api/v1/validate,https://ap1.datadoghq.com/api/v1/validate
GitBook Assistant

Validate Datadog API key
GitBook Assistant

DIGITAL_OCEAN_PERSONAL_ACCESS_TOKEN
GitBook Assistant

https://api.digitalocean.com/v2/account
GitBook Assistant

Validate DigitalOcean Personal Access Token
GitBook Assistant

DIGITAL_OCEAN_SPACES_KEYS
GitBook Assistant

https://nyc3.digitaloceanspaces.com,https://sfo2.digitaloceanspaces.com,https://ams3.digitaloceanspaces.com,https://sgp1.digitaloceanspaces.com,https://fra1.digitaloceanspaces.com
GitBook Assistant

Validate DigitalOcean Spaces keys
GitBook Assistant

DROPBOX_APP_CREDS
GitBook Assistant

https://www.dropbox.com/oauth2/authorize?client_id=${the key we found}&response_type=code
GitBook Assistant

Validate Dropbox app credentials
GitBook Assistant

DROPBOX_APP_OAUTH_TOKEN
GitBook Assistant

https://api.dropboxapi.com/2/users/get_current_account
GitBook Assistant

Validate Dropbox OAuth token and fetch account info
GitBook Assistant

DROPBOX_SIGN_API_KEY
GitBook Assistant

https://api.hellosign.com/v3/template/list
GitBook Assistant

Validate Dropbox Sign API key
GitBook Assistant

ELASTIC_CLOUD
GitBook Assistant

https://api.elastic-cloud.com/api/v1/deployments
GitBook Assistant

Validate Elastic Cloud credentials and fetch deployments
GitBook Assistant

ENTRO_API_KEY
GitBook Assistant

https://fidelity-api.entro.security/v2/scan?generic=false&redact=true
GitBook Assistant

Validate Entro API key
GitBook Assistant

FACEBOOK_APP_ID
GitBook Assistant

https://graph.facebook.com/debug_token?input_token=${credsWeFound}&access_token=${credsWeFound}
GitBook Assistant

Validate Facebook App ID
GitBook Assistant

FASTLY_API_KEY
GitBook Assistant

https://api.fastly.com/tokens/self
GitBook Assistant

Validate Fastly API key
GitBook Assistant

FIGMA_PAT
GitBook Assistant

https://api.figma.com/v1/me
GitBook Assistant

Validate Figma Personal Access Token and fetch user info
GitBook Assistant

FULLSTORY
GitBook Assistant

https://developer.fullstory.com/server/v1/authentication/me/
GitBook Assistant

Validate FullStory API key and fetch user info
GitBook Assistant

GITHUB
GitBook Assistant

https://api.github.com/user; https://api.github.com/user/repos
GitBook Assistant

Validate GitHub token and fetch user/repos info
GitBook Assistant

GITBOOK_API_KEY
GitBook Assistant

https://api.gitbook.com/v1/user
GitBook Assistant

Validate GitBook API key
GitBook Assistant

GITLAB_PAT
GitBook Assistant

https://gitlab.com/api/v4/user, https://gitlab.com/api/v4/runners, https://gitlab.com/api/v4/projects/{project_id}/cluster_agents, https://gitlab.com/api/v4/projects/{project_id}/repository/files/{file_path}/raw?ref={branch}, https://gitlab.com/api/v4/projects/{project_id}/registry/repositories
GitBook Assistant

Validate GitLab Personal Access Token and fetch user info
GitBook Assistant

GOOGLE_GCP
GitBook Assistant

https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=${key we found}
GitBook Assistant

Validate Google Cloud API token
GitBook Assistant

GOOGLE_GCP_SERVICE_ACCOUNT
GitBook Assistant

https://oauth2.googleapis.com/token
GitBook Assistant

Validate GCP service account credentials
GitBook Assistant

GROQ_API_KEY
GitBook Assistant

https://api.groq.com/openai/v1/chat/completions
GitBook Assistant

Validate Groq API key
GitBook Assistant

HEROKU
GitBook Assistant

https://api.heroku.com/apps
GitBook Assistant

Validate Heroku API key and fetch apps
GitBook Assistant

HUBSPOT
GitBook Assistant

https://api.hubapi.com/oauth/v2/private-apps/get/access-token-info
GitBook Assistant

Validate HubSpot API key and fetch token info
GitBook Assistant

HUGGING_FACE_ACCESS_TOKEN
GitBook Assistant

https://huggingface.co/api/whoami-v2
GitBook Assistant

Validate Hugging Face access token
GitBook Assistant

JFROG_JWT_ACCESS_TOKEN
GitBook Assistant

https://*.jfrog.io/artifactory/api/storageinfo, https:///artifactory/api/users
GitBook Assistant

Validate JFrog Artifactory JWT access token
GitBook Assistant

JFROG_REFERENCE_ACCESS_TOKEN
GitBook Assistant

https://*.jfrog.io/artifactory/api/storageinfo, https:///artifactory/api/users
GitBook Assistant

Validate JFrog Artifactory reference access token
GitBook Assistant

KLAVIYO_API_KEY
GitBook Assistant

https://a.klaviyo.com/api/accounts
GitBook Assistant

Validate Klaviyo API key
GitBook Assistant

LAUNCHDARKLY_API_KEY
GitBook Assistant

https://app.launchdarkly.com/api/v2/caller-identity
GitBook Assistant

Validate LaunchDarkly API key
GitBook Assistant

LAUNCHDARKLY_MOBILE
GitBook Assistant

https://app.launchdarkly.com/api/v2/caller-identity
GitBook Assistant

Validate LaunchDarkly mobile key
GitBook Assistant

LAUNCHDARKLY_SDK
GitBook Assistant

https://app.launchdarkly.com/api/v2/caller-identity
GitBook Assistant

Validate LaunchDarkly SDK key
GitBook Assistant

MAILCHIMP_API_KEY
GitBook Assistant

https://*.api.mailchimp.com/3.0/
GitBook Assistant

Validate Mailchimp API key
GitBook Assistant

MAILGUN_PAT
GitBook Assistant

https://api.mailgun.net/v4/domains
GitBook Assistant

Validate Mailgun Personal Access Token
GitBook Assistant

META_APP_CREDS
GitBook Assistant

https://graph.facebook.com/debug_token?input_token=${creds we found}&access_token=${creds we found}
GitBook Assistant

Validate Meta (Facebook) app credentials
GitBook Assistant

META_APP_CREDS_PAIR
GitBook Assistant

https://graph.facebook.com/debug_token?input_token=${credsWeFound}&access_token=${credsWeFound}
GitBook Assistant

Validate Meta (Facebook) app credentials
GitBook Assistant

META_USER_TOKEN
GitBook Assistant

https://graph.facebook.com/debug_token?input_token=${token}&access_token=${token}
GitBook Assistant

Validate Meta (Facebook) user token
GitBook Assistant

NOTION
GitBook Assistant

https://api.notion.com/v1/users/me
GitBook Assistant

Validate Notion API key and fetch user info
GitBook Assistant

NPM
GitBook Assistant

https://registry.npmjs.org/-/whoami
GitBook Assistant

Validate NPM token
GitBook Assistant

OKTA_API_KEY
GitBook Assistant

*.okta.com/*
GitBook Assistant

Validate Okta API key
GitBook Assistant

OKTA_CLIENT_SECRET
GitBook Assistant

*.okta.com/*
GitBook Assistant

Validate Okta client secret
GitBook Assistant

OPENAI
GitBook Assistant

https://api.openai.com/v1/models
GitBook Assistant

Validate OpenAI API key and fetch available models
GitBook Assistant

OPENAI_SERVICE_ACCOUNT
GitBook Assistant

https://api.openai.com/v1/models
GitBook Assistant

Validate OpenAI API key and fetch available models
GitBook Assistant

OPENWEATHER_API_KEY
GitBook Assistant

https://api.openweathermap.org/data/2.5/weather?id=524901&lang=fr&appid=${found token}
GitBook Assistant

Validate OpenWeather API key
GitBook Assistant

PAYPAL_BRAINTREE_CREDS_PAIR
GitBook Assistant

https://api-m.sandbox.paypal.com/v1/oauth2/token
GitBook Assistant

Validate PayPal Braintree credentials
GitBook Assistant

PINECONE_API_KEY
GitBook Assistant

https://controller.gcp-starter.pinecone.io/databases,https://controller.us-west1-gcp-free.pinecone.io/databases,https://controller.asia-southeast1-gcp-free.pinecone.io/databases,https://controller.us-west4-gcp-free.pinecone.io/databases,https://controller.us-west1-gcp.pinecone.io/databases,https://controller.us-central1-gcp.pinecone.io/databases,https://controller.us-west4-gcp.pinecone.io/databases,https://controller.us-east4-gcp.pinecone.io/databases,https://controller.northamerica-northeast1-gcp.pinecone.io/databases,https://controller.asia-northeast1-gcp.pinecone.io/databases,https://controller.asia-southeast1-gcp.pinecone.io/databases,https://controller.us-east1-gcp.pinecone.io/databases,https://controller.eu-west1-gcp.pinecone.io/databases,https://controller.eu-west4-gcp.pinecone.io/databases,https://controller.us-east-1-aws.pinecone.io/databases,https://controller.eastus-azure.pinecone.io/databases
GitBook Assistant

Validate Pinecone API key
GitBook Assistant

PINECONE_KEY
GitBook Assistant

https://controller.gcp-starter.pinecone.io/actions/whoami,https://controller.us-west1-gcp-free.pinecone.io/actions/whoami,https://controller.asia-southeast1-gcp-free.pinecone.io/actions/whoami,https://controller.us-west4-gcp-free.pinecone.io/actions/whoami,https://controller.us-west1-gcp.pinecone.io/actions/whoami,https://controller.us-central1-gcp.pinecone.io/actions/whoami,https://controller.us-west4-gcp.pinecone.io/actions/whoami,https://controller.us-east4-gcp.pinecone.io/actions/whoami,https://controller.northamerica-northeast1-gcp.pinecone.io/actions/whoami,https://controller.asia-northeast1-gcp.pinecone.io/actions/whoami,https://controller.asia-southeast1-gcp.pinecone.io/actions/whoami,https://controller.us-east1-gcp.pinecone.io/actions/whoami,https://controller.eu-west1-gcp.pinecone.io/actions/whoami,https://controller.eu-west4-gcp.pinecone.io/actions/whoami,https://controller.us-east-1-aws.pinecone.io/actions/whoami,https://controller.eastus-azure.pinecone.io/actions/whoami
GitBook Assistant

Validate Pinecone key
GitBook Assistant

PINGDOM_TOKEN
GitBook Assistant

https://api.pingdom.com/api/3.1/checks
GitBook Assistant

Validate Pingdom token
GitBook Assistant

PUBNUB
GitBook Assistant

https://ps.pndsn.com/v2/objects/${subscribe key}/uuids
GitBook Assistant

Validate PubNub subscribe key
GitBook Assistant

PUBNUB_FULL_CREDS
GitBook Assistant

https://ps.pndsn.com/signal/${publish key}/${subscribe key}/0/ch1/0/%22typing_on%22?uuid=user-123
GitBook Assistant

Validate PubNub full credentials
GitBook Assistant

REDIS_CLOUD_API_KEYS
GitBook Assistant

https://api.redislabs.com/v1/
GitBook Assistant

Validate Redis Cloud API key
GitBook Assistant

SENDGRID
GitBook Assistant

https://api.sendgrid.com/v3/templates
GitBook Assistant

Validate SendGrid API key and fetch templates
GitBook Assistant

SENTRY_ORGANIZATION_AUTH_TOKEN
GitBook Assistant

https://us.sentry.io/api/0/organizations/*/projects/,https://eu.sentry.io/api/0/organizations/*/projects/ where we extract the org from the found token
GitBook Assistant

Validate Sentry organization auth token
GitBook Assistant

SENTRY_TOKEN
GitBook Assistant

https://sentry.io/api/0/projects/
GitBook Assistant

Validate Sentry token
GitBook Assistant

SENTRY_USER_AUTH_TOKEN
GitBook Assistant

https://us.sentry.io/api/0/organizations/,https://eu.sentry.io/api/0/organizations/
GitBook Assistant

Validate Sentry user auth token
GitBook Assistant

SHIPPO
GitBook Assistant

https://api.goshippo.com/shipments/
GitBook Assistant

Validate Shippo API token
GitBook Assistant

SHOPIFY_KEY
GitBook Assistant

https://*.myshopify.com/admin/oauth/access_scopes.json
GitBook Assistant

Validate Shopify API key
GitBook Assistant

SLACK
GitBook Assistant

https://slack.com/api/auth.test
GitBook Assistant

Validate Slack token and fetch workspace/user info
GitBook Assistant

SLACKWEBHOOK
GitBook Assistant

https://hooks.slack.com/services/*
GitBook Assistant

Validate Slack webhook by sending a simple request
GitBook Assistant

SNOWFLAKE
GitBook Assistant

https://*.snowflakecomputing.com/session/v1/login-request, https://*.snowflakecomputing.com/queries/v1/query-request
GitBook Assistant

Validate Snowflake credentials
GitBook Assistant

SNOWFLAKE_GENERIC_CREDENTIALS
GitBook Assistant

https://*.snowflakecomputing.com/session/v1/login-request, https://*.snowflakecomputing.com/queries/v1/query-request
GitBook Assistant

Validate Snowflake credentials
GitBook Assistant

SQUARE_APP_TOKEN
GitBook Assistant

https://connect.squareupsandbox.com/v2/merchants
GitBook Assistant

Validate Square app token
GitBook Assistant

SQUARE_FULL_CREDS
GitBook Assistant

https://connect.squareupsandbox.com/v2/merchants
GitBook Assistant

Validate Square full credentials
GitBook Assistant

STRIPE_API_KEY
GitBook Assistant

https://api.stripe.com/v1/charges
GitBook Assistant

Validate Stripe API key and fetch account info
GitBook Assistant

SUMO_LOGIC_ACCESS_ID
GitBook Assistant

https://api.sumologic.com/api/v1/users
GitBook Assistant

Validate Sumo Logic Access ID credentials
GitBook Assistant

SUMO_LOGIC_CREDS
GitBook Assistant

https://api.sumologic.com/api/v1/users
GitBook Assistant

Validate Sumo Logic credentials
GitBook Assistant

TWILIO_API_KEY
GitBook Assistant

https://verify.twilio.com/v2/Services
GitBook Assistant

Validate Twilio API key
GitBook Assistant

TWILIO_MASTER_CREDENTIALS
GitBook Assistant

https://verify.twilio.com/v2/Services
GitBook Assistant

Validate Twilio master credentials
GitBook Assistant

TYPEFORM_API_TOKEN
GitBook Assistant

https://api.typeform.com/me
GitBook Assistant

Validate Typeform API token
GitBook Assistant

URI
GitBook Assistant

*
GitBook Assistant

Validate generic URI
GitBook Assistant

X_CONSUMER_CREDS
GitBook Assistant

https://api.twitter.com/oauth2/token, https://api.twitter.com/2/tweets/20
GitBook Assistant

Validate X-Consumer credentials
GitBook Assistant[PreviousSystem Requirements](/administration/entro-outpost-on-prem/system-requirements)[NextOutpost Installation](/administration/entro-outpost-on-prem/outpost-installation)

Last updated 8 months ago

- [External Access](#external-access)
- [Firewall / proxy notes](#firewall-proxy-notes)
- [Local Access](#local-access)
- [Exposure Validation Checks](#exposure-validation-checks)

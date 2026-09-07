Outpost Scanning Scheduler | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/entro-outpost-on-prem/outpost-scanning-scheduler.md).
#### Enabling scheduling[#enabling-scheduling](#enabling-scheduling)

If the customer needs the Entro Outpost to schedule scanning and downtimes, this can be enabled on the Outpost by setting up values in `helm/values.yaml`:
GitBook Assistant

1. 

`connector.scheduling` - set to true to enable the scheduling
GitBook Assistant
1. 

`connector.schedule.scaleUp` - UTC cron regex for connector scale up
GitBook Assistant
1. 

`connector.schedule.scaleDown` - UTC cron regex for connector scale down
GitBook Assistant

We can use [Dateful Time Zone Converter](https://dateful.com/time-zone-converter) to convert time zones and scheduling times:
GitBook Assistant

`spec: timeZone: ''`
GitBook Assistant

Once the values file is configured, deploy the Helm chart using the new configuration following standard procedures. This will create additional Kubernetes resources for handling permissions. Each time the cron job runs, a new pod will execute the job. By default, the configuration retains only the most recent pod from each execution, though the number of pods to keep can be customized as needed:
GitBook Assistant

`successfulJobsHistoryLimit: 1 failedJobsHistoryLimit: 1`
GitBook Assistant

 
[PreviousKubernetes Upgrade](/administration/entro-outpost-on-prem/outpost-upgrade/kubernetes-upgrade)[NextEncrypting Integration Secrets](/administration/entro-outpost-on-prem/encrypting-integration-secrets)

Last updated 11 months ago

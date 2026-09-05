Organization Configuration | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/organization-configuration.md).

The **Organization Configuration** section allows administrators to customize baseline and detection settings in Entro to better align with their organization’s environment. These configurations enhance the precision of detections, reduce unnecessary alerts, and ensure monitoring reflects your organization’s activity patterns. Through settings such as **Geo-Locations Baseline**, **Organization IP Ranges**, and **User Exclusion from Detections**, Entro continuously learns and adapts to deliver more **contextual, accurate, and actionable insights** across your connected systems.
GitBook Assistant
### **Geo-Locations Baseline**[#geo-locations-baseline](#geo-locations-baseline)

Entro automatically builds a **baseline of countries** where your organization’s accounts and tokens are active. Any new country detected after the initial learning period may indicate unfamiliar or potentially risky activity.
GitBook Assistant

The baseline view displays each country’s token count, account types, and first-seen date, allowing administrators to review and approve trusted regions. If unexpected geographic activity appears, it will be flagged for further investigation.
GitBook Assistant
### **Organization IP Ranges**[#organization-ip-ranges](#organization-ip-ranges)

This section defines the **IP ranges** associated with your organization. By adding your known cloud and on-premise IP addresses, Entro establishes a trusted network profile and can more effectively **detect anomalies or unauthorized activity**.
GitBook Assistant

Administrators can specify IP ranges by provider and region. These entries can be updated at any time as infrastructure changes, ensuring Entro continuously reflects your current network perimeter.
GitBook Assistant
### **User Exclusion from Detections**[#user-exclusion-from-detections](#user-exclusion-from-detections)

Entro enables administrators to **exclude any secret exposures made by specific users.** This feature helps prevent expected or non-sensitive exposures—such as those from internal test accounts — from creating unnecessary alerts.
GitBook Assistant

[PreviousExposed Secrets](/administration/settings/exposed-secrets)[NextRisk Configuration](/administration/settings/risk-configuration)

Last updated 10 months ago

- [Geo-Locations Baseline](#geo-locations-baseline)
- [Organization IP Ranges](#organization-ip-ranges)
- [User Exclusion from Detections](#user-exclusion-from-detections)

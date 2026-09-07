Exclusion Rule | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/exclusion-rule.md).

**Exclusion Rules** allow you to define which files or paths should be ignored during scans, ensuring that detection efforts focus on relevant and high-value areas of the codebase.
GitBook Assistant

By configuring exclusions, organizations can reduce noise from non-sensitive sources, improve scanning efficiency, and maintain clear visibility into meaningful exposures.
GitBook Assistant
### **Configuring Exclusions**[#configuring-exclusions](#configuring-exclusions)

Each exclusion rule defines a **match type**, a **file path** pattern and the **source platform**, that determines which file paths should Entro ignore during scanning.
GitBook Assistant
#### Rule Type:[#rule-type](#rule-type)

Exclusions can be applied at multiple levels - from entire repositories to individual files or file types using a variety of matching options:
GitBook Assistant

- 

**Starts With** — Excludes all paths that begin with the specified prefix.
GitBook Assistant
- 

**Contains** — Excludes any path containing the defined string.
GitBook Assistant
- 

**Ends With** — Excludes files or directories that end with a specific term or extension.
GitBook Assistant
- 

**Exact** — Excludes a specific repository, file, or directory path.
GitBook Assistant
- 

**Wildcard** — Allows flexible pattern matching using `*` to exclude multiple or partial path matches.
GitBook Assistant

These rules can be combined to create precise exclusion logic that aligns with your organization’s code structure and scanning requirements.
GitBook Assistant
#### Supported Sources**:**[#supported-sources](#supported-sources)

- 

**GitHub **(Commits)
GitBook Assistant
- 

**GitLab **(Commits)
GitBook Assistant
- 

**Bitbucket **(Commits)
GitBook Assistant
- 

**Azure DevOps **(Commits, Wiki pages)
GitBook Assistant
- 

**SharePoint** (Documents, Pages)
GitBook Assistant
- 

**Google Drive** (Files)
GitBook Assistant

Multiple accounts can be used for the same rule
GitBook Assistant
#### Examples:[#examples](#examples)

- 

`Ends With` `.html` → ignores HTML files across all scanned sources
GitBook Assistant
- 

`Wildcard` `sample*config*.yaml` → ignores variations of config templates
GitBook Assistant
- 

`Contains` `/personal/` → ignores files under the "/personal/" directory 
GitBook Assistant

### **Validating Exclusion Patterns**[#validating-exclusion-patterns](#validating-exclusion-patterns)

Before saving, Entro checks how many existing findings match your rule. This preview helps ensure the rule is accurate and intentional. You can choose to **discard all matched findings** to clean up historical noise.
GitBook Assistant
### **Best Practices**[#best-practices](#best-practices)

- 

Use **specific and well-scoped patterns** to avoid unintentionally excluding sensitive content.
GitBook Assistant
- 

Always **validate** exclusion rules before saving to confirm they behave as expected.
GitBook Assistant
- 

Review and update exclusions periodically to reflect changes in your repositories or scanning policies.
GitBook Assistant
- 

Use **wildcards cautiously**, as broad expressions may unintentionally exclude important files.
GitBook Assistant

### Suggested by Entro[#suggested-by-entro](#suggested-by-entro)

To make setup easier, Entro automatically suggests exclusion rules based on patterns that commonly contain FP findings (`Ends With` `.html` , `Ends With` `.css` , `Ends With` `.md` )
GitBook Assistant

These suggestions are enabled by default and can be removed at any time.
GitBook Assistant

[PreviousRequest New Secret](/administration/settings/request-new-secret)[NextSecret Type Control](/administration/settings/secret-type-control)

Last updated 7 months ago

- [Configuring Exclusions](#configuring-exclusions)
- [Validating Exclusion Patterns](#validating-exclusion-patterns)
- [Best Practices](#best-practices)
- [Suggested by Entro](#suggested-by-entro)

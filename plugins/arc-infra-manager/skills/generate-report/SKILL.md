---
name: generate-report
description: 'Produce fleet status, health, compliance, and patch reports for Azure Arc-enabled servers.'
---

# Generate Report

## Purpose

Query Azure Arc operational data and produce formatted reports covering fleet status, server health, compliance posture, extension coverage, and patch status. Reports provide a structured overview for shift handoffs, management summaries, or operational reviews.

## When to Use

- Producing a daily or weekly fleet status summary
- Preparing a compliance posture report for management
- Documenting the current state of the fleet for audit purposes
- Generating a patch status report before or after a maintenance window
- Summarizing extension deployment coverage across the fleet

## Instructions

1. **Determine report type**: Accept the report type from the operator:
   - **Fleet status**: Server counts by OS, location, and status with health summary
   - **Health**: Detailed agent connectivity and extension health across the fleet
   - **Compliance**: Azure Policy and machine configuration compliance posture
   - **Patch status**: Update assessment summary with pending patches by severity
   - **Extension coverage**: Matrix of which extensions are deployed on which servers
   - **Custom**: Combination of the above based on operator request

2. **Gather fleet data**: Call `arc_list_servers` to get the full server inventory. Aggregate by:
   - Operating system (Windows vs. Linux)
   - Connectivity status (Connected, Disconnected, Expired, Error)
   - Azure region
   - Resource group
   - Tags (environment, team, etc.)

3. **Gather health data** (if applicable): For each server or a sample, check agent status and extension health. Compute:
   - Fleet connectivity rate (connected / total)
   - Servers with stale heartbeats (> 1 hour)
   - Extension failure rate

4. **Gather compliance data** (if applicable): Call `arc_get_policy_compliance` to get policy compliance metrics. Compute:
   - Overall compliance percentage
   - Non-compliant server count by policy category
   - Top policy violations

5. **Gather patch data** (if applicable): For small scopes (< 10 servers), call `arc_assess_updates` to trigger on-demand scans. For larger scopes, use `arc_get_update_history` instead (read-only, no scan triggered) to avoid API rate limits and thundering herd effects. Compute:
   - Servers with pending critical/security updates
   - Total pending updates by classification
   - Servers fully patched vs. needing updates

6. **Compile the report**: Produce a structured Markdown report with:
   - Executive summary (2-3 sentences)
   - Fleet metrics table
   - Detailed sections based on report type
   - Open items or recommendations

## Expected MCP Tools

- `arc_list_servers` -- List servers for fleet inventory
- `arc_get_server` -- Get server details for health assessment
- `arc_list_extensions` -- List extensions for coverage matrix
- `arc_get_policy_compliance` -- Get compliance data for compliance reports
- `arc_assess_updates` -- Get update assessment for patch reports

## Input

- **Required**: Report type -- fleet-status, health, compliance, patch-status, extension-coverage, or custom
- **Optional**: Scope -- subscription (default), resource group, or tag filter
- **Optional**: Time range for trend comparison (e.g., "compared to last week")
- **Default**: Fleet status report for all servers in the subscription

## Output

A formatted Markdown report:

```
## Arc Fleet Status Report

**Generated**: [timestamp] | **Scope**: [subscription / resource group]

### Executive Summary

[count] Arc-enabled servers managed across [count] resource groups in [count] regions.
[connectivity rate]% fleet connectivity. [count] servers require attention.

### Fleet Overview

| Metric | Count |
|--------|-------|
| Total servers | [n] |
| Windows | [n] |
| Linux | [n] |
| Connected | [n] |
| Disconnected | [n] |

### Servers by Region

| Region | Windows | Linux | Total |
|--------|---------|-------|-------|
| eastus | [n] | [n] | [n] |
| westeurope | [n] | [n] | [n] |

### Health Summary

| Status | Count | Percentage |
|--------|-------|------------|
| Healthy | [n] | [%] |
| Warning | [n] | [%] |
| Critical | [n] | [%] |

### Servers Requiring Attention

| Server | Issue | Priority |
|--------|-------|----------|
| [name] | Disconnected for 6 hours | High |
| [name] | Extension MDE.Linux failed | Medium |

### Recommendations

1. [Prioritized recommendation]
2. [Prioritized recommendation]
```

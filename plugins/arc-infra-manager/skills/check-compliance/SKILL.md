---
name: check-compliance
description: 'Audit Azure Policy compliance and machine configuration results for Azure Arc-enabled servers.'
---

# Check Compliance

## Purpose

Audit the compliance posture of Azure Arc-enabled servers against Azure Policy assignments and machine configuration (formerly guest configuration) baselines. Identifies non-compliant resources, evaluates configuration drift, and provides remediation guidance prioritized by severity.

## When to Use

- Performing a scheduled compliance audit of the Arc server fleet
- Investigating why a specific server is flagged as non-compliant
- Checking machine configuration (DSC) compliance for security baselines
- Preparing a compliance report for management or audit requirements
- Identifying policy violations after infrastructure changes

## Instructions

1. **Determine audit scope**: Accept the scope from the operator:
   - **Subscription-wide**: All Arc-enabled servers in the subscription
   - **Resource group**: Servers in a specific resource group
   - **Individual server**: A single server by name
   - **Policy-specific**: A specific policy definition across all servers

2. **Query policy compliance**: Call `arc_get_policy_compliance` with the appropriate scope filter. Extract:
   - Overall compliance percentage
   - Non-compliant resource count by policy definition
   - Compliance state per resource (Compliant, NonCompliant, Exempt, NotStarted)
   - Policy definitions with the highest non-compliance counts

3. **Query machine configuration**: For servers in scope, call `arc_list_guest_config_assignments` to list all configuration assignments. For each assignment, note:
   - Assignment name and type (Audit, ApplyAndMonitor, ApplyAndAutoCorrect)
   - Compliance status (Compliant, NonCompliant, Pending)
   - Last compliance check timestamp

4. **Drill into non-compliance**: For non-compliant assignments, call `arc_get_guest_config_report` to get detailed results:
   - Which specific configuration resources are out of compliance
   - Current value vs. expected value for each setting
   - Reason for non-compliance (drift, never configured, error)
   - Affected configuration section (Security, Networking, Software, etc.)

5. **Categorize findings by severity**:
   - **Critical**: Security policy violations — missing encryption, disabled audit logging, open management ports, missing endpoint protection
   - **High**: Security baseline drift on production servers — password policy changes, TLS configuration, firewall rule modifications
   - **Medium**: Operational policy violations — naming conventions, tagging requirements, backup configuration
   - **Low**: Informational — agent version policies, extension version requirements

6. **Produce compliance summary**: Format results with non-compliant servers grouped by severity, including specific policy/configuration names and remediation recommendations.

## Expected MCP Tools

- `arc_get_policy_compliance` — Get Azure Policy compliance state for Arc servers
- `arc_list_guest_config_assignments` — List machine configuration assignments for a server
- `arc_get_guest_config_report` — Get detailed compliance report for a configuration assignment

## Input

- **Optional**: Scope — subscription (default), resource group name, or specific server name
- **Optional**: Specific policy definition name to check
- **Optional**: Severity filter (Critical, High, Medium, Low)
- **Default**: Full compliance audit across all Arc servers in the subscription

## Output

A structured Markdown compliance report:

```
## Compliance Audit Report

**Scope**: [subscription / resource group / server] | **Date**: [timestamp]
**Overall Compliance**: [percentage]%
**Servers Audited**: [count] | **Non-Compliant**: [count]

### Policy Compliance Summary

| Policy Definition | Compliant | Non-Compliant | Exempt | Compliance % |
|-------------------|-----------|---------------|--------|-------------|
| Require Azure Monitor Agent | 45 | 5 | 2 | 90% |
| Enable Defender for Servers | 40 | 10 | 2 | 80% |

### Critical Findings

| Server | Policy/Config | Current State | Expected State | Severity |
|--------|---------------|---------------|----------------|----------|
| db-prod-01 | Audit log retention | 30 days | 90 days | Critical |
| web-prod-03 | TLS minimum version | 1.0 | 1.2 | Critical |

### Machine Configuration Compliance

| Server | Assignment | Status | Last Checked | Non-Compliant Resources |
|--------|------------|--------|--------------|------------------------|
| db-prod-01 | WindowsSecurityBaseline | NonCompliant | 2 hours ago | 3 of 45 |
| app-linux-02 | LinuxCISBenchmark | Compliant | 1 hour ago | 0 of 38 |

### Remediation Priorities

1. **Critical** ([count] findings): [summary of critical items]
2. **High** ([count] findings): [summary of high items]
3. **Medium** ([count] findings): [summary of medium items]
```

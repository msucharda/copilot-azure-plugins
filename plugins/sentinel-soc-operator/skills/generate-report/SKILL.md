---
name: generate-report
description: 'Query Sentinel data and produce formatted shift reports or SOC metrics.'
---

# Generate Report

## Purpose

Query Microsoft Sentinel operational data and produce formatted shift reports, management summaries, or SOC performance metrics for a specified time range. Reports include incident counts by severity and status, key findings, escalation activity, and MITRE ATT&CK tactic distribution.

## When to Use

- End of shift — analyst needs to document what happened during their shift
- Management reporting — SOC lead needs a summary for stakeholders
- Shift handoff — outgoing analyst needs to brief the incoming team
- Weekly/monthly metrics — team needs operational performance data

## Instructions

1. **Accept time range**: Parse the operator's requested time range. Common inputs:
   - "last 8 hours" → `ago(8h)`
   - "last 24 hours" → `ago(24h)`
   - "today" → `startofday(now())`
   - "this week" → `startofweek(now())`
   - Specific dates: "2025-01-15 to 2025-01-16"
   - Default to last 8 hours if not specified (standard shift length)

2. **Query incident data**: Call `sentinel_list_incidents` filtered to the specified time range. Retrieve all incidents created or updated within the window.

3. **Query incident metrics**: Use `loganalytics_execute_query` to run aggregation queries against the SecurityIncident table:

   ```kql
   SecurityIncident
   | where TimeGenerated > ago(8h)
   | summarize
       TotalIncidents = count(),
       HighSeverity = countif(Severity == "High"),
       MediumSeverity = countif(Severity == "Medium"),
       LowSeverity = countif(Severity == "Low"),
       NewIncidents = countif(Status == "New"),
       ActiveIncidents = countif(Status == "Active"),
       ClosedIncidents = countif(Status == "Closed"),
       TruePositives = countif(Classification == "TruePositive"),
       FalsePositives = countif(Classification == "FalsePositive"),
       BenignPositives = countif(Classification == "BenignPositive")
   ```

4. **Query alert volume**: Use `loganalytics_execute_query` to get alert distribution:

   ```kql
   SecurityAlert
   | where TimeGenerated > ago(8h)
   | summarize AlertCount = count() by AlertName, AlertSeverity
   | top 20 by AlertCount desc
   ```

5. **Query MITRE tactic distribution**: If tactic data is available in alerts, aggregate by tactic for the time range.

6. **Compile per-incident summaries**: For each incident in the time range, include:
   - Incident ID and title
   - Severity and current status
   - Triage decision (if closed: classification and reason)
   - Escalation status (escalated to Tier 2, or resolved at Tier 1)
   - Key entities involved
   - Assigned analyst

7. **Compute operational metrics**:
   - Total incidents in time range
   - Mean time to triage (creation to first status change)
   - Closure rate (closed / total)
   - True positive rate (true positives / closed)
   - Alert-to-incident ratio
   - Top 5 alert types by volume

8. **Produce formatted report**: Generate a complete Markdown report.

## Expected MCP Tools

- `loganalytics_execute_query` — Run aggregation queries for metrics and alert data
- `sentinel_list_incidents` — List incidents in the reporting time range

## Input

- **Time range**: Natural language time range (e.g., "last 8 hours", "today", "2025-01-15")
- **Optional report type**: "shift" (default), "management", "weekly"

## Output

A formatted Markdown shift report:

```
## SOC Shift Report

**Period**: [start time] — [end time]
**Generated**: [current timestamp]
**Analyst**: [if known]

### Executive Summary

[1-2 paragraph summary of the shift — total incidents, notable events, open items]

### Incident Metrics

| Metric | Value |
|--------|-------|
| Total incidents | [count] |
| High severity | [count] |
| Medium severity | [count] |
| Low severity | [count] |
| Closed | [count] |
| Still open | [count] |
| True positive rate | [percentage] |
| Mean time to triage | [duration] |

### Incidents by Severity

| Severity | New | Active | Closed | Total |
|----------|-----|--------|--------|-------|
| High     | [n] | [n]    | [n]    | [n]   |
| Medium   | [n] | [n]    | [n]    | [n]   |
| Low      | [n] | [n]    | [n]    | [n]   |

### Top Alerts

| Alert Name | Severity | Count |
|------------|----------|-------|
| [name]     | [sev]    | [n]   |

### MITRE ATT&CK Tactic Distribution

| Tactic | Count |
|--------|-------|
| [tactic name] (TAxxxx) | [n] |

### Incident Details

#### [Incident ID] — [Title]

- **Severity**: [sev] | **Status**: [status]
- **Classification**: [True Positive / False Positive / Benign / Pending]
- **Key entities**: [entity list]
- **Triage decision**: [action taken]

[Repeat for each incident]

### Open Items

- [Any incidents still requiring follow-up]
- [Pending investigations]
- [Items for next shift]
```

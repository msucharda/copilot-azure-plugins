# Generate KQL

## Purpose

Translate natural language investigation questions, hunting hypotheses, or data exploration requests into syntactically valid KQL (Kusto Query Language) queries targeting appropriate Microsoft Sentinel log tables. The generated queries include inline comments explaining the logic, time bounds, and row limits for safe execution.

## When to Use

- An analyst describes what they want to investigate in natural language
- A threat hunter has a hypothesis that needs to be translated into a query
- An investigation requires querying specific entity activity across log tables
- An analyst needs to explore a table's data for a specific pattern

## Instructions

1. **Parse the request**: Identify the key elements:
   - **Target entities**: IPs, users, hosts, domains, file hashes
   - **Target behavior**: What activity to look for (logins, process execution, network connections)
   - **Time range**: How far back to search (default to 7 days if not specified)
   - **Output preference**: Summary counts vs. detailed records

2. **Determine relevant tables**: Based on the request, select the appropriate Sentinel tables:
   - **User sign-in activity** → SigninLogs, AADSignInEventsBeta
   - **Windows security events** → SecurityEvent (legacy), WindowsEvent (modern)
   - **Process execution** → SecurityEvent (EventID 4688), DeviceProcessEvents (MDE)
   - **Network connections** → CommonSecurityLog, DeviceNetworkEvents
   - **File operations** → DeviceFileEvents
   - **Azure AD admin actions** → AuditLogs
   - **Microsoft 365 activity** → CloudAppEvents, OfficeActivity
   - **DNS queries** → DnsEvents
   - **Linux events** → Syslog
   - **Firewall/proxy logs** → CommonSecurityLog
   - **Threat intelligence** → ThreatIntelligenceIndicator
   - **Identity context** → IdentityInfo
   - **UEBA** → BehaviorAnalytics

3. **Validate table availability**: Call `loganalytics_list_tables` to confirm the target tables exist in the workspace. If a table is missing, suggest alternative tables or note that the corresponding data connector may not be enabled.

4. **Get table schema**: Call `loganalytics_get_table_schema` for each target table to confirm column names and types. Use the actual schema to build accurate queries.

5. **Generate KQL query**: Build the query with these requirements:
   - Start with the table name
   - Add `| where TimeGenerated > ago(Xd)` as the first filter (use the specified or default time range)
   - Add entity-specific filters (e.g., `| where IPAddress == "x.x.x.x"`)
   - Add behavior-specific filters based on the request
   - Project only relevant columns to keep output focused
   - Add `| top 1000 by TimeGenerated desc` or appropriate row limit
   - Include inline comments (`//`) explaining each filter step

6. **Validate syntax**: Review the generated query for common KQL errors:
   - Correct operator usage (`==` for exact match, `contains` for substring, `has` for word match)
   - Proper string quoting (double quotes for strings)
   - Valid `ago()` duration format (e.g., `ago(7d)`, `ago(24h)`)
   - Column names match the actual schema from step 4

7. **Present the query**: Output the complete KQL query with:
   - Target table and purpose explanation
   - The query itself with inline comments
   - Suggested modifications (e.g., "Change `7d` to `30d` for broader search")

## Expected MCP Tools

- `loganalytics_list_tables` — Verify target tables exist in the workspace
- `loganalytics_get_table_schema` — Get column names and types for accurate queries

## Input

- **Natural language request**: What the analyst wants to find (e.g., "Show me all sign-ins from user john@contoso.com in the last 3 days")
- **Optional context**: Known entities, incident ID, or previous query results

## Output

A formatted KQL query block:

```
## Generated KQL Query

**Target table**: [table name]
**Purpose**: [what this query searches for]
**Time range**: [duration]

​```kql
// [Purpose description]
// Target: [entity or behavior]
// Time range: [duration]
[TableName]
| where TimeGenerated > ago(7d)
| where [entity filter]
| where [behavior filter]
| project TimeGenerated, [relevant columns]
| top 1000 by TimeGenerated desc
​```

**Suggested modifications**:
- [Suggestion 1]
- [Suggestion 2]
```

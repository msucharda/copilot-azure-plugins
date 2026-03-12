# Execute KQL

## Purpose

Execute a KQL query against the Log Analytics workspace connected to Microsoft Sentinel and return structured results. This skill validates queries against safety guardrails before execution, handles error cases (zero results, missing tables), and formats output for analysis.

## When to Use

- After `generate-kql` produces a query that needs to be run
- When an analyst provides a manual KQL query for execution
- During investigation or hunting workflows that require live data
- When validating a detection rule query against historical data

## Instructions

1. **Receive query**: Accept a KQL query string from the operator or from the output of `generate-kql`.

2. **Safety validation**: Before execution, check the query against the plugin's safety guardrails (hooks.json):
   - **BLOCK**: If the query contains `.purge`, `| delete`, `.drop table`, or `.drop function`, reject the query immediately with an explanation of why the operation is blocked.
   - **WARN**: If the query contains `.set-or-replace`, `externaldata(`, `http_request(`, or `workspace(`, warn the operator and request explicit confirmation before proceeding.
   - **SUGGEST**: If the query uses `| sort` without a row limit, a `join` without a performance hint, or lacks a `TimeGenerated` filter, suggest improvements but proceed with execution.

3. **Execute query**: Call `loganalytics_execute_query` with the validated query. Use the default timespan (PT24H) unless the query itself includes a TimeGenerated filter for a different range.

4. **Handle zero results**: If the query returns zero rows:
   - Explicitly state: "Query returned 0 results."
   - Suggest possible reasons:
     - The time range may be too narrow — try expanding with `ago(30d)`
     - The target table may not have the expected data connector enabled
     - The filter conditions may be too restrictive — try relaxing one filter
   - Call `loganalytics_list_tables` to verify the target table exists

5. **Handle table-not-found errors**: If the query fails because a table does not exist:
   - Report the missing table name
   - Call `loganalytics_list_tables` to show available tables
   - Suggest alternative tables that may contain similar data:
     - SecurityEvent ↔ WindowsEvent (legacy vs. modern Windows events)
     - DeviceProcessEvents → SecurityEvent EventID 4688 (if MDE not available)
     - OfficeActivity ↔ CloudAppEvents (legacy vs. modern M365 events)

6. **Handle query errors**: If the query fails due to syntax or other errors:
   - Report the error message from Log Analytics
   - Identify the likely cause (typo in column name, invalid operator, etc.)
   - Suggest a corrected query if possible

7. **Format results**: For successful queries:
   - Display total row count
   - Present results as a Markdown table (limit to first 50 rows for readability)
   - Highlight notable values (known-malicious IPs, admin accounts, unusual times)
   - Provide a brief summary of what the results show

## Expected MCP Tools

- `loganalytics_execute_query` — Execute the KQL query and return results
- `loganalytics_list_tables` — Verify table existence (used in error handling)

## Input

- **query**: A KQL query string to execute
- **Optional timespan**: ISO 8601 duration override (default: PT24H or as specified in query)

## Output

Structured query results:

```
## Query Results

**Query**: [abbreviated query or description]
**Rows returned**: [count]
**Time range**: [effective time range]

| TimeGenerated | [Column 2] | [Column 3] | ... |
|---------------|------------|------------|-----|
| [timestamp]   | [value]    | [value]    | ... |

[... first 50 rows ...]

### Summary

[Brief analysis of what the results show]
[Notable findings highlighted]
```

For zero results:

```
## Query Results

**Query**: [abbreviated query]
**Rows returned**: 0

No results found for this query.

### Suggestions

- Expand time range: Change `ago(7d)` to `ago(30d)`
- Verify data connector: Check that [table] is receiving data
- Relax filters: Try removing [most restrictive filter]
```

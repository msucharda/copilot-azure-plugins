---
name: author-detection
description: 'Generate KQL analytics rule templates from detection requirements or hunting findings.'
---

# Author Detection Rule

## Purpose

Generate KQL analytics rule templates for Microsoft Sentinel from natural language detection requirements or confirmed hunting findings. The output is a complete rule definition including KQL query logic, severity classification, MITRE ATT&CK mapping, entity mappings, and scheduling parameters — ready for import into Sentinel.

## When to Use

- A detection engineer wants to create a new Sentinel analytics rule
- A threat hunter has confirmed findings that should become automated detections
- A SOC team needs to close a MITRE ATT&CK coverage gap
- An existing rule needs tuning and the analyst wants a revised version

## Instructions

1. **Parse detection requirement**: Extract the key elements:
   - **What to detect**: The specific behavior or pattern (e.g., "PowerShell downloading files from external URLs")
   - **Why it matters**: The threat it represents (e.g., "Potential malware delivery via living-off-the-land technique")
   - **Target log sources**: Which tables contain the relevant evidence
   - **Expected false positive sources**: Known benign activity that may match

2. **Identify target tables**: Based on the detection requirement, determine the primary and secondary tables. Common detection targets:
   - **Process execution**: SecurityEvent (EventID 4688), DeviceProcessEvents
   - **Network connections**: CommonSecurityLog, DeviceNetworkEvents
   - **Sign-in anomalies**: SigninLogs
   - **File operations**: DeviceFileEvents
   - **Scheduled tasks/persistence**: SecurityEvent (EventID 4698/4702)
   - **DNS anomalies**: DnsEvents

3. **Generate KQL detection query**: Build the rule query with:
   - Table source with TimeGenerated filter matching the rule frequency
   - Behavioral filters that capture the target pattern
   - False positive exclusion clauses (known-good processes, internal domains, service accounts)
   - Entity extraction using `extend` and `project` for IP, Account, Host, File entity mappings
   - Result deduplication if appropriate

4. **Assign severity**: Based on the MITRE ATT&CK tactic:
   - **High**: Impact (TA0040), Exfiltration (TA0010), Lateral Movement (TA0008)
   - **Medium**: Execution (TA0002), Persistence (TA0003), Credential Access (TA0006)
   - **Low**: Discovery (TA0007), Collection (TA0009)
   - **Informational**: Reconnaissance (TA0043)

5. **Map to MITRE ATT&CK**: Assign the appropriate tactic and technique IDs using official MITRE identifiers (TAxxxx, Txxxx.xxx).

6. **Define entity mappings**: Specify how Sentinel should extract entities from query results:
   - **Account entity**: Map to UserPrincipalName, AccountName, or Account fields
   - **IP entity**: Map to IPAddress, SourceIP, or DestinationIP fields
   - **Host entity**: Map to Computer, DeviceName, or HostName fields
   - **File entity**: Map to FileName, FilePath, or FileHash fields

7. **Validate against historical data**: Execute the detection query against the last 7 days of data using `loganalytics_execute_query`. Report:
   - Match count (how many times the rule would have fired)
   - Estimated false positive rate (based on match review)
   - Suggested tuning if match count is too high or too low

8. **Review existing coverage**: Call `sentinel_list_analytics_rules` to check if a similar detection already exists. If so, note the existing rule and suggest whether to supplement or replace it.

9. **Output complete rule template**: Produce the full analytics rule definition.

## Expected MCP Tools

- `loganalytics_execute_query` — Validate the detection query against historical data
- `sentinel_list_analytics_rules` — Check for existing similar detections

## Input

- **Detection requirement**: Natural language description of what to detect
- **Optional context**: Hunting findings, incident details, or MITRE technique to cover

## Output

A complete Sentinel analytics rule template:

```
## Detection Rule: [Rule Name]

**Description**: [What this rule detects and why it matters]
**Severity**: [High/Medium/Low/Informational]
**MITRE ATT&CK**: [Tactic ID] ([Tactic Name]) — [Technique ID] ([Technique Name])
**Status**: Ready for import

### KQL Query

​```kql
// Detection: [Rule name]
// Purpose: [What this detects]
// MITRE: [Tactic] - [Technique]
[TableName]
| where TimeGenerated > ago(1h)
| where [behavioral filters]
| where [false positive exclusions]
| extend AccountEntity = [account field]
| extend IPEntity = [IP field]
| extend HostEntity = [host field]
| project TimeGenerated, AccountEntity, IPEntity, HostEntity, [relevant fields]
​```

### Rule Configuration

| Parameter | Value |
|-----------|-------|
| Frequency | Every 1 hour |
| Lookup period | Last 1 hour |
| Alert threshold | Greater than 0 |
| Event grouping | Group all events into a single alert |
| Severity | [severity] |

### Entity Mappings

| Entity Type | Sentinel Field | Query Field |
|-------------|---------------|-------------|
| Account | FullName | AccountEntity |
| IP | Address | IPEntity |
| Host | FullName | HostEntity |

### Validation Results

- **Historical matches (7 days)**: [count] matches
- **Estimated false positive rate**: [Low/Medium/High]
- **Existing similar rules**: [None / Rule name]
- **Tuning suggestions**: [suggestions if any]
```

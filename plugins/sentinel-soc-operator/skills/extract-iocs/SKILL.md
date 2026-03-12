---
name: extract-iocs
description: 'Identify indicators of compromise from incident data or free text.'
---

# Extract IoCs

## Purpose

Identify and extract indicators of compromise (IoCs) from Sentinel incident data, alert details, or free text input. IoCs include IP addresses, domain names, file hashes (MD5, SHA1, SHA256), URLs, and email addresses. Extracted IoCs are deduplicated and categorized for use in enrichment and investigation workflows.

## When to Use

- After retrieving incident or alert details to identify actionable indicators
- When an analyst pastes raw log data or threat report text for IoC extraction
- Before entity enrichment to build the entity list for TI lookups
- During investigation when examining query results for new indicators

## Instructions

1. **Receive input data**: Accept either structured incident/alert data from a previous skill or free-form text from the operator.

2. **Extract IP addresses**: Scan the input for IPv4 addresses matching the pattern `\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b`. Validate each match is a legitimate IP (each octet 0-255). Exclude common private ranges (10.x.x.x, 172.16-31.x.x, 192.168.x.x) and loopback (127.x.x.x) unless the operator requests them. Exclude common false positives like version numbers (e.g., "version 2.0.1.0").

3. **Extract domain names**: Scan for domain names matching common TLD patterns. Exclude known benign domains (microsoft.com, windows.net, azure.com, office.com, etc.) unless they appear in a suspicious context. Extract both bare domains and FQDNs.

4. **Extract file hashes**: Scan for hexadecimal strings matching:
   - **MD5**: 32 hex characters (`[a-fA-F0-9]{32}`)
   - **SHA1**: 40 hex characters (`[a-fA-F0-9]{40}`)
   - **SHA256**: 64 hex characters (`[a-fA-F0-9]{64}`)
   Automatically classify by length. Exclude strings that are clearly not hashes (e.g., GUIDs with dashes).

5. **Extract URLs**: Scan for URLs matching `https?://` followed by non-whitespace characters. Extract the full URL including path and query parameters. Also extract the domain component separately.

6. **Extract email addresses**: Scan for email addresses matching standard patterns. Categorize as potential phishing sender or recipient addresses based on context.

7. **Deduplicate and categorize**: Remove duplicate values. Group IoCs by type. For each IoC, note the source context (which alert or text section it was found in).

8. **Output structured IoC list**: Present the extracted IoCs in a structured format suitable for input to the enrich-entities skill.

## Expected MCP Tools

None -- this skill performs text processing and pattern matching only. It does not require MCP server access.

## Input

One of:
- **Incident data**: Structured output from summarize-incident skill
- **Alert details**: Raw alert descriptions and extended properties
- **Free text**: Pasted log entries, threat reports, or analyst notes

## Output

A structured Markdown IoC report:

```
## Extracted Indicators of Compromise

**Source**: [Incident ID or "Free text input"]
**Total IoCs**: [count] across [type count] categories

### IP Addresses ([count])

| IP Address | Context | Private |
|------------|---------|---------|
| 203.0.113.5 | Alert: Suspicious outbound connection | No |

### Domains ([count])

| Domain | Context |
|--------|---------|
| malware-c2.example.com | Alert: DNS query to known C2 |

### File Hashes ([count])

| Hash | Type | Context |
|------|------|---------|
| a1b2c3... | SHA256 | Alert: Suspicious file execution |

### URLs ([count])

| URL | Domain | Context |
|-----|--------|---------|
| https://evil.com/payload | evil.com | Alert: Download from external URL |

### Email Addresses ([count])

| Email | Role | Context |
|-------|------|---------|
| attacker@phish.com | Sender | Alert: Phishing email detected |
```

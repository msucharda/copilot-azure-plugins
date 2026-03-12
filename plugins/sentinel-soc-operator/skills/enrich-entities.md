# Enrich Entities

## Purpose

Look up IP addresses, domain names, user accounts, and file hashes against threat intelligence sources to determine if any entities associated with a Sentinel incident are known-malicious, suspicious, or benign. This enrichment adds critical context for triage decisions.

## When to Use

- After summarizing an incident, entities need threat intelligence context
- During investigation when new entities are discovered
- When an analyst needs to validate whether an indicator is known-malicious
- Before making a triage decision (escalate vs. close as false positive)

## Instructions

1. **Receive entity list**: Accept a list of entities from the incident summary or operator input. Each entity must have a type (IP, domain, user, file hash, URL) and value.

2. **Enrich IP addresses**: For each IP address, call `ti_lookup_ip` with the IP value. Record: reputation score, threat category, geolocation (country, city, ISP), associated threat actors, first/last seen dates, and confidence level.

3. **Enrich domains**: For each domain, call `ti_lookup_domain` with the domain value. Record: reputation score, threat category, registrar, registration date, associated IPs, and any known malware campaigns.

4. **Enrich file hashes**: For each file hash, call `ti_lookup_file_hash` with the hash value and hash type (MD5, SHA1, or SHA256). Record: detection ratio, malware family, first/last seen dates, file type, and associated threat actors.

5. **Enrich URLs**: For each URL, call `ti_lookup_url` with the URL value. Record: reputation score, threat category, hosting IP, redirect chain analysis, and scan results.

6. **Cross-reference Sentinel TI**: For each entity, also call `ti_search_indicators` to check if the value exists in the workspace's ThreatIntelligenceIndicator table. Record match status, confidence, threat type, and source feed.

7. **Aggregate results**: Compile enrichment results into a structured report:
   - Flag entities with **High confidence malicious** indicators (confidence > 80%)
   - Flag entities with **Suspicious** indicators (confidence 40-80%)
   - Note entities with **No matches** (explicitly state the check was performed)
   - Provide an overall risk assessment based on enrichment findings

## Expected MCP Tools

- `ti_lookup_ip` -- Look up IP address reputation and threat data
- `ti_lookup_domain` -- Look up domain reputation and threat data
- `ti_lookup_file_hash` -- Look up file hash against malware databases
- `ti_lookup_url` -- Look up URL reputation and scan results
- `ti_search_indicators` -- Search Sentinel ThreatIntelligenceIndicator table

## Input

A list of entities to enrich, each with:
- **type**: ip, domain, file_hash, url, or user
- **value**: The entity value (e.g., "192.168.1.1", "evil.com", "abc123def...")
- **hashType** (for file_hash only): md5, sha1, or sha256

## Output

A structured Markdown enrichment report:

```
## Entity Enrichment Report

### Malicious ([count])

| Entity | Type | Reputation | Threat | Confidence | Source |
|--------|------|------------|--------|------------|--------|
| [val]  | IP   | Malicious  | C2     | 95%        | [src]  |

### Suspicious ([count])

| Entity | Type | Reputation | Threat | Confidence | Source |
|--------|------|------------|--------|------------|--------|
| [val]  | Domain | Suspicious | Phishing | 65%    | [src]  |

### No Matches ([count])

| Entity | Type | Checks Performed |
|--------|------|-----------------|
| [val]  | IP   | TI lookup, Sentinel TI -- no matches found |

### Risk Assessment

[Overall assessment based on enrichment findings]
[Recommended action: Escalate / Investigate further / Likely benign]
```

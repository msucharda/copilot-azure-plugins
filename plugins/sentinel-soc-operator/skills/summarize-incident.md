# Summarize Incident

## Purpose

Retrieve a Microsoft Sentinel incident and produce a structured summary including severity, alert details, affected entities, and timeline. This is the first step in any triage workflow — giving the analyst a complete picture of the incident before deeper analysis.

## When to Use

- A new Sentinel incident notification arrives and needs initial assessment
- An analyst picks an incident from the queue for triage
- A team lead wants a quick overview of a specific incident
- Before enrichment or investigation to establish baseline context

## Instructions

1. **List recent incidents**: Call `sentinel_list_incidents` with a filter for open/active incidents, sorted by severity (High → Medium → Low). Request the top 20 most recent incidents.

2. **Present incident queue**: Display the incident list as a prioritized table with columns: Incident ID, Title, Severity, Status, Alert Count, Created Time. Highlight any High-severity incidents.

3. **Get incident details**: When the operator selects an incident, call `sentinel_get_incident` with the chosen incident ID. Extract: title, severity, status, classification, owner, creation time, last update time, description, and related alert IDs.

4. **Get associated alerts**: Call `sentinel_get_incident_alerts` with the incident ID. For each alert, extract: alert name, severity, provider, tactics, generation time, and description. Group alerts by tactic if MITRE mappings are present.

5. **Get associated entities**: Call `sentinel_get_incident_entities` with the incident ID. For each entity, extract the entity type and key attributes:
   - **IP addresses**: address, geolocation, ASN
   - **Accounts/Users**: username, domain, SID, UPN
   - **Hosts**: hostname, OS, IP address
   - **Files**: file name, hash values (MD5, SHA1, SHA256), path
   - **URLs/Domains**: URL or domain name

6. **Produce structured summary**: Compile all data into a formatted summary:
   - **Header**: Incident ID, title, severity, status
   - **Timeline**: Creation time, last activity, alert timeline
   - **Alerts section**: Grouped list with severity and tactic
   - **Entities section**: Categorized by type with key attributes
   - **Initial assessment**: Number of alerts, entity diversity, severity rationale

## Expected MCP Tools

- `sentinel_list_incidents` — List recent incidents from the Sentinel workspace
- `sentinel_get_incident` — Get full details of a specific incident
- `sentinel_get_incident_alerts` — Get all alerts tied to the incident
- `sentinel_get_incident_entities` — Get all entities (IPs, users, hosts, files) tied to the incident

## Input

- **Optional**: Specific incident ID to summarize directly (skips step 1-2)
- **Optional**: Filter criteria (severity level, time range, status)
- **Default**: If no input, list the 20 most recent open incidents

## Output

A structured Markdown summary containing:

```
## Incident Summary: [Incident ID] — [Title]

**Severity**: [High/Medium/Low] | **Status**: [Active/New/Closed]
**Created**: [timestamp] | **Last Updated**: [timestamp]
**Owner**: [assigned analyst or Unassigned]

### Alerts ([count])

| # | Alert Name | Severity | Tactic | Time |
|---|------------|----------|--------|------|
| 1 | [name]     | [sev]    | [tac]  | [ts] |

### Entities ([count])

**IP Addresses**: [list with geolocation]
**Accounts**: [list with UPN/domain]
**Hosts**: [list with OS]
**Files**: [list with hashes]

### Initial Assessment

[count] alerts across [count] tactics involving [count] entities.
Recommended next step: [Enrich entities / Investigate further / Close as false positive]
```

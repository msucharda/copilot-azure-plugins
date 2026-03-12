# Research: Sentinel SOC Operator Plugin

**Branch**: `001-sentinel-soc-plugin`
**Date**: 2026-03-12
**Status**: Complete

## R1: Sentinel KQL Table Inventory

**Decision**: Target 20 core Sentinel tables across two tiers.

**Rationale**: These tables represent the primary data sources a
Sentinel SOC analyst queries daily. Tier 1 tables are required for
basic triage and investigation; Tier 2 tables are needed for
advanced investigation, hunting, and detection engineering.

**Tier 1 — Daily Use (8 tables)**:

| Table | Purpose | Workflows |
|-------|---------|-----------|
| SecurityIncident | Master incident record | Triage, Reporting |
| SecurityAlert | Individual alert details | Triage, Investigation |
| SigninLogs | Azure AD/Entra sign-in events | Investigation, Hunting |
| SecurityEvent | Windows security events (4624, 4688, 4672) | Investigation, Hunting |
| CommonSecurityLog | Firewall, proxy, network device logs | Investigation, Hunting |
| ThreatIntelligenceIndicator | IoC enrichment data | Triage, Hunting |
| AuditLogs | Azure AD/Entra admin actions | Investigation |
| CloudAppEvents | Microsoft 365 activity | Investigation, Hunting |

**Tier 2 — Extended (12 tables)**:

| Table | Purpose | Workflows |
|-------|---------|-----------|
| OfficeActivity | Office 365 audit events | Investigation |
| Syslog | Linux syslog events | Investigation, Hunting |
| DeviceLogonEvents | MDE logon events | Investigation, Hunting |
| DeviceProcessEvents | MDE process execution | Hunting, Detection |
| DeviceNetworkEvents | MDE network connections | Hunting, Detection |
| DeviceFileEvents | MDE file operations | Hunting, Detection |
| DeviceImageLoadEvents | MDE DLL/image loads | Hunting |
| WindowsEvent | Modern Windows event format | Investigation |
| DnsEvents | DNS query logs | Hunting |
| W3CIISLog | IIS web server logs | Investigation |
| IdentityInfo | User/identity metadata | Triage, Investigation |
| BehaviorAnalytics | UEBA anomaly scores | Hunting |

**Alternatives considered**: Including Defender for Cloud tables
(SecurityRecommendation, SecurityBaseline) — deferred to future
version as they serve a cloud-posture persona more than SOC analyst.

## R2: MITRE ATT&CK Mapping Approach

**Decision**: Use a 3-layer extraction strategy for MITRE mapping.

**Rationale**: Sentinel does not expose MITRE tactic/technique IDs
as first-class fields in SecurityIncident or SecurityAlert. The
data must be derived from alert metadata, rule configuration, and
event characteristics.

**Layer 1 — Alert Name Pattern Matching**:
Sentinel analytics rules encode tactic context in alert names.
Pattern-match against known tactic keywords:

- `AlertName contains "Lateral Movement"` → TA0008
- `AlertName contains "Execution"` → TA0002
- `AlertName contains "Persistence"` → TA0003
- `AlertName contains "Credential"` → TA0006

**Layer 2 — Analytics Rule Metadata**:
Sentinel analytics rules store MITRE mappings in their rule
definition (Tactics and Techniques arrays). Query these via the
Sentinel MCP server to get authoritative mappings for rule-generated
alerts.

**Layer 3 — Raw Event Heuristics**:
For hunting findings not linked to existing rules, use event
characteristics:

- EventID 4688 + PowerShell → T1059.001 (Command and Scripting)
- RDP connections to new hosts → T1021.001 (Remote Desktop)
- Scheduled task creation → T1053.005 (Scheduled Task/Job)

**Alternatives considered**: Relying solely on Security Copilot for
MITRE mapping — rejected because it adds an AI dependency for what
can be deterministically derived, and not all users will have
Security Copilot licensed.

## R3: MCP Server Design

**Decision**: 4 MCP server configurations with clearly scoped
tool surfaces.

**Rationale**: Each server maps to a distinct Microsoft security
service and exposes the minimum set of tools needed by the plugin's
skills.

### Sentinel MCP Server

- **Purpose**: Incident and analytics rule management
- **Tools**: `sentinel_list_incidents`, `sentinel_get_incident`,
  `sentinel_get_incident_alerts`, `sentinel_get_incident_entities`,
  `sentinel_list_analytics_rules`, `sentinel_get_analytics_rule`
- **Auth**: Azure AD (DefaultAzureCredential)
- **Env vars**: `SENTINEL_WORKSPACE_ID`,
  `SENTINEL_RESOURCE_GROUP`, `SENTINEL_SUBSCRIPTION_ID`,
  `AZURE_TENANT_ID`

### Log Analytics MCP Server

- **Purpose**: KQL query execution
- **Tools**: `loganalytics_execute_query`,
  `loganalytics_list_tables`, `loganalytics_get_table_schema`
- **Auth**: Azure AD (DefaultAzureCredential)
- **Env vars**: `LOGANALYTICS_WORKSPACE_ID`

### Threat Intelligence MCP Server

- **Purpose**: IoC lookups and enrichment
- **Tools**: `ti_lookup_ip`, `ti_lookup_domain`,
  `ti_lookup_file_hash`, `ti_lookup_url`,
  `ti_search_indicators`
- **Auth**: Azure AD + optional API keys for external TI
- **Env vars**: `AZURE_TENANT_ID` (for Sentinel TI),
  optionally `VIRUSTOTAL_API_KEY`, `ABUSEIPDB_API_KEY`

### Security Copilot MCP Server

- **Purpose**: AI-assisted analysis and summarization
- **Tools**: `seccopilot_analyze_incident`,
  `seccopilot_generate_summary`, `seccopilot_suggest_queries`
- **Auth**: Azure AD
- **Env vars**: `SECURITY_COPILOT_TENANT_ID`,
  `SECURITY_COPILOT_RESOURCE_ID`

**Alternatives considered**: Merging Sentinel and Log Analytics into
a single MCP server — rejected because they serve different API
surfaces (ARM for Sentinel, query endpoint for Log Analytics) and
separation keeps each server focused per Principle V.

## R4: KQL Safety Guardrails

**Decision**: 3-tier hook system (block, warn+confirm, suggest).

**Rationale**: The plugin is security tooling and MUST enforce
safe KQL practices per constitution Principle VI.

### Block Always (Critical)

| Pattern | Reason |
|---------|--------|
| `.purge` | Irreversible data destruction |
| `\| delete` | Bulk row deletion |
| `.drop table` | Table deletion |
| `.drop function` | Function deletion |

### Warn + Require Confirmation (High)

| Pattern | Reason |
|---------|--------|
| `.set-or-replace` | Table data replacement |
| `externaldata(` | External data ingestion |
| `http_request(` | Outbound HTTP from query |
| `workspace(` without scoping | Cross-workspace query |

### Suggest Improvement (Medium)

| Pattern | Suggestion |
|---------|------------|
| `\| sort` without `\| top` or `\| take` | Add row limit to avoid full scans |
| `join` without `hint` | Add join hint for performance |
| Unbounded time range | Suggest explicit `\| where TimeGenerated > ago(7d)` |

## R5: Plugin Manifest Schema

**Decision**: Use the Copilot CLI plugin.json format with all
required and recommended fields.

**Rationale**: Constitution Principle VII requires a valid manifest
with name, description, version, author, and component paths.

**Required fields**: `id`, `name`, `version`, `description`,
`author`

**Component references**: `agents[]` (id, path, displayName,
description), `skills[]` (id, path, displayName, description,
tags), `mcpServers[]` (id, name, configPath, requiredEnv),
`hooks[]` (id, path)

**Optional marketplace fields**: `license`, `repository`,
`keywords`, `marketplace.category`, `marketplace.tags`,
`requirements.copilot-cli-version`

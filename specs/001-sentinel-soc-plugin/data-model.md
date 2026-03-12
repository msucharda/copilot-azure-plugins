# Data Model: Sentinel SOC Operator Plugin

**Branch**: `001-sentinel-soc-plugin`
**Date**: 2026-03-12

## Overview

This plugin is declarative (Markdown content, no runtime code), so
the "data model" describes the domain entities that skills and agents
operate on — not database tables or code models. These entities
flow through MCP servers as structured data.

## Entities

### Plugin

The top-level distributable unit.

| Attribute | Type | Description |
|-----------|------|-------------|
| id | string | Unique identifier (e.g., `sentinel-soc-operator`) |
| name | string | Display name |
| version | string | SemVer version (e.g., `1.0.0`) |
| description | string | Human-readable purpose |
| author | string | Publisher name |
| agents | Agent[] | List of agent references |
| skills | Skill[] | List of skill references |
| mcpServers | McpServer[] | List of MCP server configs |
| hooks | Hook[] | List of lifecycle hooks |

**Defined in**: `.github/plugin.json`

### Skill

An atomic capability unit.

| Attribute | Type | Description |
|-----------|------|-------------|
| id | string | Unique skill identifier |
| displayName | string | Human-readable name |
| description | string | When and why to use this skill |
| path | string | Relative path to skill `.md` file |
| tags | string[] | Categorization tags |
| mcpTools | string[] | MCP tools this skill requires |
| inputExpectations | text | What the skill needs to operate |
| outputFormat | text | What the skill produces |

**Defined in**: `skills/<name>.md` (as structured Markdown sections)

**Instances** (8 skills):

| Skill ID | Purpose | MCP Tools Required |
|----------|---------|-------------------|
| summarize-incident | Retrieve and summarize a Sentinel incident | sentinel_get_incident, sentinel_get_incident_alerts, sentinel_get_incident_entities |
| enrich-entities | Enrich IPs, domains, users, hashes via TI | ti_lookup_ip, ti_lookup_domain, ti_lookup_file_hash, ti_lookup_url |
| generate-kql | Translate natural language to KQL queries | loganalytics_list_tables, loganalytics_get_table_schema |
| execute-kql | Execute a KQL query and return results | loganalytics_execute_query |
| extract-iocs | Extract IoCs from incident data or text | (none — text processing) |
| author-detection | Generate KQL analytics rule templates | loganalytics_execute_query, sentinel_list_analytics_rules |
| map-mitre | Map findings to MITRE ATT&CK tactics/techniques | sentinel_get_incident_alerts, sentinel_get_analytics_rule |
| generate-report | Produce shift/operational reports | loganalytics_execute_query, sentinel_list_incidents |

### Agent

A workflow orchestrator persona.

| Attribute | Type | Description |
|-----------|------|-------------|
| id | string | Unique agent identifier |
| displayName | string | Persona name |
| description | string | Role and purpose |
| path | string | Relative path to `.agent.md` file |
| skills | string[] | Skill IDs this agent orchestrates |
| mcpTools | string[] | Direct MCP tools (beyond skill deps) |
| scopeIn | text | What this agent handles |
| scopeOut | text | What this agent explicitly does NOT do |
| workflowSteps | text | Ordered workflow guidance |

**Defined in**: `agents/<name>.agent.md`

**Instances** (3 agents):

| Agent ID | Persona | Skills Used |
|----------|---------|-------------|
| triage-analyst | Tier 1 SOC Triage Analyst | summarize-incident, enrich-entities, extract-iocs, map-mitre |
| investigation-analyst | Tier 2 Investigation Analyst | generate-kql, execute-kql, map-mitre, enrich-entities |
| threat-hunter | Proactive Threat Hunter | generate-kql, execute-kql, map-mitre, author-detection |

### MCP Server

An external data access endpoint.

| Attribute | Type | Description |
|-----------|------|-------------|
| id | string | Server identifier |
| name | string | Display name |
| type | string | Server type/protocol |
| purpose | string | What data this server provides |
| requiredEnvVars | string[] | Environment variables for auth |
| authMethod | string | Authentication method |
| tools | Tool[] | List of exposed tools |

**Defined in**: `.mcp.json`

**Instances** (4 servers):

| Server ID | Purpose | Required Env Vars |
|-----------|---------|-------------------|
| sentinel | Incident and rule management | SENTINEL_WORKSPACE_ID, SENTINEL_RESOURCE_GROUP, SENTINEL_SUBSCRIPTION_ID, AZURE_TENANT_ID |
| loganalytics | KQL query execution | LOGANALYTICS_WORKSPACE_ID |
| threat-intel | IoC lookups and enrichment | AZURE_TENANT_ID |
| security-copilot | AI-assisted analysis | SECURITY_COPILOT_TENANT_ID, SECURITY_COPILOT_RESOURCE_ID |

### Hook

A lifecycle event handler for guardrails.

| Attribute | Type | Description |
|-----------|------|-------------|
| id | string | Hook identifier |
| trigger | string | When hook fires (e.g., before-skill-execution) |
| action | enum | block, warn, suggest |
| pattern | regex | Pattern to match in KQL content |
| message | string | User-facing message |
| confirm | boolean | Whether to require operator confirmation |

**Defined in**: `hooks.json`

## Entity Relationships

```text
Plugin
├── has many → Agent (3)
│   └── uses many → Skill
├── has many → Skill (8)
│   └── requires many → MCP Server Tool
├── has many → MCP Server (4)
│   └── exposes many → Tool
└── has many → Hook (guardrails)
    └── triggers on → Skill execution
```

## State Transitions

### Incident (external — Sentinel-managed)

```text
New → Active → [Closed: True Positive | False Positive | Benign Positive]
              → Escalated (custom status via triage agent output)
```

The plugin reads incident state but does NOT write state changes
(read-only by default per constitution Principle VI). State
transitions are documented here because agents reference them in
workflow guidance.

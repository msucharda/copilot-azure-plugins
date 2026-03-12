# Quickstart: Sentinel SOC Operator Plugin

**Branch**: `001-sentinel-soc-plugin`
**Date**: 2026-03-12

## Prerequisites

1. **Copilot CLI** installed and authenticated
2. **Microsoft Sentinel workspace** with at least one data connector
   enabled (e.g., Azure AD Sign-in Logs, Windows Security Events)
3. **Azure credentials** with read access to the Sentinel workspace
   and Log Analytics

## Install

```bash
copilot plugin install sentinel-soc-operator
```

## Configure MCP Servers

Set the required environment variables for your Sentinel workspace:

```bash
# Required — Sentinel and Log Analytics
export SENTINEL_WORKSPACE_ID="<your-workspace-guid>"
export SENTINEL_RESOURCE_GROUP="<your-resource-group>"
export SENTINEL_SUBSCRIPTION_ID="<your-subscription-guid>"
export AZURE_TENANT_ID="<your-tenant-guid>"
export LOGANALYTICS_WORKSPACE_ID="<your-workspace-guid>"

# Optional — Security Copilot (if licensed)
export SECURITY_COPILOT_TENANT_ID="<your-tenant-guid>"
export SECURITY_COPILOT_RESOURCE_ID="<your-resource-id>"

# Optional — External Threat Intelligence
export VIRUSTOTAL_API_KEY="<your-api-key>"
export ABUSEIPDB_API_KEY="<your-api-key>"
```

## Verify Installation

```bash
# List available agents
copilot agent list

# Expected output:
#   triage-analyst        Tier 1 SOC Triage Analyst
#   investigation-analyst Tier 2 Investigation Analyst
#   threat-hunter         Proactive Threat Hunter
```

## Core Workflows

### 1. Triage an Incident (P1 — most common)

```bash
# Start the triage agent
copilot agent run triage-analyst

# The agent will:
# 1. Retrieve recent Sentinel incidents
# 2. Let you pick one to triage
# 3. Summarize alerts and entities
# 4. Enrich entities against threat intelligence
# 5. Extract IoCs
# 6. Map to MITRE ATT&CK tactics
# 7. Produce a triage recommendation
```

**Expected time**: Under 5 minutes (vs. 15–30 minutes manually)

### 2. Investigate an Escalated Incident (P2)

```bash
# Start the investigation agent
copilot agent run investigation-analyst

# The agent will:
# 1. Take an incident ID or entity set as input
# 2. Generate targeted KQL queries for entity activity
# 3. Execute queries across relevant log tables
# 4. Build a chronological attack timeline
# 5. Map events to MITRE ATT&CK techniques
# 6. Produce an investigation summary with remediation advice
```

### 3. Hunt for Threats (P3)

```bash
# Start the hunting agent with a hypothesis
copilot agent run threat-hunter

# Example hypothesis:
#   "Look for lateral movement via RDP from compromised hosts
#    in the last 7 days"
#
# The agent will:
# 1. Translate hypothesis to KQL hunting queries
# 2. Execute against relevant tables
# 3. Analyze results for notable findings
# 4. Map to MITRE ATT&CK techniques
# 5. Optionally generate a detection rule from findings
```

### 4. Author a Detection Rule (P4)

```bash
# Use the detection authoring skill directly
copilot skill run author-detection

# Describe what you want to detect:
#   "Detect PowerShell downloading files from external URLs"
#
# The skill will produce a KQL analytics rule template with:
# - Query logic
# - Severity classification
# - MITRE ATT&CK mapping
# - Entity mappings
```

### 5. Generate a Shift Report (P5)

```bash
# Use the reporting skill
copilot skill run generate-report

# Specify time range:
#   "Last 8 hours"
#
# The skill will produce a summary with:
# - Incident counts by severity and status
# - Key findings and escalations
# - MITRE tactic distribution
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "MCP server connection failed" | Verify environment variables are set correctly; check Azure credential expiry |
| "Table not found" in KQL results | The data connector for that table may not be enabled in your workspace |
| "No incidents found" | Check the time range; verify incidents exist in Sentinel |
| "No TI matches" | This is normal — it means the check was performed but no indicators matched |

## What's Next

- Run `/speckit.tasks` to generate the implementation task list
- See [spec.md](spec.md) for full requirements and acceptance criteria
- See [data-model.md](data-model.md) for entity definitions
- See [contracts/](contracts/) for file format specifications

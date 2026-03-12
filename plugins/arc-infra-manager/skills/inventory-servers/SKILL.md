---
name: inventory-servers
description: 'List and filter Azure Arc-enabled servers by OS, status, location, resource group, or tags.'
---

# Inventory Servers

## Purpose

List Azure Arc-enabled servers in the subscription and filter them by key attributes — operating system, connectivity status, location, resource group, or tags. This is the foundational skill for fleet visibility, providing the operator with a structured view of their hybrid server estate.

## When to Use

- Starting a new management session and need to see what servers exist
- Filtering to a specific subset of servers (e.g., all Linux servers in westeurope)
- Identifying servers by connectivity status (e.g., all disconnected servers)
- Scoping an operation to servers with specific tags (e.g., environment:production)
- Building an inventory report for fleet management or compliance auditing

## Instructions

1. **Parse filter criteria**: Determine what filters the operator wants applied. Supported filters:
   - **OS type**: Windows or Linux
   - **Status**: Connected, Disconnected, Expired, Error
   - **Resource group**: Specific resource group name
   - **Location**: Azure region (e.g., eastus, westeurope)
   - **Tags**: Key-value pairs (e.g., environment:production, team:platform)
   - **Default**: If no filters specified, list all servers (suggest adding a filter via hooks)

2. **Query server list**: Call `arc_list_servers` with the applicable filters. Request up to 100 servers per call.

3. **Enrich with details** (if requested): For small result sets (< 20 servers) or when the operator requests details, call `arc_get_server` for each server to retrieve:
   - Agent version and status
   - OS name and version
   - Last heartbeat timestamp
   - Provisioning state
   - Network profile (private IP, FQDN)
   - Tags

4. **Format inventory table**: Present results as a structured table with columns:
   - Server Name | OS | Status | Location | Resource Group | Agent Version | Last Seen

5. **Summarize**: Include a summary line with total count and breakdown by OS and status.

## Expected MCP Tools

- `arc_list_servers` — List servers with optional filters for resource group, OS type, and status
- `arc_get_server` — Get full details of a specific server (used for enrichment)

## Input

- **Optional**: OS type filter (Windows or Linux)
- **Optional**: Status filter (Connected, Disconnected, Expired, Error)
- **Optional**: Resource group name
- **Optional**: Azure region
- **Optional**: Tag key-value pairs
- **Default**: List all servers in the subscription

## Output

A structured Markdown inventory:

```
## Arc Server Inventory

**Scope**: [subscription / resource group] | **Filters**: [applied filters]
**Total servers**: [count] | **Windows**: [count] | **Linux**: [count]
**Connected**: [count] | **Disconnected**: [count]

| Server Name | OS | Status | Location | Resource Group | Agent Version | Last Seen |
|-------------|-----|--------|----------|----------------|---------------|-----------|
| web-prod-01 | Windows Server 2022 | Connected | eastus | rg-production | 1.45.0 | 2 min ago |
| db-linux-03 | Ubuntu 22.04 | Disconnected | westeurope | rg-databases | 1.44.0 | 3 hours ago |
```

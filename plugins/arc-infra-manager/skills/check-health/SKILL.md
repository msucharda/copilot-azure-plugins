---
name: check-health
description: 'Assess Arc-enabled server health including agent connectivity, heartbeat status, extension health, and provisioning state.'
---

# Check Health

## Purpose

Evaluate the health of Azure Arc-enabled servers by checking agent connectivity, heartbeat recency, extension installation status, and provisioning state. Produces a health assessment that highlights servers needing attention — disconnected agents, stale heartbeats, failed extensions, and error states.

## When to Use

- Morning fleet check to identify servers that went offline overnight
- Before running operations to verify targets are reachable
- After maintenance to confirm servers reconnected successfully
- Investigating a specific server that appears unhealthy
- Producing a health summary for fleet status reporting

## Instructions

1. **Determine scope**: Accept either a list of specific server names or use `arc_list_servers` to get the full fleet or a filtered subset.

2. **Check agent status**: For each server, call `arc_get_server` and evaluate:
   - **Status**: Connected, Disconnected, Expired, or Error
   - **Last heartbeat**: How recently the agent checked in. Flag if > 15 minutes (stale), > 1 hour (concerning), > 24 hours (critical)
   - **Agent version**: Compare against the latest known version. Flag outdated agents.
   - **Provisioning state**: Succeeded, Failed, Creating, Updating

3. **Check extension health**: For each server (or flagged servers), call `arc_list_extensions` and evaluate:
   - **Extension provisioning state**: Succeeded, Failed, Creating, Deleting
   - **Extension status message**: Any error messages
   - Flag any extensions in Failed state with the error detail

4. **Classify server health**:
   - **Healthy** 🟢: Connected, heartbeat < 15 min, all extensions succeeded
   - **Warning** 🟡: Connected but heartbeat > 15 min, or agent outdated, or extension in non-terminal state
   - **Critical** 🔴: Disconnected, Expired, Error status, or any extension Failed

5. **Produce health report**: Present results grouped by health status:
   - Critical servers first (need immediate attention)
   - Warning servers second (need investigation)
   - Healthy servers last (or just a count)

## Expected MCP Tools

- `arc_get_server` — Get server details including agent status, heartbeat, and provisioning state
- `arc_list_extensions` — List extensions with their provisioning state and status messages
- `arc_list_servers` — List servers when checking fleet-wide health

## Input

- **Optional**: Specific server name(s) to check
- **Optional**: Resource group filter
- **Optional**: Check depth: "quick" (agent status only) or "full" (agent + extensions)
- **Default**: Full health check on all servers in the subscription

## Output

A structured Markdown health report:

```
## Fleet Health Report

**Checked**: [count] servers | **Healthy**: [count] 🟢 | **Warning**: [count] 🟡 | **Critical**: [count] 🔴

### Critical 🔴 ([count])

| Server | OS | Status | Last Heartbeat | Issue |
|--------|----|--------|----------------|-------|
| db-prod-02 | Linux | Disconnected | 6 hours ago | Agent not responding |
| app-web-05 | Windows | Connected | 3 min ago | Extension MDE.Windows Failed: Access denied |

### Warning 🟡 ([count])

| Server | OS | Status | Last Heartbeat | Issue |
|--------|----|--------|----------------|-------|
| batch-worker-01 | Linux | Connected | 45 min ago | Stale heartbeat |
| legacy-srv-12 | Windows | Connected | 2 min ago | Agent version 1.40.0 (outdated) |

### Healthy 🟢 ([count])

[count] servers healthy — all agents connected with recent heartbeats and no extension failures.
```

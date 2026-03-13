# COMPREHENSIVE INVENTORY: copilot-azure-plugins

## DIRECTORY STRUCTURE

```
/home/msucharda/git/dev/plugins/copilot-azure-plugins/plugins
├── arc-infra-manager
│   ├── .mcp.json
│   ├── .github/plugin/plugin.json
│   ├── hooks.json
│   ├── agents/
│   │   ├── compliance-auditor.md
│   │   ├── fleet-manager.md
│   │   └── ops-engineer.md
│   └── skills/
│       ├── check-compliance/SKILL.md
│       ├── check-health/SKILL.md
│       ├── generate-report/SKILL.md
│       ├── generate-script/SKILL.md
│       ├── inventory-servers/SKILL.md
│       ├── manage-extensions/SKILL.md
│       ├── manage-updates/SKILL.md
│       └── run-command/SKILL.md
└── (no other plugins)
```

---

# PLUGIN 1: arc-infra-manager

## 1.1 Plugin Metadata (.github/plugin/plugin.json)

```json
{
  "name": "arc-infra-manager",
  "description": "Copilot CLI plugin for Azure Arc infrastructure operators covering fleet inventory, health monitoring, remote operations, patch management, compliance auditing, and reporting for hybrid Windows and Linux servers.",
  "version": "1.0.0",
  "author": {
    "name": "msucharda",
    "url": "https://github.com/msucharda"
  },
  "repository": "https://github.com/msucharda/copilot-azure-plugins",
  "license": "MIT",
  "keywords": ["azure-arc", "hybrid-cloud", "infrastructure", "server-management", "compliance", "patching", "windows", "linux"],
  "agents": ["./agents"],
  "skills": [
    "./skills/inventory-servers",
    "./skills/check-health",
    "./skills/manage-extensions",
    "./skills/run-command",
    "./skills/check-compliance",
    "./skills/manage-updates",
    "./skills/generate-script",
    "./skills/generate-report"
  ]
}
```

## 1.2 MCP Servers & Tools (.mcp.json)

### Server 1: arc-servers
- **ID**: `arc-servers`
- **Type**: `azure-arc-servers`
- **Purpose**: Arc-enabled server inventory, details, and extension management
- **Auth**: DefaultAzureCredential
- **Tools**:
  1. `arc_list_servers` - List Arc-enabled servers with optional filters
  2. `arc_get_server` - Get full details of a specific Arc-enabled server
  3. `arc_list_extensions` - List VM extensions on an Arc server
  4. `arc_install_extension` - Install a VM extension
  5. `arc_remove_extension` - Remove a VM extension

### Server 2: arc-operations
- **ID**: `arc-operations`
- **Type**: `azure-arc-operations`
- **Purpose**: Remote command execution and Azure Update Manager operations for Arc-enabled servers
- **Auth**: DefaultAzureCredential
- **Tools**:
  1. `arc_run_command` - Execute PowerShell/Shell script on Arc server
  2. `arc_get_command_result` - Get result of Run Command execution
  3. `arc_assess_updates` - Trigger on-demand update assessment
  4. `arc_install_updates` - Install updates with classification/reboot options
  5. `arc_get_update_history` - Get update installation history

### Server 3: arc-governance
- **ID**: `arc-governance`
- **Type**: `azure-arc-governance`
- **Purpose**: Azure Policy compliance and machine configuration (guest config) for Arc-enabled servers
- **Auth**: DefaultAzureCredential
- **Tools**:
  1. `arc_get_policy_compliance` - Get Azure Policy compliance state
  2. `arc_list_guest_config_assignments` - List machine configuration assignments
  3. `arc_get_guest_config_report` - Get detailed machine configuration compliance report

## 1.3 Hooks (hooks.json)

Total Hooks: 9

| Hook ID | Trigger | Action | Pattern | Description |
|---------|---------|--------|---------|-------------|
| arc-block-bulk-remove-extension | before-skill-execution | block | arc_remove_extension.*\*\|remove.*all\s+extensions | Blocks bulk extension removal |
| arc-block-delete-server | before-skill-execution | block | delete.*arc.*server\|az\s+connectedmachine\s+delete | Blocks Arc server deletion |
| arc-warn-run-command | before-skill-execution | warn | arc_run_command | Warns before running remote scripts (confirms=true) |
| arc-warn-install-updates | before-skill-execution | warn | arc_install_updates | Warns before installing updates (confirms=true) |
| arc-warn-cross-subscription | before-skill-execution | warn | subscription.*\,.*subscription\|multiple.*subscriptions | Warns for cross-subscription operations |
| arc-warn-production-tag | before-skill-execution | warn | environment[=:\s]*production\|env[=:\s]*prod | Warns for production server operations |
| arc-suggest-scope-filter | before-skill-execution | suggest | arc_list_servers(?!.*resourceGroup)(?!.*osType)(?!.*status)(?!.*tag) | Suggests adding filters to server queries |
| arc-suggest-maintenance-window | before-skill-execution | suggest | arc_install_updates\|arc_run_command.*reboot\|arc_run_command.*restart | Suggests verifying maintenance windows |
| arc-suggest-test-first | before-skill-execution | suggest | (arc_install_extension\|arc_install_updates\|arc_run_command).*\ball\b | Suggests testing on single server first |

## 1.4 Agents

### Agent 1: compliance-auditor
- **Name**: compliance-auditor
- **Description**: Audits Azure Arc server fleet against Azure Policy, machine configuration baselines, and security standards, producing compliance reports with remediation guidance.
- **Frontmatter Tools**: AzureMCP/*, MicrosoftLearn/*, shell, read, edit
- **Skills Referenced**:
  - `check-compliance` - Audit Azure Policy compliance and machine configuration results
  - `inventory-servers` - List servers to determine audit scope
  - `generate-report` - Produce compliance posture reports

### Agent 2: fleet-manager
- **Name**: fleet-manager
- **Description**: Manages Azure Arc-enabled server inventory, monitors agent health, handles extension lifecycle, and produces fleet status reports.
- **Frontmatter Tools**: AzureMCP/*, MicrosoftLearn/*, shell, read, edit
- **Skills Referenced**:
  - `inventory-servers` - List and filter Arc-enabled servers
  - `check-health` - Assess agent connectivity and extension health
  - `manage-extensions` - Install, update, list, or remove VM extensions
  - `generate-report` - Produce fleet status reports

### Agent 3: ops-engineer
- **Name**: ops-engineer
- **Description**: Performs hands-on server troubleshooting with remote commands, manages patches via Azure Update Manager, and automates operational tasks across Windows and Linux.
- **Frontmatter Tools**: AzureMCP/*, MicrosoftLearn/*, shell, read, edit
- **Skills Referenced**:
  - `run-command` - Execute PowerShell or Shell scripts remotely
  - `manage-updates` - Assess pending updates, install patches
  - `generate-script` - Generate OS-aware scripts
  - `check-health` - Verify server state

## 1.5 Skills

| Skill ID | Skill Name | Purpose |
|----------|-----------|---------|
| check-compliance | Check Compliance | Audit Azure Policy compliance and machine configuration results |
| check-health | Check Health | Assess Arc-enabled server health (agent connectivity, extension status) |
| generate-report | Generate Report | Produce fleet status, health, compliance, and patch reports |
| generate-script | Generate Script | Generate OS-aware PowerShell or Bash scripts for operational tasks |
| inventory-servers | Inventory Servers | List and filter Arc-enabled servers by OS, status, location, tags |
| manage-extensions | Manage Extensions | Install, update, list, or remove VM extensions |
| manage-updates | Manage Updates | Assess, install patches, and review update history |
| run-command | Run Command | Execute PowerShell/Bash scripts on Arc servers via Run Command |

---

# CROSS-PLUGIN ANALYSIS

## 3.1 Azure CLI (az) References

**Found References:**

1. **arc-infra-manager/hooks.json** (line 15):
   - Hook: `arc-block-delete-server`
   - Pattern: `delete.*arc.*server|az\s+connectedmachine\s+delete`
   - Message: "BLOCKED: Deleting Arc server resources removes them from Azure management permanently. Use 'azcmagent disconnect' on the server instead to cleanly unregister."
   - **Reference Type**: Pattern matching for blocked operations

2. **arc-infra-manager/agents/fleet-manager.md** (line 47):
   - Section: "Remediate health issues"
   - Text: "For disconnected agents, recommend on-server remediation steps (azcmagent connect, service restart)."
   - **Reference Type**: Recommendation for on-server operations

**Summary**: Two `azcmagent` references found (not `az` CLI, but Azure Connected Machine agent). No direct `az` CLI command references found in agents, skills, or config files.

## 3.2 Skill Reference Validation

### arc-infra-manager Skills Referenced by Agents

| Agent | Skill | Exists? | Status |
|-------|-------|---------|--------|
| compliance-auditor | check-compliance | ✅ | Valid |
| compliance-auditor | inventory-servers | ✅ | Valid |
| compliance-auditor | generate-report | ✅ | Valid |
| fleet-manager | inventory-servers | ✅ | Valid |
| fleet-manager | check-health | ✅ | Valid |
| fleet-manager | manage-extensions | ✅ | Valid |
| fleet-manager | generate-report | ✅ | Valid |
| ops-engineer | run-command | ✅ | Valid |
| ops-engineer | manage-updates | ✅ | Valid |
| ops-engineer | generate-script | ✅ | Valid |
| ops-engineer | check-health | ✅ | Valid |

**Result**: ✅ All skills referenced by arc-infra-manager agents have corresponding SKILL.md files.

## 3.3 Tool Reference Validation

### arc-infra-manager: Tools in MCP vs Skills

**MCP Defines**: 13 tools across 3 servers
- arc_list_servers, arc_get_server, arc_list_extensions, arc_install_extension, arc_remove_extension (arc-servers)
- arc_run_command, arc_get_command_result, arc_assess_updates, arc_install_updates, arc_get_update_history (arc-operations)
- arc_get_policy_compliance, arc_list_guest_config_assignments, arc_get_guest_config_report (arc-governance)

**Skills Reference**: All MCP tools are documented in skill SKILL.md files under "Expected MCP Tools" sections

**Status**: ✅ No undefined tool references detected

## 3.4 Agent-to-Skill Mapping Summary

**arc-infra-manager**:
- 3 Agents × 8 Skills = 11 unique skill references (some skills used by multiple agents)
- 100% of referenced skills have SKILL.md files
- Coverage: Each agent has 3-4 skills aligned with persona

---

# SUMMARY STATISTICS

| Metric | arc-infra-manager |
|--------|-------------------|
| **Agents** | 3 |
| **Skills** | 8 |
| **MCP Servers** | 3 |
| **MCP Tools** | 13 |
| **Hooks** | 9 |
| **Agent-Skill Links** | 11 |
| **Undefined Skill References** | ✅ 0 |
| **Undefined Tool References** | ✅ 0 |
| **azcmagent References** | 2 |
| **az CLI References** | ✅ 0 |

---

# VALIDATION RESULTS

✅ **All agents reference skills that exist**
✅ **All skills reference tools that are defined in .mcp.json**
✅ **No undefined tool references detected**
✅ **All SKILL.md files present in skill directories**
✅ **No direct az CLI command references** (only azcmagent recommendations for agent lifecycle)
✅ **Hook patterns validated** (block/warn/suggest actions properly configured)
✅ **All plugin.json metadata complete**


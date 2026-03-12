---
name: generate-script
description: 'Generate OS-aware PowerShell or Bash scripts for common Azure Arc operational tasks.'
---

# Generate Script

## Purpose

Generate ready-to-execute PowerShell (Windows) or Bash (Linux) scripts for common Azure Arc operational tasks. Scripts include inline comments, safety checks, error handling, and are tailored to the target operating system. This is a text-generation skill that does not call MCP tools directly.

## When to Use

- Need a diagnostic script to gather system information from a server
- Preparing a remediation script for a known issue (service restart, disk cleanup, config reset)
- Generating an Arc onboarding script for new servers
- Creating a bulk extension installation script
- Building a maintenance script for scheduled tasks
- Need OS-specific commands and the operator is not sure of the correct syntax

## Instructions

1. **Determine the task**: Parse the operator's request to understand what the script should accomplish. Common tasks:
   - **Diagnostics**: Disk space, memory usage, service status, event logs, network connections, process list, installed software
   - **Remediation**: Restart service, clear temp/log files, reset network config, repair extension, update agent
   - **Onboarding**: Install the Azure Connected Machine agent and register the server with Arc
   - **Maintenance**: Rotate logs, clean up old updates, verify backup agent, check certificate expiry
   - **Bulk operations**: Install extensions on multiple servers, collect inventory from multiple servers

2. **Determine the target OS**: Ask or infer the target OS:
   - **Windows**: Generate PowerShell scripts using cmdlets (Get-Service, Get-WmiObject, Get-EventLog, etc.)
   - **Linux**: Generate Bash scripts using standard utilities (systemctl, journalctl, df, free, ps, ss, etc.)
   - **Both**: If the operator needs both, generate separate scripts for each OS

3. **Generate the script**: Follow these conventions:
   - **Header comment**: Script purpose, target OS, and prerequisites
   - **Safety checks**: Verify prerequisites before proceeding (e.g., check if running as admin/root, check if a service exists before restarting)
   - **Error handling**: Use `$ErrorActionPreference = 'Stop'` and try/catch (PowerShell) or `set -euo pipefail` and trap (Bash)
   - **Inline comments**: Explain each significant step
   - **Output formatting**: Structured output that is easy to parse when run via Run Command
   - **Idempotency**: Scripts should be safe to re-run without side effects where possible

4. **Validate the script**: Review the generated script for:
   - Correct syntax for the target OS
   - No hardcoded credentials or secrets
   - No destructive operations without confirmation
   - Reasonable defaults (timeouts, limits, paths)

5. **Present the script**: Show the complete script in a fenced code block with the correct language identifier (powershell or bash). Include:
   - Brief description of what the script does
   - Prerequisites (admin/root access, specific modules, etc.)
   - How to run it (directly or via Run Command)
   - Expected output format

## Expected MCP Tools

None -- this skill generates scripts through text processing only. It does not require MCP server access. The generated scripts can be executed using the `run-command` skill.

## Input

- **Required**: Description of what the script should do
- **Required**: Target OS -- Windows, Linux, or both
- **Optional**: Specific server context (hostname, services, paths) to customize the script
- **Optional**: Script complexity preference -- simple (quick one-liner) or robust (full error handling)

## Output

A ready-to-execute script with documentation:

````
## Generated Script: [task description]

**Target OS**: [Windows/Linux] | **Requires**: [Admin/Root/None]
**Safe to re-run**: [Yes/No]

### Script

```powershell
# Purpose: Check disk space and flag volumes below 10% free
# Target: Windows servers via Azure Arc Run Command
# Prerequisites: None (uses built-in cmdlets)

$ErrorActionPreference = 'Stop'

try {
    $volumes = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($vol in $volumes) {
        $freePercent = [math]::Round(($vol.FreeSpace / $vol.Size) * 100, 1)
        $status = if ($freePercent -lt 10) { "WARNING" } else { "OK" }
        [PSCustomObject]@{
            Drive = $vol.DeviceID
            SizeGB = [math]::Round($vol.Size / 1GB, 1)
            FreeGB = [math]::Round($vol.FreeSpace / 1GB, 1)
            FreePercent = $freePercent
            Status = $status
        }
    }
} catch {
    Write-Error "Failed to retrieve disk information: $_"
    exit 1
}
```

### Usage

Run directly on the server or execute via the `run-command` skill targeting the Arc-enabled server.
````

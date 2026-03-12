---
name: run-command
description: 'Execute PowerShell or Shell scripts on Azure Arc-enabled servers remotely via Azure Run Command.'
---

# Run Command

## Purpose

Execute PowerShell (Windows) or Bash (Linux) scripts on Azure Arc-enabled servers remotely using Azure Run Command. This enables diagnostics, remediation, and ad-hoc operations without direct network access to the server. The skill automatically selects the correct shell based on the server's OS type.

## When to Use

- Running diagnostic commands on a server (disk space, service status, event logs, process list)
- Executing a remediation script (restart a service, clear temp files, reset configuration)
- Collecting system information that is not available through Azure resource metadata
- Verifying the outcome of a previous operation (patch install, extension deployment)
- Running a one-off administrative task that does not justify a full automation runbook

## Instructions

1. **Identify the target server**: Confirm the server name and resource group. Call `arc_get_server` to determine the OS type (Windows or Linux) if not already known.

2. **Select the correct shell**: Based on the OS type:
   - **Windows**: Scripts execute in PowerShell. Use PowerShell syntax, cmdlets, and modules.
   - **Linux**: Scripts execute in Bash. Use standard POSIX commands and utilities.

3. **Prepare the script**: Review the script content for safety:
   - Does it modify system state? If so, the `arc-warn-run-command` hook will require confirmation.
   - Does it include any destructive operations (delete, format, stop critical service)?
   - Is the script idempotent — safe to re-run if interrupted?
   - Does it have a reasonable timeout (default: 300 seconds)?

4. **Execute the script**: Call `arc_run_command` with the server name, resource group, script content, and timeout. The Run Command is asynchronous — it may return a command name for status polling.

5. **Retrieve results**: Call `arc_get_command_result` to get the execution output:
   - **Exit code**: 0 indicates success, non-zero indicates failure
   - **stdout**: Standard output from the script
   - **stderr**: Error output from the script

6. **Present results**: Format the output with clear labeling of the server, script executed, exit code, and output content. If the command failed, analyze the error and suggest fixes.

7. **Handle errors**: Common failure modes:
   - **Agent not connected**: Server must be in Connected state for Run Command to work
   - **Timeout**: Script exceeded the allowed execution time — suggest increasing timeout or breaking into smaller steps
   - **Permission denied**: Script requires elevated privileges not available to the Run Command context
   - **Extension not installed**: Run Command requires the HybridCompute extension

## Expected MCP Tools

- `arc_run_command` — Execute a script on an Arc-enabled server
- `arc_get_command_result` — Get the result of a Run Command execution (exit code, stdout, stderr)
- `arc_get_server` — Get server details to determine OS type before running commands

## Input

- **Required**: Server name and resource group
- **Required**: Script content (PowerShell for Windows, Bash for Linux)
- **Optional**: Timeout in seconds (default: 300)
- **Optional**: OS type if already known (avoids extra API call)

## Output

A structured Markdown execution report:

````
## Run Command Result: [server-name]

**Server**: [name] | **OS**: [Windows/Linux] | **Resource Group**: [rg]
**Exit Code**: [0/non-zero] | **Status**: [Succeeded/Failed]
**Duration**: [execution time]

### Script Executed

```powershell
Get-Service -Name 'wuauserv' | Select-Object Name, Status, StartType
```

### Output (stdout)

```
Name     Status  StartType
----     ------  ---------
wuauserv Running Automatic
```

### Errors (stderr)

[empty or error content]
````

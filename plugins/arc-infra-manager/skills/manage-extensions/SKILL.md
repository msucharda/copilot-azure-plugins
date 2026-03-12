---
name: manage-extensions
description: 'Install, update, list, or remove VM extensions on Azure Arc-enabled servers.'
---

# Manage Extensions

## Purpose

Manage the lifecycle of VM extensions on Azure Arc-enabled servers -- list installed extensions, install new ones, and remove extensions that are no longer needed. Covers common extensions like Azure Monitor Agent, Microsoft Defender for Servers, Custom Script Extension, and others. Provides a before/after view of extension state for operational clarity.

## When to Use

- Auditing which extensions are deployed across the fleet
- Installing Azure Monitor Agent or Defender on servers missing them
- Removing a deprecated or failing extension
- Checking extension status after deployment
- Building an extension coverage matrix for compliance

## Instructions

1. **List current extensions**: Call `arc_list_extensions` for the target server(s) to see what is currently installed. Record the state as the "before" snapshot.

2. **For install operations**: Determine the correct extension parameters based on OS and extension type:
   - **Azure Monitor Agent (Linux)**: publisher=Microsoft.Azure.Monitor, type=AzureMonitorLinuxAgent
   - **Azure Monitor Agent (Windows)**: publisher=Microsoft.Azure.Monitor, type=AzureMonitorWindowsAgent
   - **Defender for Servers (Linux)**: publisher=Microsoft.Azure.AzureDefenderForServers, type=MDE.Linux
   - **Defender for Servers (Windows)**: publisher=Microsoft.Azure.AzureDefenderForServers, type=MDE.Windows
   - **Custom Script (Linux)**: publisher=Microsoft.Azure.Extensions, type=CustomScript
   - **Custom Script (Windows)**: publisher=Microsoft.Compute, type=CustomScriptExtension
   - **Dependency Agent (Linux)**: publisher=Microsoft.Azure.Monitoring.DependencyAgent, type=DependencyAgentLinux
   - **Dependency Agent (Windows)**: publisher=Microsoft.Azure.Monitoring.DependencyAgent, type=DependencyAgentWindows

3. **Validate OS match**: Before installing, verify the server's OS type matches the extension variant. A Windows extension on a Linux server (or vice versa) will fail. Call `arc_get_server` if the OS is not already known.

4. **Install the extension**: Call `arc_install_extension` with the correct publisher, type, and any required settings. Monitor for provisioning completion.

5. **For remove operations**: Call `arc_remove_extension` with the extension name. Confirm the extension exists before attempting removal.

6. **Verify result**: After install or remove, call `arc_list_extensions` again to confirm the operation succeeded. Present a before/after comparison.

## Expected MCP Tools

- `arc_list_extensions` -- List extensions installed on a server with their status
- `arc_install_extension` -- Install an extension with publisher, type, and settings
- `arc_remove_extension` -- Remove an extension by name
- `arc_get_server` -- Get server OS type to validate extension compatibility

## Input

- **Required**: Server name and resource group
- **Required**: Operation: list, install, or remove
- **For install**: Extension type or common name (e.g., "Azure Monitor Agent", "Defender")
- **For remove**: Extension name to remove
- **Optional**: Settings JSON for extensions that require configuration

## Output

A structured Markdown extension report:

```
## Extension Operation: [Install/Remove/List] on [server-name]

**Server**: [name] | **OS**: [Windows/Linux] | **Resource Group**: [rg]

### Before

| Extension | Publisher | Type | Status | Version |
|-----------|-----------|------|--------|---------|
| AzureMonitorLinuxAgent | Microsoft.Azure.Monitor | AzureMonitorLinuxAgent | Succeeded | 1.28.0 |

### After

| Extension | Publisher | Type | Status | Version |
|-----------|-----------|------|--------|---------|
| AzureMonitorLinuxAgent | Microsoft.Azure.Monitor | AzureMonitorLinuxAgent | Succeeded | 1.28.0 |
| MDE.Linux | Microsoft.Azure.AzureDefenderForServers | MDE.Linux | Succeeded | 1.0.2 |

### Result

Successfully installed MDE.Linux on [server-name].
```

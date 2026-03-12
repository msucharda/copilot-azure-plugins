---
name: manage-updates
description: 'Assess pending updates, install patches, and review update history for Azure Arc-enabled servers via Azure Update Manager.'
---

# Manage Updates

## Purpose

Manage the patching lifecycle for Azure Arc-enabled servers using Azure Update Manager. Assess pending updates by classification, trigger on-demand patch installations with configurable reboot behavior, and review update deployment history. Supports both Windows (Windows Update) and Linux (apt/yum/zypper) servers.

## When to Use

- Checking which servers have pending security patches
- Installing critical updates during a maintenance window
- Reviewing whether a recent patch deployment succeeded
- Assessing overall patch compliance across the fleet
- Preparing a patch status report for management

## Instructions

1. **Determine the operation**: Accept one of three operations from the operator:
   - **Assess**: Scan for pending updates and report what needs patching
   - **Install**: Apply approved patches with reboot options
   - **History**: Review past update deployments and their results

2. **For assessment**: Call `arc_assess_updates` for the target server(s). This triggers an on-demand scan that evaluates available updates. Results include:
   - **Windows**: Updates classified as Critical, Security, UpdateRollup, FeaturePack, ServicePack, Definition, Tools, Updates
   - **Linux**: Updates classified as Critical, Security, Other
   - For each update: name, classification, KB article (Windows) or package name (Linux), severity

3. **Present assessment results**: Group pending updates by classification and severity. Highlight:
   - Total pending updates by classification
   - Critical and Security updates (patch immediately)
   - Number of updates requiring reboot
   - Age of oldest pending update

4. **For installation**: Before proceeding, the `arc-warn-install-updates` hook will require confirmation. Then call `arc_install_updates` with:
   - **Classifications**: Which update categories to install (default: Critical, Security)
   - **Reboot setting**: IfRequired (default), NeverReboot (for critical servers), AlwaysReboot (for maintenance windows)
   - Monitor the installation progress

5. **Verify installation**: After installation completes, call `arc_get_update_history` to confirm:
   - Which updates were successfully installed
   - Any updates that failed with error details
   - Whether a reboot is pending
   - Total installation duration

6. **For history**: Call `arc_get_update_history` to retrieve past update deployments. Present:
   - Deployment date and time
   - Updates attempted vs. succeeded vs. failed
   - Reboot status
   - Error details for any failed updates

## Expected MCP Tools

- `arc_assess_updates` -- Trigger an on-demand update assessment
- `arc_install_updates` -- Install updates with classification filter and reboot options
- `arc_get_update_history` -- Get update installation history

## Input

- **Required**: Server name and resource group
- **Required**: Operation -- assess, install, or history
- **For install**: Update classifications to install (default: Critical, Security)
- **For install**: Reboot setting -- IfRequired (default), NeverReboot, AlwaysReboot
- **For history**: Number of results to return (default: 20)

## Output

A structured Markdown update report:

```
## Update Assessment: [server-name]

**Server**: [name] | **OS**: [Windows/Linux] | **Last Scan**: [timestamp]
**Total Pending**: [count] | **Critical**: [count] | **Security**: [count]

### Pending Updates by Classification

| Classification | Count | Reboot Required |
|---------------|-------|-----------------|
| Critical | 2 | Yes |
| Security | 5 | Yes |
| Updates | 12 | No |

### Critical and Security Updates

| Update Name | Classification | KB/Package | Published |
|-------------|---------------|------------|-----------|
| Windows Security Update | Critical | KB5034441 | 2025-01-09 |
| OpenSSL security fix | Security | openssl-3.0.13 | 2025-01-12 |

### Recommendation

[count] critical/security updates pending. Recommend installing during next maintenance window with RebootSetting=IfRequired.
```

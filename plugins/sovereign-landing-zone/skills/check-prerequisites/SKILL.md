---
name: check-prerequisites
description: 'Verify all tools, Azure subscriptions, permissions, and VCS prerequisites required for the ALZ Accelerator bootstrap.'
---

# Check Prerequisites

## Purpose

Verify that all prerequisites for the ALZ Accelerator bootstrap are met before starting the bootstrap process. This includes tools installation, Azure subscriptions, permissions, and VCS (GitHub/Azure DevOps) setup. Catching missing prerequisites early prevents failed bootstraps.

## When to Use

- Before running the ALZ Accelerator bootstrap for the first time
- When troubleshooting a failed bootstrap
- When onboarding a new team member to manage the landing zone
- After environment changes (new subscriptions, changed permissions)

## Instructions

1. **Verify required tools**: Check each tool is installed and meets minimum version:
   ```bash
   # PowerShell 7.4+
   pwsh -Command '$PSVersionTable.PSVersion.ToString()'

   # Azure CLI 2.55+
   az version --query '"azure-cli"' -o tsv

   # Git
   git --version

   # VS Code (recommended, not required)
   code --version 2>/dev/null || echo "VS Code not installed (optional)"
   ```

   If any required tool is missing, provide installation instructions:
   - PowerShell: https://learn.microsoft.com/powershell/scripting/install/installing-powershell
   - Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli
   - Git: https://git-scm.com/downloads

2. **Verify Azure authentication**:
   ```bash
   az account show --query "{user:user.name, tenant:tenantId, subscription:name}" -o table
   ```
   If not authenticated, guide the operator through `az login`.

3. **Verify platform subscriptions exist**: The ALZ Accelerator requires 4 subscriptions:
   ```bash
   az account list --query "[].{name:name, id:id, state:state}" -o table
   ```

   Ask the operator to identify which subscriptions map to:
   - **Management** — bootstrap + management resources
   - **Connectivity** — hub networking
   - **Identity** — domain services
   - **Security** — Sentinel + security resources

   If subscriptions need to be created, guide the operator to their billing portal (EA or MCA).

4. **Verify permissions**: Check the authenticated identity has Owner on the parent management group and subscriptions:
   ```bash
   # Check management group access
   az role assignment list --scope "/providers/Microsoft.Management/managementGroups/<parent-mg>" --assignee "<user-object-id>" --query "[].{role:roleDefinitionName, scope:scope}" -o table

   # Check subscription access for each platform subscription
   for sub_id in "<mgmt-sub>" "<conn-sub>" "<id-sub>" "<sec-sub>"; do
     az role assignment list --subscription "$sub_id" --assignee "<user-object-id>" --query "[?roleDefinitionName=='Owner'].{role:roleDefinitionName, sub:scope}" -o table
   done
   ```

5. **Verify VCS prerequisites**: Based on the operator's chosen VCS:

   **GitHub**:
   - Organization account exists (not personal)
   - **Recommended: Use a classic PAT** — classic tokens work more reliably with the ALZ Accelerator than fine-grained PATs. Required scopes: `repo`, `workflow`, `admin:org`, `read:user`, `delete_repo`
   - If using fine-grained PATs instead, **you must also add** `Account permissions → Email addresses → Read` — without this, the Terraform GitHub provider's `data "github_organization"` data source fails
   - Fine-grained PAT repository permissions: Actions, Administration, Contents, Environments, Secrets, Variables, Workflows (R/W)
   - Fine-grained PAT organization permissions: Members (R/W)
   - Optional second PAT for self-hosted runners (Administration R/W, Self-hosted runners R/W)

   **Azure DevOps**:
   - Organization and project exist
   - PAT with required permissions

   **Local file system**:
   - Target folder is accessible and writable

6. **Produce prerequisites report**:

   ```
   ## ALZ Accelerator Prerequisites Check

   ### Tools
   | Tool | Required | Installed | Status |
   |------|----------|-----------|--------|
   | PowerShell | >=7.4 | [version] | ✅/❌ |
   | Azure CLI | >=2.55 | [version] | ✅/❌ |
   | Git | any | [version] | ✅/❌ |
   | VS Code | optional | [version] | ℹ️ |

   ### Azure
   | Check | Status | Detail |
   |-------|--------|--------|
   | Authenticated | ✅/❌ | [user@tenant] |
   | Management sub | ✅/❌ | [name] ([id]) |
   | Connectivity sub | ✅/❌ | [name] ([id]) |
   | Identity sub | ✅/❌ | [name] ([id]) |
   | Security sub | ✅/❌ | [name] ([id]) |
   | Owner on parent MG | ✅/❌ | [scope] |
   | Owner on subs | ✅/❌ | [count]/4 |

   ### VCS ([type])
   | Check | Status | Detail |
   |-------|--------|--------|
   | [VCS-specific checks] | ✅/❌ | [detail] |

   ### Recommendation
   ✅ All prerequisites met. Ready for bootstrap.
   ❌ [N] prerequisites missing. Fix the items above before proceeding.
   ```

## Input

- **Required**: Target VCS type (github, azure-devops, local)
- **Optional**: Known subscription IDs (can be discovered)
- **Optional**: Parent management group ID (defaults to Tenant Root Group)

## Output

A structured prerequisites report showing pass/fail for each requirement, with remediation instructions for any failures.

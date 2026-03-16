---
name: bootstrap-accelerator
description: 'Generate inputs.yaml configuration and run the ALZ PowerShell Deploy-Accelerator command to bootstrap CI/CD environment for the Sovereign Landing Zone.'
---

# Bootstrap Accelerator

## Purpose

Generate the bootstrap configuration file (`inputs.yaml`) and execute the ALZ Accelerator bootstrap using the ALZ PowerShell module. The bootstrap creates the foundational CI/CD infrastructure: Terraform state storage, managed identities, VCS repositories with pipelines, and RBAC assignments. This is a one-time setup that enables all subsequent landing zone deployments through CI/CD.

## When to Use

- Setting up a new Sovereign Landing Zone environment from scratch
- The operator has completed prerequisites (tools, subscriptions, permissions, VCS)
- Moving from manual Terraform operations to CI/CD-driven deployment
- Rebuilding the bootstrap environment after cleanup

## Instructions

1. **Collect bootstrap inputs**: Gather the following from the operator:

   | Input | Description | Example |
   |-------|-------------|---------|
   | `iac_type` | Infrastructure as Code tool | `terraform` |
   | `bootstrap_module_name` | VCS bootstrap module | `alz_github`, `alz_azuredevops`, `alz_local` |
   | `starter_module_name` | Starter module name | `platform_landing_zone` |
   | `bootstrap_location` | Azure region for bootstrap resources | `uksouth` |
   | `subscription_ids` | Map of platform subscription IDs | `{management: "<guid>", identity: "<guid>", connectivity: "<guid>", security: "<guid>"}` |
   | `bootstrap_subscription_id` | Subscription for state storage | `<guid>` (usually same as management) |
   | `service_name` | Short name for resources | `alz` |
   | `environment_name` | Environment identifier | `mgmt` |
   | `postfix_number` | Numeric postfix for uniqueness | `1` |
   | `root_parent_management_group_id` | Parent MG for ALZ hierarchy | `""` (Tenant Root) |

   **For GitHub VCS**, also collect:
   | Input | Description |
   |-------|-------------|
   | `github_personal_access_token` | PAT token-1 (required) |
   | `github_runners_personal_access_token` | PAT token-2 (**only if** `use_self_hosted_runners: true`) |
   | `github_organization_name` | GitHub org name |
   | `use_self_hosted_runners` | `true` or `false` |
   | `use_private_networking` | `true` or `false` |
   | `github_organization_domain_name` | **GHE.com only**: e.g., `contoso.ghe.com` (omit for github.com) |

   **For Azure DevOps VCS**, also collect:
   | Input | Description |
   |-------|-------------|
   | `azure_devops_personal_access_token` | ADO PAT |
   | `azure_devops_organization_name` | ADO org name |
   | `azure_devops_project_name` | Project name (existing or new) |

2. **Install or update the ALZ PowerShell module**: This must be done before creating the folder structure:
   ```powershell
   $alzModule = Get-InstalledPSResource -Name ALZ 2>$null
   if (-not $alzModule) {
       Install-PSResource -Name ALZ
   } else {
       Update-PSResource -Name ALZ
   }
   ```

3. **Create folder structure**: Run in PowerShell:
   ```powershell
   $iacType = "terraform"
   $versionControl = "<github|azure-devops|local>"
   $scenarioNumber = 1  # Default sovereign scenario
   $targetFolderPath = "~/accelerator"

   New-AcceleratorFolderStructure `
       -iacType $iacType `
       -versionControl $versionControl `
       -scenarioNumber $scenarioNumber `
       -targetFolderPath $targetFolderPath
   ```

4. **Generate inputs.yaml**: Create the bootstrap configuration file at `$targetFolderPath/config/inputs.yaml`:
   ```yaml
   # ALZ Accelerator Bootstrap Configuration
   # Generated for Sovereign Landing Zone deployment

   iac_type: "terraform"
   bootstrap_module_name: "<alz_github|alz_azuredevops|alz_local>"
   starter_module_name: "platform_landing_zone"
   bootstrap_location: "<region>"

   # Subscriptions
   bootstrap_subscription_id: "<management-sub-id>"
   subscription_ids:
     management: "<management-sub-id>"
     identity: "<identity-sub-id>"
     connectivity: "<connectivity-sub-id>"
     security: "<security-sub-id>"

   # Naming
   service_name: "alz"
   environment_name: "mgmt"
   postfix_number: 1

   # Management Groups
   root_parent_management_group_id: ""  # Empty = Tenant Root Group

   # VCS-specific settings
   # (GitHub or Azure DevOps fields here)

   # GHE.com only — uncomment if using GitHub Enterprise Cloud with data residency
   # github_organization_domain_name: "<enterprise>.ghe.com"
   ```

   **⚠️ Token security**: Prefer using environment variables (`TF_VAR_github_personal_access_token`, `TF_VAR_github_runners_personal_access_token`) instead of hardcoding tokens in `inputs.yaml`. If tokens are placed in the file, they MUST be scrubbed after bootstrap completes (see step 9).

   **GHE.com note**: If the operator is using GitHub Enterprise Cloud with data residency (`*.ghe.com`), the `github_organization_domain_name` setting is **required**. Without it, the bootstrap will target github.com instead of the GHE.com instance. The ALZ PowerShell module handles the API URL and OIDC issuer differences automatically when this is set.

   **SLZ architecture file**: If adding SLZ library files under `$targetFolderPath/config/lib/architecture_definitions/`, use the default file name `alz_custom.alz_architecture_definition.yaml`. The official docs warn that renaming this file creates duplicate architecture files. If renamed, set `terraform_architecture_file_path` in `inputs.yaml`.

5. **Verify Azure login**: Ensure the operator is logged in to the correct tenant and subscription:
   ```bash
   az login --tenant "<tenant-id>"
   az account set --subscription "<bootstrap-subscription-id>"
   az account show
   ```

6. **Run Deploy-Accelerator**: Execute the bootstrap in advanced mode:
   ```powershell
   Deploy-Accelerator `
       -inputs "$targetFolderPath/config/inputs.yaml", "$targetFolderPath/config/platform-landing-zone.tfvars" `
       -starterAdditionalFiles "$targetFolderPath/config/lib" `
       -output "$targetFolderPath/output"
   ```

   The command will:
   - Validate the configuration
   - Generate a Terraform plan for the bootstrap infrastructure
   - Prompt for confirmation before applying
   - Create all bootstrap resources

   > **Alternative**: For a guided experience, run `Deploy-Accelerator` with no parameters to start the interactive wizard. The wizard collects inputs step by step and produces the same result. Use advanced mode (above) when automating or when the agent needs programmatic control.

7. **Verify bootstrap output**: After successful execution, verify:
   ```bash
   # Check state storage was created
   az storage account list --resource-group "rg-<service_name>-<environment_name>-state-<region>-<postfix>" -o table

   # Check managed identities were created
   az identity list --resource-group "rg-<service_name>-<environment_name>-identity-<region>-<postfix>" -o table
   ```

8. **Record bootstrap outputs**: Capture and save:
   - State storage account name and container
   - UAMI resource IDs (plan and apply identities)
   - VCS repository URL
   - Pipeline/Action URLs
   - Output directory path

9. **Post-bootstrap security cleanup**: After successful bootstrap, perform these security hardening steps:

   **Scrub tokens from inputs.yaml**:
   ```bash
   # Replace hardcoded PATs with placeholder text
   sed -i 's/ghp_[A-Za-z0-9_]*/\<REDACTED-ROTATE-THIS-TOKEN\>/g' "$targetFolderPath/config/inputs.yaml"
   sed -i 's/github_pat_[A-Za-z0-9_]*/\<REDACTED-ROTATE-THIS-TOKEN\>/g' "$targetFolderPath/config/inputs.yaml"
   ```

   **Delete any standalone token files**:
   ```bash
   # Remove tokens/secrets files created during setup (scoped to bootstrap dir)
   rm -f "$targetFolderPath/tokens" "$targetFolderPath/.env" "$targetFolderPath"/*.secret 2>/dev/null
   ```

   **Set file permissions on config directory**:
   ```bash
   chmod 600 "$targetFolderPath/config/inputs.yaml"
   chmod 700 "$targetFolderPath/config/"
   ```

   **Create .gitignore** (if the directory may become a git repo):
   ```bash
   cat > "$targetFolderPath/.gitignore" << 'EOF'
   # Sensitive files
   tokens
   *.secret
   .env

   # Terraform state and cache
   .terraform/
   *.tfstate
   *.tfstate.backup
   crash.log

   # Bootstrap output
   output/
   EOF
   ```

   **Rotate tokens**: After bootstrap completes, the OIDC federated credentials handle all CI/CD authentication. The PATs used for bootstrap should be:
   - Rotated immediately if they were exposed in any logs or files
   - Set to expire within 24 hours (they're no longer needed)
   - Deleted if a classic PAT was used as a one-time bootstrap token

## Input

- **Required**: All fields from the inputs table in step 1
- **Required**: Platform landing zone configuration (from `configure-platform` skill)
- **Optional**: Custom starter module overrides

## Output

A bootstrapped CI/CD environment with:
- Terraform state storage (Resource Group + Storage Account + Container)
- Managed identities with federated credentials
- VCS repository with starter module and CI/CD pipelines
- Branch policies and approval gates
- A summary report with all resource IDs and URLs for the operator

Reference: https://azure.github.io/Azure-Landing-Zones/accelerator/2_bootstrap/

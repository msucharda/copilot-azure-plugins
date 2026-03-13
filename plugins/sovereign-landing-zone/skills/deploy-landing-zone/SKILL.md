---
name: deploy-landing-zone
description: 'Execute Terraform init, plan, and apply operations for the Sovereign Landing Zone deployment with progress monitoring and error handling.'
---

# Deploy Landing Zone

## Purpose

Execute the Terraform deployment lifecycle for the Sovereign Landing Zone — initialize the working directory, generate an execution plan, and apply changes to Azure. This skill handles the full deployment workflow including backend initialization, provider authentication, plan analysis, and apply execution with progress monitoring.

## When to Use

- Deploying a new Sovereign Landing Zone for the first time
- Applying changes to an existing landing zone configuration
- Re-running a deployment after fixing configuration errors
- Updating the landing zone to a new version of AVM modules

## Instructions

1. **Verify prerequisites**: Before starting deployment, verify:
   ```bash
   # Terraform CLI version
   terraform version
   
   # Azure CLI authentication
   az account show --query "{name:name, id:id, tenantId:tenantId}" -o table
   
   # Correct subscription context
   az account set --subscription "<management-subscription-id>"
   
   # Required resource providers
   az provider show --namespace Microsoft.Management --query "registrationState" -o tsv
   az provider show --namespace Microsoft.Network --query "registrationState" -o tsv
   az provider show --namespace Microsoft.Authorization --query "registrationState" -o tsv
   az provider show --namespace Microsoft.OperationalInsights --query "registrationState" -o tsv
   ```

   If any provider is not registered, register it:
   ```bash
   az provider register --namespace <namespace> --wait
   ```

2. **Initialize Terraform**: Run `terraform init` in the landing zone directory:
   ```bash
   terraform init -upgrade
   ```

   Handle common initialization failures:
   - **Backend access denied**: Verify storage account exists and identity has Storage Blob Data Contributor role
   - **Module download failure**: Check network connectivity and Terraform registry access
   - **Provider version conflict**: Run `terraform init -upgrade` to resolve version constraints
   - **State lock error**: Check if another operation is in progress

3. **Format and validate**: Run pre-deployment checks:
   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```
   Fix any formatting or validation errors before proceeding.

4. **Generate execution plan**: Create a saved plan file:
   ```bash
   terraform plan -out=tfplan -detailed-exitcode
   ```

   Analyze the plan output:
   - **Exit code 0**: No changes needed — infrastructure is up to date
   - **Exit code 1**: Error in plan — fix configuration and retry
   - **Exit code 2**: Changes detected — review the plan before applying

   Review criteria:
   - Count resources to add, change, destroy
   - Flag any resource deletions (potential data loss)
   - Check for management group or policy changes (wide blast radius)
   - Verify no unexpected resources are being modified

5. **Apply the plan**: Execute the saved plan:
   ```bash
   terraform apply tfplan
   ```

   Landing zone deployments are long-running (15-45 minutes). Monitor progress by watching the Terraform output. Key milestones:
   - Management group creation (1-2 minutes)
   - Policy assignment deployment (5-10 minutes)
   - Hub networking deployment (5-15 minutes)
   - Log Analytics and management resources (3-5 minutes)
   - Policy compliance evaluation (up to 30 minutes for full evaluation)

6. **Capture outputs**: After successful apply, capture key outputs:
   ```bash
   terraform output -json > deployment-outputs.json
   ```

   Key outputs to report:
   - Management group IDs
   - Hub VNet or vWAN hub IDs
   - Log Analytics workspace ID
   - Azure Firewall private IP
   - Policy assignment IDs

7. **Post-deployment verification**: Verify the deployment:
   ```bash
   # Check management groups exist
   az account management-group list --query "[].{name:name, displayName:displayName}" -o table
   
   # Check policy assignments
   az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/<root-mg>" --query "[].{name:name, displayName:displayName, enforcementMode:enforcementMode}" -o table
   
   # Check networking (hub-spoke)
   az network vnet list --resource-group "rg-connectivity-<location>" -o table
   ```

## Input

- **Required**: Path to the Terraform configuration directory
- **Optional**: `-target` flags for partial deployment
- **Optional**: `-var-file` for alternative variable files
- **Optional**: `-parallelism` setting (default 10, reduce for rate limiting)

## Output

A deployment summary report:

```
## SLZ Deployment Summary

**Status**: Succeeded / Failed
**Duration**: [minutes]
**Terraform Version**: [version]

### Resources
| Action | Count |
|--------|-------|
| Added | [n] |
| Changed | [n] |
| Destroyed | [n] |

### Key Outputs
| Output | Value |
|--------|-------|
| Root Management Group ID | [id] |
| Hub VNet ID | [id] |
| Log Analytics Workspace ID | [id] |
| Azure Firewall Private IP | [ip] |

### Post-Deployment Status
| Check | Status |
|-------|--------|
| Management Groups | ✅ Created |
| Policy Assignments | ✅ Active |
| Hub Networking | ✅ Deployed |
| Log Analytics | ✅ Configured |

### Next Steps
1. Verify policy compliance evaluation completes (up to 30 minutes)
2. Create spoke VNets and peer to hub
3. Place workload subscriptions in appropriate management groups
```

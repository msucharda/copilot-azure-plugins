---
name: validate-deployment
description: 'Run pre-flight validation checks on the Sovereign Landing Zone Terraform configuration including syntax, plan, compliance, and sovereign control verification.'
---

# Validate Deployment

## Purpose

Perform comprehensive pre-flight validation of the Sovereign Landing Zone Terraform configuration before deployment. This includes syntax validation, plan generation, compliance checks against sovereign requirements, and verification that all prerequisites are met. Catches errors early to avoid failed deployments.

## When to Use

- Before running `terraform apply` for the first time
- After modifying Terraform configurations
- After updating AVM module versions
- As part of a CI/CD pipeline pre-deployment gate
- When investigating why a previous deployment failed
- After the Compliance Guardian flags configuration drift

## Instructions

1. **Syntax and format validation**: Check that all Terraform files are syntactically correct and properly formatted:
   ```bash
   cd <landing-zone-directory>
   terraform fmt -check -recursive -diff
   terraform validate
   ```

   If `terraform validate` fails:
   - Check for missing required variables
   - Verify module source paths and versions are correct
   - Ensure provider configuration is complete
   - Look for circular dependencies between modules

2. **Variable completeness check**: Verify all required variables have values:
   ```bash
   # List all variables that need values
   terraform console <<< "var"
   ```
   
   Check `terraform.tfvars` provides values for all required variables. Common missing values:
   - Subscription IDs (management, connectivity, identity)
   - Allowed locations list
   - CIDR ranges for networking
   - Organization name and naming prefixes

3. **Plan generation**: Generate and analyze the execution plan:
   ```bash
   terraform plan -out=validation.tfplan -detailed-exitcode 2>&1 | tee plan-output.txt
   ```

   Analyze for:
   - **Resource count**: Is the number of resources reasonable for the configuration?
   - **Unexpected destroys**: Are any existing resources being destroyed?
   - **Policy changes**: Are policy assignments being modified?
   - **Networking changes**: Are VNet address spaces or firewall rules changing?

4. **Sovereign control validation**: Verify sovereign controls are correctly configured:

   **Data residency**: Check that `allowed_locations` policy is assigned at the root management group:
   ```bash
   grep -r "allowed_locations" *.tf terraform.tfvars
   ```
   Verify the allowed regions list matches sovereignty requirements.

   **CMK enforcement**: If enabled, verify CMK policies target the correct resource types:
   ```bash
   grep -r "cmk\|customer.managed.key\|encryption" *.tf terraform.tfvars
   ```

   **Encryption**: Verify encryption-in-transit policies are configured:
   ```bash
   grep -r "https\|tls\|encryption.in.transit" *.tf terraform.tfvars
   ```

5. **Provider version compatibility**: Verify AVM module versions are compatible:
   ```bash
   terraform providers lock
   terraform version
   ```
   
   Check that:
   - AzureRM provider version meets module requirements
   - AzAPI provider is included if required by newer AVM modules
   - No provider version conflicts between modules

6. **Backend validation**: Verify the Terraform backend is accessible:
   ```bash
   terraform init -backend=true
   ```
   
   If using Azure Storage backend, verify:
   - Storage account exists and is accessible
   - Container exists
   - Identity has Storage Blob Data Contributor role
   - No state lock conflicts

7. **Dependency validation**: Verify Azure prerequisites:
   ```bash
   # Required resource providers
   for ns in Microsoft.Management Microsoft.Network Microsoft.Authorization Microsoft.OperationalInsights Microsoft.Compute Microsoft.KeyVault; do
     state=$(az provider show --namespace $ns --query "registrationState" -o tsv 2>/dev/null)
     echo "$ns: ${state:-NOT FOUND}"
   done
   
   # Subscription existence
   az account show --subscription "<management-sub-id>" --query "state" -o tsv
   az account show --subscription "<connectivity-sub-id>" --query "state" -o tsv
   ```

8. **Produce validation report**: Summarize all checks:

## Input

- **Required**: Path to the Terraform configuration directory
- **Optional**: Specific checks to run (syntax-only, plan-only, full)
- **Optional**: Sovereignty requirements for validation comparison

## Output

A structured validation report:

```
## SLZ Pre-Deployment Validation

**Configuration**: [directory path]
**Timestamp**: [date/time]

### Checks
| Check | Status | Detail |
|-------|--------|--------|
| Terraform fmt | ✅ Pass | All files formatted |
| Terraform validate | ✅ Pass | Configuration valid |
| Variables complete | ✅ Pass | All required vars set |
| Plan generation | ✅ Pass | 47 to add, 0 to change, 0 to destroy |
| Data residency | ✅ Pass | Allowed locations: westeurope, northeurope |
| CMK enforcement | ✅ Pass | Deny policy on storage, disks, databases |
| Encryption | ✅ Pass | HTTPS/TLS enforced |
| Provider versions | ✅ Pass | AzureRM 4.x compatible |
| Backend access | ✅ Pass | State storage accessible |
| Resource providers | ✅ Pass | All required providers registered |

### Sovereign Controls Summary
| Control | Configured | Effect | Scope |
|---------|-----------|--------|-------|
| Allowed Locations | westeurope, northeurope | Deny | Root MG |
| Customer-Managed Keys | Enabled | Deny | Landing Zones |
| Encryption in Transit | Enabled | Deny | Root MG |
| Confidential Computing | Disabled | N/A | N/A |

### Recommendation
✅ Configuration is ready for deployment. Proceed with `terraform apply`.
```

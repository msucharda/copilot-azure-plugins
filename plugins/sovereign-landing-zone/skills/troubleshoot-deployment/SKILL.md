---
name: troubleshoot-deployment
description: 'Diagnose and fix Terraform deployment failures for the Sovereign Landing Zone with autonomous error resolution, retry logic, and rollback capabilities.'
---

# Troubleshoot Deployment

## Purpose

Diagnose Terraform deployment failures, identify root causes, apply fixes, and retry operations. This skill enables autonomous recovery from common Azure and Terraform errors without operator intervention. It maintains a decision tree of known failure patterns and their resolutions, attempting fixes in order of likelihood before escalating to the operator.

## When to Use

- A `terraform apply` has failed and needs diagnosis
- `terraform plan` produces errors
- `terraform init` fails (backend issues, provider download failures)
- State lock conflicts prevent operations
- Azure API errors during deployment (throttling, permissions, quotas)
- Post-deployment verification reveals missing or misconfigured resources

## Instructions

### Error Diagnosis Flow

1. **Capture the error**: Extract the error message from Terraform output. Key fields:
   - Error type (validation, API, provider, state)
   - Resource address (e.g., `module.alz.azurerm_management_group.this["landing-zones"]`)
   - Azure error code (e.g., `AuthorizationFailed`, `QuotaExceeded`)
   - HTTP status code (403, 409, 429, etc.)

2. **Classify the error**: Match against known patterns. When the error references a specific resource type or module argument, use `get_provider_details` or `get_module_details` via the Terraform MCP server to look up current documentation before attempting a fix.

   ### Permission Errors (403 / AuthorizationFailed)
   ```
   Error: AuthorizationFailed - The client does not have authorization to perform action
   ```
   **Diagnosis**: The authenticated identity lacks required permissions.
   **Autonomous fix**:
   1. Identify the missing permission from the error message
   2. Check current role assignments: `az role assignment list --assignee <identity> --all`
   3. Recommend the minimum required role (e.g., Owner at management group scope for ALZ)
   4. If the operator has elevated access: `az role assignment create --assignee <identity> --role "Owner" --scope "/providers/Microsoft.Management/managementGroups/<mg>"`
   5. Retry the deployment

   ### Resource Provider Not Registered
   ```
   Error: Provider Microsoft.X not registered
   ```
   **Autonomous fix**:
   1. Register the provider: `az provider register --namespace Microsoft.X --wait`
   2. Wait for registration to complete (up to 5 minutes)
   3. Retry the deployment

   ### Quota Exceeded
   ```
   Error: QuotaExceeded - Operation could not be completed as it results in exceeding quota
   ```
   **Autonomous fix**:
   1. Identify the quota limit and current usage from the error
   2. Check available quota: `az vm list-usage --location <region> -o table`
   3. Options: request quota increase, use a different region, or use a smaller SKU
   4. If a region change is viable, update `terraform.tfvars` and retry
   5. Otherwise, inform the operator with the quota request command

   ### Naming Conflict (409 / Conflict)
   ```
   Error: A resource with the name 'X' already exists
   ```
   **Autonomous fix**:
   1. Check if the existing resource can be imported: `terraform import <address> <resource-id>`
   2. If not importable, generate a unique name and update the configuration
   3. Retry the deployment

   ### API Throttling (429 / Too Many Requests)
   ```
   Error: StatusCode=429 - Too many requests
   ```
   **Autonomous fix**:
   1. Reduce Terraform parallelism: add `-parallelism=5` to the apply command
   2. Wait 120 seconds for rate limit reset
   3. Retry the deployment

   ### State Lock (Lock ID conflict)
   ```
   Error: Error locking state: Error acquiring the state lock
   ```
   **Autonomous fix**:
   1. Check if another Terraform process is running: look for the lock holder in the error
   2. If the lock is stale (holder process no longer running):
      - Back up state: `terraform state pull > backup-state.json`
      - Force unlock: `terraform force-unlock <LOCK_ID>`
   3. If another process is actively running: wait and retry

   ### Policy Blocking Deployment
   ```
   Error: RequestDisallowedByPolicy - Resource creation disallowed by policy
   ```
   **Autonomous fix**:
   1. Identify the blocking policy from the error details
   2. Check if this is a sovereign policy that should NOT be bypassed
   3. If it's a legitimate deployment blocked by an overly broad policy:
      - Create a targeted policy exemption (temporary, with expiration)
      - Retry the deployment
   4. If it's a configuration error (deploying to wrong region, missing encryption):
      - Fix the configuration to comply with the policy
      - Retry the deployment

   ### Module Version Incompatibility
   ```
   Error: Unsupported Terraform Core version / Module version constraints
   ```
   **Autonomous fix**:
   1. Check the required version: `grep -r "required_version" *.tf`
   2. Check current version: `terraform version`
   3. Use `get_latest_module_version` to find the latest published version of each module, then use `get_module_details` to check its `required_version` constraint against the current Terraform version before changing pins
   4. Either upgrade Terraform or adjust module version constraints to a compatible version
   5. Run `terraform init -upgrade` and retry

3. **Apply fix and retry**: After applying the fix:
   ```bash
   terraform plan -out=retry.tfplan
   terraform apply retry.tfplan
   ```
   Maximum 3 retry attempts per unique error. If the same error persists, escalate to the operator.

4. **Rollback if needed**: If the deployment is partially applied and cannot be completed:
   ```bash
   # Option 1: Targeted destroy of partially-created resources
   terraform destroy -target=<resource-address>
   
   # Option 2: Full rollback to previous state (if state backup exists)
   terraform state push backup-state.json
   
   # Option 3: Mark resources as tainted for recreation
   terraform taint <resource-address>
   terraform apply
   ```

5. **Escalate to operator**: When autonomous resolution fails, provide:
   - Full error message and context
   - What was attempted and why it failed
   - Recommended manual steps
   - Links to relevant Azure documentation

## Input

- **Required**: Terraform error output (from failed plan/apply/init)
- **Optional**: Path to the Terraform configuration directory
- **Optional**: Previous successful state file for comparison

## Output

A troubleshooting report:

```
## SLZ Deployment Troubleshooting

**Error**: [error classification]
**Resource**: [terraform resource address]
**Azure Error Code**: [code]

### Root Cause
[Explanation of why the error occurred]

### Fix Applied
[What was done to fix it]

### Retry Result
| Attempt | Status | Detail |
|---------|--------|--------|
| 1 | ❌ Failed | Original error |
| 2 | ✅ Succeeded | After [fix description] |

### Remaining Issues
[Any issues that could not be resolved autonomously]
```

---
name: configure-sovereignty
description: 'Apply and manage sovereign controls for the landing zone — data residency policies, customer-managed keys, confidential computing, and encryption enforcement using the SLZ library.'
---

# Configure Sovereignty

## Purpose

Configure and manage the sovereign controls that differentiate a Sovereign Landing Zone from a standard Azure Landing Zone. This includes data residency enforcement through allowed locations policies, customer-managed key (CMK) requirements, encryption policies, and confidential computing controls. All sovereign controls are implemented through Azure Policy using the SLZ library (`platform/slz`) from the Azure Landing Zone Library.

## When to Use

- Configuring sovereign controls for a new SLZ deployment
- Adding or modifying data residency requirements (changing allowed regions)
- Enabling or updating CMK enforcement across resource types
- Enabling confidential computing policies for sensitive workloads
- Reviewing and updating sovereign control configurations after regulatory changes
- Generating policy exemptions for resources that legitimately need exceptions

## Instructions

1. **Identify sovereignty requirements**: Determine which controls are needed:

   | Control Category | Policy Effect | Description |
   |-----------------|---------------|-------------|
   | **Data Residency** | Deny | Restrict resource creation to approved Azure regions |
   | **CMK Enforcement** | Deny/Audit | Require customer-managed keys for encryption at rest |
   | **Encryption in Transit** | Deny | Enforce HTTPS/TLS for all data in transit |
   | **Encryption at Rest** | Deny/Audit | Ensure all data at rest is encrypted |
   | **Confidential Computing** | Deny/Audit | Require confidential VMs or containers for sensitive workloads |
   | **Key Management** | Audit | External key management (BYOK, DKE, HSM-backed) |
   | **Diagnostic Logging** | DeployIfNotExists | Ensure all resources log to central workspace |

2. **Configure the SLZ library reference**: The sovereignty controls come from the Azure Landing Zone Library's SLZ platform. Library references go in the **`alz` provider block**, not in the module:
   ```hcl
   # In providers.tf — library references go here, NOT in the module
   provider "alz" {
     library_references = [
       {
         path = "platform/alz"
         ref  = "2025.02.0"  # verify via get_latest_module_version
       },
       {
         path = "platform/slz"
         ref  = "2025.02.0"  # verify via get_latest_module_version
       },
     ]
   }
   ```

   The SLZ library assigns sovereign policies automatically:
   - `Enforce-Sovereign-Global` — assigned at the root MG (`slz`), enforces data residency and encryption globally
   - `Enforce-Sovereign-Conf` — assigned at `confidential_corp` and `confidential_online` MGs, enforces CMK and confidential computing

   **⚠️ Do NOT reference**: `Deny-Resource-Locations` or `Deny-RSG-Locations` — these policy names do not exist in the SLZ/ALZ library.

3. **Configure allowed locations** (data residency):
   ```hcl
   # In the avm-ptn-alz module configuration (.tf file)
   # Note: Value MUST be capitalized in jsonencode()
   policy_default_values = {
     allowed_locations          = jsonencode({ Value = var.allowed_locations })
     log_analytics_workspace_id = jsonencode({ Value = local.log_analytics_workspace_id })
   }
   ```

   **⚠️ CRITICAL — .tfvars files**: When setting `allowed_locations` in a `.tfvars` file, use **literal HCL values only**. Terraform functions like `jsonencode()`, `tolist()`, `toset()` are NOT allowed in `.tfvars` files — they cause `Error: Function calls not allowed`. Use:
   ```hcl
   # ✅ CORRECT (list literal in .tfvars)
   allowed_locations = ["swedencentral"]

   # ❌ WRONG (function call — .tfvars files don't support functions)
   allowed_locations = jsonencode(["swedencentral"])
   ```

   Key considerations:
   - Include paired regions for disaster recovery (e.g., westeurope + northeurope)
   - Include regions required by Azure services (some global services need specific regions)
   - Document justification for each allowed region

4. **Configure customer-managed keys** (CMK):
   - Decide CMK scope: all resources or specific resource types
   - Choose key storage: Azure Key Vault (standard), Managed HSM, or external HSM
   - Configure key rotation policy
   - Determine enforcement mode: Deny (block non-compliant) or Audit (monitor only)

5. **Configure confidential computing** (if required):
   - Define which management groups or subscriptions require confidential computing
   - Choose the enforcement level: VM-level, container-level, or both
   - Configure trusted launch requirements
   - Set up attestation policies

6. **Generate the sovereignty configuration**: Produce the `sovereignty.tf` file:
   ```hcl
   # Sovereign control configuration
   locals {
     sovereignty_config = {
       allowed_locations = var.allowed_locations
       
       cmk_enforcement = {
         enabled    = var.enable_cmk
         effect     = var.cmk_policy_effect  # "Deny" or "Audit"
         key_vault_id = var.cmk_key_vault_id
       }
       
       confidential_computing = {
         enabled = var.enable_confidential_computing
         effect  = var.confidential_computing_effect
       }
       
       encryption_in_transit = {
         enabled = true
         effect  = "Deny"
       }
     }
   }
   ```

7. **Configure policy exemptions**: For resources that legitimately need exceptions:
   - Document the business justification
   - Set an expiration date for the exemption
   - Use the narrowest scope possible (single resource, not resource group)
   - Require operator approval before creating exemptions

8. **Validate sovereign controls**: After configuration, verify:
   - Policy assignments are active at the correct scope
   - Deny policies actually block non-compliant resource creation
   - Audit policies correctly identify non-compliant resources
   - No conflicts between sovereign policies and workload requirements

## Input

- **Required**: Allowed Azure regions (data residency)
- **Required**: CMK enforcement level (enabled/disabled, deny/audit)
- **Optional**: Confidential computing requirements (defaults to disabled)
- **Optional**: Custom policy overrides for specific resource types
- **Optional**: Policy exemption requests with justification

## Output

A Terraform configuration file (`sovereignty.tf`) with sovereign control definitions, plus updates to `terraform.tfvars` with the sovereignty-specific variable values. Includes inline comments explaining each control and its regulatory justification.

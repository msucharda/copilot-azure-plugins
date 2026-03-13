---
name: generate-tfvars
description: 'Interactively generate terraform.tfvars files for the Sovereign Landing Zone from operator requirements, with validation and sensible defaults.'
---

# Generate Terraform Variables

## Purpose

Generate `terraform.tfvars` files for the Sovereign Landing Zone by interactively gathering requirements from the operator. Translates high-level design decisions (organization structure, sovereignty requirements, networking topology) into concrete Terraform variable values with validation and sensible defaults.

## When to Use

- Starting a new SLZ deployment and need to populate variable values
- Modifying an existing deployment's configuration
- Creating environment-specific variable files (dev.tfvars, staging.tfvars, prod.tfvars)
- Migrating from another landing zone implementation and need to map existing values
- After the Landing Zone Architect generates a scaffold that needs variable values

## Instructions

1. **Read the variables.tf file**: Parse the variable definitions to understand what values are needed:
   ```bash
   grep -A 5 'variable "' variables.tf
   ```
   
   Categorize variables into:
   - **Identity**: Organization name, subscription IDs, tenant ID
   - **Sovereignty**: Allowed locations, CMK configuration, confidential computing
   - **Networking**: CIDR ranges, topology, firewall SKU, DNS
   - **Management**: Log retention, capacity, automation
   - **Tagging**: Default tags, cost center, environment

2. **Gather identity values**:
   - Organization name (for naming conventions)
   - Azure tenant ID: `az account show --query tenantId -o tsv`
   - Management subscription ID
   - Connectivity subscription ID
   - Identity subscription ID (if separate)
   - Default Azure region

3. **Gather sovereignty values**:
   - Allowed Azure regions (data residency)
   - CMK enforcement: enabled/disabled, deny/audit effect
   - Key Vault ID for CMK (if using CMK)
   - Confidential computing: enabled/disabled
   - Log retention requirements (regulatory minimum)

4. **Gather networking values**:
   - Topology: hub-spoke or vWAN
   - Hub CIDR range (e.g., 10.0.0.0/16)
   - Firewall subnet prefix (e.g., 10.0.1.0/24)
   - Gateway subnet prefix (e.g., 10.0.2.0/24)
   - Spoke CIDR ranges
   - On-premises CIDR ranges (for conflict avoidance)
   - Firewall SKU tier: Standard or Premium
   - DNS configuration

5. **Apply sensible defaults**: For values the operator doesn't specify, apply these defaults:

   | Variable | Default | Rationale |
   |----------|---------|-----------|
   | `firewall_sku_tier` | "Standard" | Premium only needed for TLS inspection |
   | `log_retention_days` | 365 | Common sovereign requirement |
   | `hub_cidr` | "10.0.0.0/16" | Standard private range, room for growth |
   | `enable_cmk` | true | Sovereign default |
   | `cmk_policy_effect` | "Audit" | Start with audit, move to deny after validation |
   | `enable_confidential_computing` | false | Not commonly required |
   | `enable_bastion` | true | Secure remote access |
   | `enable_ddos_protection` | false | Cost-intensive, enable per requirement |

6. **Validate CIDR ranges**: Check for overlapping ranges:
   ```python
   # Pseudo-validation logic
   # hub_cidr must not overlap with spoke_cidrs
   # spoke_cidrs must not overlap with each other
   # No ranges should overlap with on_premises_cidrs
   # AzureFirewallSubnet must be within hub_cidr
   # GatewaySubnet must be within hub_cidr
   ```

7. **Generate the terraform.tfvars file**:
   ```hcl
   # ==============================================================================
   # Sovereign Landing Zone Configuration
   # Organization: {org_name}
   # Generated: {timestamp}
   # ==============================================================================

   # --- Identity ---
   org_name                  = "{org_name}"
   default_location          = "{location}"
   management_subscription_id = "{sub_id}"
   connectivity_subscription_id = "{sub_id}"
   identity_subscription_id    = "{sub_id}"

   # --- Sovereignty ---
   allowed_locations = ["{region1}", "{region2}"]
   enable_cmk        = {true/false}
   cmk_policy_effect = "{Deny/Audit}"
   enable_confidential_computing = {true/false}
   log_retention_days = {days}

   # --- Networking ---
   networking_topology  = "{hub-spoke/vwan}"
   hub_address_space    = "{cidr}"
   firewall_subnet_prefix = "{cidr}"
   gateway_subnet_prefix  = "{cidr}"
   firewall_sku_tier    = "{Standard/Premium}"

   # --- Tags ---
   tags = {
     Environment = "{env}"
     ManagedBy   = "Terraform-AVM"
     CostCenter  = "{cost_center}"
     Project     = "Sovereign Landing Zone"
   }
   ```

8. **Validate the generated file**: Run a quick validation:
   ```bash
   terraform validate
   terraform plan -var-file=terraform.tfvars
   ```

## Input

- **Required**: Organization name
- **Required**: Default Azure region
- **Required**: At least one subscription ID
- **Optional**: All other values (defaults will be applied)
- **Optional**: Existing terraform.tfvars to merge with

## Output

A `terraform.tfvars` file with all required variable values populated, commented with explanations, and validated against the `variables.tf` definitions. Includes a summary of defaults applied and values that the operator should review.

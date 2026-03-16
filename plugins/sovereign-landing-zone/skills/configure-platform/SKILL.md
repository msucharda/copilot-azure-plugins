---
name: configure-platform
description: 'Generate platform-landing-zone.tfvars configuration for the ALZ Accelerator with sovereignty controls, networking topology, and region settings.'
---

# Configure Platform

## Purpose

Generate the `platform-landing-zone.tfvars` configuration file required by the ALZ Accelerator's Terraform starter module. This file defines the Azure regions, networking topology, sovereignty controls, and security settings for the Platform Landing Zone deployment. It is used alongside `inputs.yaml` during the bootstrap and by the CI/CD pipeline for ongoing deployments.

## When to Use

- Configuring the platform landing zone as part of a new ALZ Accelerator bootstrap
- Updating regions, networking, or sovereignty settings for an existing deployment
- Migrating from a custom Terraform configuration to the ALZ Accelerator starter module
- Preparing for a new region expansion

## Instructions

1. **Gather region requirements**: Ask the operator for their Azure region selections:

   | Setting | Description | Example |
   |---------|-------------|---------|
   | `starter_locations` | Primary and secondary regions | `["uksouth", "ukwest"]` |
   | Management region | Where Log Analytics and automation deploy | `uksouth` |
   | Connectivity region | Where hub networking deploys | `uksouth` |

   For sovereign deployments, these regions must align with data residency policies (e.g., EU-only, UK-only).

2. **Configure security contact**:
   ```hcl
   defender_email_security_contact = "security@example.com"
   ```

3. **Configure networking topology**: Ask the operator:
   - **Hub-and-spoke** with Azure Firewall — simpler, single-region
   - **Virtual WAN** — multi-region, branch connectivity, transitive routing

   The starter module supports both topologies. The choice affects which connectivity resources are deployed.

4. **Configure sovereignty controls**: For Sovereign Landing Zones, configure:
   - **Allowed locations**: Regions permitted for resource deployment
   - **Customer-managed keys**: CMK enforcement level (Audit or Deny)
   - **Confidential computing**: VM and container encryption requirements
   - **Encryption in transit**: HTTPS/TLS enforcement

   These map to the SLZ library's policy sets (`platform/slz`) which the starter module references.

5. **Generate platform-landing-zone.tfvars**: Create the file with all collected values.

   **⚠️ CRITICAL**: `.tfvars` files do NOT support Terraform functions (`jsonencode()`, `tolist()`, `toset()`, `format()`, etc.). Use only **literal HCL values** — strings, numbers, booleans, lists, and maps. Violating this causes `Error: Function calls not allowed` at plan/apply time.

   ```hcl
   # ==============================================================================
   # Platform Landing Zone Configuration
   # Generated for ALZ Accelerator — Sovereign Landing Zone
   # ==============================================================================

   # --- Regions ---
   # IMPORTANT: Replace ALL <region-#> placeholders with valid Azure regions
   starter_locations = ["<primary-region>", "<secondary-region>"]

   # --- Security ---
   defender_email_security_contact = "<security-email>"

   # --- Networking ---
   # Topology is determined by the scenario chosen during bootstrap.
   # Customize CIDR ranges and firewall settings below.

   # --- Sovereignty (SLZ-specific) ---
   # These settings are applied through the SLZ library policy sets.
   # Uncomment and configure as needed for your sovereignty requirements.
   # NOTE: Use literal values only — NO function calls (jsonencode, etc.)

   # allowed_locations = ["swedencentral"]  # List literal (NOT jsonencode)
   # enable_cmk_enforcement = true
   # cmk_policy_effect = "Audit"  # or "Deny"
   # enable_confidential_computing = false
   ```

6. **Validate the configuration**: Before proceeding with bootstrap, verify:
   - All `<region-#>` placeholders are replaced with valid Azure region names
   - `defender_email_security_contact` is set to a real email
   - Allowed locations match the `starter_locations` regions
   - No conflicting settings (e.g., confidential computing in unsupported regions)

7. **Place the file**: Copy to `$targetFolderPath/config/platform-landing-zone.tfvars` for use by the bootstrap.

## Input

- **Required**: Primary and secondary Azure regions
- **Required**: Security contact email address
- **Required**: Networking topology choice (hub-spoke or vWAN)
- **Optional**: Sovereignty controls (allowed locations, CMK, confidential computing)
- **Optional**: Custom CIDR ranges for networking
- **Optional**: Additional starter module options (see https://azure.github.io/Azure-Landing-Zones/accelerator/starter-terraform/options/)

## Output

A `platform-landing-zone.tfvars` file with all required settings populated and validated, ready for use by the ALZ Accelerator bootstrap and CI/CD pipeline. Includes inline comments explaining each setting.

Reference: https://azure.github.io/Azure-Landing-Zones/accelerator/starter-terraform/

---
name: scaffold-landing-zone
description: 'Generate complete Azure Verified Module (AVM) based Terraform configurations for a new Sovereign Landing Zone deployment.'
---

# Scaffold Landing Zone

## Purpose

Generate a complete, production-ready Terraform project for deploying an Azure Sovereign Landing Zone using Azure Verified Modules. The scaffold includes all necessary files — providers, variables, module declarations, outputs, and documentation — configured for the operator's specific sovereignty requirements, organizational structure, and networking topology.

## When to Use

- Starting a new Sovereign Landing Zone deployment from scratch
- Migrating an existing landing zone to AVM-based Terraform modules
- Generating a reference architecture that the operator can customize before deployment
- Creating a staging/dev landing zone for testing before production deployment

## Instructions

1. **Gather requirements**: The following inputs are required before scaffolding:
   - **Organization name**: Used for naming conventions and resource prefixes
   - **Sovereignty requirements**: Allowed Azure regions, CMK enforcement, confidential computing
   - **Management group hierarchy**: Number of business units, environment tiers
   - **Networking topology**: Hub-spoke or vWAN, number of regions, CIDR ranges
   - **Backend configuration**: Azure Storage Account for Terraform state (or local for dev)
   - **Target subscription IDs**: Management, Connectivity, Identity subscriptions

2. **Generate the Terraform project structure**:
   ```
   {org}-sovereign-landing-zone/
   ├── main.tf                          # Root module orchestrating all child modules
   ├── variables.tf                     # All input variable definitions with descriptions
   ├── terraform.tfvars                 # Operator-specific values
   ├── outputs.tf                       # Key outputs (IDs, endpoints)
   ├── providers.tf                     # AzureRM provider + backend configuration
   ├── locals.tf                        # Computed values, naming conventions
   ├── management-groups.tf             # avm-ptn-alz module declaration
   ├── networking.tf                    # avm-ptn-alz-connectivity-hub-and-spoke-vnet or virtual-wan module
   ├── management.tf                    # avm-ptn-alz-management module
   ├── sovereignty.tf                   # SLZ library references and policy overrides
   ├── versions.tf                      # Required providers and version constraints
   └── README.md                        # Deployment guide with prerequisites
   ```

3. **Configure the AVM modules**:

   **Before generating any module declaration**, use the Terraform MCP tools to get current documentation:
   - Run `get_latest_module_version` for each module to get the current version
   - Run `get_module_details` for each module to get the current input schema, required variables, and examples
   - Do not rely on hardcoded HCL snippets — module interfaces change between versions

   **Management Groups (avm-ptn-alz)** — version below is a reference minimum; replace with the result of `get_latest_module_version`:
   ```hcl
   module "alz" {
     source  = "Azure/avm-ptn-alz/azurerm"
     version = "~> 0.11"  # verify via get_latest_module_version

     architecture_definition_name = "slz"
     location                     = var.default_location
     
     # SLZ library for sovereign policies
     library_references = {
       alz = {
         path = "platform/alz"
         ref  = "2025.02.0"
       }
       slz = {
         path    = "platform/slz"
         ref     = "2025.02.0"
         depends = ["alz"]
       }
     }
   }
   ```

   **Hub & Spoke Networking (avm-ptn-alz-connectivity-hub-and-spoke-vnet)** — verify version via `get_latest_module_version`:
   ```hcl
   module "hubnetworking" {
     source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
     version = "~> 0.8"  # verify via get_latest_module_version

     hub_virtual_networks = {
       primary = {
         name                = "vnet-hub-${var.default_location}"
         address_space       = [var.hub_cidr]
         location            = var.default_location
         resource_group_name = "rg-connectivity-${var.default_location}"
         
         firewall = {
           sku_name = "AZFW_VNet"
           sku_tier = var.firewall_sku_tier
         }
       }
     }
   }
   ```

   **Management (avm-ptn-alz-management)** — verify version via `get_latest_module_version`:
   ```hcl
   module "management" {
     source  = "Azure/avm-ptn-alz-management/azurerm"
     version = "~> 0.7"  # verify via get_latest_module_version

     location                       = var.default_location
     resource_group_name            = "rg-management-${var.default_location}"
     log_analytics_workspace_name   = "law-${var.org_name}-management"
     automation_account_name        = "aa-${var.org_name}-management"
   }
   ```

4. **Configure the Terraform backend**: Generate `providers.tf` with Azure Storage backend:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = var.backend_resource_group
       storage_account_name = var.backend_storage_account
       container_name       = "tfstate"
       key                  = "sovereign-landing-zone.tfstate"
     }
   }
   ```

5. **Generate README.md**: Include:
   - Prerequisites (Terraform version, Azure CLI, permissions)
   - Quick start deployment steps
   - Variable reference table
   - Architecture diagram description
   - Links to AVM module documentation

6. **Validate the scaffold**: Run `terraform validate` and `terraform fmt -check` to ensure the generated code is syntactically correct and properly formatted.

## Input

- **Required**: Organization name, default Azure region, sovereignty requirements
- **Required**: Networking topology choice (hub-spoke or vWAN)
- **Required**: Management group hierarchy design
- **Optional**: Backend storage account details (defaults to local state)
- **Optional**: CIDR ranges (defaults will be calculated if not provided)
- **Optional**: Target subscription IDs (can be added later)

## Output

A complete Terraform project directory with all files populated, validated, and ready for `terraform init && terraform plan`. The scaffold follows HashiCorp and AVM naming conventions, includes comprehensive variable descriptions, and is formatted with `terraform fmt`.

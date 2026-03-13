---
name: design-networking
description: 'Design hub-spoke or Virtual WAN networking topology for the Sovereign Landing Zone using avm-ptn-alz-connectivity-hub-and-spoke-vnet and avm-ptn-alz-connectivity-virtual-wan modules.'
---

# Design Networking

## Purpose

Design the networking topology for the Sovereign Landing Zone, supporting both hub-spoke with Azure Firewall and Virtual WAN (vWAN) patterns. This skill generates the Terraform configuration for the selected topology using AVM pattern modules, including IP address planning, firewall rules, DNS configuration, and connectivity to on-premises networks.

## When to Use

- Designing networking for a new Sovereign Landing Zone
- Adding a new regional hub or vWAN hub to an existing deployment
- Planning IP address allocation for new spoke VNets
- Configuring ExpressRoute or VPN connectivity
- Setting up Azure DNS Private Resolver

## Instructions

1. **Determine the topology**: Ask the operator about their connectivity requirements:

   **Virtual WAN** — Recommended when:
   - Multi-region deployment (2+ Azure regions)
   - Branch office connectivity (SD-WAN integration)
   - Multiple ExpressRoute circuits
   - Need for transitive routing between spokes across regions
   - Hub-to-hub connectivity across regions

   **Hub-Spoke with Azure Firewall** — Recommended when:
   - Single-region deployment
   - Simpler connectivity requirements
   - Need for granular firewall rule management
   - Cost sensitivity (vWAN has higher base cost)

2. **Plan IP address spaces**: Design non-overlapping CIDR ranges:

   **Hub-Spoke Example**:
   | Component | CIDR | Purpose |
   |-----------|------|---------|
   | Hub VNet | 10.0.0.0/16 | Central hub |
   | AzureFirewallSubnet | 10.0.1.0/24 | Azure Firewall (minimum /26) |
   | GatewaySubnet | 10.0.2.0/24 | VPN/ER Gateway (minimum /27) |
   | AzureBastionSubnet | 10.0.3.0/24 | Bastion Host |
   | DNSResolverInbound | 10.0.4.0/28 | DNS Private Resolver inbound |
   | DNSResolverOutbound | 10.0.4.16/28 | DNS Private Resolver outbound |
   | Corp Spoke 1 | 10.1.0.0/16 | First workload |
   | Corp Spoke 2 | 10.2.0.0/16 | Second workload |
   | On-premises | 172.16.0.0/12 | On-prem networks (no overlap!) |

   **vWAN Example**:
   | Component | CIDR | Purpose |
   |-----------|------|---------|
   | vWAN Hub (Region 1) | 10.0.0.0/23 | vWAN hub address prefix |
   | vWAN Hub (Region 2) | 10.0.2.0/23 | vWAN hub address prefix |
   | Spoke VNet 1 | 10.1.0.0/16 | Workload in Region 1 |
   | Spoke VNet 2 | 10.2.0.0/16 | Workload in Region 2 |

3. **Configure the networking module**:

   **For Hub-Spoke** — Use `avm-ptn-alz-connectivity-hub-and-spoke-vnet`:
   ```hcl
   module "hubnetworking" {
     source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
     version = "~> 0.8"

     hub_virtual_networks = {
       primary = {
         name                = "vnet-hub-${var.primary_location}"
         address_space       = [var.hub_address_space]
         location            = var.primary_location
         resource_group_name = "rg-connectivity-${var.primary_location}"

         firewall = {
           sku_name                = "AZFW_VNet"
           sku_tier                = "Standard"  # or "Premium" for TLS inspection
           subnet_address_prefix   = var.firewall_subnet_prefix
           default_ip_configuration = {
             public_ip_config = { name = "pip-fw-${var.primary_location}" }
           }
         }

         subnets = {
           GatewaySubnet = { address_prefixes = [var.gateway_subnet_prefix] }
           AzureBastionSubnet = { address_prefixes = [var.bastion_subnet_prefix] }
         }
       }
     }
   }
   ```

   **For vWAN** — Use `avm-ptn-alz-connectivity-virtual-wan`:
   ```hcl
   module "vwan" {
     source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm"
     version = "~> 0.8"

     resource_group_name         = "rg-connectivity-vwan"
     location                    = var.primary_location
     virtual_wan_name            = "vwan-${var.org_name}"
     allow_branch_to_branch_traffic = true

     virtual_hubs = {
       primary = {
         name           = "vhub-${var.primary_location}"
         location       = var.primary_location
         address_prefix = var.vwan_hub_primary_prefix
         
         firewall = {
           name     = "fw-vhub-${var.primary_location}"
           sku_name = "AZFW_Hub"
           sku_tier = "Standard"
         }
       }
     }
   }
   ```

4. **Configure DNS**: Plan DNS resolution strategy:
   - Azure Private DNS zones for PaaS services (privatelink.*)
   - Azure DNS Private Resolver for hybrid DNS resolution
   - Conditional forwarding to on-premises DNS servers

5. **Configure connectivity**: Plan on-premises and cross-region connectivity:
   - ExpressRoute circuits and connections
   - VPN Gateway connections (site-to-site, point-to-site)
   - VNet peering (hub-spoke) or vWAN spoke connections

6. **Validate IP addressing**: Verify no CIDR range conflicts exist between:
   - Hub and spoke VNets
   - On-premises networks
   - Other Azure regions
   - Reserved Azure ranges (169.254.0.0/16, 168.63.129.16/32)

## Input

- **Required**: Topology choice (hub-spoke or vWAN)
- **Required**: Primary Azure region
- **Required**: Hub/vWAN CIDR ranges
- **Optional**: Secondary region for multi-region (defaults to single region)
- **Optional**: On-premises CIDR ranges (for conflict detection)
- **Optional**: ExpressRoute/VPN configuration
- **Optional**: DNS configuration preferences

## Output

A Terraform configuration file (`networking.tf`) containing the networking module declaration with complete topology definition, IP addressing, firewall configuration, and DNS setup. Includes commented sections for optional components (VPN, ExpressRoute, Bastion) that the operator can enable as needed.

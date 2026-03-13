---
name: design-management-groups
description: 'Interactively design the management group hierarchy for a Sovereign Landing Zone using the avm-ptn-alz module and Azure Landing Zone Library.'
---

# Design Management Groups

## Purpose

Design the management group hierarchy that forms the governance backbone of the Sovereign Landing Zone. The hierarchy determines policy scope, RBAC inheritance, and subscription organization. This skill uses the `avm-ptn-alz` module with the Azure Landing Zone Library (`platform/slz`) to create a hierarchy with sovereign controls baked in.

## When to Use

- Designing a new Sovereign Landing Zone management group structure
- Modifying an existing hierarchy to add business units or environment tiers
- Migrating from a manually-created hierarchy to Terraform-managed
- Adding sovereign policy sets to an existing ALZ hierarchy

## Instructions

1. **Start with the CAF reference architecture**: The Cloud Adoption Framework recommends this baseline hierarchy:
   ```
   Tenant Root Group
   └── {Organization}
       ├── Platform
       │   ├── Management          → Log Analytics, Automation, Monitoring
       │   ├── Connectivity        → Hub networking, DNS, ExpressRoute
       │   └── Identity            → Domain Controllers, Entra Connect
       ├── Landing Zones
       │   ├── Corp                → Internal workloads (connected to hub)
       │   └── Online              → Internet-facing workloads (DMZ)
       ├── Sandbox                 → Dev/test (relaxed policies)
       └── Decommissioned          → Retired subscriptions
   ```

2. **Customize for the organization**: Ask the operator:
   - Do you need separate management groups per business unit under Landing Zones?
   - Do you need environment tiers (Dev/Test/Staging/Prod) as management groups?
   - Are there regulatory boundaries requiring separate hierarchies (e.g., PCI, HIPAA)?
   - Do you need a Confidential management group for confidential computing workloads?

3. **Configure the avm-ptn-alz module**: The module uses architecture definitions from the Azure Landing Zone Library. The SLZ architecture definition (`slz`) extends the base `alz` definition with sovereign controls.

   Key configuration decisions:
   - **Architecture definition**: Use `slz` for sovereign landing zones
   - **Library references**: Include both `platform/alz` (base) and `platform/slz` (sovereign)
   - **Policy defaults overrides**: Customize allowed locations, CMK requirements
   - **Subscription placement**: Map existing subscriptions to management groups
   - **Custom archetypes**: Add organization-specific management group types if needed

4. **Map subscriptions to management groups**: For each subscription, determine placement:
   - Management subscription → Platform/Management
   - Connectivity subscription → Platform/Connectivity
   - Identity subscription → Platform/Identity
   - Workload subscriptions → Landing Zones/Corp or Landing Zones/Online

5. **Configure policy assignments**: The SLZ library provides policy sets for:
   - Allowed locations (data residency enforcement)
   - Customer-managed keys (CMK enforcement)
   - Encryption requirements (at-rest and in-transit)
   - Confidential computing (if enabled)
   - Diagnostic settings (centralized logging)
   - Network security (NSG requirements, no public IPs)

6. **Generate the Terraform configuration**: Produce the `management-groups.tf` file with the complete `avm-ptn-alz` module declaration including all management groups, policy assignments, and subscription placements.

7. **Validate**: Run `terraform validate` on the generated configuration. Check that management group names follow naming conventions and don't conflict with existing groups.

## Input

- **Required**: Organization name
- **Required**: Sovereignty requirements (allowed regions, CMK, confidential computing)
- **Optional**: Custom management group hierarchy (defaults to CAF reference)
- **Optional**: Existing subscription IDs for placement
- **Optional**: Custom policy overrides

## Output

A Terraform configuration file (`management-groups.tf`) containing the complete `avm-ptn-alz` module declaration with:
- Management group hierarchy definition
- SLZ library references
- Policy assignment configurations
- Subscription placements
- Policy defaults overrides for sovereign controls

Additionally, a text-based hierarchy diagram for the operator to review before deployment.

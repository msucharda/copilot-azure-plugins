---
name: deploy-management
description: 'Deploy and configure the management and monitoring layer of the Sovereign Landing Zone using avm-ptn-alz-management for Log Analytics, data collection rules, and automation.'
---

# Deploy Management

## Purpose

Configure and deploy the management and monitoring infrastructure for the Sovereign Landing Zone. This includes the centralized Log Analytics workspace, data collection rules (DCRs), automation accounts, and Azure Monitor configuration. These components provide the observability foundation that all workloads in the landing zone depend on.

## When to Use

- Deploying the management layer as part of a new SLZ
- Updating Log Analytics workspace configuration (retention, capacity reservation)
- Adding or modifying data collection rules for new log sources
- Configuring Azure Monitor alerts for landing zone health
- Setting up automation accounts for operational tasks
- Integrating with Microsoft Sentinel for security monitoring

## Instructions

1. **Determine management requirements**: Ask the operator about:
   - Log retention period (default 90 days, sovereign requirements may mandate 365+ days)
   - Capacity reservation tier (commitment tiers reduce cost for predictable log volumes)
   - Which log sources to collect (Activity Logs, VM metrics, network flow logs, security events)
   - Whether Microsoft Sentinel is needed (SIEM/SOAR for security operations)
   - Automation requirements (runbooks, DSC configurations, update management)

2. **Configure the avm-ptn-alz-management module**:
   ```hcl
   module "management" {
     source  = "Azure/avm-ptn-alz-management/azurerm"
     version = "~> 0.7"

     location                           = var.default_location
     resource_group_name                = "rg-management-${var.default_location}"
     log_analytics_workspace_name       = "law-${var.org_name}-management"
     automation_account_name            = "aa-${var.org_name}-management"

     # Retention configuration
     log_analytics_workspace_retention_in_days = var.log_retention_days  # 90-730

     # Capacity reservation (optional, for cost optimization)
     log_analytics_workspace_daily_quota_gb = var.log_daily_quota_gb

     # Data collection rules
     data_collection_rules = {
       vm_insights = {
         name        = "dcr-vm-insights"
         description = "Data collection rule for VM Insights"
         data_flows = [{
           streams      = ["Microsoft-InsightsMetrics", "Microsoft-ServiceMap"]
           destinations = ["log-analytics"]
         }]
       }
       
       change_tracking = {
         name        = "dcr-change-tracking"
         description = "Data collection rule for Change Tracking"
         data_flows = [{
           streams      = ["Microsoft-ConfigurationChange"]
           destinations = ["log-analytics"]
         }]
       }
     }

     tags = var.tags
   }
   ```

3. **Configure Activity Log diagnostics**: Ensure all subscriptions send Activity Logs to the central workspace. This is typically handled by the avm-ptn-alz module through a DeployIfNotExists policy assignment, ensuring all new subscriptions automatically forward logs.

4. **Configure Azure Monitor alerts** (recommended):
   - Service Health alerts for Azure region issues
   - Resource Health alerts for landing zone components
   - Policy compliance alerts for sovereign control violations
   - Budget alerts for cost management

5. **Configure Sentinel** (if required):
   - Enable Microsoft Sentinel on the Log Analytics workspace
   - Configure data connectors for Azure AD, Azure Activity, Azure Security Center
   - Set up analytics rules for common threat detection
   - Note: Sentinel configuration may require additional Terraform resources beyond the management module

6. **Validate management deployment**: After deployment, verify:
   ```bash
   # Check Log Analytics workspace
   az monitor log-analytics workspace show \
     --workspace-name "law-${org}-management" \
     --resource-group "rg-management-${location}" \
     --query "{name:name, retentionDays:retentionInDays, sku:sku.name}" -o table
   
   # Check data collection rules
   az monitor data-collection rule list \
     --resource-group "rg-management-${location}" \
     --query "[].{name:name, provisioningState:provisioningState}" -o table
   
   # Check automation account
   az automation account show \
     --name "aa-${org}-management" \
     --resource-group "rg-management-${location}" \
     --query "{name:name, state:state}" -o table
   ```

## Input

- **Required**: Organization name and Azure region
- **Required**: Log retention period (days)
- **Optional**: Capacity reservation tier
- **Optional**: Sentinel enablement (defaults to disabled)
- **Optional**: Custom data collection rules
- **Optional**: Automation runbooks to deploy

## Output

A Terraform configuration file (`management.tf`) containing the complete `avm-ptn-alz-management` module declaration with Log Analytics, DCRs, automation, and monitoring configuration. Includes output values for the workspace ID and automation account ID for use by other modules.

#!/bin/bash
# SLZ Safety Guard — preToolUse hook for Sovereign Landing Zone plugin
# Inspects shell commands for dangerous Terraform and Azure operations before execution.
set -e
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')

# Only inspect shell/bash tool invocations
if [ "$TOOL_NAME" != "bash" ] && [ "$TOOL_NAME" != "shell" ]; then
  exit 0
fi

TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs')
COMMAND=$(echo "$TOOL_ARGS" | jq -r '.command // empty')
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block: terraform destroy without explicit -target (full destroy)
if echo "$COMMAND" | grep -qE 'terraform\s+destroy' && ! echo "$COMMAND" | grep -qE '\-target'; then
  jq -n '{permissionDecision:"deny",permissionDecisionReason:"BLOCKED: Full terraform destroy will tear down the entire landing zone. Use -target to destroy specific resources, or confirm this is intentional by using the troubleshoot-deployment skill with explicit destroy scope."}'
  exit 0
fi

# Block: deleting management groups via Azure CLI
if echo "$COMMAND" | grep -qE 'az\s+account\s+management-group\s+delete'; then
  jq -n '{permissionDecision:"deny",permissionDecisionReason:"BLOCKED: Deleting management groups can orphan subscriptions and break policy inheritance. Use Terraform to manage management group lifecycle instead."}'
  exit 0
fi

# Block: terraform state rm without backup
if echo "$COMMAND" | grep -qE 'terraform\s+state\s+rm' && ! echo "$COMMAND" | grep -qE 'backup|state\s+pull'; then
  jq -n '{permissionDecision:"deny",permissionDecisionReason:"BLOCKED: Removing resources from Terraform state without a backup is dangerous. Run terraform state pull > backup.tfstate first."}'
  exit 0
fi

# Warn: terraform apply on production-scoped resources
if echo "$COMMAND" | grep -qE 'terraform\s+apply' && echo "$COMMAND" | grep -qiE 'prod'; then
  echo "WARNING: Terraform apply targeting production scope detected. Verify the plan output carefully before proceeding." >&2
fi

# Warn: terraform apply without explicit plan file
if echo "$COMMAND" | grep -qE 'terraform\s+apply' && ! echo "$COMMAND" | grep -qE '\.tfplan|\.out|-auto-approve'; then
  echo "WARNING: Running terraform apply without a saved plan file. Consider running terraform plan -out=tfplan first, then terraform apply tfplan." >&2
fi

# Warn: policy assignment changes
if echo "$COMMAND" | grep -qE 'az\s+policy\s+assignment\s+(create|delete|update)'; then
  echo "WARNING: Policy assignment changes can affect all resources under the scope. Verify the assignment scope and effect before proceeding." >&2
fi

# Warn: CIDR or address space changes
if echo "$COMMAND" | grep -qE 'terraform\s+(apply|plan)' && echo "$COMMAND" | grep -qiE 'address.?space|cidr|vnet|virtual.?network|vwan'; then
  echo "WARNING: Network address space changes detected. Verify no IP conflicts or connectivity disruptions will occur." >&2
fi

# Warn: terraform force-unlock
if echo "$COMMAND" | grep -qE 'terraform\s+force-unlock'; then
  echo "WARNING: Force-unlocking Terraform state can cause corruption if another process is actively writing. Verify no other operations are running." >&2
fi

# Warn: terraform import (state manipulation)
if echo "$COMMAND" | grep -qE 'terraform\s+import'; then
  echo "WARNING: Terraform import adds existing resources to state. Verify the resource address matches the configuration exactly." >&2
fi

# Allow by default
exit 0

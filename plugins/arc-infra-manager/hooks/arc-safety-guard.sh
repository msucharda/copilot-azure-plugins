#!/bin/bash
# Arc Safety Guard — preToolUse hook for Arc Infrastructure Manager
# Inspects shell commands for dangerous Arc operations before execution.
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

# Block: deleting Arc server resources
if echo "$COMMAND" | grep -qE 'az\s+connectedmachine\s+delete'; then
  jq -n '{permissionDecision:"deny",permissionDecisionReason:"BLOCKED: Deleting Arc server resources removes them from Azure management permanently. Use azcmagent disconnect on the server instead."}'
  exit 0
fi

# Block: bulk extension removal (wildcard or --yes on delete without specific target)
if echo "$COMMAND" | grep -qE 'connectedmachine\s+extension\s+delete.*(\*|--no-wait.*--yes)'; then
  jq -n '{permissionDecision:"deny",permissionDecisionReason:"BLOCKED: Bulk extension removal is not permitted. Specify individual servers and extensions explicitly."}'
  exit 0
fi

# Warn: remote command execution
if echo "$COMMAND" | grep -qE 'connectedmachine\s+run-command\s+create'; then
  echo "WARNING: Run Command executes scripts remotely on the target server. Review the script content carefully." >&2
fi

# Warn: installing patches (may reboot)
if echo "$COMMAND" | grep -qE 'connectedmachine\s+install-patches'; then
  echo "WARNING: Installing updates may require a server reboot and could cause service interruption. Verify the maintenance window." >&2
fi

# Warn: extension install on production-tagged resources
if echo "$COMMAND" | grep -qE 'connectedmachine\s+extension\s+create' && echo "$COMMAND" | grep -qiE 'prod'; then
  echo "WARNING: Extension installation targeting production resources detected. Test on a non-production server first." >&2
fi

# Warn: operations mentioning multiple servers (batch scope)
if echo "$COMMAND" | grep -qE 'connectedmachine.*(--resource-group|--subscription)' && echo "$COMMAND" | grep -qvE '(--machine-name|-n\s)'; then
  echo "WARNING: This command targets an entire resource group or subscription scope. Verify this is intentional." >&2
fi

# Allow by default
exit 0

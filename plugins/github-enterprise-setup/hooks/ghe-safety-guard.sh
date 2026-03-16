#!/usr/bin/env bash
set -euo pipefail

# GHE.com Safety Guard — pre-tool-use hook
# Intercepts potentially destructive enterprise operations

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs // empty')

decision="allow"
reason=""

if [[ "$TOOL_NAME" == "bash" || "$TOOL_NAME" == "shell" ]]; then
  CMD=$(echo "$TOOL_ARGS" | jq -r '.command // empty')

  # DENY checks first — once denied, never downgraded

  # BLOCK: Enterprise deletion
  if echo "$CMD" | grep -qE 'gh api.*DELETE.*/enterprises/'; then
    decision="deny"
    reason="BLOCKED: Deleting enterprise-level resources is not allowed via automation. Use the GitHub web UI with proper authorization."
  fi

  # BLOCK: Organization deletion
  if [[ "$decision" != "deny" ]] && echo "$CMD" | grep -qE 'gh api.*DELETE.*/orgs/'; then
    decision="deny"
    reason="BLOCKED: Organization deletion is irreversible. Use the GitHub web UI for this operation."
  fi

  # BLOCK: Repository deletion
  if [[ "$decision" != "deny" ]] && echo "$CMD" | grep -qE 'gh api.*-X DELETE.*/repos/[^/]+/[^/]+\b'; then
    decision="deny"
    reason="BLOCKED: Repository deletion is irreversible. Use the GitHub web UI for this operation."
  fi

  # WARN checks — only if not already denied

  # WARN: Team deletion
  if [[ "$decision" != "deny" ]] && echo "$CMD" | grep -qE 'gh api.*DELETE.*/teams/'; then
    reason="WARNING: Deleting a team will remove all its members and repository access. Verify this is intentional."
  fi

  # WARN: Repository transfer
  if [[ "$decision" != "deny" ]] && echo "$CMD" | grep -qE 'gh api.*PATCH.*/repos/.*/transfer'; then
    reason="WARNING: Repository transfer detected. Verify the target is correct."
  fi

  # WARN: PAT revocation (could lock out setup user)
  if [[ "$decision" != "deny" ]] && echo "$CMD" | grep -qE 'gh api.*DELETE.*/personal-access-tokens/'; then
    reason="WARNING: Revoking a PAT may lock out the setup user if it's the SCIM provisioning token. Verify this is not the enterprise setup PAT."
  fi

  # WARN: Changing enterprise action policies
  if [[ "$decision" != "deny" ]] && echo "$CMD" | grep -qE 'gh api.*(PUT|PATCH).*/actions/permissions'; then
    reason="WARNING: Changing action permissions may break existing CI/CD workflows. Review the change carefully."
  fi
fi

echo "{\"permissionDecision\": \"$decision\", \"permissionDecisionReason\": \"$reason\"}"

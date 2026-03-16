#!/usr/bin/env bats

# Tests for SLZ Safety Guard hook script
# SLZ hook format: DENY = JSON stdout + exit 0, ALLOW = no stdout + exit 0, WARN = stderr + exit 0

HOOK="./plugins/sovereign-landing-zone/hooks/slz-safety-guard.sh"

# Helper: get stdout from hook
run_hook() {
  echo "$1" | bash "$HOOK" 2>/dev/null
}

# Helper: get stderr from hook
run_hook_stderr() {
  echo "$1" | bash "$HOOK" 2>&1 1>/dev/null
}

# Helper: get decision from JSON stdout (empty if allowed)
get_decision() {
  local output
  output=$(echo "$1" | bash "$HOOK" 2>/dev/null)
  if [ -z "$output" ]; then
    echo "allow"
  else
    echo "$output" | jq -r '.permissionDecision'
  fi
}

# === DENY tests ===

@test "DENY: terraform destroy without -target" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"terraform destroy"}}')
  [ "$result" = "deny" ]
}

@test "DENY: terraform destroy -auto-approve (no -target)" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"terraform destroy -auto-approve"}}')
  [ "$result" = "deny" ]
}

@test "DENY: az management-group delete" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"az account management-group delete --name contoso"}}')
  [ "$result" = "deny" ]
}

@test "DENY: terraform state rm without backup" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"terraform state rm module.alz"}}')
  [ "$result" = "deny" ]
}

# === ALLOW tests ===

@test "ALLOW: terraform destroy with -target" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"terraform destroy -target=module.foo"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: terraform plan" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"terraform plan"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: terraform init" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"terraform init"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: terraform validate" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"terraform validate"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: non-bash tool" {
  result=$(get_decision '{"toolName":"read","toolArgs":{"path":"main.tf"}}')
  [ "$result" = "allow" ]
}

# === WARN tests (stderr warnings, still allowed) ===

@test "WARN: terraform apply without plan file produces stderr warning" {
  stderr=$(run_hook_stderr '{"toolName":"bash","toolArgs":{"command":"terraform apply"}}')
  [[ "$stderr" == *"WARNING"* ]]
}

@test "WARN: terraform force-unlock produces stderr warning" {
  stderr=$(run_hook_stderr '{"toolName":"bash","toolArgs":{"command":"terraform force-unlock abc123"}}')
  [[ "$stderr" == *"WARNING"* ]]
}

@test "WARN: terraform import produces stderr warning" {
  stderr=$(run_hook_stderr '{"toolName":"bash","toolArgs":{"command":"terraform import module.alz /subscriptions/123"}}')
  [[ "$stderr" == *"WARNING"* ]]
}

# === DENY output format ===

@test "DENY OUTPUT: returns valid JSON with permissionDecision" {
  output=$(run_hook '{"toolName":"bash","toolArgs":{"command":"terraform destroy"}}')
  echo "$output" | jq -e '.permissionDecision' >/dev/null 2>&1
}

@test "DENY OUTPUT: returns valid JSON with permissionDecisionReason" {
  output=$(run_hook '{"toolName":"bash","toolArgs":{"command":"terraform destroy"}}')
  echo "$output" | jq -e '.permissionDecisionReason' >/dev/null 2>&1
}

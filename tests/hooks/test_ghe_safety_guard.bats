#!/usr/bin/env bats

# Tests for GHE Safety Guard hook script
# Each test pipes JSON input and verifies the decision output

HOOK="./plugins/github-enterprise-setup/hooks/ghe-safety-guard.sh"

# Helper functions
run_hook() {
  echo "$1" | bash "$HOOK"
}

get_decision() {
  echo "$1" | bash "$HOOK" | jq -r '.permissionDecision'
}

get_reason() {
  echo "$1" | bash "$HOOK" | jq -r '.permissionDecisionReason'
}

# === DENY: Enterprise deletion ===

@test "DENY: enterprise resource deletion" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /enterprises/acme/settings"}}')
  [ "$result" = "deny" ]
}

@test "DENY: enterprise DELETE with --hostname" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /enterprises/acme --hostname foo.ghe.com"}}')
  [ "$result" = "deny" ]
}

# === DENY: Organization deletion (exact path) ===

@test "DENY: org deletion" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /orgs/acme --hostname foo.ghe.com"}}')
  [ "$result" = "deny" ]
}

@test "DENY: org deletion without hostname" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /orgs/myorg"}}')
  [ "$result" = "deny" ]
}

# === DENY: Repository deletion (exact path, no sub-resources) ===

@test "DENY: repo deletion" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /repos/acme/demo"}}')
  [ "$result" = "deny" ]
}

@test "DENY: repo deletion with hostname flag" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /repos/acme/demo --hostname foo.ghe.com"}}')
  [ "$result" = "deny" ]
}

# === ALLOW: Sub-resource operations (NOT repo/org deletion) ===

@test "ALLOW: branch deletion (sub-resource of repo)" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /repos/acme/demo/git/refs/heads/feature"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: issue comment deletion (sub-resource)" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /repos/acme/demo/issues/comments/123"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: team deletion via org path (not org deletion)" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /orgs/acme/teams/devs"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: GET request to org endpoint" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api /orgs/acme"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: non-bash tool" {
  result=$(get_decision '{"toolName":"read","toolArgs":{"path":"config.yaml"}}')
  [ "$result" = "allow" ]
}

@test "ALLOW: gh api GET (no DELETE)" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api --hostname foo.ghe.com /enterprises/acme"}}')
  [ "$result" = "allow" ]
}

# === WARN: Team deletion ===

@test "WARN: team deletion has warning reason" {
  reason=$(get_reason '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /orgs/acme/teams/devs"}}')
  [[ "$reason" == *"WARNING"* ]]
}

# === WARN: PAT revocation ===

@test "WARN: PAT revocation has warning" {
  reason=$(get_reason '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /orgs/acme/personal-access-tokens/123"}}')
  [[ "$reason" == *"WARNING"* ]]
}

# === WARN: Action policy changes ===

@test "WARN: action permissions change has warning" {
  reason=$(get_reason '{"toolName":"bash","toolArgs":{"command":"gh api -X PUT /enterprises/acme/actions/permissions --hostname foo.ghe.com"}}')
  [[ "$reason" == *"WARNING"* ]]
}

# === DENY priority: deny cannot be overridden by later warn ===

@test "DENY PRIORITY: org delete stays denied even if action policy in same command" {
  result=$(get_decision '{"toolName":"bash","toolArgs":{"command":"gh api -X DELETE /orgs/acme && gh api -X PUT /enterprises/acme/actions/permissions"}}')
  [ "$result" = "deny" ]
}

# === Output format ===

@test "OUTPUT: returns valid JSON" {
  output=$(run_hook '{"toolName":"bash","toolArgs":{"command":"echo hello"}}')
  echo "$output" | jq . >/dev/null 2>&1
}

@test "OUTPUT: has required fields" {
  output=$(run_hook '{"toolName":"bash","toolArgs":{"command":"echo hello"}}')
  echo "$output" | jq -e '.permissionDecision' >/dev/null 2>&1
  echo "$output" | jq -e '.permissionDecisionReason' >/dev/null 2>&1
}

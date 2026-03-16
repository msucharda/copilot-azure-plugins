# SLZ Plugin Content Evals
# Each assertion maps to a real deployment issue discovered in session f374727b or later fixes.

# --- Management Group IDs (session f374727b turn 2) ---
assert_contains "sovereign-landing-zone" "skills/design-management-groups/SKILL.md" \
  "slz" "Root MG must use SLZ library ID 'slz', not org-prefixed"

assert_contains "sovereign-landing-zone" "skills/design-management-groups/SKILL.md" \
  "confidential_corp" "SLZ includes confidential_corp MG"

# The skill warns AGAINST contoso- prefixed IDs — verify the warning exists
assert_contains "sovereign-landing-zone" "skills/design-management-groups/SKILL.md" \
  "do not use custom prefixed" "Must warn against org-prefixed MG IDs (session f374727b)"

# --- Policy Names (session f374727b turn 2) ---
assert_contains "sovereign-landing-zone" "skills/design-management-groups/SKILL.md" \
  "Enforce-Sovereign-Global" "Correct SLZ root policy name"

assert_contains "sovereign-landing-zone" "skills/configure-sovereignty/SKILL.md" \
  "Enforce-Sovereign-Conf" "Correct SLZ confidential policy name"

# The skill warns AGAINST these non-existent policies — verify warnings exist
assert_contains "sovereign-landing-zone" "skills/design-management-groups/SKILL.md" \
  "Do NOT use" "Must warn against non-existent policy names (session f374727b)"

assert_contains "sovereign-landing-zone" "skills/configure-sovereignty/SKILL.md" \
  "Do NOT reference" "Must warn against non-existent policy names"

# --- policy_default_values (session f374727b turn 2) ---
assert_contains "sovereign-landing-zone" "skills/scaffold-landing-zone/SKILL.md" \
  "policy_default_values" "Must pass policy_default_values with log_analytics_workspace_id"

assert_contains "sovereign-landing-zone" "skills/scaffold-landing-zone/SKILL.md" \
  "log_analytics_workspace_id" "Monitoring policies need workspace ID"

# --- policy_assignments_dependencies (session f374727b turn 2) ---
# The skill contains the correct arg AND a comment warning against the wrong one
assert_contains "sovereign-landing-zone" "skills/scaffold-landing-zone/SKILL.md" \
  "policy_assignments_dependencies" "Correct dependency arg (NOT management_groups_dependencies)"

# --- jsonencode in tfvars (session f374727b turn 10) ---
assert_contains "sovereign-landing-zone" "skills/scaffold-landing-zone/SKILL.md" \
  "literal HCL values" "Must warn about no functions in .tfvars files"

assert_contains "sovereign-landing-zone" "skills/configure-platform/SKILL.md" \
  "Function calls not allowed" "Must warn about tfvars function restriction"

assert_contains "sovereign-landing-zone" "skills/troubleshoot-deployment/SKILL.md" \
  "Function calls not allowed" "Must have error pattern for tfvars function calls"

# --- AVM Module Names (official ALZ docs) ---
assert_contains "sovereign-landing-zone" "skills/scaffold-landing-zone/SKILL.md" \
  "avm-ptn-alz" "Must reference correct ALZ pattern module"

assert_contains "sovereign-landing-zone" "skills/design-networking/SKILL.md" \
  "avm-ptn-alz-connectivity" "Must use correct connectivity module name"

assert_not_contains "sovereign-landing-zone" "skills/design-networking/SKILL.md" \
  "avm-ptn-hubnetworking" "Wrong module name — use avm-ptn-alz-connectivity-hub-and-spoke-vnet"

assert_not_contains "sovereign-landing-zone" "skills/design-networking/SKILL.md" \
  "avm-ptn-virtualwan" "Wrong module name — use avm-ptn-alz-connectivity-virtual-wan"

# --- GHE.com support (v1.5.0) ---
assert_contains "sovereign-landing-zone" "skills/check-prerequisites/SKILL.md" \
  "ghe.com" "Must document GHE.com support"

assert_contains "sovereign-landing-zone" "skills/troubleshoot-deployment/SKILL.md" \
  "ghe.com" "Must have GHE.com error patterns"

# --- Bootstrap (v1.2.0+) ---
assert_contains "sovereign-landing-zone" "skills/bootstrap-accelerator/SKILL.md" \
  "Deploy-Accelerator" "Must document the Deploy-Accelerator PowerShell command"

assert_contains "sovereign-landing-zone" "skills/bootstrap-accelerator/SKILL.md" \
  "starterAdditionalFiles" "Must use -starterAdditionalFiles param"

# --- Token security (v1.4.0) ---
assert_contains "sovereign-landing-zone" "skills/bootstrap-accelerator/SKILL.md" \
  "scrub" "Must document token scrubbing after bootstrap"

assert_contains "sovereign-landing-zone" "skills/check-prerequisites/SKILL.md" \
  "classic PAT" "Must recommend classic PATs over fine-grained"

# --- Agent naming convention (v2.2.0) ---
assert_contains "sovereign-landing-zone" "agents/landing-zone-architect.md" \
  "slz-" "Agent name must have slz- prefix"

assert_contains "sovereign-landing-zone" "agents/terraform-operator.md" \
  "slz-" "Agent name must have slz- prefix"

# GHE Plugin Content Evals
# Each assertion maps to a real issue discovered in session 9d7f1338 or 694590cf.

# --- OIDC Setup (session 9d7f1338 turn 6) ---
assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "Enable SSO" "OIDC uses built-in 'Enable SSO' button, not manual app registration"

assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "do NOT need to manually create" "OIDC path must clarify auto-registration via Enable SSO button"

# --- 2FA Required (session 9d7f1338 turn 4, official docs) ---
assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "2FA" "Must document 2FA requirement for setup user"

assert_contains "github-enterprise-setup" "agents/enterprise-setup-operator.md" \
  "required" "2FA must be described as required (per official docs)"

# --- SCIM UI (session 9d7f1338 turn 9) ---
assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "Add new configuration" "Current Entra ID uses '+ Add new configuration' for SCIM"

# --- Entra App Names (session 9d7f1338 turn 8) ---
assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "GitHub Enterprise Managed User (OIDC)" "Must specify exact OIDC app name in Entra ID"

assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "GitHub Enterprise Managed User" "Must specify SAML app name (non-OIDC)"

# --- Billing Prerequisites (session 694590cf, session 9d7f1338) ---
assert_contains "github-enterprise-setup" "agents/enterprise-setup-operator.md" \
  "billing address" "Must document billing address required before Azure subscription link"

assert_contains "github-enterprise-setup" "agents/enterprise-setup-operator.md" \
  "shipping" "Must document shipping address required"

assert_contains "github-enterprise-setup" "skills/check-ghe-prerequisites/SKILL.md" \
  "Owner role" "Must require Azure subscription Owner (not just Tenant GA)"

# --- EMU Limitations (discovered during session) ---
assert_contains "github-enterprise-setup" "skills/configure-organizations/SKILL.md" \
  "fork" "Must document EMU cannot fork from github.com"

assert_contains "github-enterprise-setup" "skills/configure-organizations/SKILL.md" \
  "No public repos" "Must document no public repos on GHE.com"

assert_contains "github-enterprise-setup" "skills/configure-organizations/SKILL.md" \
  "gist" "Must document no gists on GHE.com"

# --- GHE.com URL Format ---
assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "api.<enterprise>.ghe.com" "Must use correct GHE.com API URL format"

assert_not_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "api.github.com" "Must NOT reference api.github.com for GHE.com operations"

# --- PAT for SCIM ---
assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "scim:enterprise" "SCIM PAT must have scim:enterprise scope"

assert_contains "github-enterprise-setup" "skills/configure-emu/SKILL.md" \
  "No expiration" "SCIM PAT must have no expiration"

# --- github.com account for trial (session 9d7f1338 turn 2) ---
assert_contains "github-enterprise-setup" "skills/check-ghe-prerequisites/SKILL.md" \
  "personal account" "Must document github.com personal account needed for trial signup"

# --- Agent naming convention ---
assert_contains "github-enterprise-setup" "agents/enterprise-setup-operator.md" \
  "ghe-" "Agent name must have ghe- prefix"

assert_contains "github-enterprise-setup" "agents/platform-admin.md" \
  "ghe-" "Agent name must have ghe- prefix"

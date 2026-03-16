---
name: validate-enterprise
description: 'Post-setup validation for GHE.com — verify EMU authentication, API access, action workflows, organization structure, security policies, and billing.'
---

# Validate GHE.com Enterprise

## Purpose

Comprehensive post-setup validation of a GHE.com instance. Run after initial setup or after major configuration changes to verify everything works correctly.

## When to Use

- After initial GHE.com enterprise setup to confirm all components are working
- After major configuration changes (security policies, action policies, org changes)
- As a periodic health check of the enterprise configuration
- Before onboarding users to verify readiness

## Instructions

1. **Verify API access**:

   ```bash
   # Test enterprise API access
   gh api --hostname <enterprise>.ghe.com /user --jq '.login'

   # Test enterprise endpoint
   gh api --hostname <enterprise>.ghe.com \
     /enterprises/<enterprise> \
     --jq '{name, slug, created_at}'
   ```

2. **Verify EMU authentication**:

   ```bash
   # List provisioned users
   gh api --hostname <enterprise>.ghe.com \
     /enterprises/<enterprise>/members --paginate \
     --jq '.[].login' | head -10

   # Check SCIM provisioning status
   gh api --hostname <enterprise>.ghe.com \
     /scim/v2/enterprises/<enterprise>/Users \
     --jq '.totalResults'
   ```

3. **Verify organizations**:

   ```bash
   # List all organizations in the enterprise
   gh api --hostname <enterprise>.ghe.com \
     /enterprises/<enterprise>/organizations --paginate \
     --jq '.[].login'
   ```

4. **Verify action policies**:

   ```bash
   # Check action permissions
   gh api --hostname <enterprise>.ghe.com \
     /enterprises/<enterprise>/actions/permissions \
     --jq '{enabled_organizations, allowed_actions}'

   # Check allowed action patterns
   gh api --hostname <enterprise>.ghe.com \
     /enterprises/<enterprise>/actions/permissions/selected-actions \
     --jq '.'
   ```

5. **Test a workflow run** — create a minimal test workflow in a repo and run it:

   ```yaml
   name: GHE.com Smoke Test
   on: workflow_dispatch
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - run: echo "GHE.com actions working!"
         - uses: hashicorp/setup-terraform@v3
         - run: terraform version
   ```

   This validates: runner availability, `actions/checkout` access, `hashicorp/setup-terraform` access, and internet egress from runners.

6. **Verify security policies**:

   ```bash
   # Check GHAS status for an org
   gh api --hostname <enterprise>.ghe.com \
     /orgs/<org-name> \
     --jq '{advanced_security: .plan.name, secret_scanning: .security_and_analysis.secret_scanning.status}'
   ```

7. **Produce validation report**:

   ```
   ## GHE.com Enterprise Validation Report

   ### API Access
   | Check | Status | Detail |
   |-------|--------|--------|
   | Enterprise API | ✅/❌ | <enterprise>.ghe.com |
   | Authenticated user | ✅/❌ | [username] |

   ### EMU
   | Check | Status | Detail |
   |-------|--------|--------|
   | SCIM users provisioned | ✅/❌ | [count] users |
   | Setup user accessible | ✅/❌ | [username]_admin |

   ### Organizations
   | Check | Status | Detail |
   |-------|--------|--------|
   | Orgs created | ✅/❌ | [count] orgs |
   | Teams configured | ✅/❌ | [count] teams |

   ### Actions
   | Check | Status | Detail |
   |-------|--------|--------|
   | Actions enabled | ✅/❌ | [policy] |
   | Required namespaces allowed | ✅/❌ | actions/*, hashicorp/* |
   | Test workflow passed | ✅/❌ | [result] |

   ### Security
   | Check | Status | Detail |
   |-------|--------|--------|
   | GHAS enabled | ✅/❌ | [status] |
   | Secret scanning | ✅/❌ | [status] |
   | Branch protection | ✅/❌ | [repos protected] |

   ### Recommendation
   ✅ Enterprise ready for use.
   ❌ [N] checks failed. Fix items above.
   ```

## Input

- Enterprise subdomain
- Expected org names
- Expected team count

## Output

- Comprehensive validation report showing pass/fail for each area

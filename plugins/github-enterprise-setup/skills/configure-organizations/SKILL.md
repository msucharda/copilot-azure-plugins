---
name: configure-organizations
description: 'Create and configure organizations on GHE.com — org creation via API, team structure, default permissions, and repository policies.'
---

# Configure Organizations

## Purpose

Create the organizational structure on GHE.com for enterprise teams. For IaC/platform teams deploying Azure Landing Zones, this typically includes a platform org (for IaC repos) and workload-specific orgs.

## When to Use

- After GHE.com enterprise and EMU setup is complete
- When onboarding new teams or business units to the enterprise
- When restructuring the org/team hierarchy

## Instructions

1. **Create organizations** via the GHE.com API:
   ```bash
   # Create a new organization
   gh api --hostname <enterprise>.ghe.com \
     -X POST /admin/organizations \
     -f login="platform-team" \
     -f admin="<setup_user>" \
     -f profile_name="Platform Team"
   ```
   Recommended org structure for landing zone deployments:
   - `platform-team` — IaC repos (alz-mgmt, landing zone configs)
   - `security-team` — Security policies, scanning configs
   - Workload orgs as needed per business unit

2. **Configure default repository permissions**: For each org:
   ```bash
   gh api --hostname <enterprise>.ghe.com \
     -X PATCH /orgs/<org-name> \
     -f default_repository_permission="read" \
     -f members_can_create_repositories=false \
     -f members_can_create_public_repositories=false
   ```
   Note: On GHE.com with EMU, public repos are NOT available.

3. **Create teams** linked to IdP groups:
   ```bash
   gh api --hostname <enterprise>.ghe.com \
     -X POST /orgs/<org-name>/teams \
     -f name="platform-admins" \
     -f description="Platform team administrators" \
     -f privacy="closed"
   ```
   Teams should map to IdP groups configured during EMU setup (see configure-emu).

4. **Set repository access per team**:
   ```bash
   gh api --hostname <enterprise>.ghe.com \
     -X PUT /orgs/<org-name>/teams/<team-slug>/repos/<org-name>/<repo-name> \
     -f permission="push"
   ```

5. **Configure org-level policies**:
   - Fork policy: Disabled (enterprise repos should not be forked externally)
   - Base permissions: Read (least privilege)
   - Repository creation: Restricted to admins

## Input

- Enterprise subdomain
- Org names
- Team structure
- IdP group mappings

## Output

- Organizations created with teams, permissions, and policies configured

---
name: configure-actions
description: 'Configure GitHub Actions policies for GHE.com — allow-list external action namespaces, set up runner groups, verify egress connectivity, and handle namespace retirement.'
---

# Configure GitHub Actions

## Purpose

Configure GitHub Actions on a GHE.com instance. Since GitHub Marketplace is NOT available on GHE.com, actions must be explicitly allow-listed from github.com repositories. This skill ensures IaC workflows (particularly Azure Landing Zone deployments) have the actions they need.

## When to Use

- After GHE.com enterprise provisioning is complete
- When setting up CI/CD pipelines for IaC or application repos
- When adding new external action dependencies to workflows
- When troubleshooting action access or runner connectivity issues

## Instructions

1. **Allow-list action namespaces**: Via the GHE.com API:
   ```bash
   # Set enterprise action policy to allow select actions
   gh api --hostname <enterprise>.ghe.com \
     -X PUT /enterprises/<enterprise>/actions/permissions \
     -f allowed_actions=selected

   # Allow specific action patterns
   gh api --hostname <enterprise>.ghe.com \
     -X PUT /enterprises/<enterprise>/actions/permissions/selected-actions \
     -f github_owned_allowed=true \
     -f patterns_allowed='["hashicorp/*", "azure/*"]'
   ```
   Required namespaces for ALZ Accelerator workflows:
   - `actions/*` (covered by `github_owned_allowed=true`)
   - `hashicorp/*` (setup-terraform)
   - `azure/*` (Azure login, deployment actions)

2. **Configure runner groups**: For GitHub-hosted runners (default):
   - Linux and Windows runners are available; macOS is NOT available on GHE.com
   - Verify egress connectivity from runners to: `releases.hashicorp.com`, `registry.terraform.io`, `management.azure.com`, `*.blob.core.windows.net`, `github.com`

   For self-hosted runners (if GitHub-hosted won't work):
   ```bash
   # Create a runner group
   gh api --hostname <enterprise>.ghe.com \
     -X POST /enterprises/<enterprise>/actions/runner-groups \
     -f name="terraform-runners" \
     -f visibility="selected"
   ```

3. **Handle namespace retirement**: When a github.com action is used for the first time, its namespace is retired in the enterprise. If someone already created a matching org name on GHE.com, it conflicts. Fix: Enterprise settings → Policies → Actions → Retired namespaces → Release the namespace.
   Reference: https://docs.github.com/en/enterprise-cloud@latest/actions/administering-github-actions/making-retired-namespaces-available-on-ghecom

4. **Validate action access**:
   ```bash
   # Test that a required action is accessible
   gh api --hostname <enterprise>.ghe.com \
     /enterprises/<enterprise>/actions/permissions/selected-actions
   ```

## Input

- Enterprise subdomain
- List of required action namespaces
- Runner type preference (GitHub-hosted or self-hosted)

## Output

- Actions configured and validated
- Runner groups created if needed
- Namespace conflicts resolved

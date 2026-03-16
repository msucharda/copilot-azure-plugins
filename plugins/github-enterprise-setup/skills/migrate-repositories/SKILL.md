---
name: migrate-repositories
description: 'Migrate repositories to GHE.com using GitHub Enterprise Importer — supports migration from github.com, GitHub Enterprise Server, Azure DevOps, and Bitbucket Server.'
---

# Migrate Repositories to GHE.com

## Purpose

Execute repository migrations to GHE.com using GitHub Enterprise Importer (GEI). This supports migration from github.com, GitHub Enterprise Server, Azure DevOps, and Bitbucket Server. Migration includes source code, pull requests, issues, and metadata.

## When to Use

- Migrating repositories from github.com, GHES, Azure DevOps, or Bitbucket Server to GHE.com
- Performing bulk repository migrations using generated scripts
- Verifying post-migration integrity of repos, PRs, and issues

## Instructions

1. **Install GH GEI extension**:

   ```bash
   gh extension install github/gh-gei
   ```

2. **Prepare migration tokens**:

   - **Source PAT** (e.g., for github.com): needs `repo`, `admin:org`, `workflow` scopes
   - **Target PAT** (for GHE.com): needs `repo`, `admin:org`, `workflow` scopes. Create at `https://<enterprise>.ghe.com/settings/tokens/new`

   ```bash
   export GH_PAT="<target-ghe-pat>"
   export GH_SOURCE_PAT="<source-pat>"
   ```

3. **Pre-migration inventory** — generate a migration script:

   ```bash
   gh gei generate-script \
     --github-source-org <source-org> \
     --github-target-org <target-org> \
     --target-api-url https://api.<enterprise>.ghe.com \
     --output migration-script.sh
   ```

   Review the generated script — it lists all repos to be migrated. Remove any repos you don't want to migrate.

4. **Execute migration**:

   ```bash
   # Single repo migration
   gh gei migrate-repo \
     --github-source-org <source-org> \
     --source-repo <repo-name> \
     --github-target-org <target-org> \
     --target-repo <repo-name> \
     --target-api-url https://api.<enterprise>.ghe.com \
     --verbose

   # Or run the generated script for bulk migration
   chmod +x migration-script.sh
   ./migration-script.sh
   ```

   Note: The `--target-api-url` parameter is **required** for GHE.com migrations. Without it, the tool targets github.com.

5. **Post-migration verification**:

   ```bash
   # List repos in the target org
   gh api --hostname <enterprise>.ghe.com \
     /orgs/<target-org>/repos --paginate \
     --jq '.[].full_name'

   # Verify a specific repo
   gh api --hostname <enterprise>.ghe.com \
     /repos/<target-org>/<repo-name> \
     --jq '{name, default_branch, size, pushed_at}'
   ```

   Check: all repos present, default branches correct, recent push dates match source, PR history preserved.

6. **Reconfigure CI/CD** — after migration, update GitHub Actions workflows:

   - Verify action references resolve (see configure-actions)
   - Update any hardcoded github.com URLs to GHE.com equivalents
   - Re-configure repository secrets and variables
   - Test a workflow run to confirm functionality

### Migration Source Options

| Source | Tool | Key Flag |
|--------|------|----------|
| github.com | `gh gei migrate-repo` | `--target-api-url https://api.<enterprise>.ghe.com` |
| GHES | `gh gei migrate-repo` | `--ghes-api-url https://<ghes>/api/v3` + `--target-api-url` |
| Azure DevOps | `gh gei migrate-repo` | `--ado-source-org` + `--target-api-url` |
| Bitbucket Server | `gh bbs2gh migrate-repo` | `--bbs-server-url` + `--target-api-url` |

## Input

- Source platform
- Source org/repos
- Target org on GHE.com
- PATs for both source and target

## Output

- Repositories migrated to GHE.com with history, PRs, and issues preserved
- CI/CD reconfigured

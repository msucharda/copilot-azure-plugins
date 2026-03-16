---
name: configure-security
description: 'Configure security features for GHE.com — GitHub Advanced Security, secret scanning, code scanning, Dependabot, branch protection, and audit log streaming.'
---

# Configure Security for GHE.com

## Purpose

Harden the GHE.com instance with security best practices. For sovereign/regulated environments, security configuration is critical — this skill covers GitHub Advanced Security (GHAS), secret scanning, code scanning, branch protection for IaC repos, and audit log streaming.

## When to Use

- Setting up a new GHE.com enterprise and need to enable security features
- Hardening an existing enterprise with GHAS, secret scanning, or code scanning
- Configuring branch protection rules for infrastructure-as-code repositories
- Setting up audit log streaming to Azure or other destinations

## Instructions

1. **Enable GitHub Advanced Security** at enterprise level:

   Enterprise settings → Code security → GitHub Advanced Security → Enable for all organizations.

   Alternatively, per-org: Org settings → Code security and analysis → Enable GHAS.

2. **Configure secret scanning + push protection**:

   ```bash
   # Enable secret scanning for an org
   gh api --hostname <enterprise>.ghe.com \
     -X PATCH /orgs/<org-name> \
     -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}'
   ```

   Push protection blocks commits containing known secret patterns (API keys, tokens, connection strings). Critical for IaC repos that may contain Azure credentials.

3. **Configure code scanning with CodeQL**:

   Create a default CodeQL workflow for all repos:

   ```yaml
   # .github/workflows/codeql.yml
   name: CodeQL Analysis
   on:
     push:
       branches: [main]
     pull_request:
       branches: [main]
   jobs:
     analyze:
       runs-on: ubuntu-latest
       permissions:
         security-events: write
       steps:
         - uses: actions/checkout@v4
         - uses: github/codeql-action/init@v3
           with:
             languages: javascript, python
         - uses: github/codeql-action/analyze@v3
   ```

   Note: `github/codeql-action` must be allow-listed in action policies (see configure-actions). The `github/*` namespace should be covered by `github_owned_allowed=true`.

4. **Configure Dependabot alerts and security updates**:

   ```bash
   gh api --hostname <enterprise>.ghe.com \
     -X PATCH /orgs/<org-name> \
     -f security_and_analysis='{"dependabot_security_updates":{"status":"enabled"}}'
   ```

5. **Set up branch protection for IaC repos**:

   ```bash
   gh api --hostname <enterprise>.ghe.com \
     -X PUT /repos/<org>/<repo>/branches/main/protection \
     -f required_status_checks='{"strict":true,"contexts":["Terraform Plan"]}' \
     -f enforce_admins=true \
     -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
     -f restrictions=null
   ```

   For ALZ repos: require Terraform plan status check, 1+ approving review, dismiss stale reviews on new commits.

6. **Configure audit log streaming**:

   Enterprise settings → Audit log → Log streaming → Set up a stream.

   Supported destinations: Azure Blob Storage, Azure Event Hubs, Amazon S3, Datadog, Splunk, Google Cloud Storage.

   For Azure sovereign environments, use Azure Event Hubs or Azure Blob Storage to keep audit data within your data residency boundary.

   Note: S3 streaming with OIDC is NOT available on GHE.com.

## Input

- Enterprise subdomain
- Org names
- Security policy requirements
- Audit log destination

## Output

- GHAS enabled
- Secret scanning + push protection active
- CodeQL configured
- Branch protection on IaC repos
- Audit log streaming configured

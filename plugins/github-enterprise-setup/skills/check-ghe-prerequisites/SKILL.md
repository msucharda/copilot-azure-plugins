---
name: check-ghe-prerequisites
description: 'Verify all prerequisites for GHE.com setup — identity provider readiness, billing access, network connectivity, and required tooling.'
---

# Check GHE Prerequisites

## Purpose

Validate that all prerequisites for GitHub Enterprise Cloud with data residency are met before starting the setup process. This prevents failed provisioning and wasted trial time.

## When to Use

- Before starting a new GHE.com enterprise provisioning
- When onboarding a new team to an existing GHE.com instance
- When troubleshooting a failed GHE.com setup

## Instructions

1. Verify `gh` CLI is installed and meets the minimum version requirement:
   ```bash
   gh --version
   ```
   Must be >= 2.40. Install from: https://cli.github.com/

2. Determine IdP choice and readiness:
   - **Entra ID** (recommended): Verify tenant access, check if OIDC or SAML. OIDC is recommended for Conditional Access Policy support. If multiple enterprises from one tenant: the first can use SAML or OIDC, but each additional enterprise must use SAML.
   - **Okta**: SAML only. Verify Okta admin access and SCIM support.
   - **PingFederate**: SAML only. Verify admin access.

3. Verify Azure billing prerequisites (if paying via Azure subscription): Admin access to Azure portal or admin consent workflow configured.
   Reference: https://docs.github.com/en/enterprise-cloud@latest/billing/managing-the-plan-for-your-github-account/connecting-an-azure-subscription#prerequisites

4. Verify network requirements: Client systems must trust GitHub SSH fingerprints and access GHE.com hostnames.
   Reference: https://docs.github.com/en/enterprise-cloud@latest/admin/data-residency/network-details-for-ghecom

5. Choose data residency region: EU, US, Australia, or Japan.

6. Choose enterprise subdomain: `<name>.ghe.com` — **cannot be changed after creation**.

## Input

- Target data residency region
- Preferred identity provider (Entra ID, Okta, or PingFederate)
- Azure subscription details (if using Azure billing)

## Output

- Prerequisites report table (Tool | Required | Status | Detail)
- IdP decision (OIDC vs SAML)
- Region and subdomain selections

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

1. **Verify a github.com personal account exists**: A personal account on **github.com** is required to initiate the GHE.com trial/signup at [github.com/account/enterprises/new](https://github.com/account/enterprises/new). This account is only used to start the signup — it does NOT become part of the GHE.com enterprise. After provisioning, a separate setup user is created on the `<enterprise>.ghe.com` domain.

2. Verify `gh` CLI is installed and meets the minimum version requirement:
   ```bash
   gh --version
   ```
   Must be >= 2.40. Install from: https://cli.github.com/

3. Determine IdP choice and readiness:
   - **Entra ID** (recommended): Verify tenant access, check if OIDC or SAML. OIDC is recommended for Conditional Access Policy support. If multiple enterprises from one tenant: the first can use SAML or OIDC, but each additional enterprise must use SAML.
   - **Okta**: SAML only. Verify Okta admin access and SCIM support.
   - **PingFederate**: SAML only. Verify admin access.

4. Verify Azure billing prerequisites (if paying via Azure subscription):
   - **Owner role on the Azure subscription** — this is an Azure RBAC role, NOT an Entra ID role. Entra ID Global Administrator does NOT automatically grant Azure subscription Owner. These are separate permission planes.
     ```bash
     # Check if you have Owner on the target subscription
     az role assignment list --subscription "<sub-id>" --assignee "$(az ad signed-in-user show --query id -o tsv)" --query "[?roleDefinitionName=='Owner']" -o table
     ```
     If missing, an existing Owner must grant it: `az role assignment create --assignee "<user>" --role "Owner" --scope "/subscriptions/<sub-id>"`
   - **Cloud Application Administrator** (or Global Admin) in Entra ID — required to grant admin consent when GitHub's billing app requests tenant access
   - **Billing address and shipping address** must be filled in on GHE.com BEFORE the "Add Azure Subscription" option appears (Enterprise settings → Billing & Licensing → Payment information)
   - **Note**: The "Metered billing via Azure" option is at the **very bottom** of the Payment information page. If not visible after filling addresses, common reasons: existing contract/agreement, wrong account level (must be Enterprise, not personal), insufficient permissions (must be enterprise owner), or not on GitHub Enterprise Cloud plan.
   Reference: https://docs.github.com/en/enterprise-cloud@latest/billing/managing-the-plan-for-your-github-account/connecting-an-azure-subscription#prerequisites

5. Verify network requirements: Client systems must trust GitHub SSH fingerprints and access GHE.com hostnames.
   Reference: https://docs.github.com/en/enterprise-cloud@latest/admin/data-residency/network-details-for-ghecom

6. Choose data residency region: EU, US, Australia, or Japan.

7. Choose enterprise subdomain: `<name>.ghe.com` — **⚠️ cannot be changed after creation**. Double-check spelling.

## Input

- Target data residency region
- Preferred identity provider (Entra ID, Okta, or PingFederate)
- Azure subscription details (if using Azure billing)

## Output

- Prerequisites report table (Tool | Required | Status | Detail)
- IdP decision (OIDC vs SAML)
- Region and subdomain selections

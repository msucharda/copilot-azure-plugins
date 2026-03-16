---
name: configure-emu
description: 'Guide enterprise admins through Enterprise Managed Users (EMU) setup — setup user creation, IdP authentication (OIDC/SAML), SCIM provisioning, and team synchronization.'
---

# Configure Enterprise Managed Users

## Purpose

Configure Enterprise Managed Users for the GHE.com instance. EMU is the only identity management option on GHE.com — no personal accounts are supported.

## When to Use

- After a GHE.com enterprise has been provisioned
- When setting up identity management for a new enterprise
- When changing IdP configuration or adding SCIM provisioning

## Instructions

1. **Setup user creation**: After enterprise provisioning, the admin receives an email invitation. Sign in with the randomly generated `<shortcode>_admin` username using an incognito window. Set password, enable 2FA, save recovery codes. **Store credentials in company password manager** — this user is needed for IdP changes.

2. **Create SCIM PAT**: While signed in as the setup user, create a personal access token (classic) at `https://<enterprise>.ghe.com/settings/tokens/new`. Scope: `scim:enterprise`. Expiration: **No expiration** (required for SCIM provisioning).

3. **Configure authentication** — choose based on IdP:
   - **Entra ID with OIDC** (recommended): Enterprise settings → Authentication security → Configure OIDC. Register GitHub EMU app in Entra ID, configure tenant ID and client credentials. Supports Conditional Access Policies.
   - **Entra ID with SAML**: Enterprise settings → Authentication security → Configure SAML. Register app, configure SSO URL, certificate, entity ID.
   - **Okta with SAML**: Install GitHub EMU app from Okta Integration Network, configure SAML with enterprise SSO URL.
   - **PingFederate with SAML**: Configure SP connection in PingFederate admin console.

   Reference: https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/getting-started-with-enterprise-managed-users

4. **Configure SCIM provisioning**: Set up SCIM in your IdP using the PAT created in step 2. This creates managed user accounts automatically. Test by assigning a user in IdP and verifying account creation on GHE.com.
   Reference: https://docs.github.com/en/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/configuring-scim-provisioning-for-enterprise-managed-users

5. **Set up team sync**: Map IdP groups to GitHub teams for automatic membership management. Enterprise settings → Teams → Create team → Link to IdP group.
   Reference: https://docs.github.com/en/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/managing-team-memberships-with-identity-provider-groups

## Input

- IdP type (Entra ID, Okta, or PingFederate)
- Enterprise subdomain
- Admin email

## Output

- Configured EMU with authenticated users
- SCIM provisioning active
- Teams synced with IdP groups

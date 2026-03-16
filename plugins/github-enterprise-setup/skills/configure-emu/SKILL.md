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

1. **Setup user creation**: After enterprise provisioning, the admin receives an email invitation. Sign in with the randomly generated `<shortcode>_admin` username using an **incognito/private browsing window**. Set password and save recovery codes. **Store credentials in company password manager** — this is a break-glass account needed for IdP changes and emergencies.

   **2FA**: Enable 2FA on the setup user as part of the initial setup. The official GitHub docs list this as a required step. The setup user is a break-glass account that persists after SSO — subsequent logins require the 2FA challenge. Without 2FA, a compromised password gives full enterprise admin access.

2. **Create SCIM PAT**: While signed in as the setup user, create a personal access token (**classic**, not fine-grained) at `https://<enterprise>.ghe.com/settings/tokens/new`:
   - **Scope**: `scim:enterprise`
   - **Expiration**: **No expiration** (required for SCIM provisioning to work continuously)
   - Save this token securely — you'll need it when configuring SCIM in your IdP

3. **Configure authentication** — choose based on IdP:

   **Entra ID with OIDC** (recommended — supports Conditional Access Policies):
   1. On GHE.com: Enterprise settings → Authentication security → Click **"Enable SSO" → "OIDC auth"**
   2. This redirects to Entra ID and **automatically registers** the GitHub EMU app — you do NOT need to manually create an Enterprise Application
   3. Sign in to your Entra ID tenant and grant admin consent when prompted
   4. The OIDC connection is configured automatically upon successful consent

   **Entra ID with SAML** (required for 2nd+ enterprise from same tenant):
   - Enterprise settings → Authentication security → Configure SAML
   - In Entra ID: manually create Enterprise Application → search for **"GitHub Enterprise Managed User"** (without "OIDC")
   - Configure SSO URL, certificate, and entity ID

   **Okta with SAML**:
   - Install **"GitHub Enterprise Managed User"** app from Okta Integration Network
   - Configure SAML with enterprise SSO URL from GHE.com

   **PingFederate with SAML**:
   - Configure SP connection in PingFederate admin console with GHE.com SSO metadata

   Reference: https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/getting-started-with-enterprise-managed-users

4. **Configure SCIM provisioning**: In your IdP, set up automatic user provisioning:

   **For Entra ID (OIDC path)**:
   1. In [entra.microsoft.com](https://entra.microsoft.com) → Enterprise applications → find the **"GitHub Enterprise Managed User (OIDC)"** app (created automatically in step 3)
   2. Go to **Provisioning → + Add new configuration**
   3. Set mode to **Automatic**
   4. Enter:
      - **Tenant URL**: `https://api.<enterprise>.ghe.com/scim/v2/enterprises/<enterprise>`
      - **Secret Token**: the PAT from step 2
   5. Click **Test Connection** — must succeed ✅
   6. Save, then set **Provisioning Status** to **On**
   7. **Assign users/groups**: App → Users and groups → + Add user/group → select Entra ID users or groups
   8. Provisioning starts within ~40 minutes, or use **Provision on demand** for immediate testing

   **For Entra ID (SAML path)**:
   1. In [entra.microsoft.com](https://entra.microsoft.com) → Enterprise applications → find the **"GitHub Enterprise Managed User"** app (non-OIDC — manually registered in step 3)
   2. Follow the same provisioning steps as above (Provisioning → + Add new configuration → Automatic → Tenant URL + Secret Token)

   **For Okta/PingFederate**:
   - Configure SCIM 2.0 provisioning in the app settings
   - Use the same Tenant URL and Secret Token as above

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

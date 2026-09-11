# Portier SSO for roam-panel

roam-panel supports optional SSO via [Portier](https://github.com/javimosch/portier),
an OAuth/OIDC broker. When enabled, users get a "Login with portier" button for
one-click login through GitHub, Google, or any OIDC provider — instead of the
email magic-link flow.

SSO is **opt-in and disabled by default**. Self-hosters with no interest in SSO
see zero difference — the login page shows only the email form.

## Prerequisites

- A running Portier instance (self-hosted or use `portier.intrane.fr`)
- At least one identity provider configured in Portier (GitHub, Google, machin-idp, or generic OIDC)

## Setup

### 1. Register your app in Portier

```bash
curl -X POST https://your-portier.example.com/v1/apps \
  -H "Content-Type: application/json" \
  -d '{
    "name": "roam-panel",
    "redirect_uris": "https://panel.example.com/auth/portier"
  }'
```

Save the `app_id` and `app_secret` from the response — the secret is shown only once.

### 2. Add an identity provider

Choose a provider and configure it in Portier:

**GitHub:**
```bash
curl -X POST https://your-portier.example.com/v1/apps/provider \
  -H "Authorization: Bearer <app_secret>" \
  -H "Content-Type: application/json" \
  -d '{"name":"github","kind":"github","client_id":"<github-oauth-client-id>","client_secret":"<github-oauth-client-secret>"}'
```

**Google:**
```bash
curl -X POST https://your-portier.example.com/v1/apps/provider \
  -H "Authorization: Bearer <app_secret>" \
  -H "Content-Type: application/json" \
  -d '{"name":"google","kind":"google","client_id":"<google-oauth-client-id>","client_secret":"<google-oauth-client-secret>"}'
```

**Generic OIDC (e.g., machin-idp, Keycloak, Authentik):**
```bash
curl -X POST https://your-portier.example.com/v1/apps/provider \
  -H "Authorization: Bearer <app_secret>" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-idp","kind":"oidc","client_id":"<client_id>","client_secret":"<client_secret>","authorize_url":"https://idp.example.com/authorize","token_url":"https://idp.example.com/token","userinfo_url":"https://idp.example.com/userinfo","scope":"openid email profile"}'
```

The IdP's redirect URI should be `https://your-portier.example.com/cb/<provider_name>`.

### 3. (Optional) Set an email allowlist

Restrict who can log in by setting a per-app allowlist in Portier:

```bash
curl -X POST https://your-portier.example.com/v1/apps/allowlist \
  -H "Authorization: Bearer <app_secret>" \
  -H "Content-Type: application/json" \
  -d '{"allowlist":"you@example.com,@yourcompany.com"}'
```

Entries can be exact emails (`you@example.com`) or domain patterns (`@yourcompany.com`).
Empty string clears the allowlist (allow everyone).

### 4. Configure roam-panel

Set these environment variables in your roam-panel env file:

```bash
PORTIER_URL=https://your-portier.example.com
PORTIER_APP_ID=app_xxxxxxxxxxxx
PORTIER_APP_SECRET=psk_xxxxxxxxxxxxxxxxxxxxxxxx
PORTIER_PROVIDER=github
```

`PORTIER_PROVIDER` is the provider name you configured in step 2
(`github`, `google`, `my-idp`, etc.).

All four variables must be set. If any is missing, SSO is disabled and the
login page shows only the email magic-link form.

### 5. Restart roam-panel

```bash
sudo systemctl restart roam-panel
```

The login page should now show a "Login with portier" button alongside the
email form.

## How it works

1. User clicks "Login with portier" → redirect to `portier/auth/<app_id>/<provider>`
2. Portier brokers the OAuth dance with the IdP (GitHub, Google, etc.)
3. Browser redirects back to `panel/auth/portier?code=pc_...&state=...`
4. roam-panel verifies the state, exchanges the code for a verified email
5. roam-panel creates or finds the account by email → sets session cookie

The same account infrastructure as magic-link is used — no schema changes.
A user who signed up via magic-link can later use SSO with the same email,
and vice versa.

## Security

- **State is HMAC-signed** with a 10-minute window (CSRF protection)
- **Redirect URI exact-match** (open-redirect guard)
- **Portier codes are one-time**, 5-minute TTL, redeemable only with the app secret
- **Email allowlist** (optional) restricts who can complete login
- **No passwords stored** — roam-panel only stores the email-derived account

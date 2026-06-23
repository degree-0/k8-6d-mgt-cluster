# Stack Auth / Hexclave SSO Troubleshooting Log

**Date:** 2026-06-21  
**Service:** Stack Auth (`stackauth/server:latest`)  
**URL:** https://sso.6degrees.com.sa  
**Cluster:** `6-degrees-management-cluster`  
**Namespace:** `six-degrees-apps`  
**ArgoCD app:** `stackauth`  
**Git path:** `kubernetes/99-argocd/99-deleted/12-deleted-stack-auth-test/`

---

## Executive Summary

Self-hosted Stack Auth (Hexclave) on `sso.6degrees.com.sa` was debugged end-to-end: dashboard redirect loops, Vault-backed secrets, halapass project billing onboarding, noisy payments metering errors, Microsoft OAuth 502 via nginx, and Microsoft tenant configuration for open sign-in.

**Current state (as of 2026-06-21):**

- Dashboard and API work on a single host (`sso.6degrees.com.sa`)
- Internal project keys synced from Vault
- halapass onboarding marked `completed`, payments disabled
- Ingress patched for OAuth large-header 502s
- halapass Microsoft `microsoftTenantId` set to `common`
- Azure app registration must still allow multi-tenant + personal accounts

---

## Architecture

| Component | Details |
|---|---|
| Ingress | `/api` → port 8102 (API), `/` → port 8101 (dashboard) |
| Secrets | Vault `six-degrees/stack-auth-test/secrets` → ExternalSecret `stack-auth-secret` |
| ConfigMap | `stack-auth-configmap` — URLs, `STACK_RUN_SEED_SCRIPT: false` |
| Database | Postgres `stackauth_db` |
| ClickHouse | `stack-auth-clickhouse` (emptyDir) |
| Seed | Disabled — dev project in DB causes seed crash |

### Key files

| File | Purpose |
|---|---|
| `es.yaml` | DB, internal keys, S3, Freestyle, Vercel sandbox, email vars |
| `cm.yaml` | Public URLs on `sso.6degrees.com.sa`, migrations, ClickHouse URL |
| `deployment.yaml` | `envFrom`: secret + clickhouse-secret + configmap |
| `ingress.yaml` | TLS, proxy buffer fix for OAuth |
| `clickhouse.yaml` | ClickHouse deployment |
| `ingress.yaml` | Single-host routing |

---

## Issues Resolved

### 1. Dashboard redirect loop / invalid publishable key

**Symptoms:** Redirect loop on dashboard; invalid publishable key errors.

**Root cause:** Internal project API keys out of sync. Entrypoint reads `STACK_INTERNAL_PROJECT_*` (not only `STACK_SEED_*`). Seed skipped due to existing dev project.

**Fixes:**

- Vault keys for internal project publishable/secret/admin keys
- `es.yaml` mappings for `STACK_INTERNAL_PROJECT_*` and seed vars
- Pod restart after ExternalSecret sync (`envFrom` does not hot-reload)
- SQL upsert to `ApiKeySet` for project `internal`
- `STACK_RUN_SEED_SCRIPT: false` in `cm.yaml`

### 2. Secrets moved to Vault

SMTP, S3 (Hetzner Object Storage), Freestyle, Vercel Sandbox tokens added to Vault + `es.yaml`.

Critical vars:

- `STACK_INTERNAL_PROJECT_PUBLISHABLE_CLIENT_KEY`
- `STACK_INTERNAL_PROJECT_SECRET_SERVER_KEY`

**Not in es.yaml:** `STACK_STRIPE_SECRET_KEY` (only needed if enabling Payments).

### 3. Email `render-email` failures

Freestyle works for simple templates; React Email templates fail → fallback to Vercel Sandbox. Added `STACK_VERCEL_SANDBOX_TOKEN` (+ team/project IDs) to `es.yaml` — values must exist in Vault.

### 4. halapass project stuck on billing (payments setup)

**Project:** `dac776e0-d787-42f9-8ad0-34050ce73c19` (halapass)

| | halapass (stuck) | subscriptions-tracker (working) |
|---|---|---|
| `onboardingStatus` | `payments_setup` | `completed` |
| `onboardingState` | included `"payments"` | `null` |
| `apps.installed.payments.enabled` | not set | `false` |

Skipping billing UI called `POST /api/v1/internal/payments/setup` → 500 (no Stripe key).

**DB fix applied:**

```sql
BEGIN;
UPDATE "Project"
SET "onboardingStatus" = 'completed', "onboardingState" = NULL, "updatedAt" = NOW()
WHERE id = 'dac776e0-d787-42f9-8ad0-34050ce73c19';

UPDATE "BranchConfigOverride"
SET config = config || '{"apps.installed.payments.enabled": false}'::jsonb, "updatedAt" = NOW()
WHERE "projectId" = 'dac776e0-d787-42f9-8ad0-34050ce73c19' AND "branchId" = 'main';
COMMIT;
```

### 5. Microsoft OAuth 502 + browser CORS error

**Symptoms:** Login with Microsoft failed; browser showed CORS error and `502 Bad Gateway` on `GET /api/v1/auth/oauth/authorize/microsoft`.

**Root cause:** nginx ingress — `upstream sent too big header while reading response header from upstream`. OAuth authorize responses return large `Set-Cookie` headers; default proxy buffers too small. CORS error was a symptom of 502 (no CORS headers on gateway error).

**Fix:** Added to `ingress.yaml`:

```yaml
nginx.ingress.kubernetes.io/proxy-buffer-size: "128k"
nginx.ingress.kubernetes.io/proxy-buffers-number: "8"
```

Sync ArgoCD app `stackauth`. No pod restart required.

### 6. Microsoft “We couldn't find a Microsoft account”

**Symptoms:** OAuth reached Microsoft login page; Microsoft rejected the account.

**Root cause:** halapass `microsoftTenantId` was empty (`""`) in `EnvironmentConfigOverride` config key `auth.oauth.providers.microsoft`. Empty tenant uses `/common/` inconsistently; Azure app must match account types allowed.

**User goal:** Everyone should be able to sign in (any Microsoft account).

**Fix applied (DB):**

```javascript
// config key is flat: "auth.oauth.providers.microsoft"
config["auth.oauth.providers.microsoft"].microsoftTenantId = "common"
```

**Required Azure Portal change (manual):**

App registration → Authentication → Supported account types:

> Accounts in any organizational directory (Multitenant) and personal Microsoft accounts

Redirect URI must include:

```
https://sso.6degrees.com.sa/api/v1/auth/oauth/callback/microsoft
```

---

## Known Noise (Low Impact)

### Payments `update-quantity` 500

**Endpoint:** `POST /api/v1/payments/items/team/{teamId}/analytics_events/update-quantity`  
**Body:** `{"delta":-1}`

**Backend error:** `Cannot use $replica inside of a transaction` (Hexclave bug).

Occurs during internal dashboard metering and sometimes during OAuth token save (`saveToken` → `tryDecreaseQuantity`). ~400+ times/24h. **Does not block auth** when OAuth authorize succeeds. Safe to ignore without Stripe/billing. Possible fix: upgrade Hexclave image.

### Svix webhook errors

Background `Error sending Svix webhook!` on anonymous sign-up — non-blocking.

### Analytics not enabled

`POST /api/v1/analytics/events/batch` → “Analytics is not enabled for this project.” Expected when analytics app disabled.

---

## Operational Notes

1. **After Vault / ExternalSecret changes:** `kubectl rollout restart deployment/stack-auth -n six-degrees-apps`
2. **Keep `STACK_RUN_SEED_SCRIPT: false`** unless dev project `5f2a45c8-9096-4f0b-b987-7640a47f7a79` is removed from DB
3. **ArgoCD sync** for git changes — do not `kubectl apply` without approval unless explicitly agreed
4. **Stripe `account-info` errors** in logs are expected without `STACK_STRIPE_SECRET_KEY`
5. **Microsoft sign-in** covers Microsoft accounts only; Gmail users need Google OAuth provider added separately
6. **Rotate Azure client secret** if exposed during debugging sessions

---

## halapass OAuth Config Snapshot (2026-06-21)

| Setting | Value |
|---|---|
| Project ID | `dac776e0-d787-42f9-8ad0-34050ce73c19` |
| `allowSignIn` | `true` |
| `microsoftTenantId` | `common` (updated from empty) |
| `customCallbackUrl` | `https://sso.6degrees.com.sa/api/v1/auth/oauth/callback/microsoft` |
| Local dev redirect | `http://localhost:3001/handler/oauth-callback` |
| Config storage | `EnvironmentConfigOverride.config` with flat key `auth.oauth.providers.microsoft` |

---

## Condensed Timeline

1. Stack Auth dashboard redirect loop → fixed internal project keys + Vault + DB `ApiKeySet`
2. Secrets externalized to Vault; seed disabled
3. halapass stuck on billing → DB onboarding + `payments.enabled: false`
4. Log noise from payments metering → documented as Hexclave bug, ignore without billing
5. Microsoft login 502 → nginx proxy buffer ingress patch → **works**
6. Microsoft account not found → tenant empty → set to `common` + Azure multi-tenant config required

---

## Open / Optional Follow-ups

- [ ] Confirm Azure app registration supports multitenancy + personal accounts
- [ ] Populate Vercel Sandbox vars in Vault if email templates still fail
- [ ] Add `STACK_STRIPE_SECRET_KEY` only if Payments needed later
- [ ] Add Google OAuth if non-Microsoft users must sign in
- [ ] Upgrade Hexclave to reduce `$replica` metering errors
- [ ] Commit/push `ingress.yaml` if not yet on remote ArgoCD tracks

# Stack Auth (retired)

Test deployment of [Stack Auth](https://stack-auth.com/) — replaced by Keycloak.

## What was deployed

- **ArgoCD app**: `stack-auth-test` (project: `six-degrees`)
- **Namespace**: `six-degrees-apps`
- **URL**: `sso.6degrees.com.sa` (dashboard + API on one host; `sso.dashboard.*` deprecated)
- **Secrets**: Vault path `six-degrees/stack-auth-test/secrets`
- **Database**: External PostgreSQL (connection string in Vault)

## Stack Auth + ClickHouse

`:latest` requires ClickHouse since 2026-01-28. This folder deploys:

- `stackauth/server:latest`
- `stack-auth-clickhouse` (ClickHouse 25.10, ephemeral `emptyDir` — no PVC)
- `STACK_CLICKHOUSE_URL` + admin/external passwords via `stack-auth-clickhouse-secret`

`STACK_RUN_SEED_SCRIPT` is `true` — upserts the internal dashboard project keys and trusted domains on startup. Internal project keys are synced from Vault via `stack-auth-secret` (see `es.yaml`).

### Vault keys (`six-degrees/stack-auth-test/secrets`)

| Property | Purpose |
|---|---|
| `STACK_DATABASE_CONNECTION_STRING` | Postgres (pooled) |
| `STACK_DIRECT_DATABASE_CONNECTION_STRING` | Postgres (direct) |
| `STACK_SERVER_SECRET` | Stack Auth server secret |
| `NEXT_PUBLIC_STACK_PROJECT_ID` | Dashboard project id (`internal`) |
| `NEXT_PUBLIC_STACK_PUBLISHABLE_CLIENT_KEY` | Baked-in publishable key (must match seed) |
| `STACK_SECRET_SERVER_KEY` | Baked-in secret server key (must match seed) |
| `STACK_SEED_INTERNAL_PROJECT_PUBLISHABLE_CLIENT_KEY` | Same value as publishable key above |
| `STACK_SEED_INTERNAL_PROJECT_SECRET_SERVER_KEY` | Same value as secret server key above |
| `STACK_SEED_INTERNAL_PROJECT_SUPER_SECRET_ADMIN_KEY` | Admin key for internal project |

## Dashboard redirect loop

If `/` ↔ `/projects` loops with no login form, check logs for:

```
The publishable key is not valid for the project "internal"
```

That means dashboard env keys don't match Postgres. Fix: stable `STACK_SEED_INTERNAL_PROJECT_*` keys in Vault + `STACK_RUN_SEED_SCRIPT: true` (synced via `es.yaml`).

Splitting dashboard and API across subdomains also breaks cookies — use **`https://sso.6degrees.com.sa`** only (`/api` → API, `/` → dashboard).

ClickHouse uses ephemeral `emptyDir` (no PVC) — data is rebuilt from Postgres on pod restart. ClickHouse must be ready before Stack Auth migrations finish.

```bash
kubectl get pods -n six-degrees-apps | grep stack-auth
kubectl logs -l app=stack-auth-clickhouse -n six-degrees-apps --tail=30
kubectl logs -l app=stack-auth -n six-degrees-apps --tail=50
```

Stack Auth `:latest` needs at least **2Gi memory** — the Bulldozer Postgres→ClickHouse sync plus two Next.js processes OOM at 512Mi.

## Retirement

```bash
# 1. Delete the ArgoCD Application (prune removes all managed resources)
kubectl delete application stack-auth-test -n argocd

# 2. Verify cleanup
kubectl get all,ingress,externalsecret -n six-degrees-apps | grep stack-auth

# 3. Delete any leftover secrets (if ArgoCD missed them)
kubectl delete externalsecret stack-auth-secret -n six-degrees-apps --ignore-not-found
kubectl delete secret stack-auth-secret stack-auth-internal-project-secret stack-auth-tls stack-auth-test-tls -n six-degrees-apps --ignore-not-found
```

## PostgreSQL cleanup (pgAdmin)

```sql
-- Replace 'stack_auth' with the actual database name from Vault
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'stack_auth';

DROP DATABASE IF EXISTS stack_auth;
DROP USER IF EXISTS stack_auth;
```

## Vault cleanup (optional)

Remove `six-degrees/stack-auth-test/secrets` from Vault once nothing references it.

## DNS

`sso.6degrees.com.sa` will be free for Keycloak after retirement. Remove or repoint DNS for `sso.dashboard.6degrees.com.sa` if it still exists.

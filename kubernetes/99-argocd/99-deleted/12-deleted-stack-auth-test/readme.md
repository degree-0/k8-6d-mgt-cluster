# Stack Auth (retired)

Test deployment of [Stack Auth](https://stack-auth.com/) — replaced by Keycloak.

## What was deployed

- **ArgoCD app**: `stack-auth-test` (project: `six-degrees`)
- **Namespace**: `six-degrees-apps`
- **URLs**: `sso.6degrees.com.sa`, `sso.dashboard.6degrees.com.sa`
- **Secrets**: Vault path `six-degrees/stack-auth-test/secrets`
- **Database**: External PostgreSQL (connection string in Vault)

## Stack Auth + ClickHouse

`:latest` requires ClickHouse since 2026-01-28. This folder deploys:

- `stackauth/server:latest`
- `stack-auth-clickhouse` (ClickHouse 25.10, 5Gi Longhorn PVC)
- `STACK_CLICKHOUSE_URL` + admin/external passwords via `stack-auth-clickhouse-secret`

`STACK_RUN_SEED_SCRIPT` is `false` — the Postgres DB is already populated; re-seeding breaks on schema drift.

## Troubleshooting 502 Bad Gateway

```bash
kubectl get pods -n six-degrees-apps | grep stack-auth
kubectl logs -l app=stack-auth-clickhouse -n six-degrees-apps --tail=30
kubectl logs -l app=stack-auth -n six-degrees-apps --tail=50
```

ClickHouse must be ready before Stack Auth migrations finish. If Stack Auth crash-loops, check ClickHouse pod first.

## Retirement

```bash
# 1. Delete the ArgoCD Application (prune removes all managed resources)
kubectl delete application stack-auth-test -n argocd

# 2. Verify cleanup
kubectl get all,ingress,externalsecret -n six-degrees-apps | grep stack-auth

# 3. Delete any leftover secrets (if ArgoCD missed them)
kubectl delete externalsecret stack-auth-secret -n six-degrees-apps --ignore-not-found
kubectl delete secret stack-auth-secret stack-auth-tls stack-auth-test-tls -n six-degrees-apps --ignore-not-found
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

`sso.6degrees.com.sa` and `sso.dashboard.6degrees.com.sa` will be free for Keycloak after retirement.

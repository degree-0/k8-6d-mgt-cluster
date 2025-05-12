# Vault - Secrets Management

This component provides secure secret storage and management.

## Installation

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault
helm show values hashicorp/vault --version 0.29.1 > defaults.yaml
helm upgrade --install vault hashicorp/vault --namespace "vault" --create-namespace \
    --set injector.enabled=false \
    --set server.ingress.enabled=true \
    --set 'server.ingress.annotations.cert-manager\.io/cluster-issuer=http01-clusterissuer' \
    --set server.ingress.ingressClassName=nginx \
    --set server.ingress.hosts[0].host=vault.6degrees.com.sa \
    --set server.ingress.tls[0].hosts[0]=vault.6degrees.com.sa \
    --set server.ingress.tls[0].secretName=vault-tls-cert

```

## Initial Setup

1. Initialize Vault:
```bash
kubectl exec -n vault -it vault-0 -- vault operator init
```
2. Unseal Vault using the provided keys

3. Create authentication methods

4. Revoke root token for security

> root token is only for setting up authentication methods, then it should be revoked
create userpass auth method and create your admin password

## Verification

```bash
kubectl get pods -n vault
kubectl get ingress -n vault
kubectl get certificate -n vault
```

## Maintenance
- Regularly rotate secrets
- Monitor unseal status
- Backup Vault data

# Cert-Manager with Let's Encrypt

This component manages TLS certificates using Let's Encrypt.

## Installation

```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm search repo cert-manager
helm show values jetstack/cert-manager --version 1.16.3 > defaults.yaml
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
  
# create external secret for DNS provider API token
kubectl apply -f cloudflare-es.yaml

# create cluster issuers
kubectl apply -f http01-clusterissuer.yaml
kubectl apply -f dns01-clusterissuer.yaml
```

## DNS-01 Setup

For DNS-01 challenge (required for non-HTTP services like SMTP):

1. **Get Cloudflare API Token** (or configure your DNS provider):
   - Login to Cloudflare Dashboard
   - Go to "My Profile" → "API Tokens"
   - Create token with Zone:Edit permissions for your domain

2. **Store token in Vault**:
   ```bash
   # Store the API token in Vault under the path:
   # six-degrees/cert-manager/secrets
   # with property: CLOUDFLARE_API_TOKEN
   
   # The ExternalSecret will automatically create the secret
   kubectl apply -f cloudflare-es.yaml
   ```

3. **Verify DNS-01 issuer**:
   ```bash
   kubectl describe clusterissuer dns01-clusterissuer
   kubectl get externalsecret -n cert-manager
   kubectl get secret cloudflare-api-token-secret -n cert-manager
   ```

## Verification

```bash
kubectl get pods -n cert-manager
kubectl get certificates -A
kubectl get certificaterequests -A
kubectl get clusterissuers
```

## Configuration

Key configurations:
- HTTP01 challenge solver (for web services)
- DNS01 challenge solver (for any service, including SMTP)
- ClusterIssuer configuration
- Certificate renewal policies

## Maintenance
- Monitor certificate renewals
- Check certificate expiration dates
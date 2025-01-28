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
  
# create cluster issuer
kubectl apply -f http01-clusterissuer.yaml
```

## Verification

```bash
kubectl get pods -n cert-manager
kubectl get certificates -A
kubectl get certificaterequests -A
```

## Configuration

Key configurations:
- HTTP01 challenge solver
- ClusterIssuer configuration
- Certificate renewal policies

## Maintenance
- Monitor certificate renewals
- Check certificate expiration dates
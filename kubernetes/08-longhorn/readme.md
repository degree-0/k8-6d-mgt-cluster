# Longhorn

## Installation

```bash
helm repo add longhorn https://charts.longhorn.io/
helm repo update
helm search repo longhorn
helm show values longhorn/longhorn --version 1.8.1 > defaults.yaml

kubectl apply -f external-secrets.yaml
kubectl get externalsecrets

helm upgrade --install longhorn longhorn/longhorn --namespace longhorn --create-namespace -f values.yaml
```

## Verification

```bash
kubectl get all -n longhorn
kubectl get ingress -n longhorn
```

## Access

- [Longhorn UI](https://longhorn.6degrees.com.sa/)

## Troubleshooting
- [Mount Volume](https://longhorn.io/docs/archives/1.2.3/advanced-resources/data-recovery/export-from-replica/)


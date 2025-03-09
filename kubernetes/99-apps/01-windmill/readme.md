# Windmill

## Installation

```bash
helm repo add windmill https://windmill-labs.github.io/windmill-helm-charts/
helm repo update
helm search repo windmill
helm show values windmill/windmill --version 2.0.392 > defaults.yaml

kubectl apply -f external-secrets.yaml

helm upgrade --install mywindmill windmill/windmill -n windmill --create-namespace --values values.yaml
```

## Verification

```bash
kubectl get all -n windmill
kubectl get ingress -n windmill
```

## Access

- [Windmill Admin Panel](https://windmill.6degrees.com.sa/)


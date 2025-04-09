# Prometheus

## Installation

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo prometheus-community/kube
helm show values prometheus-community/kube-prometheus-stack --version 69.8.0 > defaults.yaml

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack /
    -n prometheus /
    --create-namespace 
    /--values values.yaml
```

## Verification

```bash
kubectl get all -n prometheus
kubectl get ingress -n prometheus
```
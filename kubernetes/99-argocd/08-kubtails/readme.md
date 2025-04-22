# Kubetails

## Installation

```bash
helm repo add kubetail https://kubetail-org.github.io/helm-charts/
helm repo update
helm search repo kubetail
helm show values kubetail/kubetail --version 0.9.13 > defaults.yaml

kubectl apply -f external-secrets.yaml
kubectl get externalsecrets

helm upgrade --install longhorn longhorn/longhorn --namespace longhorn --create-namespace -f values.yaml
```

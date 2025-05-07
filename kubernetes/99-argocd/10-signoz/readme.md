# Kubetails

## Installation

```bash
helm repo add signoz https://charts.signoz.io

helm repo update
helm search repo signoz
helm show values signoz/signoz --version 0.79.2 > defaults.yaml

helm upgrade --install signoz signoz/signoz --namespace signoz --create-namespace --wait --timeout 1h -f values.yaml
```

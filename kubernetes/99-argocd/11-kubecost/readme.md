# Signoz

## Installation

```bash
helm repo add kubecost https://kubecost.github.io/cost-analyzer/

helm repo update
helm search repo kubecost
helm show values kubecost/cost-analyzer --version 2.7.2 > defaults.yaml

helm upgrade --install signoz signoz/signoz --namespace signoz --create-namespace --wait --timeout 1h -f values.yaml
```

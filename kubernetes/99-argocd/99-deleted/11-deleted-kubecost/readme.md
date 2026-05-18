# Signoz

## Installation

```bash
helm repo add kubecost https://kubecost.github.io/cost-analyzer/

helm repo update
helm search repo kubecost
helm show values kubecost/cost-analyzer --version 2.7.2 > defaults.yaml

helm upgrade --install kubecost kubecost/cost-analyzer --namespace kubecost --create-namespace  -f values.yaml
```

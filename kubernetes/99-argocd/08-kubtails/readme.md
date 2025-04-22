# Kubetails

## Installation

```bash
helm repo add kubetail https://kubetail-org.github.io/helm-charts/
helm repo update
helm search repo kubetail
helm show values kubetail/kubetail --version 0.9.13 > defaults.yaml

helm upgrade --install kubetail kubetail/kubetail --namespace kubetail --create-namespace -f values.yaml
```

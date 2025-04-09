# Kong API Gateway

This describes the manual way to implement, however, I moved my implementation
to argocd. This component provides API gateway and management capabilities.

## Installation

```bash
helm repo add imgproxy https://helm.imgproxy.net/
helm repo update
helm search repo imgproxy
helm show values imgproxy/imgproxy --version 0.9.0 > defaults.yaml
helm upgrade --install imgproxy imgproxy/imgproxy --namespace imgproxy --create-namespace -f values.yaml
```

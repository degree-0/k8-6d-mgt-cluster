# ArgoCD - GitOps Continuous Delivery

This component provides GitOps capabilities for the cluster.

## Installation

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm search repo argo/argo-cd
helm show values argo/argo-cd --version 7.7.18 > defaults.yaml
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values values.yaml
```

## Configuration

Key configurations:
- TLS with Let's Encrypt
- SSO integration
- Application definitions
- RBAC policies

## Customizations

for cert-manager auto letsencrypt to work, make sure you set

```yaml
# values.yaml
server.ingress.annotation: {
    cert-manager.io/cluster-issuer: "http01-clusterissuer"
}
server.tls: true
```

## Access

1. Get initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

2. Access UI at: https://argocd.yourdomain.com

3. Reset password and delete initial secret:
```bash
kubectl delete secret argocd-initial-admin-secret -n argocd
```

## Maintenance
- Regularly update ArgoCD
- Monitor application sync status
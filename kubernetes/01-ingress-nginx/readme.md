# Ingress-NGINX Controller

This component installs the NGINX Ingress Controller using Helm.

## Installation

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress ingress-nginx/ingress-nginx
```

## Upgrade for TCP Services (SMTP)

To enable TCP services support for SMTP:

```bash
# Upgrade with TCP services configuration
helm upgrade --install ingress ingress-nginx/ingress-nginx -f values-with-tcp.yaml

```

## Verification

```bash
kubectl get services
```

## Configuration

Key configurations:
- Automatic SSL with Cert-Manager
- HTTP/HTTPS redirection
- Load balancer configuration

## Maintenance
- Regularly update the Helm chart
- Monitor ingress controller logs
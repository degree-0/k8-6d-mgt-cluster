# 6degrees-management-cluster

 K8 Management Cluster

## Overview

Kubernetes management cluster configuration for 6degrees infrastructure.

## Prerequisites

- Kubernetes Cluster
- Helm 3.x
- kubectl configured

## Repository Structure

```bash
.
├── README.md
├── helmfile.yaml
├── namespaces/
│   ├── management.yaml
│   └── shared-services.yaml
├── argocd/
│   └── installation.yaml
├── vault/
│   └── installation.yaml
└── monitoring/
    └── prometheus-values.yaml
```

## Getting Started

### Initialize Namespaces

```bash
kubectl apply -f namespaces/
```

### Install ArgoCD

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n management
```

### Install Vault

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n management
```

## Security Considerations

- Use least-privilege access
- Rotate secrets regularly
- Implement network policies

## Maintenance

Regularly update helm charts and review configurations.

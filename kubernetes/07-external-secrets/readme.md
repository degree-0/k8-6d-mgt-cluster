# External Secrets Operator

This component synchronizes Kubernetes secrets with external secret management systems like Vault.

## Installation

```bash
cd kubernetes/07-external-secrets
helm repo add external-secrets https://charts.external-secrets.io
helm search repo external-secrets
helm show values external-secrets/external-secrets --version 0.9.13 > defaults.yaml
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --values values.yaml
```

## Vault Integration Setup

1. Create a Vault token for External Secrets:
```bash
# Create a policy in Vault
kubectl exec -it -n vault vault-0 -- /bin/sh
vault policy write external-secrets - <<EOF
path "kv/data/*" {
  capabilities = ["read"]
}
EOF

# Create a token with the policy
vault token create -policy=external-secrets
```

2. Store the Vault token as a Kubernetes secret:
```bash
kubectl create namespace external-secrets
kubectl create secret generic vault-token \
  --namespace external-secrets \
  --from-literal=token=hvs.your-vault-token-here
```

3. Apply the ClusterSecretStore configuration:
```bash
kubectl apply -f cluster-secret-store.yaml
```

## Verification

```bash
kubectl get pods -n external-secrets
kubectl get clustersecretstores
```

## Usage

### Create an ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vault-example
  namespace: default
spec:
  refreshInterval: "15s"
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: example-secret
    creationPolicy: Owner
  data:
    - secretKey: test2
      remoteRef:
        key: test
        property: test2
```

### Verify Secret Creation

```bash
kubectl get externalsecrets
kubectl get secret example-secret -o jsonpath='{.data.test2}' | base64 -d
```

## Troubleshooting

- Check External Secrets controller logs:
```bash
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

- Check the status of your ExternalSecret:
```bash
kubectl describe externalsecret vault-example
```

- Verify Vault connectivity using a temporary debug pod:
```bash
# Create a temporary debug pod with curl installed
kubectl run debug-pod --image=curlimages/curl -n external-secrets --rm -it -- sh

# From inside the debug pod, test connectivity to Vault
curl http://vault.vault.svc.cluster.local:8200/v1/sys/health

# Exit the debug pod when done
exit
```

- Alternative: Use port-forwarding to test Vault connectivity:
```bash
# Forward Vault's port to your local machine
kubectl port-forward -n vault svc/vault 8200:8200

# In another terminal, test connectivity
curl http://localhost:8200/v1/sys/health
```

- If you see TLS errors, you may need to add the CA certificate or disable TLS verification:
```yaml
# Add to your ClusterSecretStore if needed
spec:
  provider:
    vault:
      # For insecure development environments only
      caBundle: "" # Empty to disable verification (NOT recommended for production)
```

- For production, properly configure TLS:
```yaml
# Secure configuration with CA certificate
spec:
  provider:
    vault:
      caProvider:
        type: ConfigMap
        name: vault-ca
        namespace: external-secrets
        key: ca.crt
```

- Check if the Vault token has the correct permissions:
```bash
# Get into the Vault pod
kubectl exec -it -n vault vault-0 -- sh

# Check if the token can access the path
VAULT_TOKEN=your-token vault kv get -mount=kv test

# Check token capabilities
VAULT_TOKEN=your-token vault token capabilities kv/data/test
```

## Maintenance
- Rotate Vault tokens regularly
- Monitor External Secrets controller logs
- Update the Helm chart periodically
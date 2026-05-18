# CouchDB

Apache CouchDB is a database featuring seamless multi-master sync, that scales from big data to mobile, with an intuitive HTTP/JSON API and designed for reliability.

## Installation

```bash
helm repo add apache-couchdb https://apache.github.io/couchdb-helm
helm repo update
helm search repo apache-couchdb/couchdb
helm show values apache-couchdb/couchdb --version 4.6.2 > defaults.yaml

kubectl create namespace couchdb
kubectl apply -f external-secrets.yaml
kubectl get externalsecrets

helm upgrade --install couchdb apache-couchdb/couchdb --namespace couchdb --create-namespace -f values.yaml
```

## Verification

```bash
kubectl get all -n couchdb
kubectl get ingress -n couchdb
kubectl get pvc -n couchdb
```

## Access

- [CouchDB Web Interface](https://couchdb.6degrees.com.sa/)
- [CouchDB Fauxton UI](https://couchdb.6degrees.com.sa/_utils)

## Configuration

### Cluster Setup

The deployment is configured with:
- **Cluster Size**: 3 nodes for high availability
- **Persistent Storage**: 20Gi per node
- **Auto Setup**: Enabled to automatically finalize cluster after installation

### Authentication

CouchDB uses external secrets from Vault for:
- Admin username and password
- Cookie authentication secret
- Erlang cookie for cluster communication
- Basic auth for ingress

Secrets are managed via External Secrets Operator and stored in Vault under `mfo/private/couchdb/secrets`.

### Ingress

The ingress is configured with:
- TLS termination via cert-manager
- Basic authentication for web access
- Hostname: `couchdb.6degrees.com.sa`

## Maintenance

- Monitor cluster health via Fauxton UI
- Backup persistent volumes regularly
- Review and update CouchDB configuration as needed
- Monitor resource usage and adjust limits if necessary


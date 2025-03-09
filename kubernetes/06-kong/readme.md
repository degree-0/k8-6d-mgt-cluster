# Kong API Gateway

This component provides API gateway and management capabilities.

## Installation

```bash
helm repo add kong https://charts.konghq.com
helm repo update
helm search repo kong
helm show values kong/kong --version 2.47.0 > defaults.yaml

kubectl apply -f external-secrets.yaml
kubectl get externalsecrets

helm upgrade --install kong kong/kong --namespace kong --create-namespace -f values.yaml
```

## Verification

```bash
kubectl get all -n kong
kubectl get ingress -n kong
```

## Access

- [Kong Manager](https://manager.kong.6degrees.com.sa/)
- [Kong Admin API](https://admin.kong.6degrees.com.sa/)
- [Kong API Gateway](https://api.kong.6degrees.com.sa/)

## Configuration

### Example Service Configuration
```json
{
  "tags": [
    "test",
    "dummy",
    "jsonplaceholder"
  ],
  "name": "jsonplaceholder.typicode.com",
  "port": 443,
  "protocol": "https",
  "path": "/users",
  "host": "jsonplaceholder.typicode.com",
  "enabled": true
}
```

### Example Route Configuration
```json
{
  "service": {
    "id": "point to the service"
  },
  "name": "test-route",
  "protocols": [
    "http",
    "https"
  ],
  "strip_path": true,
  "methods": [
    "GET"
  ],
  "paths": [
    "/test-user",
    "/test-something"
  ]
}
```

## Testing

```bash
curl https://api.kong.6degrees.com.sa/test-user/1
curl https://api.kong.6degrees.com.sa/test-something/1
```

These routes will proxy to:
```bash
curl https://jsonplaceholder.typicode.com/users/1
```

## Maintenance

- Regularly update Kong components
- Monitor API traffic and logs
- Review and update routes and services
- Backup Kong configuration
# F6sny App

## API

Helm Chart
```bash
cd 01-strapi-api/helm
helm upgrade --install strapi strapi-chart -f app.yaml --atomic

```

## Frontend

```bash
cd 02-next-frontend
kubectl apply -f ./
```

## Troubleshooting

### To recreate pods
```bash
kubectl rollout restart deployment f6sny-next-frontend
kubectl rollout status deployment f6sny-next-frontend
```

### Debug secrets

```bash
kubectl delete externalsecrets f6sny-secrets
kubectl delete secret f6sny-frontend-secrets
kubectl apply -f extenal-secrets.yaml
kubectl get secret f6sny-frontend-secrets -o jsonpath='{.data.API_URL}' | base64 --decode
```
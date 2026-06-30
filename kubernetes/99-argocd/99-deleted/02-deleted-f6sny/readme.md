# F6sny App

## API

moved to argocd.
repo `https://github.com/f6sny/api.f6sny.com`

## Frontend

Moved to argocd.
repo `https://github.com/f6sny/www.f6sny.com/tree/next_js`

```bash
cd 02-next-frontend
kubectl apply -f ./
```

## Troubleshooting

### To recreate pods
```bash
kubectl rollout restart deployment f6sny-next-frontend
kubectl rollout status deployment f6sny-next-frontend -w
```

### Debug secrets

```bash
kubectl delete externalsecrets f6sny-secrets
kubectl delete secret f6sny-frontend-secrets
kubectl apply -f external-secrets.yaml
kubectl get secret f6sny-frontend-secrets -o jsonpath='{.data.API_URL}' | base64 --decode
```
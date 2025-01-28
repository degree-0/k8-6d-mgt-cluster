`$ helm repo add argo https://argoproj.github.io/argo-helm`

`$ helm search repo argo/argo-cd`

`helm show values argo/argo-cd --version 7.7.18 > _values.yaml`

customize values

`helm upgrade --install argocd argo/argo-cd --values values.yaml --namespace argocd --create-namespaceca`

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
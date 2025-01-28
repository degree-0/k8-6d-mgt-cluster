helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress ingress-nginx/ingress-nginx
kubectl get services
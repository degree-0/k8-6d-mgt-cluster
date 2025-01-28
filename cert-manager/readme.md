$ helm repo add jetstack https://charts.jetstack.io --force-update

$ helm search repo cert-manager
helm show values jetstack/cert-manager --version 1.16.3 > defaults.yaml

helm install cert-manager jetstack/cert-manager   --namespace cert-manager --create-namespace  --set crds.enabled=true

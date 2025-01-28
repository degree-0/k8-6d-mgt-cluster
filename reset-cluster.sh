#!/bin/bash

echo "🗑️  Starting cluster reset..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to force delete namespace
force_delete_namespace() {
    local ns=$1
    echo "    ⮑ Force deleting namespace: $ns"
    
    # Remove from kubectl proxy
    (
        kubectl proxy &
        PROXY_PID=$!
        sleep 2
        
        # Get namespace manifest
        kubectl get namespace $ns -o json > tmp_ns.json
        
        # Remove finalizers
        sed -i 's/"finalizers": \[.*\]/"finalizers": []/' tmp_ns.json
        
        # Force update through API
        curl -k -H "Content-Type: application/json" -X PUT --data-binary @tmp_ns.json http://127.0.0.1:8001/api/v1/namespaces/$ns/finalize
        
        kill $PROXY_PID
        rm -f tmp_ns.json
    ) 2>/dev/null || true
    
    # Direct delete
    kubectl delete namespace $ns --force --grace-period=0 2>/dev/null || true
    
    # If namespace still exists, try raw API call
    if kubectl get namespace $ns 2>/dev/null; then
        echo "        ⮑ Namespace still exists, trying raw API call..."
        kubectl get namespace $ns -o json | \
        tr -d "\n" | \
        sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | \
        kubectl replace --raw /api/v1/namespaces/$ns/finalize -f - 2>/dev/null || true
    fi
}

# Check required commands
for cmd in kubectl helm helmfile; do
    if ! command_exists "$cmd"; then
        echo "❌ $cmd is required but not installed."
        exit 1
    fi
done

echo "🧹 Force removing ArgoCD resources..."
# Remove finalizers from ArgoCD resources
for resource in applications appprojects applicationsets; do
    echo "    ⮑ Removing finalizers from $resource"
    kubectl get $resource.argoproj.io -n argocd -o name 2>/dev/null | while read -r name; do
        echo "        ⮑ Cleaning $name"
        kubectl patch ${name} -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
    done
done

# Force delete ArgoCD resources
echo "    ⮑ Force deleting ArgoCD resources"
kubectl delete applications.argoproj.io --all --all-namespaces --force --grace-period=0 2>/dev/null || true
kubectl delete appprojects.argoproj.io --all --all-namespaces --force --grace-period=0 2>/dev/null || true
kubectl delete applicationsets.argoproj.io --all --all-namespaces --force --grace-period=0 2>/dev/null || true

echo "🧹 Force removing Helm releases..."
helm list --all-namespaces --short | while read -r release; do
    echo "    ⮑ Removing release $release"
    helm delete "$release" --no-hooks --force 2>/dev/null || true
done

echo "🧹 Force removing cert-manager resources..."
echo "    ⮑ Removing webhook configurations"
kubectl delete validatingwebhookconfiguration cert-manager-webhook --force --grace-period=0 2>/dev/null || true
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --force --grace-period=0 2>/dev/null || true

echo "    ⮑ Removing cert-manager CRDs and resources"
for resource in certificates certificaterequests challenges clusterissuers issuers orders; do
    echo "        ⮑ Removing $resource"
    kubectl delete $resource --all --all-namespaces --force --grace-period=0 2>/dev/null || true
done

echo "🧹 Force removing Rancher resources..."
echo "    ⮑ Removing ALL webhook configurations first"
# Remove ALL webhook configurations that might block deletions
kubectl get validatingwebhookconfigurations -o name | while read webhook; do
    echo "        ⮑ Removing webhook $webhook"
    kubectl patch $webhook -p '{"webhooks": []}' --type=merge 2>/dev/null || true
    kubectl delete $webhook --force --grace-period=0 2>/dev/null || true
done

kubectl get mutatingwebhookconfigurations -o name | while read webhook; do
    echo "        ⮑ Removing webhook $webhook"
    kubectl patch $webhook -p '{"webhooks": []}' --type=merge 2>/dev/null || true
    kubectl delete $webhook --force --grace-period=0 2>/dev/null || true
done

echo "    ⮑ Removing specific Rancher webhooks"
# Remove specific Rancher webhooks
for webhook in rancher.cattle.io.secrets rancher-webhook; do
    kubectl delete validatingwebhookconfiguration $webhook --force --grace-period=0 2>/dev/null || true
    kubectl delete mutatingwebhookconfiguration $webhook --force --grace-period=0 2>/dev/null || true
done

echo "    ⮑ Removing Rancher webhook service and deployment"
kubectl delete service rancher-webhook -n cattle-system --force --grace-period=0 2>/dev/null || true
kubectl delete deployment rancher-webhook -n cattle-system --force --grace-period=0 2>/dev/null || true

# Remove Rancher admission webhook configurations
echo "    ⮑ Removing Rancher admission webhooks"
kubectl get validatingwebhookconfiguration -o name | grep -i rancher | while read webhook; do
    kubectl patch $webhook -p '{"webhooks": []}' --type=merge 2>/dev/null || true
    kubectl delete $webhook --force --grace-period=0 2>/dev/null || true
done

kubectl get mutatingwebhookconfiguration -o name | grep -i rancher | while read webhook; do
    kubectl patch $webhook -p '{"webhooks": []}' --type=merge 2>/dev/null || true
    kubectl delete $webhook --force --grace-period=0 2>/dev/null || true
done

echo "    ⮑ Removing Rancher roles and bindings"
kubectl delete clusterrolebinding cattle-admin-binding --force --grace-period=0 2>/dev/null || true
kubectl delete clusterrole cattle-admin --force --grace-period=0 2>/dev/null || true

echo "    ⮑ Removing Rancher CRDs"
kubectl delete crd -l app.kubernetes.io/instance=rancher --force --grace-period=0 2>/dev/null || true
kubectl delete crd -l release=rancher --force --grace-period=0 2>/dev/null || true

# Add specific Rancher finalizer removal
echo "    ⮑ Removing Rancher finalizers"
for ns in $(kubectl get ns -o name); do
    kubectl patch ${ns} -p '{"metadata":{"finalizers": null, "annotations": {"lifecycle.cattle.io/create.namespace-auth": null}}}' --type=merge 2>/dev/null || true
done

echo "🧹 Force removing namespaces and their contents..."
for ns in argocd cattle-system cert-manager monitoring; do
    echo "    ⮑ Cleaning namespace: $ns"
    
    # Remove Rancher-specific finalizers first
    echo "        ⮑ Removing Rancher finalizers"
    kubectl patch namespace $ns -p '{"metadata":{"annotations":{"lifecycle.cattle.io/create.namespace-auth": null}}}' --type=merge 2>/dev/null || true
    kubectl patch namespace $ns -p '{"metadata":{"finalizers": null}}' --type=merge 2>/dev/null || true
    kubectl patch namespace $ns -p '{"spec":{"finalizers": null}}' --type=merge 2>/dev/null || true
    
    echo "        ⮑ Removing namespace finalizers"
    kubectl patch namespace $ns -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
    kubectl patch namespace $ns -p '{"spec":{"finalizers":null}}' --type=merge 2>/dev/null || true
    
    echo "        ⮑ Removing pod finalizers"
    kubectl get pods -n $ns -o name 2>/dev/null | while read -r pod; do
        kubectl patch $pod -n $ns -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
    done
    
    echo "        ⮑ Removing resources in order"
    # Remove webhooks first
    kubectl delete validatingwebhookconfiguration -l app.kubernetes.io/instance=$ns --force --grace-period=0 2>/dev/null || true
    kubectl delete mutatingwebhookconfiguration -l app.kubernetes.io/instance=$ns --force --grace-period=0 2>/dev/null || true
    
    # Remove workloads
    kubectl delete deployment,statefulset,daemonset --all -n $ns --force --grace-period=0 2>/dev/null || true
    kubectl delete replicaset,pod --all -n $ns --force --grace-period=0 2>/dev/null || true
    
    # Remove networking
    kubectl delete service,ingress,endpoints --all -n $ns --force --grace-period=0 2>/dev/null || true
    
    # Remove storage
    kubectl delete pvc,pv --all -n $ns --force --grace-period=0 2>/dev/null || true
    
    # Remove config and secrets
    kubectl delete configmap,secret --all -n $ns --force --grace-period=0 2>/dev/null || true
    
    # Remove RBAC
    kubectl delete serviceaccount,role,rolebinding --all -n $ns --force --grace-period=0 2>/dev/null || true
    
    # Force delete the namespace using our function
    force_delete_namespace $ns
done

echo "🧹 Force removing CRDs..."
echo "    ⮑ Removing ArgoCD CRDs"
kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io \
    --force --grace-period=0 2>/dev/null || true

echo "    ⮑ Removing cert-manager CRDs"
kubectl delete crd certificates.cert-manager.io certificaterequests.cert-manager.io \
    challenges.acme.cert-manager.io clusterissuers.cert-manager.io issuers.cert-manager.io \
    orders.acme.cert-manager.io --force --grace-period=0 2>/dev/null || true

echo "🧹 Force removing cluster-wide resources..."
echo "    ⮑ Removing cluster roles and bindings"
kubectl delete clusterrole,clusterrolebinding --all --force --grace-period=0 2>/dev/null || true

echo "    ⮑ Removing webhook configurations"
kubectl delete validatingwebhookconfiguration --all --force --grace-period=0 2>/dev/null || true
kubectl delete mutatingwebhookconfiguration --all --force --grace-period=0 2>/dev/null || true

echo "🔄 Resetting Helm and local state..."
echo "    ⮑ Cleaning Helm cache"
rm -rf ~/.helm/repository/cache/* 2>/dev/null || true

echo "    ⮑ Removing Helm repos"
helm repo remove rancher-stable argo hashicorp jetstack 2>/dev/null || true
helm repo update

echo "✅ Cluster reset complete!"
echo "🚀 To redeploy, run: helmfile sync"